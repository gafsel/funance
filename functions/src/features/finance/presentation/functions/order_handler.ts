import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { MONEY_CENTS_FIELDS, ORDER_DERIVED_FIELDS, OrderModel } from "../../domain/models/finance.models";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import { applyCentsPatch } from "../../../../core/utils/money_cents";

export const onOrderWritten = onDocumentWritten(
    "workspaces/{workspaceId}/orders/{orderId}",
    async (event) => {
        const { workspaceId, orderId } = event.params;
        const financeService = container.financeService;

        const beforeData = event.data?.before.exists ? event.data.before.data() : null;
        const afterData = event.data?.after.exists ? event.data.after.data() : null;

        // F1.10 — passo derivado: completa `amountCents` a partir do `double`
        // que o CLIENTE gravou.
        if (afterData) {
            await applyCentsPatch(
                admin.firestore().collection(`workspaces/${workspaceId}/orders`).doc(orderId),
                afterData,
                MONEY_CENTS_FIELDS.orders,
                "onOrderWritten"
            );
        }

        // GUARDA POR CONTEÚDO (F1.10): a escrita do espelho inteiro acima gera
        // um novo evento. A order não tinha guarda nenhuma, e sem esta cada
        // documento tocado pela migração ganharia um registro de `history` do
        // nada — além de reexecutar `syncInstallments` de graça.
        if (beforeData && afterData) {
            const changedFields = getChangedFields(beforeData, afterData);
            if (changedFields.every((field) => ORDER_DERIVED_FIELDS.has(field))) {
                logger.info(`[onOrderWritten] Saída antecipada: ${orderId} mudou apenas campos derivados [${changedFields.join(", ")}].`);
                return;
            }
        }

        const before = beforeData ? {
            id: orderId,
            ...beforeData,
        } as OrderModel : null;

        const after = afterData ? {
            id: orderId,
            ...afterData,
        } as OrderModel : null;

        console.log(`Order ${orderId} escrita no workspace ${workspaceId}. Sincronizando installments.`);
        await container.idempotencyService.runIdempotency(event.id, "syncInstallments", async () => {
            await financeService.syncInstallments(workspaceId, orderId, before, after);
        });

        // 4. Criar um registro de histórico de order que copia o snapshot da order e salva juntamente de uma data/hora sempre que houver uma alteração
        if (afterData) {
            await container.idempotencyService.runIdempotency(event.id, "createOrderHistory", async () => {
                await financeService.createOrderHistory(workspaceId, orderId, afterData);
            });
        }
    }
);
