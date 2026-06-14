import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";

export const getWorkspaceMembers = onCall(async (request) => {
    // 1. Verificar autenticação
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId } = request.data;
    if (!workspaceId) {
        throw new HttpsError("invalid-argument", "O ID do workspace é obrigatório.");
    }

    try {
        const workspaceService = container.workspaceService;
        return await workspaceService.getWorkspaceMembers(workspaceId, request.auth.uid);
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        console.error("Erro ao buscar membros do workspace:", error);
        throw new HttpsError("internal", "Erro ao buscar membros do workspace.");
    }
});
