import { CategoryModel } from "../../../workspace/domain/models/category.model";

export enum OrderStatus {
  active = "active",
  paid = "paid",
  cancelled = "cancelled",
}

export enum OrderType {
  expense = "expense",
  income = "income",
  transfer = "transfer",
}

export interface OrderModel {
  id: string;
  description: string;
  totalAmount: number;
  category: CategoryModel;
  installmentsCount: number;
  date: Date;
  status: OrderStatus;
  type: OrderType;
  planningId?: string;
  accountIds: string[];
  metadata?: Record<string, any>;
}

export enum LedgerEntryStatus {
  forecast = "forecast",
  cleared = "cleared",
}

export enum LedgerEntryType {
  debit = "debit",
  credit = "credit",
  initial_balance = "initial_balance",
}

export interface LedgerEntryModel {
  id: string;
  orderId: string;
  orderType?: OrderType;
  category: CategoryModel;
  amount: number;
  dueDate: Date;
  status: LedgerEntryStatus;
  type: LedgerEntryType;
  accountId: string;
  planningId?: string;
}

export enum PlanningType {
  unique = "unique",
  recurrent = "recurrent",
  parcelado = "parcelado",
}

export interface PlanningModel {
  id: string;
  category: CategoryModel;
  amount: number;
  type: PlanningType;
  installmentsCount?: number;
  startDate: Date;
  endDate: Date;
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
