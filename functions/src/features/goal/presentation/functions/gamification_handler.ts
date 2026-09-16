import { onDocumentWritten, onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { AI_SCHEDULE_OPTIONS } from "../../../../core/config/functions.config";
import { GAMIFICATION_TIME_ZONE } from "../../domain/services/gamification_time.util";

/**
 * Campos do doc do workspace escritos pela própria gamificação
 * (addXp/unlockBadge/updateWorkspaceStreaks). Escritas que alteram APENAS
 * estes campos não devem redisparar as checagens de badge — sem este guard,
 * cada unlock/addXp reativa onWorkspaceUpdated em cascata.
 */
const GAMIFICATION_ONLY_FIELDS = new Set([
    "xp",
    "level",
    "unlockedBadges",
    "weeklyStreaks",
    "lastLevelUpAt",
]);

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
    }
);

export const onAccountCreatedGamification = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onAccountCreatedGamification] Triggered for workspaceId=${workspaceId}`);
        const gamificationService = container.gamificationService;
        await gamificationService.checkFirstAccount(workspaceId);
        // Simple: multi-account badges
        await gamificationService.checkSimpleAccountBadges(workspaceId);
    }
);

export const onInstallmentWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/installments/{installmentId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        if (!after || after.status === "removed") return;

        logger.info(`[onInstallmentWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        const gamificationService = container.gamificationService;

        if (after.status === "paid" || after.status === "settled") {
            // 1. Check first_transaction
            await gamificationService.checkFirstTransaction(workspaceId);

            // 2. Check dynamic_duo
            const paidDate = after.paidDate?.toDate ? after.paidDate.toDate() : (after.paidDate ? new Date(after.paidDate) : new Date());
            await gamificationService.checkDynamicDuo(workspaceId, paidDate);

            // 3. Simple transaction-count and type badges
            await gamificationService.checkSimpleTransactionBadges(workspaceId, after);
        }

        // 4. Update weekly mission progress
        await gamificationService.updateWeeklyMissionsProgress(workspaceId, "transaction", after);
    }
);

export const onCategoryPlanningWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/category_plannings/{planningId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryPlanningWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        const gamificationService = container.gamificationService;
        await gamificationService.checkPlanner(workspaceId);
        await gamificationService.checkGoldenRule(workspaceId);

        // Simple: planning count badges
        await gamificationService.checkSimplePlanningBadges(workspaceId);

        const after = event.data?.after.exists ? event.data.after.data() : null;
        await gamificationService.updateWeeklyMissionsProgress(workspaceId, "planning", after);
    }
);

export const onCategoryWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/categories/{categoryId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryWrittenGamification] Triggered for workspaceId=${workspaceId}`);
        await container.gamificationService.checkSimpleCategoryBadges(workspaceId);
    }
);

export const onReconciliationWritten = onDocumentWritten(
    "workspaces/{workspaceId}/reconciliations/{recId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        if (!after) return;

        logger.info(`[onReconciliationWritten] Triggered for workspaceId=${workspaceId}`);

        const gamificationService = container.gamificationService;

        if (after.status === "completed") {
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
        }
    }
);

export const onGoalWritten = onDocumentWritten(
    "workspaces/{workspaceId}/goals/{goalId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        if (!after) return;

        logger.info(`[onGoalWritten] Triggered for workspaceId=${workspaceId}`);
        const gamificationService = container.gamificationService;

        // Advanced goal badges
        await gamificationService.checkGoalBadges(workspaceId, after);

        // Simple goal badges
        await gamificationService.checkSimpleGoalBadges(workspaceId, after);
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
