import { InstallmentModel, InstallmentStatus, OrderType, CategoryPlanningModel } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";

export class SummaryService {
    constructor(private financeRepository: IFinanceRepository) {}

    async processCategoryPlanningChange(
        workspaceId: string,
        before: CategoryPlanningModel | null,
        after: CategoryPlanningModel | null
    ): Promise<void> {
        if (!before && !after) return;

        // Se for criação
        if (!before && after) {
            await this.updatePlanningImpact(workspaceId, after, 1);
        }
        // Se for exclusão
        else if (before && !after) {
            await this.updatePlanningImpact(workspaceId, before, -1);
        }
        // Se for atualização
        else if (before && after) {
            // Simplificando: remove o impacto antigo e adiciona o novo
            // Nota: No frontend, edições que preservam histórico criam novo registro e cortam o antigo via endMonth.
            // Aqui tratamos a mudança física do documento.
            await this.updatePlanningImpact(workspaceId, before, -1);
            await this.updatePlanningImpact(workspaceId, after, 1);
        }
    }

    private async updatePlanningImpact(workspaceId: string, planning: CategoryPlanningModel, multiplier: number): Promise<void> {
        const [startYear, startMonth] = planning.startMonth.split("-").map(Number);
        const [endYear, endMonth] = planning.endMonth.split("-").map(Number);

        const totalMonths = (endYear - startYear) * 12 + (endMonth - startMonth) + 1;

        for (let i = 0; i < totalMonths; i++) {
            const date = new Date(startYear, startMonth - 1 + i, 1, 12);
            const year = date.getFullYear();
            const month = date.getMonth() + 1;

            // Meta Mensal (Month)
            await this.financeRepository.updatePeriodSummary(
                workspaceId,
                year,
                month,
                planning.category,
                { generalPlannedDelta: planning.amount * multiplier }
            );

            // Meta Anual (Year)
            await this.financeRepository.updatePeriodSummary(
                workspaceId,
                year,
                undefined,
                planning.category,
                { generalPlannedDelta: planning.amount * multiplier }
            );
        }
    }

    async processInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        if (!before && !after) return;

        // 1. Processar Valor Planejado (Projeção) no dueDate
        if (before && before.status !== InstallmentStatus.removed) {
            await this.updateSummaryProjetado(workspaceId, before, -1);
        }
        if (after && after.status !== InstallmentStatus.removed) {
            await this.updateSummaryProjetado(workspaceId, after, 1);
        }

        // 2. Processar Valor Realizado (Fluxo de Caixa) no paidDate
        const isPaidStatus = (s: InstallmentStatus) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        if (before && isPaidStatus(before.status) && before.paidDate && (before.paidAmount ?? before.amount)) {
            await this.updateSummaryRealizado(workspaceId, before, -1);
        }
        if (after && isPaidStatus(after.status) && after.paidDate && (after.paidAmount ?? after.amount)) {
            await this.updateSummaryRealizado(workspaceId, after, 1);
        }
    }

    private async updateSummaryProjetado(workspaceId: string, inst: InstallmentModel, multiplier: number) {
        if (inst.type === OrderType.transfer || !inst.category) return;

        const year = inst.dueDate.getFullYear();
        const month = inst.dueDate.getMonth() + 1;
        const amount = inst.amount * multiplier;

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, inst.category, {
            specificPlannedDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, inst.category, {
            specificPlannedDelta: amount,
        });
    }

    private async updateSummaryRealizado(workspaceId: string, inst: InstallmentModel, multiplier: number) {
        if (inst.type === OrderType.transfer || !inst.category || !inst.paidDate) return;

        const year = inst.paidDate.getFullYear();
        const month = inst.paidDate.getMonth() + 1;
        const amount = (inst.paidAmount ?? inst.amount) * multiplier;

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, inst.category, {
            actualDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, inst.category, {
            actualDelta: amount,
        });
    }
}
