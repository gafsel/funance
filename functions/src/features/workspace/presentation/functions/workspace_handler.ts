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

/**
 * Remove um membro do workspace.
 *
 * Passa por callable (e não pelas rules) porque `members` é imutável pelo
 * cliente: a lista é a base de toda permissão do workspace, e quem a edita é
 * sempre o Admin SDK. A validação de dono fica em `WorkspaceServiceImpl`.
 */
export const removeWorkspaceMember = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, memberId } = request.data || {};

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "O ID do workspace é obrigatório.");
    }

    if (!memberId || typeof memberId !== "string") {
        throw new HttpsError("invalid-argument", "O ID do membro é obrigatório.");
    }

    try {
        await container.workspaceService.removeWorkspaceMember(
            workspaceId,
            memberId,
            request.auth.uid
        );

        return { removed: true };
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        console.error("Erro ao remover membro do workspace:", error);
        throw new HttpsError("internal", "Erro ao remover membro do workspace.");
    }
});
