import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { IGoalRepository } from "../../../goal/domain/repositories/goal.repository";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { IAIRepository } from "../../../../core/services/ai.service";
import { InstallmentStatus } from "../../../finance/domain/models/finance.models";

export class CoachingService {
    constructor(
        private financeRepository: IFinanceRepository,
        private goalRepository: IGoalRepository,
        private categoryRepository: ICategoryRepository,
        private aiRepository: IAIRepository
    ) {
    }

    async generateCoaching(workspaceId: string): Promise<any> {
        const now = new Date();

        // 1. Mapeamento de categorias para nomes
        const categories = await this.categoryRepository.getCategories(workspaceId);
        const categoryMap = new Map(categories.map(c => [c.id, c.name]));

        // 2. Levantamento de dados sobre gastos dos últimos dias (2 semanas)
        const recentSpending = await this.getWeeklySpending(workspaceId, now, categoryMap);

        // 3. Forecasts (próximos 30 dias)
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
        const forecasts = await this.financeRepository.getInstallments(workspaceId, {
            startDate: now,
            endDate: endOfMonth,
            status: [InstallmentStatus.pending]
        });

        // 4. Metas traçadas
        const goals = await this.goalRepository.getGoals(workspaceId);

        // Formatação dos dados para a LLM
        const coachingData = {
            recentSpending,
            forecasts: forecasts.map(f => ({
                description: f.description,
                amount: f.amount,
                dueDate: f.dueDate.toISOString().split("T")[0],
                type: f.type
            })),
            goals: goals.map(g => ({
                name: g.name,
                targetAmount: g.targetAmount,
                currentAmount: g.currentAmount,
                deadline: g.deadline?.toISOString().split("T")[0]
            }))
        };

        const coachingResponse = await this.aiRepository.generateCoachingSlides(
            workspaceId,
            coachingData.recentSpending,
            coachingData.forecasts,
            coachingData.goals
        );

        return {
            id: "", // Será gerado no app ou no save
            message: coachingResponse.message || "Insights do seu Coach Financeiro",
            date: new Date().toISOString(),
            type: coachingResponse.type || "insight",
            slides: coachingResponse.slides
        };
    }

    private async getWeeklySpending(workspaceId: string, now: Date, categoryMap: Map<string, string>): Promise<any[]> {
        const year = now.getFullYear();
        const currentWeek = this.getWeekNumber(now);

        const weeks = [currentWeek - 1, currentWeek];
        const summaries: any[] = [];

        for (const week of weeks) {
            const summary = await this.financeRepository.getPeriodSummary(workspaceId, year, undefined, week);
            if (summary) {
                const categoriesList = Object.entries(summary.categories || {}).map(([id, data]: [string, any]) => ({
                    categoryName: categoryMap.get(id) || "Outros",
                    amount: data.actualAmount || 0,
                }));

                summaries.push({
                    period: `Semana ${week}`,
                    categories: categoriesList
                });
            }
        }

        return summaries;
    }

    private getWeekNumber(d: Date): number {
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
        return weekNo;
    }
}
