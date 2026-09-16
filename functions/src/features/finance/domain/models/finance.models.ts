import { CategoryModel } from "../../../workspace/domain/models/category.model";

export enum OrderStatus {
    active = "active",
    cancelled = "cancelled",
    settled = "settled",
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
    description: string;
    startMonth: string; // YYYY-MM
    endMonth?: string; // YYYY-MM
    installmentCount?: number;
    installmentType: InstallmentType;
    status: OrderStatus;
    type: OrderType;
    installmentCreationStatus?: InstallmentStatus;
    lastGeneratedDueDate?: Date;
    accounts?: Record<string, "debt" | "credit">;
    accountIds: string[];
    category?: CategoryModel;
    isInvoice?: boolean;
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
    description: string;
    paidAmount?: number;
    paidDate?: Date;
    installmentNumber?: number;
    installmentCount?: number;
    installmentType: InstallmentType;
    status: InstallmentStatus;
    type: OrderType;
    accounts?: Record<string, "debt" | "credit">;
    accountIds: string[];
    category?: CategoryModel;
    replicationCascade?: ReplicationCascade;
    xp?: number;
    referenceDate: Date;
    referenceAmount: number;
    isInvoice?: boolean;
}

/**
 * Campos derivados/técnicos da parcela: escritos pelo PRÓPRIO servidor em
 * resposta a um evento (o `xp` calculado, a cascata zerada, carimbos de
 * atualização), nunca uma intenção do usuário.
 *
 * Uma escrita que mexe SOMENTE nestes campos é o eco da execução anterior.
 * Mora aqui, no modelo, porque mais de um gatilho observa a coleção
 * `installments` e todos precisam da mesma definição.
 */
export const INSTALLMENT_DERIVED_FIELDS = new Set([
    "xp",
    "replicationCascade",
    "lastUpdate",
    "updatedAt",
]);

export interface CategoryPlanningModel {
    id: string;
    category: CategoryModel;
    amount: number;
    startMonth: string; // YYYY-MM
    endMonth: string; // YYYY-MM
    lastSummaryMonth?: string; // YYYY-MM
}

export interface PeriodSummaryModel {
    id: string; // YYYY-MM-categoryId ou YYYY-categoryId ou YYYY-Www-categoryId
    year: number;
    month?: number;
    week?: number;
    category: CategoryModel;
    generalPlannedAmount: number; // Da CategoryPlanning
    specificPlannedAmount: number; // Das Installments projetadas
    actualAmount: number; // Do Realizado
    lastUpdate: Date;
}

export enum AccountType {
    checking = "checking",
    investment = "investment",
    creditCard = "creditCard",
    debt = "debt",
}

export enum BankLogo {
    none = "none",
    nubank = "nubank",
    inter = "inter",
    itau = "itau",
    bradesco = "bradesco",
    santander = "santander",
    bb = "bb",
    caixa = "caixa",
    c6 = "c6",
    xp = "xp",
    btg = "btg",
    visa = "visa",
    mastercard = "mastercard",
    elo = "elo",
    amex = "amex",
}

export interface AccountModel {
    id: string;
    name: string;
    icon: string;
    color: string;
    runtimeType: AccountType;
    isDeleted: boolean;
    initialBalance: number;
    initialBalanceDate: Date;
    closingDay?: number;
    dueDay?: number;
    limit?: number;
    interestRate?: number;
    bankLogo?: BankLogo;
    ownerIds?: string[];
}

export interface AccountBalanceModel {
    id: string; // YYYY-MM-DD
    balance: number;
    updatedAt: Date;
}

export interface PeriodSummaryUpdateModel {
    year: number;
    month?: number;
    week?: number;
    category: CategoryModel;
    generalPlannedDelta?: number;
    specificPlannedDelta?: number;
    actualDelta?: number;
}
