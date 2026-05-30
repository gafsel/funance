import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
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
  getOrders(workspaceId: string, limit?: number): Promise<OrderModel[]>;

  // Installments
  createInstallments(workspaceId: string, installments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]): Promise<void>;
  updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void>;
  deleteInstallment(workspaceId: string, installmentId: string): Promise<void>;
  getInstallmentById(workspaceId: string, installmentId: string): Promise<InstallmentModel | null>;
  getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]>;
  deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void>;
  getInstallments(workspaceId: string, filters: { accountId?: string }): Promise<InstallmentModel[]>;

  // Category Planning
  getCategoryPlanningById(workspaceId: string, id: string): Promise<CategoryPlanningModel | null>;
  createCategoryPlanning(workspaceId: string, planning: Omit<CategoryPlanningModel, "id">): Promise<string>;
  updateCategoryPlanning(workspaceId: string, id: string, planning: Partial<CategoryPlanningModel>): Promise<void>;
  deleteCategoryPlanning(workspaceId: string, id: string): Promise<void>;
  getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]>;

  // Period Summaries
  updatePeriodSummary(
    workspaceId: string,
    year: number,
    month: number | undefined,
    category: CategoryModel,
    data: {
      generalPlannedDelta?: number,
      specificPlannedDelta?: number,
      actualDelta?: number
    }
  ): Promise<void>;
  updateSummaryCategoryInfo(workspaceId: string, category: CategoryModel): Promise<void>;

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

  // Generic Query
  getAllWorkspaces(): Promise<string[]>;
}
