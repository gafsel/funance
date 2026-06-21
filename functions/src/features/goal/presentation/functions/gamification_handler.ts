import { onDocumentWritten, onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";

export const onWorkspaceUpdated = onDocumentUpdated(
    "workspaces/{workspaceId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const before = event.data?.before.data();
        const after = event.data?.after.data();

        if (!before || !after) return;

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
    }
);

export const onAccountCreatedGamification = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onAccountCreatedGamification] Triggered for workspaceId=${workspaceId}`);
        await container.gamificationService.checkFirstAccount(workspaceId);
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

        // 1. Check first_transaction
        if (after.status === "paid" || after.status === "settled") {
            await gamificationService.checkFirstTransaction(workspaceId);

            // 2. Check dynamic_duo
            const paidDate = after.paidDate?.toDate ? after.paidDate.toDate() : (after.paidDate ? new Date(after.paidDate) : new Date());
            await gamificationService.checkDynamicDuo(workspaceId, paidDate);
        }

        // 3. Update weekly mission progress
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

        const after = event.data?.after.exists ? event.data.after.data() : null;
        await gamificationService.updateWeeklyMissionsProgress(workspaceId, "planning", after);
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

            // 1. Check reconciliation badges
            await gamificationService.checkReconciliationBadges(
                workspaceId,
                confirmedMatches,
                totalProcessed,
                createdCount
            );

            // 2. Update weekly mission progress
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
        await container.gamificationService.checkGoalBadges(workspaceId, after);
    }
);

// Cron simulation triggers (HTTP Callables)

export const triggerWeeklyCron = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    const { workspaceId } = request.data;
    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "O ID do workspace é obrigatório.");
    }

    try {
        await container.gamificationService.evaluateWeeklyMissionsCron(workspaceId);
        return { success: true };
    }
    catch (e: any) {
        logger.error("[triggerWeeklyCron] Error processing weekly cron:", e);
        throw new HttpsError("internal", e.message || "Erro ao executar cron semanal.");
    }
});

export const triggerMonthlyCron = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    const { workspaceId } = request.data;
    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "O ID do workspace é obrigatório.");
    }

    try {
        await container.gamificationService.evaluateMonthlyMissionsCron(workspaceId);
        return { success: true };
    }
    catch (e: any) {
        logger.error("[triggerMonthlyCron] Error processing monthly cron:", e);
        throw new HttpsError("internal", e.message || "Erro ao executar cron mensal.");
    }
});
