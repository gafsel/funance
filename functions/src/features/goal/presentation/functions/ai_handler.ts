import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";
import { assertWorkspaceMember } from "../../../../core/services/workspace_access.service";
import { AI_CALLABLE_OPTIONS, AI_CALLABLE_OPTIONS_SHORT } from "../../../../core/config/functions.config";
import { AI_DAILY_QUOTAS } from "../../../../core/config/quota.config";
import { isTransientAiError } from "../../../../core/services/ai.service";

export const analysePlanning = onCall(AI_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId } = request.data;

    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    // Sem cache server-side: a cota é consumida já aqui. O estorno em
    // falha de infraestrutura mantém a simetria com coaching/50-30-20.
    const quota = container.quotaService.guardFor(
        workspaceId, "analysePlanning", AI_DAILY_QUOTAS.analysePlanning
    );
    await quota.consume();

    try {
        const suggestions = await container.onboardingService.analyzePlanning(workspaceId);
        return suggestions;
    }
    catch (error: any) {
        if (isTransientAiError(error)) {
            await quota.refund();
        }
        console.error("Erro na análise da IA:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise de IA.");
    }
});

export const analyzeAccountDocument = onCall(AI_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, storagePath } = request.data;

    if (!workspaceId || !storagePath) {
        throw new HttpsError("invalid-argument", "Workspace ID e caminho no storage são obrigatórios.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    // Sem cache server-side: a cota é consumida já aqui. O estorno em
    // falha de infraestrutura mantém a simetria com coaching/50-30-20.
    const quota = container.quotaService.guardFor(
        workspaceId, "analyzeAccountDocument", AI_DAILY_QUOTAS.analyzeAccountDocument
    );
    await quota.consume();

    try {
        const analysis = await container.onboardingService.analyzeAccountDocument(
            workspaceId,
            storagePath,
        );
        return analysis;
    }
    catch (error: any) {
        if (isTransientAiError(error)) {
            await quota.refund();
        }
        console.error("Erro na análise do documento:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise do documento.");
    }
});

export const analyzeReconciliationDocument = onCall(AI_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, storagePath, uploadId } = request.data;

    if (!workspaceId || !storagePath) {
        throw new HttpsError("invalid-argument", "Workspace ID e caminho no storage são obrigatórios.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    // Sem cache server-side: a cota é consumida já aqui. O estorno em
    // falha de infraestrutura mantém a simetria com coaching/50-30-20.
    const quota = container.quotaService.guardFor(
        workspaceId, "analyzeReconciliationDocument", AI_DAILY_QUOTAS.analyzeReconciliationDocument
    );
    await quota.consume();

    try {
        const analysis = await container.onboardingService.analyzeReconciliationDocument(
            workspaceId,
            storagePath,
            uploadId,
        );
        return analysis;
    }
    catch (error: any) {
        if (isTransientAiError(error)) {
            await quota.refund();
        }
        console.error("Erro na análise de conciliação:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise de conciliação.");
    }
});

export const analyzeGoalFeasibility = onCall(AI_CALLABLE_OPTIONS_SHORT, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, goalPayload } = request.data;

    if (!workspaceId || !goalPayload) {
        throw new HttpsError("invalid-argument", "workspaceId e goalPayload são obrigatórios.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    // Sem cache server-side: a cota é consumida já aqui. O estorno em
    // falha de infraestrutura mantém a simetria com coaching/50-30-20.
    const quota = container.quotaService.guardFor(
        workspaceId, "analyzeGoalFeasibility", AI_DAILY_QUOTAS.analyzeGoalFeasibility
    );
    await quota.consume();

    try {
        const result = await container.goalFeasibilityService.analyze(workspaceId, goalPayload);
        return result;
    }
    catch (error: any) {
        if (isTransientAiError(error)) {
            await quota.refund();
        }
        console.error("Erro na análise de viabilidade da meta:", error);
        throw new HttpsError("internal", error.message || "Erro ao analisar viabilidade da meta.");
    }
});
