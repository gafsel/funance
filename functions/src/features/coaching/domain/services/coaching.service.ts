import { HttpsError } from "firebase-functions/v2/https";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { IGoalRepository } from "../../../goal/domain/repositories/goal.repository";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { IWorkspaceRepository } from "../../../workspace/domain/repositories/workspace.repository";
import { IAIRepository, isTransientAiError } from "../../../../core/services/ai.service";
import { QuotaGuard } from "../../../../core/services/quota.service";
import { InstallmentStatus, InstallmentType, OrderType } from "../../../finance/domain/models/finance.models";
import {
    CategoryModel,
    CategoryType,
    VIRTUAL_DEBT_EXPENSE_CATEGORY,
    VIRTUAL_INVESTMENT_EXPENSE_CATEGORY,
} from "../../../workspace/domain/models/category.model";
import { getWeekRefBefore } from "../../../../core/utils/week.utils";
import { CategoryGroupService } from "./category_group.service";
import { CategoryGroup } from "../models/category_group.model";
import {
    CategoryProfileInput,
    buildCategoryProfile,
    buildLifestyleDiagnosis,
    buildSavingsOpportunities,
    computeMonthlyIncome,
} from "./coaching_context.utils";

// Rotas internas válidas para actionPath — mesma allowlist do prompt em ai.config.ts
const ALLOWED_ACTION_PATHS = [
    "/planning",
    "/planning-50-30-20",
    "/workspace/categories",
    "/workspace/accounts",
    "/transactions/form",
    "/",
];

const ALLOWED_ANIMATION_TYPES = ["zoom", "slide", "bounce", "fade", "pulse"];
const ALLOWED_COACHING_TYPES = ["insight", "warning", "tip"];
const HEX_COLOR_REGEX = /^#[0-9a-fA-F]{6}$/;

const DEFAULT_SLIDE_COLOR = "#4A8C9C";
const DEFAULT_SLIDE_ICON = "insights";
const DEFAULT_SLIDE_TITLE = "Insight Financeiro";

// Se já existe um insight com menos de 5 dias, retornamos ele sem chamar a IA
// (a UI considera deprecated a partir de 7 dias; 5 dias dá margem).
// Reabrir um insight já existente NÃO consome cota.
const CACHE_MAX_AGE_DAYS = 5;

// Limite de categorias enviadas no categoryProfile (mantém o custo do prompt razoável)
const MAX_PROFILE_CATEGORIES = 20;

export class CoachingService {
    private categoryGroupService: CategoryGroupService;

    constructor(
        private financeRepository: IFinanceRepository,
        private goalRepository: IGoalRepository,
        private categoryRepository: ICategoryRepository,
        private workspaceRepository: IWorkspaceRepository,
        private aiRepository: IAIRepository
    ) {
        this.categoryGroupService = new CategoryGroupService(financeRepository, aiRepository);
    }

