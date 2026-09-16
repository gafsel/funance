import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { assertWorkspaceOwner } from "../../../../core/services/workspace_access.service";
import { REBUILD_CALLABLE_OPTIONS } from "../../../../core/config/functions.config";

export interface RebuildCallableRequest {
    workspaceId: string;
    /** Só muda a PRÉVIA: mostra o que o `--rebuild-planning` do script faria. */
    rebuildPlanning: boolean;
}

/**
 * Valida o payload da callable.
 *
 * A callable é **somente leitura**: `apply` e `pruneResidual` são rejeitados
 * com `invalid-argument`. Escrever é responsabilidade exclusiva do script
 * operacional `lib/scripts/rebuild_workspace.js`, que roda com service account,
 * sob supervisão e depois de um dry-run revisado.
 */
export function parseRebuildRequest(data: any): RebuildCallableRequest {
    const { workspaceId, apply, pruneResidual, rebuildPlanning } = data || {};

    if (!workspaceId || typeof workspaceId !== "string") {
        throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
    }

    if (apply !== undefined) {
        throw new HttpsError(
            "invalid-argument",
            "Esta função roda apenas em modo simulação. A reconstrução é aplicada pelo script operacional rebuild_workspace."
        );
    }

    if (pruneResidual !== undefined) {
        throw new HttpsError(
            "invalid-argument",
            "'pruneResidual' só existe na aplicação, feita pelo script operacional rebuild_workspace."
        );
    }

    if (rebuildPlanning !== undefined && typeof rebuildPlanning !== "boolean") {
        throw new HttpsError("invalid-argument", "O campo 'rebuildPlanning' deve ser booleano.");
    }

    return { workspaceId, rebuildPlanning: rebuildPlanning === true };
}

/**
 * Simula a reconstrução de saldos diários, `period_summaries` e `weekly_xp` do
 * workspace a partir de `installments` + `category_planning`.
 *
 * - **Sempre dry-run**: devolve o diff, nunca escreve (ver `parseRebuildRequest`).
 * - **Somente o dono do workspace** (criador, `members[0]`).
 * - **Não consome cota de IA** — não há chamada ao Gemini aqui.
 */
export const rebuildWorkspace = onCall(REBUILD_CALLABLE_OPTIONS, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { workspaceId, rebuildPlanning } = parseRebuildRequest(request.data);

    await assertWorkspaceOwner(workspaceId, request.auth.uid);

    try {
        const report = await container.rebuildService.rebuildWorkspace(workspaceId, {
            dryRun: true,
            rebuildPlanning,
        });

        logger.info(
            `[rebuildWorkspace] ${workspaceId}: simulação, mudanças=${report.totalChanges}, planejado=${report.diff.periodSummaries.generalPlannedChanges}.`
        );

        return report;
    }
    catch (error: any) {
        if (error instanceof HttpsError) {
            throw error;
        }
        logger.error(`[rebuildWorkspace] Falha ao simular a reconstrução de ${workspaceId}:`, error);
        throw new HttpsError("internal", error.message || "Erro ao simular a reconstrução do workspace.");
    }
});
