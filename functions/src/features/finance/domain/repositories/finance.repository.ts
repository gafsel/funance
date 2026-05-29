import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
  OrderModel,
  InstallmentModel,
  CategoryPlanningModel,
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

  // Installments
  createInstallments(workspaceId: string, installments: Omit<InstallmentModel, "id">[]): Promise<void>;
  updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void>;
  deleteInstallment(workspaceId: string, installmentId: string): Promise<void>;
  getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]>;
  deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void>;
  getInstallments(workspaceId: string, filters: { accountId?: string }): Promise<InstallmentModel[]>;

  // Category Planning
  getCategoryPlanningById(workspaceId: string, id: string): Promise<CategoryPlanningModel | null>;
  createCategoryPlanning(workspaceId: string, planning: Omit<CategoryPlanningModel, "id">): Promise<string>;
  updateCategoryPlanning(workspaceId: string, id: string, planning: Partial<CategoryPlanningModel>): Promise<void>;
  deleteCategoryPlanning(workspaceId: string, id: string): Promise<void>;

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
