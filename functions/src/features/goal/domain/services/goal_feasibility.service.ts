import { IAIRepository, isTransientAiError } from "../../../../core/services/ai.service";
import { AI_CACHE_FUNCTIONS, IAiCacheService } from "../../../../core/services/ai_cache.service";
import { QuotaGuard } from "../../../../core/services/quota.service";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { GoalFeasibilityPayload, MonthlyBreakdownEntry } from "../models/goal.model";

export class GoalFeasibilityService {
    constructor(
        private financeRepository: IFinanceRepository,
        private categoryRepository: ICategoryRepository,
        private aiRepository: IAIRepository,
        private aiCacheService: IAiCacheService,
    ) { }

    /**
     * @param quota cota diária do chamador. Só é consumida em cache-miss,
     *              imediatamente antes da chamada à IA.
     */
    async analyze(
        workspaceId: string,
        goalPayload: GoalFeasibilityPayload,
        quota?: QuotaGuard,
    ): Promise<{ status: string; reason: string; suggestion: string }> {
        const now = new Date();
        const monthlyBreakdown: MonthlyBreakdownEntry[] = [];

        // Buscar os period_summaries dos últimos 3 meses (3 leituras pontuais)
        const categories = await this.categoryRepository.getCategories(workspaceId);
        const categoryMap = new Map(categories.map(c => [c.id, c]));

        for (let i = 1; i <= 3; i++) {
            const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const year = date.getFullYear();
            const month = date.getMonth() + 1;
            const monthStr = `${year}-${String(month).padStart(2, "0")}`;

            const summary = await this.financeRepository.getPeriodSummary(workspaceId, year, month);
            if (!summary) continue;

            const categoriesData = summary.categories as Record<string, { actualAmount?: number }> ?? {};

            let totalIncome = 0;
            let totalExpense = 0;
            const categoryBreakdown: { name: string; type: string; allocation: string | undefined, amount: number }[] = [];

            for (const [categoryId, data] of Object.entries(categoriesData)) {
                const amount = data.actualAmount ?? 0;
                if (amount === 0) continue;

                const category = categoryMap.get(categoryId);
                if (!category) continue;

                const categoryType = category.type as string;

                if (categoryType === "income") {
                    totalIncome += amount;
                }
                else if (categoryType === "expense") {
                    totalExpense += amount;
                }

                categoryBreakdown.push({
                    name: category.name,
                    type: categoryType,
                    allocation: category.allocation,
                    amount: Math.abs(amount),
                });
            }

            monthlyBreakdown.push({
                month: monthStr,
                totalIncome,
                totalExpense,
                categories: categoryBreakdown,
            });
        }

        // Cache por hash da ENTRADA (F5.6): mexer no prazo e voltar ao valor
        // original refaz exatamente a mesma pergunta. Cache-hit não gasta cota.
        const cacheInput = { goalPayload, monthlyBreakdown };
        const cached = await this.aiCacheService.get<{ status: string; reason: string; suggestion: string }>(
            workspaceId, AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, cacheInput
        );
        if (cached) return cached;

        // A cota é consumida AQUI, imediatamente antes da chamada real.
        await quota?.consume();

        let result: any;
        try {
            result = await this.aiRepository.analyzeGoalFeasibility(
                workspaceId,
                goalPayload,
                monthlyBreakdown,
            );
        }
        catch (error) {
            if (isTransientAiError(error)) {
                await quota?.refund();
            }
            throw error;
        }

        const analysis = {
            status: result.status ?? "challenging",
            reason: result.reason ?? "",
            suggestion: result.suggestion ?? "",
        };

        await this.aiCacheService.set(
            workspaceId, AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, cacheInput, analysis
        );

        return analysis;
    }
}
