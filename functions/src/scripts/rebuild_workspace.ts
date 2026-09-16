/**
 * Reconstrução de saldos, sumários e XP semanal de UM workspace (F1.0).
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
 *  - `generalPlannedAmount` é PRESERVADO por padrão: esse campo não é
 *    reconstruível (a projeção de `category_planning` só olha para a frente,
 *    então recalcular zera o planejado dos meses passados). Só com
 *    `--rebuild-planning`.
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
 *
 * Flags:
 *   --workspace=<id>     OBRIGATÓRIA: workspace a reconstruir
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --page-size=<n>      tamanho da página nas leituras (default 500)
 *   --chunk-size=<n>     operações por batch (default e máximo 400)
 *   --sample-limit=<n>   caminhos listados por coleção no relatório (default 50)
 *   --prune-residual     apaga também os documentos residuais (zerados/sem
 *                        movimento). Sem a flag eles são apenas reportados.
 *   --rebuild-planning   RECALCULA o `generalPlannedAmount` a partir de
 *                        `category_planning`. DESTRUTIVO: zera o planejado dos
 *                        meses passados e o resultado depende do dia em que o
 *                        job roda. Use só com dry-run revisado.
 */

import * as admin from "firebase-admin";
import { RebuildRepositoryImpl } from "../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";
import { CollectionDiff, RebuildReport, RebuildService } from "../features/finance/domain/services/rebuild.service";

export interface ScriptOptions {
    workspaceId?: string;
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

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (!options.workspaceId) {
        console.error("[rebuild_workspace] --workspace=<id> é obrigatório.");
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

    const report = await service.rebuildWorkspace(options.workspaceId, {
        dryRun: options.dryRun,
        pageSize: options.pageSize,
        chunkSize: options.chunkSize,
        sampleLimit: options.sampleLimit,
        pruneResidual: options.pruneResidual,
        rebuildPlanning: options.rebuildPlanning,
    });

    console.log(formatReport(report));

    if (options.rebuildPlanning) {
        console.log("[rebuild_workspace] ATENÇÃO: --rebuild-planning recalcula o generalPlannedAmount e zera o planejado dos meses passados.");
    }

    if (!options.dryRun) {
        console.log("[rebuild_workspace] O job NÃO é transacional: qualquer escrita feita pelo app durante a execução pode ter sido sobrescrita.");
    }

    if (options.dryRun) {
        console.log("[rebuild_workspace] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[rebuild_workspace] Erro fatal:", error);
        process.exit(1);
    });
}
