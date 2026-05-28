import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
  OrderModel,
  LedgerEntryModel,
  CategoryMonthSummaryModel,
  AccountModel,
  AccountBalanceModel,
} from "../models/finance.models";

export interface IFinanceRepository {
  // Orders
  createOrder(workspaceId: string, order: Omit<OrderModel, "id">): Promise<string>;
  getOrderById(workspaceId: string, orderId: string): Promise<OrderModel | null>;
  updateOrder(workspaceId: string, orderId: string, order: Partial<OrderModel>): Promise<void>;
  deleteOrder(workspaceId: string, orderId: string): Promise<void>;
  deleteOrdersByAccountId(workspaceId: string, accountId: string): Promise<void>;

  // Ledger Entries
  createLedgerEntries(workspaceId: string, entries: Omit<LedgerEntryModel, "id">[]): Promise<void>;
  updateLedgerEntry(workspaceId: string, entryId: string, entry: Partial<LedgerEntryModel>): Promise<void>;
  deleteLedgerEntry(workspaceId: string, entryId: string): Promise<void>;
  getLedgerEntriesByOrderId(workspaceId: string, orderId: string): Promise<LedgerEntryModel[]>;
  deleteLedgerEntriesByOrderId(workspaceId: string, orderId: string): Promise<void>;
  getLedgerEntries(workspaceId: string, filters: { accountId?: string }): Promise<LedgerEntryModel[]>;

  // Category Month Summary
  updateCategoryMonthSummary(
    workspaceId: string,
    year: number,
    month: number,
    category: CategoryModel,
    data: { debitDelta: number, creditDelta: number, countDelta: number }
  ): Promise<void>;
  updateSummaryCategoryInfo(workspaceId: string, category: CategoryModel): Promise<void>;
  getCategoryMonthSummaries(workspaceId: string, year: number, month: number): Promise<CategoryMonthSummaryModel[]>;

  // Accounts
  getAccountById(workspaceId: string, accountId: string): Promise<AccountModel | null>;

  // Account Balances
  updateAccountBalance(
    workspaceId: string,
    accountId: string,
    date: Date,
    delta: number
  ): Promise<void>;
  getLastBalanceBefore(
    workspaceId: string,
    accountId: string,
    date: Date
  ): Promise<AccountBalanceModel | null>;

  // Planning
  updateCategoryMonthSummaryPlanning(
    workspaceId: string,
    year: number,
    month: number,
    category: CategoryModel,
    plannedDelta: number
  ): Promise<void>;

  updatePlanningMonthSummary(
    workspaceId: string,
    planningId: string,
    year: number,
    month: number,
    data: { plannedDelta: number, actualDelta: number }
  ): Promise<void>;

  // Generic Query
  getAllWorkspaces(): Promise<string[]>;
}
