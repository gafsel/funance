import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { MONEY_CENTS_FIELDS, ORDER_DERIVED_FIELDS, OrderModel } from "../../domain/models/finance.models";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import { applyCentsPatch, withFreshCents } from "../../../../core/utils/money_cents";

// Reexportada por conveniência: quem testa a guarda importa daqui, como já
// acontece com `INSTALLMENT_DERIVED_FIELDS`.
export { ORDER_DERIVED_FIELDS };

export interface OrderEventContext {
    workspaceId: string;
    orderId: string;
    eventId: string;
}

/**
 * Corpo do gatilho de order, como função pura (sem `CloudEvent`).
 *
 * Isolada assim ela pode ser chamada direto nos testes de integração — o
 * emulador do Firestore não dispara triggers, então a única forma de verificar
 * o encadeamento evento -> escrita derivada -> evento é invocar o handler com o
 * par (before, after) que a escrita derivada produziria.
 */
export async function handleOrderWritten(
    beforeData: Record<string, any> | null,
    afterData: Record<string, any> | null,
    ctx: OrderEventContext
): Promise<void> {
    const { workspaceId, orderId, eventId } = ctx;
    const financeService = container.financeService;

    // GUARDA POR CONTEÚDO (F1.10) — ANTES do passo derivado. A escrita do
    // espelho inteiro gera um novo evento, e a order não tinha guarda nenhuma:
    // sem esta saída, cada documento tocado pela migração ganharia um registro
    // em `orders/{id}/history` do nada, além de reexecutar `syncInstallments`
    // de graça. São 1.074 orders em produção.
    if (beforeData && afterData) {
        const changedFields = getChangedFields(beforeData, afterData);
        if (changedFields.every((field) => ORDER_DERIVED_FIELDS.has(field))) {
            logger.info(`[onOrderWritten] Saída antecipada: ${orderId} mudou apenas campos derivados [${changedFields.join(", ")}].`);
            return;
        }
    }

    // F1.10 — passo derivado: completa `amountCents` a partir do `double` que o
    // CLIENTE gravou.
    if (afterData) {
        await applyCentsPatch(
            admin.firestore().collection(`workspaces/${workspaceId}/orders`).doc(orderId),
            afterData,
            MONEY_CENTS_FIELDS.orders,
            "onOrderWritten"
        );
    }

    // HOTFIX — o payload do evento carrega o `*Cents` de ANTES do passo
    // derivado; `resolveCents` prefere o inteiro, então `syncInstallments`
    // repartiria o valor ANTIGO entre as parcelas.
    const before = beforeData ? {
        id: orderId,
        ...withFreshCents(beforeData, MONEY_CENTS_FIELDS.orders),
    } as OrderModel : null;

    const after = afterData ? {
        id: orderId,
        ...withFreshCents(afterData, MONEY_CENTS_FIELDS.orders),
    } as OrderModel : null;

    console.log(`Order ${orderId} escrita no workspace ${workspaceId}. Sincronizando installments.`);
    await container.idempotencyService.runIdempotency(eventId, "syncInstallments", async () => {
        await financeService.syncInstallments(workspaceId, orderId, before, after);
    });

    // 4. Criar um registro de histórico de order que copia o snapshot da order e salva juntamente de uma data/hora sempre que houver uma alteração
    if (afterData) {
        await container.idempotencyService.runIdempotency(eventId, "createOrderHistory", async () => {
            await financeService.createOrderHistory(workspaceId, orderId, afterData);
        });
    }
}

export const onOrderWritten = onDocumentWritten(
    "workspaces/{workspaceId}/orders/{orderId}",
    async (event) => {
        await handleOrderWritten(
            event.data?.before.exists ? event.data.before.data() ?? null : null,
            event.data?.after.exists ? event.data.after.data() ?? null : null,
            {
                workspaceId: event.params.workspaceId,
                orderId: event.params.orderId,
                eventId: event.id,
            }
        );
    }
);
