import { onDocumentWritten, onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import {
    AI_SCHEDULE_OPTIONS,
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
    CRON_WORKSPACE_CONCURRENCY,
} from "../../../../core/config/functions.config";
import { forEachWorkspacePaged } from "../../../../core/utils/cron_runner";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import { INSTALLMENT_DERIVED_FIELDS } from "../../../finance/domain/models/finance.models";
import { GAMIFICATION_TIME_ZONE } from "../../domain/services/gamification_time.util";
import { GoalModel, resolveGoalOutcome, toGoalDate } from "../../domain/models/goal.model";

/**
 * Campos do doc do workspace escritos pelo próprio SERVIDOR
 * (addXp/unlockBadge/updateWorkspaceStreaks e, desde F2.2/F2.3, a Bússola da
 * Liberdade e os marcadores de XP único). Escritas que alteram APENAS estes
 * campos não devem redisparar as checagens de badge — sem este guard, cada
 * unlock/addXp reativa onWorkspaceUpdated em cascata.
 *
 * `healthDirtyAt` é o caso mais crítico da lista: ele é carimbado a CADA
 * escrita de parcela (ver `installment_handler`). Fora daqui, todo pagamento
 * do usuário dispararia, de graça, a bateria inteira de checagens de badge do
 * workspace.
 */
const GAMIFICATION_ONLY_FIELDS = new Set([
    "xp",
    "level",
    "unlockedBadges",
    "weeklyStreaks",
    "lastLevelUpAt",
    // F2.2 — Bússola da Liberdade.
    "financialHealth",
    "healthDirtyAt",
    // F2.3 — marcadores de XP concedido uma única vez por categoria e o mapa
    // de streaks semanais (escrito junto do `weeklyStreaks` numérico).
    "xpAwardedFor",
    "streaks",
]);

/**
 * Nomes de ação da idempotência — ESTÁVEIS: mudar um destes valores faz o
 * marcador antigo deixar de casar e a ação roda de novo para eventos em voo.
 *
 * A chave gravada é `${eventId}_${actionName}`. Estes handlers observam os
 * mesmos documentos que os handlers de finanças (ex.: installments), por isso
 * os nomes são prefixados: se a plataforma entregar o mesmo `event.id` para
 * dois triggers da mesma escrita, um não pode roubar a chave do outro.
 */
export const GAMIFICATION_ACTIONS = {
    workspaceUpdated: "gamification:workspaceUpdated",
    accountCreated: "gamification:accountCreated",
    installmentWritten: "gamification:installmentWritten",
    categoryPlanningWritten: "gamification:categoryPlanningWritten",
    orderWritten: "gamification:orderWritten",
    categoryWritten: "gamification:categoryWritten",
    reconciliationWritten: "gamification:reconciliationWritten",
    goalWritten: "gamification:goalWritten",
    goalRecompute: "gamification:goalRecompute",
} as const;

function getChangedTopLevelFields(before: Record<string, any>, after: Record<string, any>): string[] {
    const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
    const changed: string[] = [];
    for (const key of keys) {
        if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
            changed.push(key);
        }
    }
    return changed;
}