    /**
     * @param quota cota diária do chamador. Só é consumida em cache-miss,
     *              imediatamente antes da chamada à IA. O cron de coaching
     *              proativo chama sem cota (é uso server-side, não do usuário).
     */
    async generateCoaching(workspaceId: string, quota?: QuotaGuard): Promise<any> {
        const now = new Date();

        // 0. Contexto anterior (também usado como cache/rate-limit)
        const previousAnalyses = await this.financeRepository.getLastCoachingAnalyses(workspaceId, 3);

        const latest = previousAnalyses[0];
        const latestDate = this.toDate(latest?.date);
        if (latest && latestDate) {
            const ageDays = (now.getTime() - latestDate.getTime()) / (24 * 60 * 60 * 1000);
            if (ageDays >= 0 && ageDays < CACHE_MAX_AGE_DAYS) {
                console.log(`Coaching: insight recente (${ageDays.toFixed(1)} dias) encontrado para ${workspaceId}. Retornando cache.`);
                return this.formatResponse(latest.id || "", latest, latestDate);
            }
        }

        // 1. Tipo de workspace
        const workspace = await this.workspaceRepository.getWorkspaceById(workspaceId);
        const workspaceType = workspace?.type || "personal";

        // 2. Mapeamento de categorias
        const categories = await this.categoryRepository.getCategories(workspaceId);
        const categoryById = new Map<string, CategoryModel>(categories.map(c => [c.id, c]));

        // 3. Gastos semanais (2 últimas semanas completas + semana parcial)
        const weeklyExpenses = await this.getWeeklyExpenses(workspaceId, now, categoryById);

        // 4. Summaries mensais (mês atual + 6 meses anteriores) — buscados uma única vez
        //    e compartilhados entre o contexto mensal existente e o contexto avançado v2.
        const currentSummary = await this.financeRepository.getPeriodSummary(workspaceId, now.getFullYear(), now.getMonth() + 1);
        const previousSummaries = await this.getPreviousMonthlySummaries(workspaceId, now, 6);

        // 4.1. Contexto mensal pré-calculado (totais, variações e planejado vs realizado)
        const monthlyContext = await this.buildMonthlyContext(workspaceId, now, categoryById, currentSummary, previousSummaries.slice(0, 3));

        // 4.2. Contexto avançado v2: renda mensal, perfil por categoria de despesa,
        //      diagnóstico de estilo de vida por grupo macro e oportunidades de economia.
        const advancedContext = await this.buildAdvancedContext(
            workspaceId,
            now,
            categories,
            categoryById,
            workspace,
            previousSummaries,
            monthlyContext.currentMonthTotals.totalIncome
        );

        // 5. Forecasts (próximos 30 dias)
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
        const installments = await this.financeRepository.getInstallments(workspaceId, {
            startDate: now,
            endDate: endOfMonth,
            status: [InstallmentStatus.pending]
        });

        // 5.1. Enriquecer installments com tipo de conta
        const accountTypesCache = new Map<string, string>();
        const forecasts = await Promise.all(installments.map(async (f) => {
            const accountId = f.accountIds?.[0];
            let accountType = "unknown";

            if (accountId) {
                if (accountTypesCache.has(accountId)) {
                    accountType = accountTypesCache.get(accountId)!;
                }
                else {
                    const account = await this.financeRepository.getAccountById(workspaceId, accountId);
                    if (account) {
                        accountType = account.runtimeType;
                        accountTypesCache.set(accountId, accountType);
                    }
                }
            }

            return {
                description: f.description,
                amount: f.amount,
                dueDate: f.dueDate.toISOString().split("T")[0],
                type: f.type,
                accountType
            };
        }));

        // 6. Metas com progresso pré-calculado
        const goals = await this.goalRepository.getGoals(workspaceId);
        const goalsData = goals.map(g => this.buildGoalProgress(g, now));

        // 7. Contexto de interações anteriores
        const previousContext = previousAnalyses.map(a => ({
            date: this.toDate(a.date)?.toISOString() || "",
            summary: a.summary || a.message
        }));

        const financialData = {
            weeklyExpenses,
            currentMonthTotals: monthlyContext.currentMonthTotals,
            categoryMonthlyAnalysis: monthlyContext.categoryMonthlyAnalysis,
            planVsActual: monthlyContext.planVsActual,
            ...advancedContext,
        };

        // A cota é consumida AQUI: é o único ponto em que o Gemini é chamado
        // de fato. Se a falha for de infraestrutura, estorna.
        await quota?.consume();

        let coachingResponse: any;
        try {
            coachingResponse = await this.aiRepository.generateCoachingSlides(
                workspaceId,
                workspaceType,
                financialData,
                forecasts,
                goalsData,
                previousContext
            );
        }
        catch (error) {
            if (isTransientAiError(error)) {
                await quota?.refund();
            }
            throw error;
        }

        // 8. Validação server-side do payload gerado pela IA
        const validated = this.validateCoachingResponse(coachingResponse);

        // 9. Persistência server-side (o cliente não deve mais gravar este documento)
        const generatedAt = new Date();
        const docId = await this.financeRepository.saveCoachingAnalysis(workspaceId, {
            message: validated.message,
            summary: validated.summary,
            type: validated.type,
            slides: validated.slides,
            date: generatedAt,
            generatedBy: "server",
        });

        return this.formatResponse(docId, validated, generatedAt);
    }

