import { HttpsError } from "firebase-functions/v2/https";
import { IFinanceRepository } from "../repositories/finance.repository";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { IAIRepository } from "../../../../core/services/ai.service";
import { CategoryModel, CategoryType } from "../../../workspace/domain/models/category.model";
import { CategoryGroupService } from "../../../coaching/domain/services/category_group.service";
import { CategoryGroup } from "../../../coaching/domain/models/category_group.model";
import {
    ALLOCATION_TARGETS,
    PlanningAllocation,
    PlanningCategoryInput,
    buildAllocationTotals,
    buildPlanningCategoryContext,
    computeProjectedIncome,
    isValidPlanningAllocation,
    resolveBenchmarksBRL,
    validatePlanningAnalysis,
} from "./planning_analysis.utils";

// Se a análise do mês tem menos de 3 dias e force!=true, retornamos o cache
// sem chamar a IA.
const CACHE_MAX_AGE_DAYS = 3;

/**
 * Análise ideal 50-30-20: monta o contexto pré-computado (receita prevista,
 * categorias de despesa com planejado/realizado, totais por alocação e
 * benchmarks por grupo macro), chama a IA com schema estruturado, valida o
 * payload e persiste em workspaces/{wid}/planning_analysis/{yyyy-MM}.
 */
export class PlanningAnalysisService {
    private categoryGroupService: CategoryGroupService;

    constructor(
        private financeRepository: IFinanceRepository,
        private categoryRepository: ICategoryRepository,
        private aiRepository: IAIRepository
    ) {
        this.categoryGroupService = new CategoryGroupService(financeRepository, aiRepository);
    }

    async analyze(workspaceId: string, force = false): Promise<any> {
        const now = new Date();
        const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

        // 0. Cache do mês (menos de 3 dias e sem force)
        if (!force) {
            const cached = await this.financeRepository.getPlanningAnalysis(workspaceId, monthKey);
            const createdAt = this.toDate(cached?.createdAt);
            if (cached && createdAt) {
                const ageDays = (now.getTime() - createdAt.getTime()) / (24 * 60 * 60 * 1000);
                if (ageDays >= 0 && ageDays < CACHE_MAX_AGE_DAYS) {
                    console.log(`PlanningAnalysis: cache recente (${ageDays.toFixed(1)} dias) para ${workspaceId}/${monthKey}.`);
                    return this.formatResponse(monthKey, cached, createdAt);
                }
            }
        }

        // 1. Categorias ativas do workspace
        const categories = await this.categoryRepository.getCategories(workspaceId);
        const activeCategories = categories.filter(c => !c.isDeleted);
        const incomeCategoryIds = new Set(
            activeCategories.filter(c => c.type === CategoryType.income).map(c => c.id)
        );

        // 2. Summaries: mês corrente + 3 meses completos anteriores
        const currentSummary = await this.financeRepository.getPeriodSummary(
            workspaceId, now.getFullYear(), now.getMonth() + 1
        );

        const previousSummaries: (any | null)[] = [];
        for (let i = 1; i <= 3; i++) {
            const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
            previousSummaries.push(
                await this.financeRepository.getPeriodSummary(workspaceId, date.getFullYear(), date.getMonth() + 1)
            );
        }

        // 3. Receita prevista do mês (com fallback para a média realizada)
        const plannedIncome = this.sumByCategoryIds(
            currentSummary, incomeCategoryIds, "specificPlannedAmount"
        );
        const actualIncomePerFullMonth = previousSummaries.map(summary =>
            this.sumByCategoryIds(summary, incomeCategoryIds, "actualAmount")
        );

        const { projectedIncome, source } = computeProjectedIncome(plannedIncome, actualIncomePerFullMonth);
        if (projectedIncome === null) {
            throw new HttpsError(
                "failed-precondition",
                "Nenhuma receita prevista encontrada. Planeje as receitas do mês " +
                "(ou registre receitas realizadas) para liberar a análise ideal 50-30-20."
            );
        }

        // 4. Grupos macro (cache em coaching_meta; IA apenas para categorias novas)
        const groupByCategoryId = await this.categoryGroupService.resolveCategoryGroups(
            workspaceId, activeCategories
        );

        // 5. Contexto por categoria de despesa
        const expenseCategories = activeCategories.filter(c => c.type === CategoryType.expense);
        const monthsWithData = previousSummaries.filter(s => s !== null).length;

        const inputs: PlanningCategoryInput[] = expenseCategories.map(category => {
            const summaryEntry = currentSummary?.categories?.[category.id];
            const plannedAmount = Math.max(
                summaryEntry?.generalPlannedAmount || 0,
                summaryEntry?.specificPlannedAmount || 0
            );
            const actualAmount = summaryEntry?.actualAmount || 0;

            let sumActual = 0;
            for (const summary of previousSummaries) {
                sumActual += summary?.categories?.[category.id]?.actualAmount || 0;
            }

            return {
                categoryId: category.id,
                categoryName: category.name,
                allocation: this.resolveAllocation(category),
                group: groupByCategoryId[category.id] || CategoryGroup.other,
                plannedAmount,
                actualAmount,
                avgActual3Months: monthsWithData > 0 ? sumActual / monthsWithData : 0,
            };
        });

        const categoryContext = buildPlanningCategoryContext(inputs, projectedIncome);
        if (categoryContext.length === 0) {
            throw new HttpsError(
                "failed-precondition",
                "Nenhuma categoria de despesa encontrada. Crie categorias de despesa para liberar a análise."
            );
        }

        const context = {
            month: monthKey,
            projectedIncome,
            incomeSource: source,
            allocationTargets: ALLOCATION_TARGETS,
            allocations: buildAllocationTotals(categoryContext, projectedIncome),
            categories: categoryContext,
            benchmarks: resolveBenchmarksBRL(projectedIncome),
        };

        // 6. IA com responseSchema + validação server-side
        const raw = await this.aiRepository.analyze503020Ideal(workspaceId, context);

        const allocationById = new Map<string, PlanningAllocation>(
            categoryContext.map(entry => [entry.categoryId, entry.allocation])
        );
        const validated = validatePlanningAnalysis(raw, allocationById);

        if (validated.categories.length === 0) {
            throw new HttpsError(
                "internal",
                "A IA não retornou nenhuma análise de categoria válida. Tente novamente em instantes."
            );
        }

        // 7. Enriquecimento para a UI/histórico (nome e alocação atual são do servidor)
        const contextById = new Map(categoryContext.map(entry => [entry.categoryId, entry]));
        const enrichedCategories = validated.categories.map(category => {
            const entry = contextById.get(category.categoryId)!;
            return {
                ...category,
                categoryName: entry.categoryName,
                currentAllocation: entry.allocation,
                plannedAmount: entry.plannedAmount,
                actualAmount: entry.actualAmount,
            };
        });

        // 8. Persistência server-side (o cliente não escreve nesta coleção)
        const payload = {
            month: monthKey,
            summary: validated.summary,
            groups: validated.groups,
            categories: enrichedCategories,
            insights: validated.insights,
            projectedIncome,
            incomeSource: source,
            generatedBy: "server",
        };

        const generatedAt = new Date();
        await this.financeRepository.savePlanningAnalysis(workspaceId, monthKey, {
            ...payload,
            createdAt: generatedAt,
        });

        return this.formatResponse(monthKey, payload, generatedAt);
    }

