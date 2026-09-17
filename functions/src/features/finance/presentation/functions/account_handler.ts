import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { AccountType } from "../../domain/models/finance.models";

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
            // O resumo da fatura precisa sair junto: uma conta apagada não
            // cobra mais nada, e o app mostraria uma fatura fantasma.
            await container.idempotencyService.runIdempotency(event.id, "syncNextInvoice", async () => {
                await container.invoiceSyncService.syncNextInvoice(workspaceId, accountId);
            });
            // F2.2 — a conta sai das somas da Bússola: o saldo dela deixa de
            // contar como reserva (ou como dívida) na hora em que ela é
            // apagada. Sem este carimbo, o índice seguiria exibindo um Fôlego
            // sustentado por uma conta que não existe mais até o próximo
            // pagamento sujar o workspace por outro caminho.
            await container.financialHealthService.markHealthDirty(workspaceId);
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

        // F1.8: mudar o dia de fechamento ou de vencimento muda o vencimento,
        // a janela do ciclo e — por tabela — o id da order de fatura. O resumo
        // denormalizado precisa acompanhar.
        //
        // A guarda é ESTREITA de propósito: a própria escrita de `nextInvoice`
        // dispara este gatilho, e sincronizar em toda atualização faria a conta
        // se realimentar em laço. É também por isso que não existe uma lista de
        // "campos derivados da conta" como a das parcelas: aqui a proteção é
        // por LISTA DE PERMISSÃO, que já exclui `nextInvoice` por construção —
        // duas defesas para o mesmo laço seriam uma a mais para manter.
        const invoiceConfigChanged = before.closingDay !== after.closingDay
            || before.dueDay !== after.dueDay
            || before.runtimeType !== after.runtimeType;

        if (invoiceConfigChanged) {
            await container.idempotencyService.runIdempotency(event.id, "syncNextInvoice", async () => {
                console.log(`Fechamento/vencimento da conta ${accountId} alterado no workspace ${workspaceId}. Recalculando nextInvoice.`);
                await container.invoiceSyncService.syncNextInvoice(workspaceId, accountId);
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

        // Cartão novo já nasce com a janela e o vencimento da fatura corrente
        // (valor zero): sem isso o app ficaria em "calculando" até a primeira
        // compra ou até o cron da madrugada.
        if (account?.runtimeType === AccountType.creditCard) {
            await container.idempotencyService.runIdempotency(event.id, "syncNextInvoice", async () => {
                await container.invoiceSyncService.syncNextInvoice(workspaceId, accountId);
            });
        }
    }
);
