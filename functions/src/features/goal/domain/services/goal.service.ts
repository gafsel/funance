import { InstallmentModel } from "../../../finance/domain/models/finance.models";
import { GoalModel } from "../models/goal.model";

export interface IGoalService {
  /** Recalcula as metas afetadas por uma mudança de parcela. */
  processInstallmentChange(workspaceId: string, before: InstallmentModel | null, after: InstallmentModel | null): Promise<void>;
  /**
   * Recalcula UMA meta pela regra do seu tipo e grava se o valor mudou.
   * Devolve o `currentAmount` gravado, ou `null` quando nada mudou.
   *
   * Usado na criação da meta (para ela já nascer com o progresso real) e pelo
   * script `recompute_goals`.
   */
  recomputeGoal(workspaceId: string, goal: GoalModel): Promise<number | null>;
  /**
   * Valor que a meta DEVERIA ter, calculado do zero pela fonte de verdade do
   * tipo, sem gravar nada. `null` quando o tipo da meta não é reconhecido.
   */
  computeCurrentAmount(workspaceId: string, goal: GoalModel): Promise<number | null>;
}
