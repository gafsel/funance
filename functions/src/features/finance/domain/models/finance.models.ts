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

/**
 * Planejamento por categoria (`workspaces/{wid}/category_planning/{id}`).
 *
 * Os quatro últimos campos são mantidos EXCLUSIVAMENTE pelo servidor (F1.5) e
 * registram o que já foi lançado nos sumários:
 *
 *  - `summarizedUntil` — último mês já sumarizado. `PLANNING_FULLY_SUMMARIZED`
 *    ("9999-12") marca o planejamento que cabe inteiro no horizonte e não tem
 *    mais nada a aplicar;
 *  - `appliedAmount`/`appliedFrom`/`appliedUntil` — o que exatamente foi
 *    aplicado (valor e intervalo), para que uma alteração estorne o que foi
 *    aplicado, e não um chute.
 */
export interface CategoryPlanningModel {
    id: string;
    category: CategoryModel;
    amount: number;
    startMonth: string; // YYYY-MM
    endMonth: string; // YYYY-MM
    /** LEGADO (pré-F1.5): ninguém grava mais; substituído por `summarizedUntil`. */
    lastSummaryMonth?: string; // YYYY-MM
    summarizedUntil?: string; // YYYY-MM | "9999-12"
    appliedAmount?: number | null;
    appliedFrom?: string | null; // YYYY-MM
    appliedUntil?: string | null; // YYYY-MM
}

/**
 * Campos do planejamento escritos pelo PRÓPRIO servidor em resposta a um
 * evento. Uma escrita que mexe só neles é o eco da execução anterior e não
 * pode disparar o gatilho de novo (senão o estorno/reaplicação vira laço).
 */
export const CATEGORY_PLANNING_DERIVED_FIELDS = new Set([
    "summarizedUntil",
    "appliedAmount",
    "appliedFrom",
    "appliedUntil",
    "lastSummaryMonth",
    "lastUpdate",
    "updatedAt",
]);

/** Marcadores gravados no planejamento depois de aplicar os impactos. */
export interface CategoryPlanningMarks {
    summarizedUntil: string;
    appliedAmount: number | null;
    appliedFrom: string | null;
    appliedUntil: string | null;
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

/**
 * Saldo diário: `accounts/{accountId}/balance/{dateKey}`.
 *
 * O id do documento é SEMPRE igual ao `dateKey` — é assim que o cliente Flutter
 * lê os últimos saldos (`orderBy(documentId, desc)`), e por isso o contrato do
 * id não mudou em F1.4. O que mudou é o significado: o dia agora é o dia de
 * calendário no fuso do produto (antes era UTC) e o documento passou a guardar
 * também o movimento do dia.
 */
export interface AccountBalanceModel {
    id: string; // YYYY-MM-DD (igual ao dateKey)
    /** YYYY-MM-DD no fuso do produto. Ausente nos documentos anteriores a F1.4. */
    dateKey?: string;
    /** Soma dos movimentos DO DIA. Ausente nos documentos anteriores a F1.4. */
    delta?: number;
    /** Saldo acumulado ao FIM do dia. */
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
