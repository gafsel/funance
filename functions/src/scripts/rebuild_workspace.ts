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
 *   --chunk-size=<n>     operações por batch (default 400, máximo 500)
 *   --prune-residual     apaga também os documentos residuais (zerados/sem
 *                        movimento). Sem a flag eles são apenas reportados.
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
    pruneResidual: boolean;
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
        pruneResidual: argv.includes("--prune-residual"),
    };
}

export function formatReport(report: RebuildReport): string {
    const line = (name: string, diff: CollectionDiff) =>
        `  ${name.padEnd(18)} criar=${diff.toCreate} alterar=${diff.toUpdate} apagar=${diff.toDelete} iguais=${diff.unchanged} residuais=${diff.residual}`;

    const samples = [
        ...report.diff.balances.samples,
        ...report.diff.periodSummaries.samples,
        ...report.diff.weeklyXp.samples,
    ];

    return [
        `[rebuild_workspace] workspace=${report.workspaceId} modo=${report.mode} duração=${report.durationMs}ms`,
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
        pruneResidual: options.pruneResidual,
    });

    console.log(formatReport(report));

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
