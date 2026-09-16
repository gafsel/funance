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
  getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]>;
  /**
   * Parcelas do workspace. Por padrão EXCLUI as de status 'removed'
   * (exclusão lógica); passe `includeRemoved: true` para trazê-las.
   */
  getInstallments(workspaceId: string, filters: {
    accountId?: string,
    startDate?: Date,
    endDate?: Date,
    status?: InstallmentStatus[],
    includeRemoved?: boolean
  }): Promise<InstallmentModel[]>;
  getOrdersByRecurringNextGenerationGroup(dateThreshold: Date, limit: number): Promise<(OrderModel & { workspaceId: string })[]>;
  processRecurringInstallmentsChunk(
    chunk: (OrderModel & { workspaceId: string })[],
    installmentFactory: (order: OrderModel) => Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]
  ): Promise<void>;

  // Category Planning
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

  // Coaching History
  getLastCoachingAnalyses(workspaceId: string, limit: number): Promise<any[]>;
  saveCoachingAnalysis(workspaceId: string, analysis: any): Promise<string>;

  // Coaching Meta: cache de classificação de categorias em grupos macro
  // (workspaces/{wid}/coaching_meta/category_groups — escrito apenas via Admin SDK)
  getCoachingCategoryGroups(workspaceId: string): Promise<Record<string, { group: string; name: string }> | null>;
  saveCoachingCategoryGroups(workspaceId: string, entries: Record<string, { group: string; name: string }>): Promise<void>;

  // Atividade recente (usado pelo coaching proativo)
  hasPaidInstallmentSince(workspaceId: string, since: Date): Promise<boolean>;

  // Análise ideal 50-30-20 (workspaces/{wid}/planning_analysis/{yyyy-MM} —
  // escrita apenas via Admin SDK; o cliente só lê)
  getPlanningAnalysis(workspaceId: string, monthKey: string): Promise<any | null>;
  savePlanningAnalysis(workspaceId: string, monthKey: string, analysis: any): Promise<void>;

  // Accounts
  getAccounts(workspaceId: string): Promise<AccountModel[]>;
}
