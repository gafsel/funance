import { AccountType } from "../../../finance/domain/models/finance.models";
import { GoalModel, GoalOutcome } from "../models/goal.model";

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
   * Escrita mínima do progresso: só `currentAmount`/`currentAmountCents` (e o
   * desfecho, quando a meta acabou de desfechar). Não reescreve o documento
   * inteiro, de modo que uma edição feita no app entre a leitura e a escrita
   * não é sobrescrita.
   *
   * F1.10 — o progresso entra em CENTAVOS INTEIROS: é o repositório que grava
   * o par (inteiro + espelho `round2`), para que não exista um caminho em que
   * só um dos dois seja atualizado.
   */
  updateGoalProgress(
    workspaceId: string,
    goalId: string,
    currentAmountCents: number,
    outcome?: GoalOutcomeStamp | null
  ): Promise<void>;
  /**
   * Carimba SÓ o desfecho, sem tocar em `currentAmount` — o caminho do cron de
   * vencimento, que fecha metas cujo valor não mudou.
   */
  updateGoalOutcome(
    workspaceId: string,
    goalId: string,
    stamp: GoalOutcomeStamp
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
   * Saldo mais recente da conta — o que uma meta `saveMoney` de cofrinho
   * (conta de investimento) persegue. `null` quando a conta não tem nenhum
   * documento de saldo.
   */
  getCurrentBalance(workspaceId: string, accountId: string): Promise<number | null>;
  /**
   * `runtimeType` da conta, ou `null` quando a conta não existe (ou o campo
   * está fora do enum). É o que decide se uma meta `saveMoney` mede SALDO
   * (conta de investimento) ou APORTES desde o início (as demais).
   */
  getAccountType(workspaceId: string, accountId: string): Promise<AccountType | null>;
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

/** Desfecho + instante, do jeito que vai para o documento. */
export interface GoalOutcomeStamp {
  outcome: GoalOutcome;
  at: Date;
}

export interface GoalBalances {
  /**
   * Marco zero da meta: o saldo no FIM DO DIA ANTERIOR ao início — o
   * documento mais recente ESTRITAMENTE antes do `startDate`. O documento do
   * próprio dia de início fica de fora de propósito: ele já inclui o que foi
   * pago naquele dia. `null` quando a conta não tinha saldo gravado até lá.
   */
  startBalance: number | null;
  /** Saldo do último documento de `balance` da conta. */
  currentBalance: number | null;
}

/** Só o que o cálculo de meta precisa de uma parcela. */
export interface InstallmentLike {
  amount?: number;
  paidAmount?: number;
  /** F1.10 — espelhos inteiros, quando o documento já foi migrado. */
  amountCents?: number;
  paidAmountCents?: number;
  paidDate?: Date | null;
  status?: string;
  accounts?: Record<string, "debt" | "credit">;
}
