import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";
import { assertWorkspaceMember } from "../../../../core/services/workspace_access.service";
import { AI_CALLABLE_OPTIONS_SHORT } from "../../../../core/config/functions.config";
import { AI_DAILY_QUOTAS } from "../../../../core/config/quota.config";

export const analyze503020Ideal = onCall(AI_CALLABLE_OPTIONS_SHORT, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    // `force` NÃO é aceito do cliente (F0.8): o cache de 3 dias é a principal
    // proteção de custo da análise 50-30-20 e não pode ser contornado pelo app.
    const { workspaceId } = request.data;

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    // A cota não é CONSUMIDA aqui: o serviço tem cache de 3 dias e só gasta
    // cota quando realmente chama a IA (ver PlanningAnalysisService.analyze).
    // Mas fazemos a pré-checagem somente-leitura já: com a cota esgotada não
    // vale a pena montar o contexto nem classificar grupos de categoria (que
    // pode chamar o Gemini) para descartar tudo depois.
    const quota = container.quotaService.guardFor(
        workspaceId, "analyze503020Ideal", AI_DAILY_QUOTAS.analyze503020Ideal
    );
    await quota.check();

    try {
        const analysis = await container.planningAnalysisService.analyze(workspaceId, quota);
        return analysis;
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        console.error("Erro na análise ideal 50-30-20:", error);
        throw new HttpsError("internal", error.message || "Erro ao gerar a análise ideal 50-30-20.");
    }
});
