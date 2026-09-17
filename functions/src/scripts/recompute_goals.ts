/**
 * Recálculo do `currentAmount` de todas as metas pela regra nova (F2.5).
 *
 * Contexto: até aqui só `saveMoney` e `reduceCreditCard` andavam, e mesmo essas
 * andavam por delta — uma parcela perdida (evento não entregue, migração,
 * documento corrigido à mão) deixava o progresso torto para sempre. As metas
 * `reduceExpense` e `payDebt` nunca progrediram: o card mostrava barra e
 * "Faltam R$ X" sobre um número que ninguém atualizava.
 *
 * Este script recalcula do zero, com a mesma fonte de verdade que o gatilho usa
 * (`GoalServiceImpl.computeCurrentAmount`):
 *
 *   saveMoney        conta de INVESTIMENTO (cofrinho): saldo atual da conta
 *                    (piso zero) — o dinheiro guardado ali É o progresso;
 *                    qualquer outro tipo de conta: soma das parcelas pagas
 *                    desde `startDate` (crédito soma, débito subtrai)
 *   reduceCreditCard soma dos débitos da conta desde `startDate`
 *   reduceExpense    `actualAmount` da categoria nos `period_summaries` mensais
 *                    do período da meta
 *   payDebt          saldo atual da conta menos o saldo no fim do dia ANTERIOR
 *                    ao `startDate` (piso zero)
 *
 * Características:
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply`.
 *  - IDEMPOTENTE: pula a meta cujo valor já bate (tolerância de 1 centavo).
 *  - Carimba `completedAt` na primeira vez que a meta alcança o alvo; NUNCA
 *    reescreve um `completedAt` que já existe.
 *  - Log por meta, com resumo final.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_goals.js --project=<projectId>
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_goals.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_goals.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a execução a um único workspace
 */

import * as admin from "firebase-admin";
import { GoalRepositoryImpl } from "../features/goal/data/repositories/goal.repository.impl";
import { GoalServiceImpl } from "../features/goal/domain/services/goal.service.impl";
import { IGoalRepository } from "../features/goal/domain/repositories/goal.repository";
import {
    GoalModel,
    GoalOutcome,
    evaluateGoalOutcome,
    isGoalActive,
    resolveGoalOutcome,
    resolveGoalType,
} from "../features/goal/domain/models/goal.model";

/** Diferença abaixo da qual a meta é considerada já correta. */
const AMOUNT_EPSILON = 0.005;

export interface RecomputeOptions {
    dryRun: boolean;
    workspaceId?: string;
}

export interface RecomputeSummary {
    /** Workspaces inspecionados. */
    scanned: number;
    /** Metas lidas (não deletadas). */
    goals: number;
    /** Metas cujo `currentAmount` foi (ou seria) alterado. */
    updated: number;
    /** Metas que já estavam corretas. */
    skipped: number;
    /** Metas que desfecharam (ou desfechariam) em SUCESSO. */
    completed: number;
    /** Metas que desfecharam (ou desfechariam) em FALHA. */
    lost: number;
    /** Metas ativas ao fim do recálculo (definição de `isGoalActive`). */
    active: number;
    /** Metas que falharam. */
    failed: number;
}

/**
 * Núcleo do recálculo, isolado do bootstrap para permitir teste com mocks
 * (recebe o Firestore e o repositório por parâmetro).
 */
