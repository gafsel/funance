/**
 * Reconstrução de saldos, sumários e XP semanal — de UM workspace ou de TODOS
 * (F1.0; `--all-workspaces` em F1.4/F1.5).
 *
 * Recalcula do zero, a partir de `installments` (ignorando as `removed`) e
 * `category_planning`:
 *   - `workspaces/{wid}/accounts/{aid}/balance/{YYYY-MM-DD}`
 *   - `workspaces/{wid}/period_summaries/{YYYY|YYYY-MM|YYYY-Www}`
 *   - `workspaces/{wid}/weekly_xp/{YYYY-Www}`
 *
 * A semântica é a dos gatilhos (`installment_handler` -> `summary.service`,
 * `finance.service.applyInstallmentBalance`, `updateXpOnInstallmentChange`):
 * o job REPRODUZ o que eles produzem, ele não redefine a regra.
 *
 * Características:
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *  - NÃO É TRANSACIONAL: lê o workspace, calcula e depois commita em lotes. Um
 *    pagamento feito no app entre a leitura e o commit é SOBRESCRITO. Rode numa
 *    janela sem uso e refaça o dry-run imediatamente antes do `--apply`.
 *  - `generalPlannedAmount` é PRESERVADO por padrão: ele só é recalculado com
 *    `--rebuild-planning`, que desde F1.5 é determinístico (cobre
 *    `startMonth..min(endMonth, horizonte)`).
 *  - IDEMPOTENTE: aplicar duas vezes seguidas não muda nada (a segunda
 *    execução reporta zero diferenças).
 *  - Escritas em lotes de no máximo 400 operações; leituras paginadas.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 * Rode o dry-run, revise a saída e só então aplique.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/rebuild_workspace.js --project=<projectId> --workspace=<workspaceId>
 *   # 2) Execução real (somente após revisar a saída do dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/rebuild_workspace.js --project=<projectId> --workspace=<workspaceId> --apply
 *   # 3) Base inteira, um workspace de cada vez (dry-run e depois --apply):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/rebuild_workspace.js --project=<projectId> --all-workspaces
 *
 * Flags:
 *   --workspace=<id>     workspace a reconstruir (obrigatória sem --all-workspaces)
 *   --all-workspaces     percorre TODOS os workspaces (`listDocuments()`), um a
 *                        um, com um relatório por workspace e um resumo final.
 *                        Continua dry-run por padrão; com --apply, aplica um a
 *                        um. Um workspace que falha não interrompe os demais.
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --page-size=<n>      tamanho da página nas leituras (default 500)
 *   --chunk-size=<n>     operações por batch (default e máximo 400)
 *   --sample-limit=<n>   caminhos listados por coleção no relatório (default 50)
 *   --prune-residual     apaga também os documentos residuais (zerados/sem
 *                        movimento). Sem a flag eles são apenas reportados.
 *   --rebuild-planning   RECALCULA o `generalPlannedAmount` a partir de
 *                        `category_planning`, cobrindo todo o período do
 *                        planejamento até o horizonte (determinístico desde
 *                        F1.5). Preenche meses passados que o incremental nunca
 *                        preencheu. Use só com dry-run revisado.
 */

import * as admin from "firebase-admin";
import { RebuildRepositoryImpl } from "../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";
import { CollectionDiff, RebuildReport, RebuildService } from "../features/finance/domain/services/rebuild.service";

export interface ScriptOptions {
    workspaceId?: string;
    allWorkspaces: boolean;
    dryRun: boolean;
    projectId?: string;
    pageSize?: number;
    chunkSize?: number;
    sampleLimit?: number;
    pruneResidual: boolean;
    rebuildPlanning: boolean;
}

export function parseArgs(argv: string[]): ScriptOptions {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const toNumber = (raw?: string) => {
        if (raw === undefined) return undefined;
        const value = Number(raw);
        return Number.isFinite(value) && value > 0 ? Math.floor(value) : undefined;
    };

    return {
        workspaceId: getValue("--workspace="),
        allWorkspaces: argv.includes("--all-workspaces"),
        // Dry-run é o padrão: só escreve com --apply explícito.
        dryRun: !argv.includes("--apply"),
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
        pageSize: toNumber(getValue("--page-size=")),
        chunkSize: toNumber(getValue("--chunk-size=")),
        sampleLimit: toNumber(getValue("--sample-limit=")),
        pruneResidual: argv.includes("--prune-residual"),
        rebuildPlanning: argv.includes("--rebuild-planning"),
    };
}

