import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import { CATEGORY_PLANNING_DERIVED_FIELDS, CategoryPlanningModel } from "../../domain/models/finance.models";

export { CATEGORY_PLANNING_DERIVED_FIELDS };

export interface CategoryPlanningEventContext {
    workspaceId: string;
    planningId: string;
    eventId: string;
}

/**
 * Corpo do gatilho de planejamento, como função pura (sem `CloudEvent`).
 *
 * Isolada assim ela pode ser chamada direto nos testes de integração — o
 * emulador do Firestore não dispara triggers, então a única forma de verificar
 * o encadeamento evento -> escrita derivada -> evento é invocar o handler com o
 * par (before, after) que a escrita derivada produziria.
 */
export async function handleCategoryPlanningWritten(
    beforeData: Record<string, any> | null,
    afterData: Record<string, any> | null,
    ctx: CategoryPlanningEventContext
): Promise<void> {
    const { workspaceId, planningId, eventId } = ctx;

    // GUARDA POR CONTEÚDO (F1.5): depois de aplicar os impactos, o servidor
    // grava `summarizedUntil`/`appliedAmount`/`appliedFrom`/`appliedUntil` no
    // próprio planejamento. Essa escrita gera um novo evento; sem esta guarda
    // ele estornaria e reaplicaria tudo de novo, em laço.
    if (beforeData && afterData) {
        const changedFields = getChangedFields(beforeData, afterData);
        const onlyDerived = changedFields.every((field) => CATEGORY_PLANNING_DERIVED_FIELDS.has(field));

        if (onlyDerived) {
            logger.info(`[onCategoryPlanningWritten] Saída antecipada: ${planningId} mudou apenas campos derivados [${changedFields.join(", ")}].`);
            return;
        }
    }

    const before = beforeData ? { id: planningId, ...beforeData } as CategoryPlanningModel : null;
    const after = afterData ? { id: planningId, ...afterData } as CategoryPlanningModel : null;

    // Atualizar sumários por categoria (planejado geral).
    await container.idempotencyService.runIdempotency(eventId, "processCategoryPlanningChange", async () => {
        await container.summaryService.processCategoryPlanningChange(workspaceId, before, after);
    });

    // F2.2 — o limite é insumo DIRETO da Disciplina (quantas categorias com
    // limite fecharam o mês dentro dele). Criar ou apagar um limite muda o
    // denominador do componente, e sem este carimbo o índice só perceberia na
    // próxima parcela paga — ou nunca, num mês em que o usuário só planejou.
    //
    // Fora da idempotência, como no gatilho de parcela: reexecutar um carimbo é
    // inofensivo, e a guarda por conteúdo lá em cima já descartou o eco da
    // escrita dos marcadores de F1.5.
    await container.financialHealthService.markHealthDirty(workspaceId);
}

export const onCategoryPlanningWritten = onDocumentWritten(
    "workspaces/{workspaceId}/category_planning/{planningId}",
    async (event) => {
        await handleCategoryPlanningWritten(
            event.data?.before.exists ? event.data.before.data() ?? null : null,
            event.data?.after.exists ? event.data.after.data() ?? null : null,
            {
                workspaceId: event.params.workspaceId,
                planningId: event.params.planningId,
                eventId: event.id,
            }
        );
    });
