import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { OrderModel } from "../../domain/models/finance.models";

export const onOrderWritten = onDocumentWritten(
    "workspaces/{workspaceId}/orders/{orderId}",
    async (event) => {
        const { workspaceId, orderId } = event.params;
        const financeService = container.financeService;

        const beforeData = event.data?.before.exists ? event.data.before.data() : null;
        const afterData = event.data?.after.exists ? event.data.after.data() : null;

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
