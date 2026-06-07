import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    AccountModel,
    AccountBalanceModel,
    PeriodSummaryUpdateModel, InstallmentStatus,
} from "../models/finance.models";

export interface IFinanceRepository {
  // Orders
  createOrder(workspaceId: string, order: Omit<OrderModel, "id">, id?: string): Promise<string>;
  getOrderById(workspaceId: string, orderId: string): Promise<OrderModel | null>;
  updateOrder(workspaceId: string, orderId: string, order: Partial<OrderModel>): Promise<void>;
  deleteOrder(workspaceId: string, orderId: string): Promise<void>;
  deleteOrdersByAccountId(workspaceId: string, accountId: string): Promise<void>;
  getOrders(workspaceId: string, limit?: number): Promise<OrderModel[]>;

  // Order History
  createOrderHistory(workspaceId: string, orderId: string, snapshot: any): Promise<void>;

  // Installments
  createInstallments(workspaceId: string, installments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]): Promise<void>;
  updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void>;
  deleteInstallment(workspaceId: string, installmentId: string): Promise<void>;
  getInstallmentById(workspaceId: string, installmentId: string): Promise<InstallmentModel | null>;
  getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]>;
  deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void>;
  getInstallments(workspaceId: string, filters: { 
    accountId?: string, 
    startDate?: Date, 
    endDate?: Date, 
    status?: InstallmentStatus[] 
  }): Promise<InstallmentModel[]>;
  getOrdersByRecurringNextGenerationGroup(dateThreshold: Date, limit: number): Promise<(OrderModel & { workspaceId: string })[]>;
  processRecurringInstallmentsChunk(
    chunk: (OrderModel & { workspaceId: string })[],
    installmentFactory: (order: OrderModel) => Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]
  ): Promise<void>;

  // Category Planning
  getCategoryPlanningById(workspaceId: string, id: string): Promise<CategoryPlanningModel | null>;
  createCategoryPlanning(workspaceId: string, planning: Omit<CategoryPlanningModel, "id">): Promise<string>;
  updateCategoryPlanning(workspaceId: string, id: string, planning: Partial<CategoryPlanningModel>): Promise<void>;
  deleteCategoryPlanning(workspaceId: string, id: string): Promise<void>;
  deleteCategoryPlanningsByCategoryId(workspaceId: string, categoryId: string): Promise<void>;
  getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]>;
  getCategoryPlanningsByLastSummaryMonthGroup(nowStr: string, limit: number): Promise<(CategoryPlanningModel & { workspaceId: string, ref: any })[]>;
  processCategoryPlanningSummariesChunk(
    chunk: (CategoryPlanningModel & { workspaceId: string, ref: any })[],
    nowStr: string,
    summaryFactory: (workspaceId: string, planning: CategoryPlanningModel) => PeriodSummaryUpdateModel[]
  ): Promise<void>;

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
        },
        week?: number
    ): Promise<void>;
  getPeriodSummary(workspaceId: string, year: number, month?: number, week?: number): Promise<any | null>;

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

  updateOrderCategory(workspaceId: string, category: CategoryModel): any;
  updateInstallmentCategory(workspaceId: string, category: CategoryModel): any;
  updateInvoiceWithDelta(
    workspaceId: string,
    account: AccountModel,
    dueDate: Date,
    delta: number
  ): Promise<void>;
}
