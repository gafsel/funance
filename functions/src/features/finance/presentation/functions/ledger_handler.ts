import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { LedgerEntryModel } from "../../domain/models/finance.models";

export const onLedgerEntryWritten = onDocumentWritten(
  "workspaces/{workspaceId}/ledger_entries/{entryId}",
  async (event) => {
    const workspaceId = event.params.workspaceId;

    const beforeData = event.data?.before.exists ? event.data.before.data() : null;
    const afterData = event.data?.after.exists ? event.data.after.data() : null;

    const before = beforeData ? {
      ...beforeData,
      id: event.data?.before.id,
      dueDate: (beforeData.dueDate?.toDate ? beforeData.dueDate.toDate() : new Date(beforeData.dueDate)),
      accountId: beforeData.accountId,
      orderId: beforeData.orderId,
      orderType: beforeData.orderType,
      planningId: beforeData.planningId,
    } as LedgerEntryModel : null;

    const after = afterData ? {
      ...afterData,
      id: event.data?.after.id,
      dueDate: afterData.dueDate?.toDate ? afterData.dueDate.toDate() : new Date(afterData.dueDate),
      accountId: afterData.accountId,
      orderId: afterData.orderId,
      orderType: afterData.orderType,
      planningId: afterData.planningId,
    } as LedgerEntryModel : null;

    // Atualizar sumários mensais por categoria
    await container.summaryService.processLedgerEntryChange(workspaceId, before, after);

    // Atualizar metas baseadas no LedgerEntry
    await container.goalService.processLedgerEntryChange(workspaceId, before, after);

    // Se a mudança NÃO veio de uma alteração de Order (que já trata o saldo),
    // mas sim de uma alteração direta na LedgerEntry (ex: conciliação, deleção manual)
    // ATENÇÃO: Atualmente as LedgerEntries são gerenciadas via syncLedgerEntries no OrderService.
    // Mas o blueprint prevê impacto de LedgerEntry no saldo.
    // Se usarmos syncLedgerEntries (que deleta e cria), este trigger onLedgerEntryWritten
    // TAMBÉM dispararia para cada delete/create.
    // Para evitar duplo processamento, o ideal é que o saldo seja atualizado apenas no FinanceService
    // OU apenas aqui. O blueprint diz: "quando uma LedgerEntry é criada/modificada/excluída os saldos... devem ser impactado".
    // Vou mover a lógica de saldo do FinanceService para este handler (via service),
    // assim garantimos que QUALQUER mudança na LedgerEntry impacte o saldo.

    await container.financeService.updateAccountBalanceOnLedgerChange(workspaceId, before, after);
  });
