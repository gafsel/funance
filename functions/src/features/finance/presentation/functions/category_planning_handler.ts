import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import {
    CATEGORY_PLANNING_DERIVED_FIELDS,
    CategoryPlanningModel,
    MONEY_CENTS_FIELDS,
} from "../../domain/models/finance.models";
import { applyCentsPatch, withFreshCents } from "../../../../core/utils/money_cents";

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

    // F1.10 — passo derivado: completa `amountCents`/`appliedAmountCents` a
    // partir do `double`. Antes da guarda: uma escrita que só mexeu nos
    // marcadores de F1.5 não tem impacto a reaplicar, mas o `appliedAmount`
    // que ela acabou de gravar precisa do espelho inteiro.
    if (afterData) {
        await applyCentsPatch(
            admin.firestore().collection(`workspaces/${workspaceId}/category_planning`).doc(planningId),
            afterData,
            MONEY_CENTS_FIELDS.category_planning,
            "onCategoryPlanningWritten"
        );
    }

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

    // HOTFIX — o payload do evento carrega o `*Cents` de ANTES do passo
    // derivado: uma edição de `amount` feita pelo app chega com o `double` novo
    // e o inteiro velho, e `resolveCents` prefere o inteiro. Sem normalizar
    // aqui, o estorno e a reaplicação usariam o valor ANTIGO — o planejamento
    // aplicava 500 nos sumários para uma edição de 1000, e o segundo evento
    // (só o espelho) saía pela guarda sem corrigir nada. Vale para os DOIS
    // lados: o `before` também pode ter o espelho defasado.
    const before = beforeData
        ? { id: planningId, ...withFreshCents(beforeData, MONEY_CENTS_FIELDS.category_planning) } as CategoryPlanningModel
        : null;
    const after = afterData
        ? { id: planningId, ...withFreshCents(afterData, MONEY_CENTS_FIELDS.category_planning) } as CategoryPlanningModel
        : null;

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
