import { IGoalService } from "./goal.service";
import { InstallmentModel, InstallmentStatus } from "../../../finance/domain/models/finance.models";
import { IGoalRepository } from "../repositories/goal.repository";
import { GoalType, resolveGoalType } from "../models/goal.model";

export class GoalServiceImpl implements IGoalService {
    constructor(private goalRepository: IGoalRepository) {}

    async processInstallmentChange(workspaceId: string, before: InstallmentModel | null, after: InstallmentModel | null): Promise<void> {
    // Pegar todas as contas envolvidas (antes e depois)
        const accountIds = new Set<string>();
        if (before?.accounts) Object.keys(before.accounts).forEach(id => accountIds.add(id));
        if (after?.accounts) Object.keys(after.accounts).forEach(id => accountIds.add(id));

        if (accountIds.size === 0) return;

        const isPaidStatus = (s: InstallmentStatus) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        for (const accountId of accountIds) {
            // Buscar metas ativas associadas a esta conta
            const activeGoals = await this.goalRepository.getActiveGoalsByAccount(workspaceId, accountId);
            if (activeGoals.length === 0) continue;

            for (const goal of activeGoals) {
                // O discriminador da union freezed é gravado em `runtimeType`;
                // `type` não é serializado pelo cliente. Ler `goal.type` direto
                // devolvia undefined e a contribuição era sempre zero — o
                // progresso das metas nunca era atualizado.
                const goalType = resolveGoalType(goal);
                if (!goalType) continue;

                let amountChange = 0;

                if (before && isPaidStatus(before.status) && before.paidDate) {
                    if (before.paidDate >= goal.startDate && before.accounts && before.accounts[accountId]) {
                        amountChange -= this.calculateContribution(goalType, before, accountId);
                    }
                }
                if (after && isPaidStatus(after.status) && after.paidDate) {
                    if (after.paidDate >= goal.startDate && after.accounts && after.accounts[accountId]) {
                        amountChange += this.calculateContribution(goalType, after, accountId);
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

        if (goalType === GoalType.saveMoney) {
            // Contribui positivamente se for crédito, negativamente se for débito
            return role === "credit" ? amount : -amount;
        }
        else if (goalType === GoalType.reduceCreditCard) {
            // Interessa o total gasto (débitos)
            return role === "debt" ? amount : 0;
        }
        return 0;
    }
}