export function formatReport(report: RebuildReport): string {
    const line = (name: string, diff: CollectionDiff) =>
        `  ${name.padEnd(18)} criar=${diff.toCreate} alterar=${diff.toUpdate} apagar=${diff.toDelete} iguais=${diff.unchanged} residuais=${diff.residual} (destes, mexendo em generalPlannedAmount=${diff.generalPlannedChanges})`;

    const samples = [
        ...report.diff.balances.samples,
        ...report.diff.periodSummaries.samples,
        ...report.diff.weeklyXp.samples,
    ];

    return [
        `[rebuild_workspace] workspace=${report.workspaceId} modo=${report.mode} planejamento=${report.rebuildPlanning ? "RECALCULADO" : "preservado"} duração=${report.durationMs}ms`,
        `  lidos: parcelas=${report.scanned.installments} (removidas ignoradas=${report.scanned.installmentsRemoved}), contas=${report.scanned.accounts}, planejamentos=${report.scanned.categoryPlannings}`,
        line("balance", report.diff.balances),
        line("period_summaries", report.diff.periodSummaries),
        line("weekly_xp", report.diff.weeklyXp),
        `  total de mudanças=${report.totalChanges}, escritas commitadas=${report.writesCommitted}`,
        samples.length > 0 ? `  amostra:\n${samples.map((s) => `    - ${s}`).join("\n")}` : "  amostra: (nenhuma mudança)",
    ].join("\n");
}

/** Serviço mínimo que o script consome (facilita o teste com um dublê). */
export interface RebuildRunner {
    rebuildWorkspace(workspaceId: string, options: Record<string, any>): Promise<RebuildReport>;
}

/** Resumo de uma execução em lote. */
export interface RebuildRunSummary {
    reports: RebuildReport[];
    failures: string[];
    totalChanges: number;
    writesCommitted: number;
}

/**
 * Resolve a lista de workspaces e reconstrói um de cada vez.
 *
 * `--all-workspaces` usa `listDocuments()` de propósito: ele traz também os
 * workspaces "fantasmas" (documento apagado que ainda tem subcoleções), que um
 * `get()` não retornaria — são justamente os que acumulam saldo órfão.
 */
export async function runRebuild(
    firestore: admin.firestore.Firestore,
    service: RebuildRunner,
    options: ScriptOptions,
    log: (message: string) => void = console.log
): Promise<RebuildRunSummary> {
    const workspaceIds = options.allWorkspaces
        ? (await firestore.collection("workspaces").listDocuments()).map((ref) => ref.id).sort()
        : [options.workspaceId!];

    if (options.allWorkspaces) {
        log(`[rebuild_workspace] ${options.dryRun ? "DRY-RUN" : "APPLY"} em ${workspaceIds.length} workspace(s).`);
    }

    const summary: RebuildRunSummary = { reports: [], failures: [], totalChanges: 0, writesCommitted: 0 };

    for (const workspaceId of workspaceIds) {
        try {
            const report = await service.rebuildWorkspace(workspaceId, {
                dryRun: options.dryRun,
                pageSize: options.pageSize,
                chunkSize: options.chunkSize,
                sampleLimit: options.sampleLimit,
                pruneResidual: options.pruneResidual,
                rebuildPlanning: options.rebuildPlanning,
            });

            summary.reports.push(report);
            summary.totalChanges += report.totalChanges;
            summary.writesCommitted += report.writesCommitted;
            log(formatReport(report));
        }
        catch (error) {
            // Numa varredura da base inteira, um workspace corrompido não pode
            // derrubar os outros: registra a falha e segue.
            summary.failures.push(workspaceId);
            log(`[rebuild_workspace] workspace=${workspaceId} FALHOU — ${error}`);
        }
    }

    return summary;
}

/** Linha final de uma execução em lote. */
export function formatTotals(summary: RebuildRunSummary): string {
    return [
        `[rebuild_workspace] RESUMO: ${summary.reports.length} workspace(s) processado(s), ${summary.failures.length} falha(s).`,
        `  total de mudanças=${summary.totalChanges}, escritas commitadas=${summary.writesCommitted}`,
        summary.failures.length > 0 ? `  falharam: ${summary.failures.join(", ")}` : "  falharam: (nenhum)",
    ].join("\n");
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (!options.workspaceId && !options.allWorkspaces) {
        console.error("[rebuild_workspace] informe --workspace=<id> ou --all-workspaces.");
        process.exit(1);
    }

    if (options.workspaceId && options.allWorkspaces) {
        console.error("[rebuild_workspace] --workspace e --all-workspaces são mutuamente exclusivos.");
        process.exit(1);
    }

    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: options.projectId,
        });
        admin.firestore().settings({ ignoreUndefinedProperties: true });
    }

    const financeRepository = new FinanceRepositoryImpl();
    const service = new RebuildService(
        new RebuildRepositoryImpl(),
        new SummaryService(financeRepository),
        new FinanceService(financeRepository)
    );

    const summary = await runRebuild(admin.firestore(), service, options);

    if (options.allWorkspaces) {
        console.log(formatTotals(summary));
    }

    if (options.rebuildPlanning) {
        console.log("[rebuild_workspace] ATENÇÃO: --rebuild-planning recalcula o generalPlannedAmount de todo o período do planejamento, inclusive meses passados que o incremental nunca preencheu.");
    }

    if (!options.dryRun) {
        console.log("[rebuild_workspace] O job NÃO é transacional: qualquer escrita feita pelo app durante a execução pode ter sido sobrescrita.");
    }

    if (options.dryRun) {
        console.log("[rebuild_workspace] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failures.length > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[rebuild_workspace] Erro fatal:", error);
        process.exit(1);
    });
}
