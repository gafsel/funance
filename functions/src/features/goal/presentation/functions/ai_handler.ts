import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";

export const analysePlanning = onCall(async (request) => {
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

export const analyzeAccountDocument = onCall(async (request) => {
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
