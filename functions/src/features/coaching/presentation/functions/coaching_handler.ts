import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";
import { assertWorkspaceMember } from "../../../../core/services/workspace_access.service";
import { AI_CALLABLE_OPTIONS } from "../../../../core/config/functions.config";
import { AI_DAILY_QUOTAS } from "../../../../core/config/quota.config";

export const generateCoaching = onCall(AI_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId } = request.data;

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);
    await container.quotaService.assertQuota(workspaceId, "generateCoaching", AI_DAILY_QUOTAS.generateCoaching);

    try {
        const coaching = await container.coachingService.generateCoaching(workspaceId);
        return coaching;
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        console.error("Erro ao gerar coaching:", error);
        throw new HttpsError("internal", error.message || "Erro ao gerar coaching.");
    }
});
