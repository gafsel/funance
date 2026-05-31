import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";

export const onAccountUpdated = onDocumentUpdated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const { workspaceId, accountId } = event.params;
        const financeService = container.financeService;

        const before = event.data?.before.data();
        const after = event.data?.after.data();

        if (!before || !after) {
            return;
        }

        // Verifica se a conta foi marcada como excluída (soft delete)
        if (!before.isDeleted && after.isDeleted) {
            console.log(`Conta ${accountId} marcada como excluída no workspace ${workspaceId}. Removendo transações associadas.`);
            await financeService.deleteOrdersByAccountId(workspaceId, accountId);
        }
    }
);

export const onAccountCreated = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const { workspaceId, accountId } = event.params;
        const financeService = container.financeService;

        const account = event.data?.data() as any;

        await financeService.syncInitialBalance(workspaceId, accountId, account);
    }
);
