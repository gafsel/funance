import { IAIRepository } from "../../../../core/services/ai.service";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { GoalFeasibilityPayload, MonthlyBreakdownEntry } from "../models/goal.model";

export class GoalFeasibilityService {
    constructor(
        private financeRepository: IFinanceRepository,
        private categoryRepository: ICategoryRepository,
        private aiRepository: IAIRepository,
    ) { }

    async analyze(
        workspaceId: string,
        goalPayload: GoalFeasibilityPayload,
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

        const result = await this.aiRepository.analyzeGoalFeasibility(
            workspaceId,
            goalPayload,
            monthlyBreakdown,
        );

        return {
            status: result.status ?? "challenging",
            reason: result.reason ?? "",
            suggestion: result.suggestion ?? "",
        };
    }
}
