import { GoalModel } from "../models/goal.model";

export interface IGoalRepository {
  getGoals(workspaceId: string): Promise<GoalModel[]>;
  /**
   * Metas NÃO deletadas vinculadas à conta.
   *
   * "Não deletada" e não "ativa" de propósito: uma meta que já bateu o alvo
   * precisa continuar sendo recalculada, senão o estorno de um pagamento
   * deixaria o progresso congelado acima do alvo para sempre.
   */
  getActiveGoalsByAccount(workspaceId: string, accountId: string): Promise<GoalModel[]>;
  /** Metas NÃO deletadas vinculadas à categoria (`category.id`). */
  getActiveGoalsByCategory(workspaceId: string, categoryId: string): Promise<GoalModel[]>;
  getGoal(workspaceId: string, goalId: string): Promise<GoalModel | null>;
  updateGoal(workspaceId: string, goal: GoalModel): Promise<void>;
  /**
   * Escrita mínima do progresso: só `currentAmount` (e `completedAt` na
   * primeira conclusão). Não reescreve o documento inteiro, de modo que uma
   * edição feita no app entre a leitura e a escrita não é sobrescrita.
   */
  updateGoalProgress(
    workspaceId: string,
    goalId: string,
    currentAmount: number,
    completedAt?: Date
  ): Promise<void>;
  /**
   * Soma de `actualAmount` da categoria nos `period_summaries` mensais
   * indicados (ids `YYYY-MM`). Meses sem documento contam zero.
   */
  getCategoryActualByMonths(
    workspaceId: string,
    categoryId: string,
    monthKeys: string[]
  ): Promise<number>;
  /**
   * Os dois saldos que uma meta `payDebt` precisa, numa varredura só:
   * o saldo no início da meta e o saldo mais recente da conta.
   */
  getBalancesForGoal(
    workspaceId: string,
    accountId: string,
    startDate: Date
  ): Promise<GoalBalances>;
  /**
   * Parcelas pagas/liquidadas que tocam a conta, desde `since` (por
   * `paidDate`). Usada só no recálculo total (script e criação de meta): o
   * gatilho de parcela trabalha com o delta do evento, sem varrer nada.
   */
  getPaidInstallmentsByAccountSince(
    workspaceId: string,
    accountId: string,
    since: Date
  ): Promise<InstallmentLike[]>;
}

export interface GoalBalances {
  /**
   * Saldo no dia do início da meta — o documento daquele dia ou, se não
   * houver, o mais recente ANTES dele. `null` quando a conta não tinha saldo
   * gravado até lá.
   */
  startBalance: number | null;
  /** Saldo do último documento de `balance` da conta. */
  currentBalance: number | null;
}

/** Só o que o cálculo de meta precisa de uma parcela. */
export interface InstallmentLike {
  amount?: number;
  paidAmount?: number;
  paidDate?: Date | null;
  status?: string;
  accounts?: Record<string, "debt" | "credit">;
}
