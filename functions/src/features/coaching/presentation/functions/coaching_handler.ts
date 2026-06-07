import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";

export const generateCoaching = onCall({ timeoutSeconds: 300 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId } = request.data;

    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    try {
        const coaching = await container.coachingService.generateCoaching(workspaceId);
        return coaching;
    }
    catch (error: any) {
        console.error("Erro ao gerar coaching:", error);
        throw new HttpsError("internal", error.message || "Erro ao gerar coaching.");
    }
});
