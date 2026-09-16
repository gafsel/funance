/**
 * Migração (F1.5): grava `summarizedUntil`, `appliedAmount`, `appliedFrom` e
 * `appliedUntil` nos planejamentos de categoria já existentes.
 *
 * Contexto: até F1.5 nada registrava o que um planejamento já havia lançado nos
 * sumários. O gatilho aplicava 12 meses a partir de "hoje" a cada escrita (sem
 * estornar o que tinha aplicado antes) e o cron mensal procurava
 * `lastSummaryMonth < mês` — campo que nenhum planejamento criado pelo app
 * tinha, então o cron era inerte. Sem os marcadores, o regime novo não sabe o
 * que estornar quando o usuário edita o valor.
 *
 * O que este script grava, por planejamento:
 *
 *   appliedFrom     = max(startMonth, mês corrente)
 *   appliedUntil    = min(endMonth, mês corrente + 11)
 *   appliedAmount   = amount            (null quando o intervalo é vazio)
 *   summarizedUntil = horizonte, ou "9999-12" quando endMonth <= horizonte
 *
 * Ou seja: assume que o planejamento está aplicado exatamente na janela que o
 * gatilho antigo aplicaria HOJE. É exato para quem foi escrito neste mês e
 * aproximado para quem foi escrito antes.
 *
 * O que ele NÃO faz:
 *   - não escreve em `period_summaries`. Os VALORES de `generalPlannedAmount`
 *     acumulados pelo regime antigo (aplicação repetida sem estorno) são
 *     corrigidos pelo `rebuild_workspace.ts --rebuild-planning`, que agora é
 *     determinístico. Ordem recomendada: **este script primeiro, rebuild
 *     depois**;
 *   - não altera `amount`, `startMonth` nem `endMonth`.
 *
 * Características:
 *   - IDEMPOTENTE: pula quem já tem `summarizedUntil` (a não ser com
 *     `--force`, que recalcula os marcadores de todos).
 *   - DRY-RUN POR PADRÃO: só escreve com `--apply`.
 *   - Paginado por cursor e escrito em lotes de no máximo 400 operações.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_planning_summaries.js --project=<projectId>
 *   # 2) Um workspace só:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_planning_summaries.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_planning_summaries.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace
 *   --page-size=<n>      planejamentos lidos por página (default 200)
 *   --force              recalcula os marcadores mesmo de quem já os tem
 */

import * as admin from "firebase-admin";
import { BatchOperation, commitInChunks } from "../core/utils/batch.utils";
import { isMonthKey, toMonthKey } from "../core/utils/month_key";
import { CategoryPlanningMarks, CategoryPlanningModel } from "../features/finance/domain/models/finance.models";
import {
    PLANNING_FULLY_SUMMARIZED,
    intersectPlanningWindow,
    nextSummarizedUntil,
    planningHorizon,
} from "../features/finance/domain/services/summary.service";

export interface MigratePlanningOptions {
    dryRun: boolean;
    workspaceId?: string;
    pageSize?: number;
    force?: boolean;
    /** Data-base do horizonte (default: agora). Existe para os testes. */
    now?: Date;
}

export interface MigratePlanningSummary {
    /** Planejamentos inspecionados. */
    scanned: number;
    /** Planejamentos que receberam (ou receberiam) os marcadores. */
    marked: number;
    /** Planejamentos que já tinham `summarizedUntil`. */
    skippedAlreadyMarked: number;
    /** Planejamentos com `startMonth`/`endMonth` fora do formato `YYYY-MM`. */
    skippedInvalid: number;
    /** Falhas. */
    failed: number;
}

const DEFAULT_PAGE_SIZE = 200;