    /**
     * Formato de resposta retrocompatível com o parse do cliente
     * (lib/features/coaching/data/repositories/coaching_repository_impl.dart).
     */
    private formatResponse(id: string, data: any, date: Date): any {
        return {
            id,
            message: data.message || "Insights do seu Coach Financeiro",
            summary: data.summary || data.message || "",
            date: date.toISOString(),
            type: ALLOWED_COACHING_TYPES.includes(data.type) ? data.type : "insight",
            slides: Array.isArray(data.slides) ? data.slides : [],
        };
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

    private validateCoachingResponse(response: any): { message: string; summary: string; type: string; slides: any[] } {
        const slidesRaw = Array.isArray(response?.slides) ? response.slides : [];
        const slides: any[] = [];

        for (const raw of slidesRaw) {
            if (!raw || typeof raw !== "object") continue;

            // Slide sem mensagem não tem conteúdo útil — descarta
            if (typeof raw.message !== "string" || raw.message.trim().length === 0) continue;

            const slide: any = {
                title: (typeof raw.title === "string" && raw.title.trim().length > 0) ? raw.title : DEFAULT_SLIDE_TITLE,
                message: raw.message,
                icon: (typeof raw.icon === "string" && raw.icon.trim().length > 0) ? raw.icon : DEFAULT_SLIDE_ICON,
                color: (typeof raw.color === "string" && HEX_COLOR_REGEX.test(raw.color)) ? raw.color : DEFAULT_SLIDE_COLOR,
                icons: Array.isArray(raw.icons) ? raw.icons.filter((i: any) => typeof i === "string") : [],
                animationType: ALLOWED_ANIMATION_TYPES.includes(raw.animationType) ? raw.animationType : "fade",
            };

            if (typeof raw.secondaryColor === "string" && HEX_COLOR_REGEX.test(raw.secondaryColor)) {
                slide.secondaryColor = raw.secondaryColor;
            }

            // actionPath só é mantido se estiver na allowlist de rotas do app
            if (typeof raw.actionPath === "string" && ALLOWED_ACTION_PATHS.includes(raw.actionPath)) {
                slide.actionPath = raw.actionPath;
                if (typeof raw.actionLabel === "string" && raw.actionLabel.trim().length > 0) {
                    slide.actionLabel = raw.actionLabel;
                }
            }

            slides.push(slide);
        }

        if (slides.length === 0) {
            throw new HttpsError(
                "internal",
                "A IA não retornou nenhum insight válido. Tente gerar novamente em instantes."
            );
        }

        return {
            message: typeof response?.message === "string" && response.message.trim().length > 0
                ? response.message
                : "Insights do seu Coach Financeiro",
            summary: typeof response?.summary === "string" ? response.summary : (response?.message || ""),
            type: ALLOWED_COACHING_TYPES.includes(response?.type) ? response.type : "insight",
            slides,
        };
    }

    /**
     * Gastos (apenas categorias de despesa) das 2 últimas semanas COMPLETAS
     * mais a semana atual, identificada como parcial.
     * A numeração de semana segue exatamente a convenção usada na gravação
     * dos period_summaries (ver core/utils/week.utils.ts), o que também
     * trata corretamente a virada de ano.
     */
    private async getWeeklyExpenses(workspaceId: string, now: Date, categoryById: Map<string, CategoryModel>): Promise<any[]> {
        // 2 semanas completas atrás, 1 semana completa atrás, semana atual (parcial)
        const windows = [
            { ref: getWeekRefBefore(now, 2), partial: false },
            { ref: getWeekRefBefore(now, 1), partial: false },
            { ref: getWeekRefBefore(now, 0), partial: true },
        ];

        const summaries: any[] = [];

        for (const { ref, partial } of windows) {
            const summary = await this.financeRepository.getPeriodSummary(workspaceId, ref.year, undefined, ref.week);
            if (!summary) continue;

            const categoriesList = Object.entries(summary.categories || {})
                .filter(([id]) => categoryById.get(id)?.type === CategoryType.expense)
                .map(([id, data]: [string, any]) => ({
                    categoryName: categoryById.get(id)?.name || "Outros",
                    amount: this.round2(data.actualAmount || 0),
                }))
                .filter(c => c.amount !== 0);

            summaries.push({
                period: `Semana ${ref.week} de ${ref.year}${partial ? " (parcial, em andamento)" : ""}`,
                isPartialWeek: partial,
                categories: categoriesList
            });
        }

        return summaries;
    }

    /**
     * Summaries mensais dos `count` meses COMPLETOS anteriores ao mês atual,
     * do mais recente para o mais antigo (índice 0 = mês passado).
     */
    private async getPreviousMonthlySummaries(workspaceId: string, now: Date, count: number): Promise<(any | null)[]> {
        const summaries: (any | null)[] = [];
        for (let i = 1; i <= count; i++) {
            const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const summary = await this.financeRepository.getPeriodSummary(workspaceId, date.getFullYear(), date.getMonth() + 1);
            summaries.push(summary);
        }
        return summaries;
    }

    /**
     * Contexto mensal pré-calculado:
     * - totais de receitas e despesas do mês atual;
     * - variação % por categoria de despesa (mês atual vs média dos 3 meses anteriores);
     * - planejado vs realizado por categoria (category_plannings ativos no mês).
     */
    private async buildMonthlyContext(
        workspaceId: string,
        now: Date,
        categoryById: Map<string, CategoryModel>,
        currentSummary: any | null,
        previous3MonthsSummaries: (any | null)[]
    ): Promise<{
        currentMonthTotals: any;
        categoryMonthlyAnalysis: any[];
        planVsActual: any[];
    }> {
        const currentYear = now.getFullYear();
        const currentMonth = now.getMonth() + 1;
        const currentMonthStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}`;

        const currentCategories: Record<string, any> = currentSummary?.categories || {};

        // Média dos 3 meses anteriores por categoria
        const previousTotals = new Map<string, { total: number; monthsWithData: number }>();
        let previousMonthsFound = 0;

        for (const summary of previous3MonthsSummaries) {
            if (!summary) continue;
            previousMonthsFound++;

            for (const [id, data] of Object.entries<any>(summary.categories || {})) {
                const amount = data?.actualAmount || 0;
                if (amount === 0) continue;
                const entry = previousTotals.get(id) || { total: 0, monthsWithData: 0 };
                entry.total += amount;
                entry.monthsWithData++;
                previousTotals.set(id, entry);
            }
        }

        // Totais do mês atual e análise por categoria de despesa
        let totalIncome = 0;
        let totalExpense = 0;
        const categoryMonthlyAnalysis: any[] = [];

        const allCategoryIds = new Set<string>([...Object.keys(currentCategories), ...previousTotals.keys()]);

        for (const id of allCategoryIds) {
            const category = categoryById.get(id);
            if (!category) continue;

            const currentAmount = currentCategories[id]?.actualAmount || 0;

            if (category.type === CategoryType.income) {
                totalIncome += currentAmount;
                continue;
            }

            totalExpense += currentAmount;

            const previous = previousTotals.get(id);
            const averagePrevious3Months = (previous && previousMonthsFound > 0)
                ? previous.total / previousMonthsFound
                : 0;

            if (currentAmount === 0 && averagePrevious3Months === 0) continue;

            categoryMonthlyAnalysis.push({
                categoryName: category.name,
                currentMonthAmount: this.round2(currentAmount),
                averagePrevious3Months: this.round2(averagePrevious3Months),
                variationPercent: averagePrevious3Months > 0
                    ? this.round2(((currentAmount - averagePrevious3Months) / averagePrevious3Months) * 100)
                    : null,
            });
        }

        // Planejado vs realizado (category_plannings ativos no mês atual)
        const plannings = await this.financeRepository.getCategoryPlannings(workspaceId);
        const planVsActual = plannings
            .filter(p => p.startMonth <= currentMonthStr && p.endMonth >= currentMonthStr)
            .map(p => {
                const actual = currentCategories[p.category?.id]?.actualAmount || 0;
                return {
                    categoryName: p.category?.name || "Outros",
                    plannedAmount: this.round2(p.amount),
                    actualAmount: this.round2(actual),
                    usagePercent: p.amount > 0 ? this.round2((actual / p.amount) * 100) : null,
                };
            });

        return {
            currentMonthTotals: {
                month: currentMonthStr,
                totalIncome: this.round2(totalIncome),
                totalExpense: this.round2(totalExpense),
                balance: this.round2(totalIncome - totalExpense),
            },
            categoryMonthlyAnalysis,
            planVsActual,
        };
    }

    /**
     * Contexto avançado v2 — tudo pré-computado no servidor (apenas agregados,
     * nenhuma transação individual vai para o prompt):
     * - monthlyIncome: renda média mensal (3 meses completos, com fallback para o mês atual);
     * - categoryProfile: perfil por categoria de despesa dos últimos 3 meses completos;
     * - lifestyle: diagnóstico por grupo macro vs faixas de referência de % da renda;
     * - savingsOpportunities: top categorias por score de facilidade/impacto de economia;
     * - familyContext: tipo do workspace e número de membros.
     */
    private async buildAdvancedContext(
        workspaceId: string,
        now: Date,
        categories: CategoryModel[],
        categoryById: Map<string, CategoryModel>,
        workspace: { type?: string; members?: string[] } | null,
        previous6MonthsSummaries: (any | null)[],
        currentMonthIncome: number
    ): Promise<any> {
        const window1 = previous6MonthsSummaries.slice(0, 3); // 3 últimos meses completos
        const window2 = previous6MonthsSummaries.slice(3, 6); // os 3 meses anteriores a eles (base do trend)

        // Renda média mensal: receitas (categorias income) dos meses completos da janela
        const incomePerFullMonth = window1.map(summary => {
            let total = 0;
            for (const [id, data] of Object.entries<any>(summary?.categories || {})) {
                if (categoryById.get(id)?.type === CategoryType.income) {
                    total += data?.actualAmount || 0;
                }
            }
            return total;
        });
        const { monthlyIncome, source: incomeSource } = computeMonthlyIncome(incomePerFullMonth, currentMonthIncome);

        // Grupos macro (cache em coaching_meta; IA apenas para categorias novas/renomeadas)
        const activeCategories = categories.filter(c => !c.isDeleted);
        const groupByCategoryId = await this.categoryGroupService.resolveCategoryGroups(workspaceId, activeCategories);

        // Somas do realizado por categoria nas duas janelas de 3 meses (period_summaries)
        const { sums: sums1, monthsWithData: monthsWithData1 } = this.sumActualByCategory(window1);
        const { sums: sums2, monthsWithData: monthsWithData2 } = this.sumActualByCategory(window2);

        // Agregados de installments realizadas na janela (txCount, ticket médio e fração
        // recorrente). Falha aqui não derruba a geração — o perfil fica sem esses campos.
        const windowStart = new Date(now.getFullYear(), now.getMonth() - 3, 1);
        const windowEnd = new Date(now.getFullYear(), now.getMonth(), 1);
        windowEnd.setMilliseconds(-1);

        const installmentAggregates = new Map<string, { txCount: number; total: number; recurring: number }>();
        try {
            const installments = await this.financeRepository.getInstallments(workspaceId, {
                startDate: windowStart,
                endDate: windowEnd,
                status: [InstallmentStatus.paid, InstallmentStatus.settled],
            });

            for (const installment of installments) {
                if (installment.type !== OrderType.expense || installment.isInvoice) continue;
                const categoryId = installment.category?.id;
                if (!categoryId) continue;

                const amount = Math.abs(installment.referenceAmount ?? installment.amount ?? 0);
                const entry = installmentAggregates.get(categoryId) || { txCount: 0, total: 0, recurring: 0 };
                entry.txCount++;
                entry.total += amount;
                if (installment.installmentType === InstallmentType.recurring) {
                    entry.recurring += amount;
                }
                installmentAggregates.set(categoryId, entry);
            }
        }
        catch (error) {
            console.error(`Coaching: falha ao agregar installments do perfil (${workspaceId}):`, error);
        }

        // Inputs do perfil: categorias de despesa reais + virtuais presentes nos summaries
        const expenseIds = new Set<string>([...sums1.keys(), ...sums2.keys(), ...installmentAggregates.keys()]);
        const inputs: CategoryProfileInput[] = [];

        for (const id of expenseIds) {
            const resolved = this.resolveExpenseCategory(id, categoryById);
            if (!resolved) continue;

            const group = groupByCategoryId[id]
                || CategoryGroupService.resolveVirtualCategoryGroup(id)
                || CategoryGroup.other;

            const aggregates = installmentAggregates.get(id);
            inputs.push({
                categoryId: id,
                categoryName: resolved.name,
                group,
                sumLast3Months: sums1.get(id) || 0,
                monthsWithData: monthsWithData1,
                txCount: aggregates?.txCount || 0,
                installmentsTotal: aggregates?.total || 0,
                recurringAmount: aggregates?.recurring || 0,
                prevAvgMonthly: (monthsWithData2 > 0 && sums2.has(id))
                    ? sums2.get(id)! / monthsWithData2
                    : null,
            });
        }

        const fullProfile = buildCategoryProfile(inputs, monthlyIncome);
        const lifestyle = buildLifestyleDiagnosis(fullProfile, monthlyIncome);
        const savingsOpportunities = buildSavingsOpportunities(fullProfile, lifestyle);

        return {
            monthlyIncome,
            incomeSource,
            noIncomeRecorded: monthlyIncome === null,
            categoryProfile: fullProfile
                .slice(0, MAX_PROFILE_CATEGORIES)
                .map((entry) => {
                    // categoryId é interno; a IA só precisa do nome e dos números
                    const publicEntry: any = { ...entry };
                    delete publicEntry.categoryId;
                    return publicEntry;
                }),
            lifestyle,
            savingsOpportunities,
            familyContext: {
                workspaceType: workspace?.type || "personal",
                membersCount: workspace?.members?.length || 1,
            },
        };
    }

    /** Soma o realizado (actualAmount) por categoria e conta os meses com summary. */
    private sumActualByCategory(summaries: (any | null)[]): { sums: Map<string, number>; monthsWithData: number } {
        const sums = new Map<string, number>();
        let monthsWithData = 0;

        for (const summary of summaries) {
            if (!summary) continue;
            monthsWithData++;
            for (const [id, data] of Object.entries<any>(summary.categories || {})) {
                const amount = data?.actualAmount || 0;
                if (amount === 0) continue;
                sums.set(id, (sums.get(id) || 0) + amount);
            }
        }

        return { sums, monthsWithData };
    }

    /** Resolve categoria de despesa (real ou virtual dos summaries); null quando não é despesa ativa. */
    private resolveExpenseCategory(id: string, categoryById: Map<string, CategoryModel>): CategoryModel | null {
        const category = categoryById.get(id);
        if (category) {
            return (category.type === CategoryType.expense && !category.isDeleted) ? category : null;
        }
        if (id === VIRTUAL_DEBT_EXPENSE_CATEGORY.id) return VIRTUAL_DEBT_EXPENSE_CATEGORY;
        if (id === VIRTUAL_INVESTMENT_EXPENSE_CATEGORY.id) return VIRTUAL_INVESTMENT_EXPENSE_CATEGORY;
        return null;
    }

    /** Progresso pré-calculado de uma meta (% atingido vs % do prazo decorrido). */
    private buildGoalProgress(goal: any, now: Date): any {
        const target = goal.targetAmount || 0;
        const current = goal.currentAmount || 0;
        const progressPercent = target > 0 ? this.round2((current / target) * 100) : 0;

        const startDate: Date | null = this.toDate(goal.startDate);
        const deadline: Date | null = this.toDate(goal.deadline);

        let elapsedPercent: number | null = null;
        if (startDate && deadline && deadline.getTime() > startDate.getTime()) {
            const elapsed = now.getTime() - startDate.getTime();
            const total = deadline.getTime() - startDate.getTime();
            elapsedPercent = this.round2(Math.min(Math.max((elapsed / total) * 100, 0), 100));
        }

        return {
            name: goal.name,
            targetAmount: target,
            currentAmount: current,
            deadline: deadline ? deadline.toISOString().split("T")[0] : undefined,
            progressPercent,
            elapsedPercent,
            isBehindSchedule: elapsedPercent !== null ? progressPercent < elapsedPercent : null,
        };
    }

    private round2(value: number): number {
        return Math.round(value * 100) / 100;
    }
}
