import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";

export const analysePlanning = onCall({ timeoutSeconds: 300 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId } = request.data;

    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    try {
        const suggestions = await container.onboardingService.analyzePlanning(workspaceId);
        return suggestions;
    }
    catch (error: any) {
        console.error("Erro na análise da IA:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise de IA.");
    }
});

export const analyzeAccountDocument = onCall({ timeoutSeconds: 300 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, storagePath } = request.data;

    if (!storagePath) {
        throw new HttpsError("invalid-argument", "Caminho no storage e nome do arquivo são obrigatórios.");
    }

    try {
        const analysis = await container.onboardingService.analyzeAccountDocument(
            workspaceId,
            storagePath,
        );
        return analysis;
    }
    catch (error: any) {
        console.error("Erro na análise do documento:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise do documento.");
    }
});

export const analyzeReconciliationDocument = onCall({ timeoutSeconds: 300 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, storagePath } = request.data;

    if (!workspaceId || !storagePath) {
        throw new HttpsError("invalid-argument", "Workspace ID e caminho no storage são obrigatórios.");
    }

    try {
        const analysis = await container.onboardingService.analyzeReconciliationDocument(
            workspaceId,
            storagePath,
        );
        return analysis;
    }
    catch (error: any) {
        console.error("Erro na análise de conciliação:", error);
        throw new HttpsError("internal", error.message || "Erro ao processar análise de conciliação.");
    }
});

export const analyzeGoalFeasibility = onCall({ timeoutSeconds: 120 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, goalPayload } = request.data;

    if (!workspaceId || !goalPayload) {
        throw new HttpsError("invalid-argument", "workspaceId e goalPayload são obrigatórios.");
    }

    try {
        const result = await container.goalFeasibilityService.analyze(workspaceId, goalPayload);
        return result;
    }
    catch (error: any) {
        console.error("Erro na análise de viabilidade da meta:", error);
        throw new HttpsError("internal", error.message || "Erro ao analisar viabilidade da meta.");
    }
});