export const onWorkspaceUpdated = onDocumentUpdated(
    "workspaces/{workspaceId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const before = event.data?.before.data();
        const after = event.data?.after.data();

        if (!before || !after) return;

        const changedFields = getChangedTopLevelFields(before, after);
        if (changedFields.length === 0 ||
            changedFields.every((field) => GAMIFICATION_ONLY_FIELDS.has(field))) {
            // Escrita originada da própria gamificação (ou no-op): early return
            // para evitar o trigger recursivo.
            return;
        }

        logger.info(`[onWorkspaceUpdated] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.workspaceUpdated, async () => {
            const gamificationService = container.gamificationService;

            // 1. Check first_step: onboardingCompleted transitions from false to true
            const beforeCompleted = before.onboardingCompleted || false;
            const afterCompleted = after.onboardingCompleted || false;
            if (!beforeCompleted && afterCompleted) {
                await gamificationService.checkFirstStep(workspaceId, true);
            }

            // 2. Check united_front: members list length >= 3
            const beforeMembers = before.members || [];
            const afterMembers = after.members || [];
            if (beforeMembers.length !== afterMembers.length && afterMembers.length >= 3) {
                await gamificationService.checkUnitedFront(workspaceId, afterMembers.length);
            }

            // 3. Simple badges: profile, naming, team size, anniversary
            await gamificationService.checkSimpleWorkspaceBadges(workspaceId, after);
        });
    }
);

export const onAccountCreatedGamification = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onAccountCreatedGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.accountCreated, async () => {
            const gamificationService = container.gamificationService;
            await gamificationService.checkFirstAccount(workspaceId);
            // Simple: multi-account badges
            await gamificationService.checkSimpleAccountBadges(workspaceId);
        });
    }
);

/**
 * Verdadeiro quando a escrita só mexeu em campos derivados da parcela — o eco
 * da execução anterior do servidor (xp recalculado, cascata zerada).
 *
 * Mesma guarda do gatilho de finanças (`handleInstallmentWritten`): este
 * handler observa a MESMA coleção e, sem ela, cada escrita de xp reavaliava
 * badges e missões semanais de graça.
 */
export function isDerivedOnlyInstallmentWrite(
    before: Record<string, any> | null,
    after: Record<string, any> | null
): boolean {
    if (!before || !after) return false;

    return getChangedFields(before, after)
        .every((field) => INSTALLMENT_DERIVED_FIELDS.has(field));
}

export const onInstallmentWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/installments/{installmentId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const before = event.data?.before.exists ? event.data.before.data()! : null;
        const after = event.data?.after.exists ? event.data.after.data()! : null;

        if (!after || after.status === "removed") return;

        if (isDerivedOnlyInstallmentWrite(before, after)) {
            logger.info(`[onInstallmentWrittenGamification] Saída antecipada: parcela mudou apenas campos derivados (workspaceId=${workspaceId}).`);
            return;
        }

        logger.info(`[onInstallmentWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.installmentWritten, async () => {
            const gamificationService = container.gamificationService;

            if (after.status === "paid" || after.status === "settled") {
                // 1. Check first_transaction
                await gamificationService.checkFirstTransaction(workspaceId);

                // 2. Simple transaction-count and type badges
                await gamificationService.checkSimpleTransactionBadges(workspaceId, after);
            }

            // 4. Update weekly mission progress
            await gamificationService.updateWeeklyMissionsProgress(workspaceId, "transaction", after);
        });
    }
);

// A coleção real é `category_planning` (singular): é o caminho usado pelo
// cliente, pelo category_planning_handler, pelas rules e pelos índices.
// Com o plural, este trigger nunca disparava.
export const onCategoryPlanningWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/category_planning/{planningId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryPlanningWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.categoryPlanningWritten, async () => {
            const gamificationService = container.gamificationService;
            await gamificationService.checkPlanner(workspaceId);
            await gamificationService.checkGoldenRule(workspaceId);

            // Simple: planning count badges
            await gamificationService.checkSimplePlanningBadges(workspaceId);

            const after = event.data?.after.exists ? event.data.after.data() : null;
            await gamificationService.updateWeeklyMissionsProgress(workspaceId, "planning", after);

            // F2.3 — +30 XP na PRIMEIRA vez que esta categoria ganha um limite.
            //
            // Entra aqui, e não no handler de finanças, porque XP é
            // gamificação: `onCategoryPlanningWritten` (finanças) existe para
            // estornar e reaplicar o planejado nos sumários, e misturar as duas
            // responsabilidades faria uma falha de XP derrubar o cálculo do
            // planejamento. A unicidade não depende deste gatilho: ela vive no
            // marcador `xpAwardedFor.planning.<categoryId>` do workspace, então
            // uma reentrega do evento (ou o eco da escrita dos marcadores de
            // F1.5) não concede nada de novo.
            await gamificationService.awardPlanningCreationXp(workspaceId, after);
        });
    }
);

/**
 * F2.3 — gatilho de gamificação sobre as ORDERS.
 *
 * Não existia: `onOrderWritten` (finanças) só sincroniza parcelas. Este observa
 * a mesma coleção com um nome de ação próprio (`gamification:orderWritten`),
 * para que os dois não disputem a mesma chave de idempotência quando a
 * plataforma entregar o mesmo `event.id` para ambos.
 *
 * Só faz uma coisa: premiar a primeira RECORRÊNCIA de cada categoria. Criar
 * uma recorrência é declarar que um gasto se repete — é planejamento, e o
 * jogo premia planejar.
 */
