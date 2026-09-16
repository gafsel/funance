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

    // A cota não é CONSUMIDA aqui: o serviço tem cache de 5 dias e só gasta
    // cota quando realmente chama a IA (ver CoachingService.generateCoaching).
    // Mas fazemos a pré-checagem somente-leitura já: com a cota esgotada não
    // vale a pena montar o contexto financeiro nem classificar grupos de
    // categoria (que pode chamar o Gemini) para descartar tudo depois.
    const quota = container.quotaService.guardFor(
        workspaceId, "generateCoaching", AI_DAILY_QUOTAS.generateCoaching
    );
    await quota.check();

    try {
        const coaching = await container.coachingService.generateCoaching(workspaceId, quota);
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