    /** Formato de resposta estável para o cliente (createdAt em ISO-8601). */
    private formatResponse(id: string, data: any, createdAt: Date): any {
        return {
            id,
            month: data.month || id,
            summary: data.summary || "",
            groups: Array.isArray(data.groups) ? data.groups : [],
            categories: Array.isArray(data.categories) ? data.categories : [],
            insights: Array.isArray(data.insights) ? data.insights : [],
            projectedIncome: data.projectedIncome || 0,
            incomeSource: data.incomeSource || null,
            createdAt: createdAt.toISOString(),
        };
    }

    /** Soma um campo do summary apenas para os ids de categoria informados. */
    private sumByCategoryIds(
        summary: any | null,
        categoryIds: Set<string>,
        field: "specificPlannedAmount" | "actualAmount"
    ): number {
        if (!summary?.categories) return 0;
        let total = 0;
        for (const [id, data] of Object.entries<any>(summary.categories)) {
            if (!categoryIds.has(id)) continue;
            total += data?.[field] || 0;
        }
        return total;
    }

    /** Alocação atual da categoria; default comfort (mesmo default do app). */
    private resolveAllocation(category: CategoryModel): PlanningAllocation {
        return isValidPlanningAllocation(category.allocation) ? category.allocation : "comfort";
    }

    private toDate(value: any): Date | null {
        if (!value) return null;
        if (value instanceof Date) return isNaN(value.getTime()) ? null : value;
        if (typeof value.toDate === "function") return value.toDate();
        if (typeof value === "string") {
            const parsed = new Date(value);
            return isNaN(parsed.getTime()) ? null : parsed;
        }
        return null;
    }
}
