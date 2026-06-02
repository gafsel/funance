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

            // Meta Semanal (Week)
            // Para simplicidade, vamos iterar sobre as semanas que iniciam dentro deste mês
            const firstDayOfMonth = new Date(year, month - 1, 1);
            const lastDayOfMonth = new Date(year, month, 0);
            
            // Ajuste para pegar as semanas de domingo a sábado
            const currentDay = new Date(firstDayOfMonth);
            while (currentDay <= lastDayOfMonth) {
                if (currentDay.getDay() === 0 || currentDay.getDate() === 1) {
                    const week = this.getWeekNumber(currentDay);
                    const weekYear = this.getWeekYear(currentDay);
                    
                    // Calculamos a proporção do planejamento para a semana (aproximadamente planning / 4.33 ou planning / dias no mes * 7)
                    const daysInMonth = lastDayOfMonth.getDate();
                    const weeklyProportion = (planning.amount / daysInMonth) * 7;

                    await this.financeRepository.updatePeriodSummary(
                        workspaceId,
                        weekYear,
                        undefined,
                        planning.category,
                        { generalPlannedDelta: weeklyProportion * multiplier },
                        week
                    );
                }
                currentDay.setDate(currentDay.getDate() + 1);
            }
        }
    }

    private getWeekNumber(d: Date): number {
        const date = new Date(d.getTime());
        date.setHours(0, 0, 0, 0);
        // Ajusta para o domingo mais próximo (início da semana)
        date.setDate(date.getDate() - date.getDay());
        const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
        const days = Math.floor((date.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        return Math.floor(days / 7) + 1;
    }

    private getWeekYear(d: Date): number {
        const date = new Date(d.getTime());
        date.setHours(0, 0, 0, 0);
        // Ajusta para o domingo mais próximo
        date.setDate(date.getDate() - date.getDay());
        return date.getFullYear();
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

        // Week
        const week = this.getWeekNumber(inst.dueDate);
        const weekYear = this.getWeekYear(inst.dueDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, inst.category, {
            specificPlannedDelta: amount,
        }, week);
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

        // Week
        const week = this.getWeekNumber(inst.paidDate);
        const weekYear = this.getWeekYear(inst.paidDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, inst.category, {
            actualDelta: amount,
        }, week);
    }
}