export const onOrderWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/orders/{orderId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        // Saída antecipada ANTES da idempotência: a esmagadora maioria das
        // escritas de order não é recorrência, e nenhuma delas precisa custar
        // um documento em `_idempotency`.
        if (!after || after.installmentType !== "recurring") return;

        logger.info(`[onOrderWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.orderWritten, async () => {
            await container.gamificationService.awardRecurringCreationXp(workspaceId, after);
        });
    }
);

export const onCategoryWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/categories/{categoryId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.categoryWritten, async () => {
            await container.gamificationService.checkSimpleCategoryBadges(workspaceId);
        });
    }
);

export const onReconciliationWritten = onDocumentWritten(
    "workspaces/{workspaceId}/reconciliations/{recId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        if (!after) return;

        logger.info(`[onReconciliationWritten] Triggered for workspaceId=${workspaceId}`);

        if (after.status !== "completed") return;

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.reconciliationWritten, async () => {
            const gamificationService = container.gamificationService;

            const confirmedMatches = after.confirmedMatchesCount || 0;
            const totalProcessed = after.totalTransactionsProcessed || 0;
            const createdCount = after.createdTransactionsCount || 0;

            // 1. Advanced reconciliation badges
            await gamificationService.checkReconciliationBadges(
                workspaceId,
                confirmedMatches,
                totalProcessed,
                createdCount
            );

            // 2. Simple reconciliation frequency badges
            await gamificationService.checkSimpleReconciliationBadges(workspaceId);

            // 3. Update weekly mission progress
            await gamificationService.updateWeeklyMissionsProgress(workspaceId, "reconciliation", after);
        });
    }
);

export const onGoalWritten = onDocumentWritten(
    "workspaces/{workspaceId}/goals/{goalId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const goalId = event.params.goalId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        if (!after) return;

        logger.info(`[onGoalWritten] Triggered for workspaceId=${workspaceId}`);

        // Progresso da meta recém-criada/editada.
        //
        // Sem isto, uma meta de categoria ou de dívida nasce em zero e só ganha
        // vida no próximo pagamento — o usuário vê a barra vazia mesmo tendo
        // histórico. O recálculo só escreve quando o valor MUDA, então a
        // escrita que ele provoca não reentra: a segunda passada calcula o
        // mesmo número e não grava nada.
        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.goalRecompute, async () => {
            if (after.isDeleted === true) return;
            try {
                await container.goalService.recomputeGoal(workspaceId, {
                    ...after,
                    id: goalId,
                    startDate: toGoalDate(after.startDate) ?? new Date(),
                    deadline: toGoalDate(after.deadline) ?? undefined,
                    // O desfecho já gravado precisa vir junto: é ele que impede
                    // o recálculo de carimbar um segundo desfecho por cima.
                    outcome: resolveGoalOutcome(after),
                    completedAt: toGoalDate(after.completedAt),
                    failedAt: toGoalDate(after.failedAt),
                } as GoalModel);
            }
            catch (e) {
                // Recalcular é melhor-esforço: não pode impedir os badges.
                logger.error(`[onGoalWritten] Falha ao recalcular a meta ${goalId}:`, e);
            }
        });

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.goalWritten, async () => {
            const gamificationService = container.gamificationService;

            // Advanced goal badges
            await gamificationService.checkGoalBadges(workspaceId, after);

            // Simple goal badges
            await gamificationService.checkSimpleGoalBadges(workspaceId, after);
        });
    }
);

// Crons agendados (firebase-functions v2 scheduler).
// Antes eram onCall ("cron simulation triggers") que nenhum código chamava —
// streaks e missões semanais/mensais nunca eram avaliadas.

export const weeklyGamificationCron = onSchedule(
    {
        // Toda segunda-feira às 03:00, horário de São Paulo — avalia a semana
        // anterior (domingo a sábado) já encerrada.
        schedule: "0 3 * * 1",
        timeZone: GAMIFICATION_TIME_ZONE,
        // Varre todos os workspaces e gera missões semanais via IA: precisa de
        // mais memória/timeout do que o padrão global de 256MiB/60s.
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        logger.info("[weeklyGamificationCron] Starting weekly gamification cron.");
        try {
            await container.gamificationService.runWeeklyCronForAllWorkspaces();
            logger.info("[weeklyGamificationCron] Weekly gamification cron finished.");
        }
        catch (e) {
            logger.error("[weeklyGamificationCron] Error processing weekly cron:", e);
        }
    }
);

export const monthlyGamificationCron = onSchedule(
    {
        // Todo dia 1 às 03:00, horário de São Paulo — avalia o mês anterior.
        schedule: "0 3 1 * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        // Varre todos os workspaces igual ao semanal: herdar o padrão global
        // de 60s deixava a varredura morrer no meio do primeiro minuto.
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        logger.info("[monthlyGamificationCron] Starting monthly gamification cron.");
        try {
            await container.gamificationService.runMonthlyCronForAllWorkspaces();
            logger.info("[monthlyGamificationCron] Monthly gamification cron finished.");
        }
        catch (e) {
            logger.error("[monthlyGamificationCron] Error processing monthly cron:", e);
        }
    }
);

/**
 * Fecha, todo dia, as metas cujo prazo venceu.
 *
 * Sem este cron, uma meta de REDUÇÃO que atravessa o prazo dentro do teto
 * ficaria "em andamento" para sempre: o sucesso dela não é um evento — é a
 * AUSÊNCIA de estouro até o vencimento, e nada acontece no dia do vencimento
 * para disparar um gatilho. O mesmo vale para a meta de acúmulo que vence sem
 * alcançar o alvo: alguém precisa carimbar a derrota.
 *
 * 03:15 (America/Sao_Paulo), quinze minutos depois dos crons semanais/mensais,
 * para não disputar leitura com eles no mesmo minuto. A varredura é a paginada
 * com checkpoint (`forEachWorkspacePaged`), então um timeout retoma do ponto
 * exato na execução seguinte.
 *
 * Idempotente: só toca metas com `outcome == null` e prazo vencido — na segunda
 * passada elas já têm desfecho e são puladas.
 */
export const closeExpiredGoals = onSchedule(
    {
        schedule: "15 3 * * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        let closedTotal = 0;

        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "close_expired_goals",
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                const closed = await container.goalService.closeExpiredGoals(workspaceId);
                closedTotal += closed.length;

                for (const goal of closed) {
                    // Só o desfecho de SUCESSO concede alguma coisa; as
                    // checagens já sabem disso (`isGoalCompleted`). Passar a
                    // meta falhada por aqui é de propósito: é o que mantém o
                    // caminho do cron igual ao do gatilho.
                    await container.gamificationService.checkGoalBadges(workspaceId, goal);
                    await container.gamificationService.checkSimpleGoalBadges(workspaceId, goal);
                }
            }
        );

        logger.info(
            `[closeExpiredGoals] ${result.processed} workspaces, ${closedTotal} metas fechadas, ` +
            `${result.failed} com falha, varredura ${result.completed ? "completa" : `interrompida em ${result.lastWorkspaceId}`}.`
        );
    }
);

/**
 * Publica o catálogo de badges em `config/badges` (ver
 * `BadgeCatalogService.publishBadgeCatalog`).
 *
 * Por que um cron e não um gatilho: o catálogo é do PROJETO, não de um
 * workspace — não existe evento natural para publicá-lo, e amarrá-lo à criação
 * de workspace faria a publicação depender de um usuário novo aparecer. Um cron
 * diário barato (uma leitura; escreve só quando o hash do catálogo muda) faz o
 * deploy se propagar sozinho. `maxInstances: 1` porque duas execuções
 * simultâneas não têm nada a acrescentar uma à outra.
 *
 * O PRIMEIRO publish (antes do cron rodar) é feito pelo script
 * `scripts/publish_badge_catalog.ts`.
 */
export const publishBadgeCatalog = onSchedule(
    {
        schedule: "0 4 * * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        maxInstances: 1,
    },
    async () => {
        try {
            const result = await container.badgeCatalogService.publishBadgeCatalog();
            logger.info(`[publishBadgeCatalog] versão=${result.version} publicado=${result.published} badges=${result.badgeCount}`);
        }
        catch (e) {
            logger.error("[publishBadgeCatalog] Erro ao publicar o catálogo de badges:", e);
        }
    }
);
