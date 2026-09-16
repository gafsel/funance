/**
 * Tipos de meta, com os valores REALMENTE persistidos no Firestore.
 *
 * O cliente Flutter usa uma union freezed (`GoalModel.payDebt`,
 * `GoalModel.saveMoney`, ...) cujo discriminador é gravado no campo
 * `runtimeType` com o nome do factory em camelCase. O campo `type` do modelo
 * Flutter é um getter e NÃO é serializado — por isso os valores snake_case
 * que este enum usava antes (`save_money`, ...) nunca casavam com nada.
 */
export enum GoalType {
  payDebt = "payDebt",
  saveMoney = "saveMoney",
  reduceExpense = "reduceExpense",
  reduceCreditCard = "reduceCreditCard",
}

/**
 * Lê o tipo de uma meta cru do Firestore. Prioriza `runtimeType` (formato
 * atual da union freezed) e cai para `type` por segurança.
 */
export function resolveGoalType(goal: any): GoalType | undefined {
    const raw = goal?.runtimeType ?? goal?.type;
    const values = Object.values(GoalType) as string[];
    return values.includes(raw) ? (raw as GoalType) : undefined;
}

/**
 * Id da categoria de uma meta `reduceExpense`.
 *
 * O cliente grava a categoria inteira (mapa `CategoryModel`) no campo
 * `category`; `categoryId` é aceito como forma alternativa por segurança.
 */
export function resolveGoalCategoryId(goal: any): string | undefined {
    const raw = goal?.category?.id ?? goal?.categoryId;
    return typeof raw === "string" && raw.length > 0 ? raw : undefined;
}

export interface GoalModel {
  id: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  /** Pode faltar em documentos legados: o cliente sempre grava. */
  deadline?: Date;
  icon?: string;
  type: GoalType;
  /** `runtimeType` é o discriminador real gravado pelo cliente. */
  runtimeType?: string;
  accountId?: string;
  /** Categoria da meta `reduceExpense` (mapa `CategoryModel` do cliente). */
  category?: Record<string, any>;
  startDate: Date;
  /**
   * Instante em que a meta bateu o alvo pela primeira vez. É escrito
   * EXCLUSIVAMENTE pelo servidor (as rules negam a escrita pelo cliente) e
   * nunca é reescrito: ele marca a primeira conclusão, não a última.
   */
  completedAt?: Date | null;
  metadata?: Record<string, any>;
  isDeleted: boolean;
}

/**
 * Definição ÚNICA de "meta ativa", usada pelos badges (`two_active_goals`,
 * `five_active_goals`, missões) e pelo relatório do script de recálculo.
 *
 * O documento de meta NÃO tem campo `status` — o cliente nunca gravou um. Os
 * badges liam `status === "active"` e por isso jamais disparavam. Uma meta é
 * ativa quando ainda existe, ainda não bateu o alvo e ainda está no prazo.
 */
export function isGoalActive(goal: any, now: Date = new Date()): boolean {
    if (!goal || goal.isDeleted === true) {
        return false;
    }

    const current = Number(goal.currentAmount ?? 0);
    const target = Number(goal.targetAmount ?? 0);
    if (Number.isFinite(current) && Number.isFinite(target) && target > 0 && current >= target) {
        return false;
    }

    const deadline = toGoalDate(goal.deadline);
    if (deadline && deadline.getTime() < startOfDay(now).getTime()) {
        return false;
    }

    return true;
}

/** Meta concluída: tem `completedAt` ou já alcançou o alvo. */
export function isGoalCompleted(goal: any): boolean {
    if (!goal) {
        return false;
    }
    if (toGoalDate(goal.completedAt)) {
        return true;
    }
    const current = Number(goal.currentAmount ?? 0);
    const target = Number(goal.targetAmount ?? 0);
    return Number.isFinite(current) && Number.isFinite(target) && target > 0 && current >= target;
}

/** Converte Timestamp/ISO/Date num `Date` válido (ou `null`). */
export function toGoalDate(raw: any): Date | null {
    if (!raw) {
        return null;
    }
    const date = raw?.toDate ? raw.toDate() : new Date(raw);
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
}

function startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export interface GoalFeasibilityPayload {
  name: string;
  targetAmount: number;
  deadlineDays: number;
  monthlyRequired: number;
  type: string;
}

export interface MonthlyBreakdownEntry {
  month: string;
  totalIncome: number;
  totalExpense: number;
  categories: { name: string; type: string; amount: number }[];
}
