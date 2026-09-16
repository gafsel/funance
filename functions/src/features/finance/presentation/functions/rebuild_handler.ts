import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { assertWorkspaceOwner } from "../../../../core/services/workspace_access.service";
import { REBUILD_CALLABLE_OPTIONS } from "../../../../core/config/functions.config";

/**
 * Reconstrói saldos diários, `period_summaries` e `weekly_xp` do workspace a
 * partir de `installments` + `category_planning`.
 *
 * - **Dry-run por padrão**: só devolve o diff. Passe `apply: true` para gravar.
 * - **Somente o dono do workspace** (criador) pode chamar: é uma operação que
 *   apaga e reescreve coleções inteiras.
 * - **Não consome cota de IA** — não há chamada ao Gemini aqui.
 */
export const rebuildWorkspace = onCall(REBUILD_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, apply, pruneResidual } = request.data || {};

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    if (apply !== undefined && typeof apply !== "boolean") {
        throw new HttpsError("invalid-argument", "O campo 'apply' deve ser booleano.");
    }

    if (pruneResidual !== undefined && typeof pruneResidual !== "boolean") {
        throw new HttpsError("invalid-argument", "O campo 'pruneResidual' deve ser booleano.");
    }

    await assertWorkspaceOwner(workspaceId, request.auth.uid);

    try {
        const report = await container.rebuildService.rebuildWorkspace(workspaceId, {
            dryRun: apply !== true,
            pruneResidual: pruneResidual === true,
        });

        logger.info(
            `[rebuildWorkspace] ${workspaceId}: modo=${report.mode}, mudanças=${report.totalChanges}, escritas=${report.writesCommitted}.`
        );

        return report;
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        logger.error(`[rebuildWorkspace] Falha ao reconstruir ${workspaceId}:`, error);
        throw new HttpsError("internal", error.message || "Erro ao reconstruir o workspace.");
    }
});
