import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { AccountModel } from "../../domain/models/finance.models";

export const onAccountWritten = onDocumentWritten(
  "workspaces/{workspaceId}/accounts/{accountId}",
  async (event) => {
    const workspaceId = event.params.workspaceId;
    const accountId = event.params.accountId;

    const afterData = event.data?.after.exists ? event.data.after.data() : null;

    const account = afterData ? {
      ...afterData,
      id: accountId,
      initialBalanceDate: afterData.initial_balance_date.toDate(),
    } as AccountModel : null;

    // Sincronizar o LedgerEntry de saldo inicial
    await container.financeService.syncInitialBalance(workspaceId, accountId, account);
  }
);
