import { OrderModel, LedgerEntryModel, AccountModel, OrderStatus, OrderType, LedgerEntryStatus, LedgerEntryType } from "../models/finance.models";
import { CategoryType } from "../../../workspace/domain/models/category.model";
import { IFinanceRepository } from "../repositories/finance.repository";

export class FinanceService {
  constructor(private financeRepository: IFinanceRepository) {}

  async syncLedgerEntries(workspaceId: string, orderId: string, order: OrderModel | null): Promise<void> {
    // 1. Buscar entries existentes
    const existingEntries = await this.financeRepository.getLedgerEntriesByOrderId(workspaceId, orderId);

    // 2. Se a order foi excluída ou está cancelada, deletamos tudo
    if (!order || order.status === OrderStatus.cancelled) {
      for (const entry of existingEntries) {
        await this.financeRepository.deleteLedgerEntry(workspaceId, entry.id);
      }
      return;
    }

    // 3. Gerar o que deveria existir
    const expectedEntries: Omit<LedgerEntryModel, "id">[] = [];
    if (order.type === OrderType.transfer) {
      const fromAccountId = order.metadata?.fromAccountId;
      const toAccountId = order.metadata?.toAccountId;

      if (fromAccountId) {
        expectedEntries.push({
          orderId: orderId,
          orderType: order.type,
          category: order.category,
          amount: order.totalAmount,
          dueDate: order.date,
          status: LedgerEntryStatus.cleared,
          type: LedgerEntryType.debit,
          accountId: fromAccountId,
          planningId: order.planningId,
        });
      }

      if (toAccountId) {
        expectedEntries.push({
          orderId: orderId,
          orderType: order.type,
          category: order.category,
          amount: order.totalAmount,
          dueDate: order.date,
          status: LedgerEntryStatus.cleared,
          type: LedgerEntryType.credit,
          accountId: toAccountId,
          planningId: order.planningId,
        });
      }
    }
    else {
      const installmentsCount = order.installmentsCount || 1;
      const installmentAmount = parseFloat((order.totalAmount / installmentsCount).toFixed(2));
      const entryType = order.type === OrderType.income ? LedgerEntryType.credit : LedgerEntryType.debit;
      const accountId = order.metadata?.accountId;

      if (accountId) {
        for (let i = 0; i < installmentsCount; i++) {
          const dueDate = new Date(order.date);
          dueDate.setMonth(dueDate.getMonth() + i);

          let currentAmount = installmentAmount;
          if (i === installmentsCount - 1) {
            currentAmount = parseFloat((order.totalAmount - (installmentAmount * (installmentsCount - 1))).toFixed(2));
          }

          expectedEntries.push({
            orderId: orderId,
            orderType: order.type,
            category: order.category,
            amount: currentAmount,
            dueDate: dueDate,
            status: LedgerEntryStatus.cleared,
            type: entryType,
            accountId: accountId,
            planningId: order.planningId,
          });
        }
      }
    }

    // 4. Merge Inteligente
    // Deletar o que não é mais necessário
    for (let i = existingEntries.length - 1; i >= expectedEntries.length; i--) {
      await this.financeRepository.deleteLedgerEntry(workspaceId, existingEntries[i].id);
    }

    // Atualizar existentes ou criar novos
    for (let i = 0; i < expectedEntries.length; i++) {
      const expected = expectedEntries[i];
      if (i < existingEntries.length) {
        const existing = existingEntries[i];
        // Verificar se algo mudou antes de atualizar para evitar disparos desnecessários
        const hasChanged =
          existing.amount !== expected.amount ||
          existing.dueDate.getTime() !== expected.dueDate.getTime() ||
          existing.accountId !== expected.accountId ||
          existing.category.id !== expected.category.id ||
          existing.planningId !== expected.planningId ||
          existing.orderType !== expected.orderType ||
          String(existing.type) !== String(expected.type);

        if (hasChanged) {
          await this.financeRepository.updateLedgerEntry(workspaceId, existing.id, expected);
        }
      }
      else {
        await this.financeRepository.createLedgerEntries(workspaceId, [expected]);
      }
    }
  }

  async updateAccountBalanceOnLedgerChange(
    workspaceId: string,
    before: LedgerEntryModel | null,
    after: LedgerEntryModel | null
  ): Promise<void> {
    // Se houve mudança direta na LedgerEntry (ex: via dashboard, limpeza de conciliação)
    if (before && before.accountId) {
      const delta = before.type === LedgerEntryType.credit || before.type === LedgerEntryType.initial_balance ? -before.amount : before.amount;
      await this.financeRepository.updateAccountBalance(workspaceId, before.accountId, before.dueDate, delta);
    }

    if (after && after.accountId) {
      const delta = after.type === LedgerEntryType.credit || after.type === LedgerEntryType.initial_balance ? after.amount : -after.amount;
      await this.financeRepository.updateAccountBalance(workspaceId, after.accountId, after.dueDate, delta);
    }
  }

  async syncInitialBalance(workspaceId: string, accountId: string, account: AccountModel | null): Promise<void> {
    const existingEntries = await this.financeRepository.getLedgerEntries(workspaceId, { accountId });
    const initialBalanceEntry = existingEntries.find((e) => e.type === LedgerEntryType.initial_balance);

    if (!account || account.isDeleted) {
      if (initialBalanceEntry) {
        await this.financeRepository.deleteLedgerEntry(workspaceId, initialBalanceEntry.id);
      }
      return;
    }

    const expectedEntry: Omit<LedgerEntryModel, "id"> = {
      orderId: "initial_balance",
      category: {
        id: "initial_balance",
        name: "Initial Balance",
        icon: "account_balance",
        color: "0xFF9E9E9E",
        type: CategoryType.both,
        isDeleted: false,
      },
      amount: account.initialBalance,
      dueDate: account.initialBalanceDate,
      status: LedgerEntryStatus.cleared,
      type: LedgerEntryType.initial_balance,
      accountId: account.id,
    };

    if (initialBalanceEntry) {
      const hasChanged =
        initialBalanceEntry.amount !== expectedEntry.amount ||
        initialBalanceEntry.dueDate.getTime() !== expectedEntry.dueDate.getTime();

      if (hasChanged) {
        await this.financeRepository.updateLedgerEntry(workspaceId, initialBalanceEntry.id, expectedEntry);
      }
    }
    else {
      await this.financeRepository.createLedgerEntries(workspaceId, [expectedEntry]);
    }
  }
}
