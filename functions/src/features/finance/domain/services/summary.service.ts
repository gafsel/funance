import { InstallmentModel, InstallmentStatus, OrderType, CategoryPlanningModel, PeriodSummaryUpdateModel, AccountType } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";
import { DEFAULT_FINANCE_CONFIG } from "../../../../core/config/finance.config";
import {
    CategoryModel,
    VIRTUAL_DEBT_EXPENSE_CATEGORY,
    VIRTUAL_DEBT_INCOME_CATEGORY,
    VIRTUAL_INVESTMENT_EXPENSE_CATEGORY,
    VIRTUAL_INVESTMENT_INCOME_CATEGORY
} from "../../../workspace/domain/models/category.model";
import { getWeekNumber, getWeekYear } from "../../../../core/utils/week.utils";

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
                    const week = getWeekNumber(currentDay);
                    const weekYear = getWeekYear(currentDay);
                    
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
        let category = inst.category;
        const amount = inst.amount * multiplier;

        if (inst.type === OrderType.transfer) {
            const virtualData = await this.getVirtualCategoryImpact(workspaceId, inst);
            if (!virtualData) return;
            category = virtualData.category;
            // Se for destino (gasto), valor positivo (delta aumenta gasto). 
            // Se for origem (receita), valor negativo (delta aumenta receita - mas aqui o summary guarda valores absolutos de gasto?)
            // No Flutter: destino = gasto, origem = receita.
            // O PeriodSummary do projeto parece somar tudo na categoria.
            // Se a categoria for de gasto, somar aumenta o gasto.
            // Se a regra é "origem => receita", e estamos numa categoria "virtual", 
            // precisamos decidir como o PeriodSummary armazena isso.
            // Normalmente PeriodSummaryCategoryModel tem actualAmount.
        }

        if (!category) return;

        const year = inst.dueDate.getFullYear();
        const month = inst.dueDate.getMonth() + 1;

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, category, {
            specificPlannedDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, category, {
            specificPlannedDelta: amount,
        });

        // Week
        const week = getWeekNumber(inst.dueDate);
        const weekYear = getWeekYear(inst.dueDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, category, {
            specificPlannedDelta: amount,
        }, week);
    }

    private async updateSummaryRealizado(workspaceId: string, inst: InstallmentModel, multiplier: number) {
        if (!inst.paidDate) return;

        let category = inst.category;
        const amount = (inst.paidAmount ?? inst.amount) * multiplier;

        if (inst.type === OrderType.transfer) {
            const virtualData = await this.getVirtualCategoryImpact(workspaceId, inst);
            if (!virtualData) return;
            category = virtualData.category;
        }

        if (!category) return;

        const year = inst.paidDate.getFullYear();
        const month = inst.paidDate.getMonth() + 1;

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, category, {
            actualDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, category, {
            actualDelta: amount,
        });

        // Week
        const week = getWeekNumber(inst.paidDate);
        const weekYear = getWeekYear(inst.paidDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, category, {
            actualDelta: amount,
        }, week);
    }

    private async getVirtualCategoryImpact(workspaceId: string, inst: InstallmentModel): Promise<{ category: CategoryModel, type: "income" | "expense" } | null> {
        const accounts = inst.accounts || {};
        const accountIds = Object.keys(accounts);
        if (accountIds.length === 0) return null;

        const sourceId = inst.type === OrderType.transfer
            ? accountIds.find(id => accounts[id] === "debt")
            : null;
        const targetId = inst.type === OrderType.transfer
            ? accountIds.find(id => accounts[id] === "credit")
            : null;

        if (!sourceId && !targetId) return null;

        const sourceAccount = sourceId ? await this.financeRepository.getAccountById(workspaceId, sourceId) : null;
        const targetAccount = targetId ? await this.financeRepository.getAccountById(workspaceId, targetId) : null;

        if (targetAccount && (targetAccount.runtimeType === AccountType.debt || targetAccount.runtimeType === AccountType.investment)) {
            return {
                category: this.getVirtualCategoryForAccountType(targetAccount.runtimeType, "expense"),
                type: "expense"
            };
        }
        else if (sourceAccount && (sourceAccount.runtimeType === AccountType.debt || sourceAccount.runtimeType === AccountType.investment)) {
            return {
                category: this.getVirtualCategoryForAccountType(sourceAccount.runtimeType, "income"),
                type: "income"
            };
        }

        return null;
    }

    private getVirtualCategoryForAccountType(type: AccountType, categoryType: "income" | "expense"): CategoryModel {
        if (type === AccountType.debt) {
            return categoryType === "expense" ? VIRTUAL_DEBT_EXPENSE_CATEGORY : VIRTUAL_DEBT_INCOME_CATEGORY;
        }
        return categoryType === "expense" ? VIRTUAL_INVESTMENT_EXPENSE_CATEGORY : VIRTUAL_INVESTMENT_INCOME_CATEGORY;
    }
}
