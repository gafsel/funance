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
      dueDate: beforeData.due_date ? beforeData.due_date.toDate() : (beforeData.dueDate?.toDate ? beforeData.dueDate.toDate() : new Date(beforeData.dueDate)),
      accountId: beforeData.account_id || beforeData.accountId,
      orderId: beforeData.order_id || beforeData.orderId,
      orderType: beforeData.order_type || beforeData.orderType,
      planningId: beforeData.planning_id || beforeData.planningId,
    } as LedgerEntryModel : null;

    const after = afterData ? {
      ...afterData,
      id: event.data?.after.id,
      dueDate: afterData.due_date ? afterData.due_date.toDate() : (afterData.dueDate?.toDate ? afterData.dueDate.toDate() : new Date(afterData.dueDate)),
      accountId: afterData.account_id || afterData.accountId,
      orderId: afterData.order_id || afterData.orderId,
      orderType: afterData.order_type || afterData.orderType,
      planningId: afterData.planning_id || afterData.planningId,
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
