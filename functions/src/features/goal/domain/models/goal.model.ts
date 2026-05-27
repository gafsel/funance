export enum GoalType {
  save_money = "save_money",
  reduce_expense = "reduce_expense",
  reduce_credit_card = "reduce_credit_card",
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
