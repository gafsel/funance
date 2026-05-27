import { IGoalService } from "./goal.service";
import { LedgerEntryModel, LedgerEntryType } from "../../../finance/domain/models/finance.models";
import { IGoalRepository } from "../repositories/goal.repository";
import { GoalType } from "../models/goal.model";

export class GoalServiceImpl implements IGoalService {
  constructor(private goalRepository: IGoalRepository) {}

  async processLedgerEntryChange(workspaceId: string, before: LedgerEntryModel | null, after: LedgerEntryModel | null): Promise<void> {
    const accountId = after?.accountId || before?.accountId;
    if (!accountId) return;

    // Buscar metas ativas associadas a esta conta
    const activeGoals = await this.goalRepository.getActiveGoalsByAccount(workspaceId, accountId);
    if (activeGoals.length === 0) return;

    for (const goal of activeGoals) {
      let amountChange = 0;

      // Calcular a mudança de valor baseada no tipo da meta e da entrada
      // Para 'save_money', queremos somar créditos e subtrair débitos (acumular saldo)
      // Para 'reduce_credit_card', queremos rastrear os gastos (débitos)

      if (before) {
        // Só remove se o lançamento foi depois do início da meta
        const beforeDate = new Date(before.dueDate);
        if (beforeDate >= goal.startDate) {
          amountChange -= this.calculateContribution(goal.type, before);
        }
      }
      if (after) {
        // Só adiciona se o lançamento foi depois do início da meta
        const afterDate = new Date(after.dueDate);
        if (afterDate >= goal.startDate) {
          amountChange += this.calculateContribution(goal.type, after);
        }
      }

      if (amountChange !== 0) {
        goal.currentAmount += amountChange;
        await this.goalRepository.updateGoal(workspaceId, goal);
      }
    }
  }

  private calculateContribution(goalType: GoalType, entry: LedgerEntryModel): number {
    if (goalType === GoalType.save_money) {
      // Contribui positivamente se for crédito, negativamente se for débito
      return entry.type === LedgerEntryType.credit ? entry.amount : -entry.amount;
    }
    else if (goalType === GoalType.reduce_credit_card) {
      // Interessa o total gasto (débitos)
      return entry.type === LedgerEntryType.debit ? entry.amount : 0;
    }
    return 0;
  }
}
