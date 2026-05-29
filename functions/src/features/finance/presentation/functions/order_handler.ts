import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { OrderModel } from "../../domain/models/finance.models";

export const onOrderWritten = onDocumentWritten(
  "workspaces/{workspaceId}/orders/{orderId}",
  async (event) => {
    const { workspaceId, orderId } = event.params;
    const financeService = container.financeService;

    // Se o dado foi deletado
    if (!event.data?.after.exists) {
      console.log(`Order ${orderId} deletada no workspace ${workspaceId}. Removendo ledger entries.`);
      await financeService.syncLedgerEntries(workspaceId, orderId, null);
      return;
    }

    const data = event.data.after.data();

    const order: OrderModel = {
      id: orderId,
      ...data,
      date: data?.date?.toDate ? data.date.toDate() : new Date(data?.date),
    } as OrderModel;

    console.log(`Order ${orderId} criada/alterada no workspace ${workspaceId}. Sincronizando ledger entries.`);
    await financeService.syncLedgerEntries(workspaceId, orderId, order);
  }
);
