import * as admin from "firebase-admin";
import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    CategoryPlanningMarks,
    AccountModel,
    AccountBalanceModel,
    PeriodSummaryUpdateModel, InstallmentStatus,
} from "../models/finance.models";

/** Planejamento lido pelo cron: sabe de que workspace veio e onde mora. */
export type CategoryPlanningRef = CategoryPlanningModel & {
    workspaceId: string;
    ref: admin.firestore.DocumentReference;
};

/** Página de planejamentos + cursor para a próxima (null = acabou). */
export interface CategoryPlanningPage {
    items: CategoryPlanningRef[];
    cursor: admin.firestore.QueryDocumentSnapshot | null;
}

/**
 * Página da varredura completa. O cursor é o CAMINHO do último documento lido
 * (`workspaces/{wid}/category_planning/{id}`), e não um snapshot, porque ele
 * precisa sobreviver ao fim da execução: o cron guarda esse caminho num
 * checkpoint e retoma dali no mês seguinte. `nextPath: null` significa que a
 * coleção acabou.
 */
export interface CategoryPlanningScanPage {
    items: CategoryPlanningRef[];
    nextPath: string | null;
}

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
  /**
   * Único ponto de criação de parcela. Com `transaction`, as escritas entram na
   * transação do chamador (usado pelo cron de recorrência) em vez de um batch.
   */
  createInstallments(
    workspaceId: string,
    installments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[],
    transaction?: admin.firestore.Transaction
  ): Promise<void>;
  updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void>;
  deleteInstallment(workspaceId: string, installmentId: string): Promise<void>;
  getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]>;
  /** Apaga todas as parcelas da order, em lotes (usado quando a order deixa de existir). */
  deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void>;
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
  /**
   * Planejamentos cujo `summarizedUntil` ainda não alcançou o horizonte.
   * Paginado por cursor: o cron não tem limite global (F1.5).
   */
  getCategoryPlanningsPendingSummary(
    horizon: string,
    pageSize: number,
    cursor?: admin.firestore.QueryDocumentSnapshot | null
  ): Promise<CategoryPlanningPage>;
  /**
   * Varredura de TODOS os planejamentos, paginada por id. Necessária porque o
   * Firestore não consulta "documentos em que o campo não existe": é assim que
   * o cron encontra os planejamentos legados, sem `summarizedUntil`.
   */
  scanCategoryPlannings(
    pageSize: number,
    afterPath?: string | null
  ): Promise<CategoryPlanningScanPage>;
  /**
   * Aplica os deltas de `generalPlannedAmount` nos sumários (agrupados por
   * documento, um `increment` por categoria) e, por último, grava os
   * marcadores no planejamento. Em lotes de no máximo 400 escritas.
   */
  applyPlanningImpacts(
    workspaceId: string,
    updates: PeriodSummaryUpdateModel[],
    marks?: { ref: admin.firestore.DocumentReference, data: CategoryPlanningMarks }
  ): Promise<void>;
  /** Referência do documento de planejamento (para montar `marks`). */
  getCategoryPlanningRef(workspaceId: string, planningId: string): admin.firestore.DocumentReference;

  // Checkpoints de cron (`config/cron_checkpoints`) — coleção raiz, negada ao
  // cliente pela regra final `match /{document=**}`.
  /** Valor do checkpoint, ou `null` se nunca foi gravado. */
  getCronCheckpoint(field: string): Promise<string | null>;
  /** Grava (ou apaga, com `null`) o checkpoint. */
  setCronCheckpoint(field: string, value: string | null): Promise<void>;

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