export async function recomputeGoals(
    firestore: admin.firestore.Firestore,
    repository: IGoalRepository,
    options: RecomputeOptions,
    log: (message: string) => void = console.log
): Promise<RecomputeSummary> {
    const summary: RecomputeSummary = {
        scanned: 0, goals: 0, updated: 0, skipped: 0, completed: 0, lost: 0, active: 0, failed: 0,
    };

    const service = new GoalServiceImpl(repository);

    const workspaceIds: string[] = [];
    if (options.workspaceId) {
        workspaceIds.push(options.workspaceId);
    }
    else {
        const snapshot = await firestore.collection("workspaces").select().get();
        for (const doc of snapshot.docs) {
            workspaceIds.push(doc.id);
        }
    }

    log(`[recompute_goals] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s).`);

    for (const workspaceId of workspaceIds) {
        summary.scanned++;

        let goals: GoalModel[];
        try {
            goals = await repository.getGoals(workspaceId);
        }
        catch (e) {
            summary.failed++;
            log(`[recompute_goals] ${workspaceId}: FALHA ao listar metas — ${String(e)}`);
            continue;
        }

        for (const goal of goals) {
            summary.goals++;
            const goalType = resolveGoalType(goal);

            try {
                const computed = await service.computeCurrentAmount(workspaceId, goal);

                if (computed === null) {
                    summary.skipped++;
                    log(`[recompute_goals] ${workspaceId}/${goal.id}: sem base de cálculo (tipo=${goalType ?? "?"}) — mantida.`);
                    continue;
                }

                const current = Number(goal.currentAmount ?? 0);
                const changed = Math.abs(computed - current) >= AMOUNT_EPSILON;

                // Desfecho pela MESMA regra do serviço, e só para meta que
                // ainda não desfechou — o desfecho é terminal.
                const outcome = resolveGoalOutcome(goal) === null
                    ? evaluateGoalOutcome({ ...goal, currentAmount: computed })
                    : null;

                if (!changed && !outcome) {
                    summary.skipped++;
                    if (isGoalActive({ ...goal, currentAmount: computed })) {
                        summary.active++;
                    }
                    continue;
                }

                if (outcome === GoalOutcome.success) {
                    summary.completed++;
                }
                if (outcome === GoalOutcome.failed) {
                    summary.lost++;
                }
                summary.updated++;

                const verb = options.dryRun ? "GRAVARIA" : "gravado";
                log(`[recompute_goals] ${workspaceId}/${goal.id} (${goalType ?? "?"}): ${current} -> ${computed}${outcome ? ` + outcome=${outcome}` : ""} (${verb}).`);

                if (!options.dryRun) {
                    await repository.updateGoalProgress(
                        workspaceId,
                        goal.id,
                        computed,
                        outcome ? { outcome, at: new Date() } : null
                    );
                }

                const after = { ...goal, currentAmount: computed, outcome: outcome ?? goal.outcome };
                if (isGoalActive(after)) {
                    summary.active++;
                }
            }
            catch (e) {
                summary.failed++;
                log(`[recompute_goals] ${workspaceId}/${goal.id}: FALHA — ${String(e)}`);
            }
        }
    }

    log(`[recompute_goals] Fim: workspaces=${summary.scanned} metas=${summary.goals} atualizadas=${summary.updated} iguais=${summary.skipped} sucesso=${summary.completed} falha=${summary.lost} ativas=${summary.active} falhas=${summary.failed}`);

    return summary;
}

/** Bootstrap: só roda quando o arquivo é executado direto por `node`. */
if (require.main === module) {
    const args = process.argv.slice(2);
    const dryRun = !args.includes("--apply");
    const projectId = args.find((a) => a.startsWith("--project="))?.split("=")[1]
        || process.env.GOOGLE_CLOUD_PROJECT;
    const workspaceId = args.find((a) => a.startsWith("--workspace="))?.split("=")[1];

    if (!projectId) {
        console.error("[recompute_goals] Informe --project=<projectId> (ou defina GOOGLE_CLOUD_PROJECT).");
        process.exit(1);
    }

    admin.initializeApp({ projectId });
    admin.firestore().settings({ ignoreUndefinedProperties: true });

    recomputeGoals(admin.firestore(), new GoalRepositoryImpl(), { dryRun, workspaceId })
        .then((summary) => process.exit(summary.failed > 0 ? 1 : 0))
        .catch((e) => {
            console.error("[recompute_goals] Erro fatal:", e);
            process.exit(1);
        });
}
