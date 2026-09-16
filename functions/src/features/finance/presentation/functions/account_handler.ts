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
            await container.idempotencyService.runIdempotency(event.id, "deleteOrdersByAccount", async () => {
                console.log(`Conta ${accountId} marcada como excluída no workspace ${workspaceId}. Removendo transações associadas.`);
                await financeService.deleteOrdersByAccountId(workspaceId, accountId);
            });
            return;
        }

        // Saldo inicial editado: a order sintética `initial-balance-{accountId}`
        // (e a parcela correspondente) precisa ser ressincronizada, senão o
        // saldo da conta fica preso no valor informado na criação.
        const balanceChanged = before.initialBalance !== after.initialBalance;
        const balanceDateChanged = normalizeDate(before.initialBalanceDate) !== normalizeDate(after.initialBalanceDate);

        if (balanceChanged || balanceDateChanged) {
            await container.idempotencyService.runIdempotency(event.id, "syncInitialBalance", async () => {
                console.log(`Saldo inicial da conta ${accountId} alterado no workspace ${workspaceId}. Ressincronizando a order de saldo inicial.`);
                await financeService.syncInitialBalance(workspaceId, accountId, after as any);
            });
        }
    }
);

/**
 * `initialBalanceDate` chega como string ISO (cliente atual) ou Timestamp
 * (documentos antigos): normalizamos para comparar antes/depois.
 */
function normalizeDate(raw: any): string {
    if (!raw) return "";
    if (typeof raw.toDate === "function") return raw.toDate().toISOString();
    return String(raw);
}

export const onAccountCreated = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const { workspaceId, accountId } = event.params;
        const financeService = container.financeService;

        const account = event.data?.data() as any;

        await container.idempotencyService.runIdempotency(event.id, "syncInitialBalance", async () => {
            await financeService.syncInitialBalance(workspaceId, accountId, account);
        });
    }
);
