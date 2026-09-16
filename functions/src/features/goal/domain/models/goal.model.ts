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

export interface GoalModel {
  id: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  deadline: Date;
  icon?: string;
  type: GoalType;
  accountId?: string;
  startDate: Date;
  metadata?: Record<string, any>;
  isDeleted: boolean;
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

