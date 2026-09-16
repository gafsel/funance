import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";
import { assertWorkspaceMember } from "../../../../core/services/workspace_access.service";
import { AI_CALLABLE_OPTIONS_SHORT } from "../../../../core/config/functions.config";

export const analyze503020Ideal = onCall(AI_CALLABLE_OPTIONS_SHORT, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, force } = request.data;

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    await assertWorkspaceMember(workspaceId, request.auth.uid);

    try {
        const analysis = await container.planningAnalysisService.analyze(workspaceId, force === true);
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
