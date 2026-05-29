import { CategoryModel } from "../../../workspace/domain/models/category.model";

export enum OrderStatus {
  active = "active",
  cancelled = "cancelled",
}

export enum OrderType {
  expense = "expense",
  income = "income",
  transfer = "transfer",
}

export enum InstallmentType {
  single = "single",
  installment = "installment",
  recurring = "recurring",
}

export interface OrderModel {
  id: string;
  amount: number;
  dueDay: number;
  startMonth: string; // YYYY-MM
  endMonth?: string; // YYYY-MM
  installmentCount?: number;
  installmentType: InstallmentType;
  status: OrderStatus;
  type: OrderType;
  accounts?: Record<string, "debt" | "credit">;
  category?: CategoryModel;
}

export enum InstallmentStatus {
  pending = "pending",
  paid = "paid",
  settled = "settled",
  removed = "removed",
}

export enum ReplicationCascade {
  none = "none",
  all = "all",
  future = "future",
}

export interface InstallmentModel {
  id: string;
  orderId: string;
  amount: number;
  dueDate: Date;
  paidAmount?: number;
  paidDate?: Date;
  status: InstallmentStatus;
  type: OrderType;
  accounts?: Record<string, "debt" | "credit">;
  category?: CategoryModel;
  replicationCascade?: ReplicationCascade;
}

export interface CategoryPlanningModel {
  id: string;
  categoryId: string;
  amount: number;
  startMonth: string; // YYYY-MM
  endMonth: string; // YYYY-MM
}

export interface PlanningMonthSummaryModel {
  id: string; // "YYYY-MM"
  year: number;
  month: number;
  plannedAmount: number;
  actualAmount: number;
  lastUpdate: Date;
}

export interface CategoryMonthSummaryModel {
  id: string; // "YYYY-MM_categoryId"
  year: number;
  month: number;
  category: CategoryModel;
  totalDebit: number;
  totalCredit: number;
  plannedAmount: number;
  actualAmount: number;
  count: number;
  lastUpdate: Date;
}

export enum AccountType {
  checking = "checking",
  investment = "investment",
  credit_card = "credit_card",
  debt = "debt",
}

export interface AccountModel {
  id: string;
  name: string;
  icon: string;
  color: string;
  type: AccountType;
  metadata?: Record<string, any>;
  isDeleted: boolean;
  initialBalance: number;
  initialBalanceDate: Date;
}

export interface AccountBalanceModel {
  id: string; // YYYY-MM-DD
  balance: number;
  updatedAt: Date;
}