/** Marcadores que um planejamento DEVERIA ter, na data-base informada. */
export function buildPlanningMarks(planning: CategoryPlanningModel, now: Date): CategoryPlanningMarks | null {
    if (!isMonthKey(planning.startMonth) || !isMonthKey(planning.endMonth)) return null;

    const currentMonth = toMonthKey(now);
    const horizon = planningHorizon(now);
    const window = intersectPlanningWindow(planning.startMonth, planning.endMonth, currentMonth, horizon);

    return {
        summarizedUntil: nextSummarizedUntil(planning.endMonth, horizon),
        appliedAmount: window ? planning.amount : null,
        appliedFrom: window ? window.from : null,
        appliedUntil: window ? window.until : null,
    };
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function migratePlanningSummaries(
    firestore: admin.firestore.Firestore,
    options: MigratePlanningOptions,
    log: (message: string) => void = console.log
): Promise<MigratePlanningSummary> {
    const summary: MigratePlanningSummary = {
        scanned: 0,
        marked: 0,
        skippedAlreadyMarked: 0,
        skippedInvalid: 0,
        failed: 0,
    };

    const pageSize = Math.max(1, options.pageSize ?? DEFAULT_PAGE_SIZE);
    const now = options.now ?? new Date();

    log(`[migrate_planning_summaries] ${options.dryRun ? "DRY-RUN" : "APPLY"} — horizonte ${planningHorizon(now)}.`);

    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

    for (;;) {
        let query: admin.firestore.Query = options.workspaceId
            ? firestore.collection("workspaces").doc(options.workspaceId).collection("category_planning")
            : firestore.collectionGroup("category_planning");

        query = query.orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
        if (cursor) query = query.startAfter(cursor);

        const snapshot = await query.get();
        if (snapshot.empty) break;

        const operations: BatchOperation[] = [];

        for (const doc of snapshot.docs) {
            summary.scanned++;

            const workspaceId = doc.ref.parent.parent?.id ?? "?";

            try {
                const data = doc.data() ?? {};
                const planning = { id: doc.id, ...data } as CategoryPlanningModel;

                const alreadyMarked = isMonthKey(planning.summarizedUntil) ||
                    planning.summarizedUntil === PLANNING_FULLY_SUMMARIZED;

                if (alreadyMarked && !options.force) {
                    summary.skippedAlreadyMarked++;
                    continue;
                }

                const marks = buildPlanningMarks(planning, now);
                if (!marks) {
                    summary.skippedInvalid++;
                    log(`[migrate_planning_summaries] ${workspaceId}/${doc.id}: startMonth/endMonth fora do formato YYYY-MM — ignorado.`);
                    continue;
                }

                summary.marked++;

                if (options.dryRun) {
                    log(`[migrate_planning_summaries] ${workspaceId}/${doc.id}: GRAVARIA summarizedUntil=${marks.summarizedUntil}, aplicado=${marks.appliedFrom ?? "-"}..${marks.appliedUntil ?? "-"} (${marks.appliedAmount ?? 0}) (dry-run).`);
                    continue;
                }

                operations.push({ op: "set", ref: doc.ref, data: { ...marks }, options: { merge: true } });
            }
            catch (error) {
                summary.failed++;
                log(`[migrate_planning_summaries] ${workspaceId}/${doc.id}: FALHOU — ${error}`);
            }
        }

        if (operations.length > 0) {
            await commitInChunks(firestore, operations);
        }

        if (snapshot.size < pageSize) break;
        cursor = snapshot.docs[snapshot.size - 1];
    }

    log(
        "[migrate_planning_summaries] Resumo: " +
        `planejamentos=${summary.scanned}, marcados=${summary.marked}, ` +
        `já_marcados=${summary.skippedAlreadyMarked}, inválidos=${summary.skippedInvalid}, falhas=${summary.failed}.`
    );
    return summary;
}

export function parseArgs(argv: string[]): MigratePlanningOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const pageSize = Number(getValue("--page-size="));

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        force: argv.includes("--force"),
        workspaceId: getValue("--workspace="),
        pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : undefined,
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
    };
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: options.projectId,
        });
    }

    const summary = await migratePlanningSummaries(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[migrate_planning_summaries] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[migrate_planning_summaries] Erro fatal:", error);
        process.exit(1);
    });
}
