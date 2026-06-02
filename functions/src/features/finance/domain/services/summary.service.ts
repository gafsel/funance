import { InstallmentModel, InstallmentStatus, OrderType, CategoryPlanningModel, PeriodSummaryUpdateModel } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";
import { DEFAULT_FINANCE_CONFIG } from "../../../../core/config/finance.config";

export class SummaryService {
    constructor(private financeRepository: IFinanceRepository) {}

    async processCategoryPlanningChange(
        workspaceId: string,
        before: CategoryPlanningModel | null,
        after: CategoryPlanningModel | null
    ): Promise<void> {
        if (!before && !after) return;

        // Se houver uma mudança no planejamento, garantimos a previsibilidade configurada
        const predictabilityMonths = DEFAULT_FINANCE_CONFIG.categoryPlanning.predictabilityMonths;
        if (before) {
            await this.updatePlanningImpactForMonth(workspaceId, before, -1, new Date(), predictabilityMonths);
        }
        if (after) {
            await this.updatePlanningImpactForMonth(workspaceId, after, 1, new Date(), predictabilityMonths);
        }
    }

    private async updatePlanningImpactForMonth(
        workspaceId: string, 
        planning: CategoryPlanningModel, 
        multiplier: number,
        baseDate: Date,
        monthsAhead = 1
    ): Promise<void> {
        const impacts = this.calculatePlanningImpacts(planning, multiplier, baseDate, monthsAhead);
        
        for (const impact of impacts) {
            await this.financeRepository.updatePeriodSummary(
                workspaceId,
                impact.year,
                impact.month,
                impact.category,
                { generalPlannedDelta: impact.generalPlannedDelta },
                impact.week
            );
        }
    }

    private calculatePlanningImpacts(
        planning: CategoryPlanningModel,
        multiplier: number,
        baseDate: Date,
        monthsAhead = 1
    ): PeriodSummaryUpdateModel[] {
        const impacts: PeriodSummaryUpdateModel[] = [];
        const [startYear, startMonth] = planning.startMonth.split("-").map(Number);
        const [endYear, endMonth] = planning.endMonth.split("-").map(Number);
        const startTotalMonths = startYear * 12 + startMonth;
        const endTotalMonths = endYear * 12 + endMonth;

        for (let i = 0; i < monthsAhead; i++) {
            const date = new Date(baseDate.getFullYear(), baseDate.getMonth() + i, 1);
            const year = date.getFullYear();
            const month = date.getMonth() + 1;
            const currentTotalMonths = year * 12 + month;

            // Verifica se o mês base está dentro do intervalo do planejamento
            if (currentTotalMonths < startTotalMonths || currentTotalMonths > endTotalMonths) {
                continue;
            }

            // Meta Mensal (Month)
            impacts.push({
                year,
                month,
                category: planning.category,
                generalPlannedDelta: planning.amount * multiplier,
            });

            // Se for Janeiro, aproveita e gera o total do ano (Previsibilidade anual)
            if (month === 1) {
                impacts.push({
                    year,
                    category: planning.category,
                    generalPlannedDelta: planning.amount * 12 * multiplier,
                });
            }

            // Meta Semanal (Week)
            const lastDayOfMonth = new Date(year, month, 0);
            const currentDay = new Date(year, month - 1, 1);
            
            while (currentDay <= lastDayOfMonth) {
                if (currentDay.getDay() === 0 || currentDay.getDate() === 1) {
                    const week = this.getWeekNumber(currentDay);
                    const weekYear = this.getWeekYear(currentDay);
                    
                    const daysInMonth = lastDayOfMonth.getDate();
                    const weeklyProportion = (planning.amount / daysInMonth) * 7;

                    impacts.push({
                        year: weekYear,
                        week,
                        category: planning.category,
                        generalPlannedDelta: weeklyProportion * multiplier,
                    });
                }
                currentDay.setDate(currentDay.getDate() + 1);
            }
        }
        return impacts;
    }

    async generateCategoryPlanningSummaries(): Promise<void> {
        const now = new Date();
        const nowStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
        const GLOBAL_LIMIT = 500;
        const CHUNK_SIZE = 50;

        console.log("Buscando planejamentos de categoria para processar...");
        const planningsToProcess = await this.financeRepository.getCategoryPlanningsByLastSummaryMonthGroup(nowStr, GLOBAL_LIMIT);

        if (planningsToProcess.length === 0) {
            console.log("Nenhum planejamento de categoria pendente de processamento.");
            return;
        }

        console.log(`Processando ${planningsToProcess.length} planejamentos em chunks de ${CHUNK_SIZE}...`);

        for (let i = 0; i < planningsToProcess.length; i += CHUNK_SIZE) {
            const chunk = planningsToProcess.slice(i, i + CHUNK_SIZE);
            console.log(`Processando chunk de ${chunk.length} planejamentos...`);

            const predictabilityMonths = DEFAULT_FINANCE_CONFIG.categoryPlanning.predictabilityMonths;
            await this.financeRepository.processCategoryPlanningSummariesChunk(chunk, nowStr, (_, planning) => {
                return this.calculatePlanningImpacts(planning, 1, new Date(), predictabilityMonths);
            });
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
