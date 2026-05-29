import { IGoalService } from "./goal.service";
import { InstallmentModel, InstallmentStatus } from "../../../finance/domain/models/finance.models";
import { IGoalRepository } from "../repositories/goal.repository";
import { GoalType } from "../models/goal.model";

export class GoalServiceImpl implements IGoalService {
    constructor(private goalRepository: IGoalRepository) {}

    async processInstallmentChange(workspaceId: string, before: InstallmentModel | null, after: InstallmentModel | null): Promise<void> {
    // Pegar todas as contas envolvidas (antes e depois)
        const accountIds = new Set<string>();
        if (before?.accounts) Object.keys(before.accounts).forEach(id => accountIds.add(id));
        if (after?.accounts) Object.keys(after.accounts).forEach(id => accountIds.add(id));

        if (accountIds.size === 0) return;

        for (const accountId of accountIds) {
            // Buscar metas ativas associadas a esta conta
            const activeGoals = await this.goalRepository.getActiveGoalsByAccount(workspaceId, accountId);
            if (activeGoals.length === 0) continue;

            for (const goal of activeGoals) {
                let amountChange = 0;

                if (before && before.status === InstallmentStatus.paid && before.paidDate) {
                    if (before.paidDate >= goal.startDate && before.accounts && before.accounts[accountId]) {
                        amountChange -= this.calculateContribution(goal.type, before, accountId);
                    }
                }
                if (after && after.status === InstallmentStatus.paid && after.paidDate) {
                    if (after.paidDate >= goal.startDate && after.accounts && after.accounts[accountId]) {
                        amountChange += this.calculateContribution(goal.type, after, accountId);
                    }
                }

                if (amountChange !== 0) {
                    goal.currentAmount += amountChange;
                    await this.goalRepository.updateGoal(workspaceId, goal);
                }
            }
        }
    }

    private calculateContribution(goalType: GoalType, inst: InstallmentModel, accountId: string): number {
        const role = inst.accounts![accountId];
        const amount = inst.paidAmount || inst.amount;

        if (goalType === GoalType.save_money) {
            // Contribui positivamente se for crédito, negativamente se for débito
            return role === "credit" ? amount : -amount;
        }
        else if (goalType === GoalType.reduce_credit_card) {
            // Interessa o total gasto (débitos)
            return role === "debt" ? amount : 0;
        }
        return 0;
    }
}
