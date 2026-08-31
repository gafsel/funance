import * as logger from "firebase-functions/logger";
import { CategoryType } from "../../../workspace/domain/models/category.model";
import { IAIRepository } from "../../../../core/services/ai.service";
import { IIdempotencyService } from "../../../../core/services/idempotency.service";
import { IGamificationRepository } from "../repositories/gamification.repository";
import {
    addCalendarDays,
    endOfWeekFromStart,
    getDayIndexInTz,
    getMonthKeyInTz,
    getMonthRangeInTz,
    getWeekId,
    getZonedParts,
    startOfWeekInTz,
} from "./gamification_time.util";

/**
 * Um planning cobre o mês se startMonth <= mês <= endMonth (chaves "YYYY-MM").
 * Plannings sem período definido são considerados sempre ativos.
 */
function planningCoversMonth(planning: any, monthKey: string): boolean {
    const start = planning.startMonth || "0000-00";
    const end = planning.endMonth || "9999-12";
    return start <= monthKey && monthKey <= end;
}

export function calculateLevel(xp: number): number {
    if (xp <= 0) {
        return 1;
    }
    return Math.floor(Math.log2(xp / 300 + 1)) + 1;
}

export interface BadgeConfig {
    id: string;
    name: string;
    icon: string;
    xpReward: number;
}

export const BADGES: Record<string, BadgeConfig> = {
    first_step: { id: "first_step", name: "Primeiro Passo", icon: "rocket_launch", xpReward: 100 },
    first_account: { id: "first_account", name: "Primeira Conta", icon: "account_balance", xpReward: 150 },
    first_transaction: { id: "first_transaction", name: "Ponto de Partida", icon: "add_circle", xpReward: 150 },
    planner: { id: "planner", name: "Planejador Estrategista", icon: "assignment", xpReward: 200 },
    reconcile_junior: { id: "reconcile_junior", name: "Conciliador Júnior", icon: "point_of_sale", xpReward: 300 },
    cash_detective: { id: "cash_detective", name: "Detetive de Caixa", icon: "fact_check", xpReward: 500 },
    reconcile_master: { id: "reconcile_master", name: "Mestre da Conciliação", icon: "workspace_premium", xpReward: 1000 },
    zero_friction: { id: "zero_friction", name: "Atrito Zero", icon: "bolt", xpReward: 800 },
    savings_seed: { id: "savings_seed", name: "Semente de Poupança", icon: "savings", xpReward: 500 },
    goal_bronze: { id: "goal_bronze", name: "Colecionador de Metas", icon: "military_tech", xpReward: 1000 },
    goal_silver: { id: "goal_silver", name: "Foco Inabalável", icon: "stars", xpReward: 2000 },
    emergency_shield: { id: "emergency_shield", name: "Escudo de Emergência", icon: "shield", xpReward: 800 },
    under_control: { id: "under_control", name: "Tudo Sob Controle", icon: "check_circle", xpReward: 1500 },
    golden_rule: { id: "golden_rule", name: "Regra de Ouro", icon: "pie_chart", xpReward: 1200 },
    future_focus: { id: "future_focus", name: "Visão de Futuro", icon: "trending_up", xpReward: 1000 },
    cost_cutter: { id: "cost_cutter", name: "Tesoura de Gastos", icon: "content_cut", xpReward: 800 },
    dynamic_duo: { id: "dynamic_duo", name: "Dupla Dinâmica", icon: "people", xpReward: 400 },
    united_front: { id: "united_front", name: "Equipe Unida", icon: "groups", xpReward: 600 },
    financial_synapsis: { id: "financial_synapsis", name: "Sinergia Financeira", icon: "hub", xpReward: 800 },
    iron_consistency: { id: "iron_consistency", name: "Consistência de Aço", icon: "calendar_month", xpReward: 2500 },

    // ── Simple Badges — Primeiros Passos (10) ────────────────────────────────────────
    first_category: { id: "first_category", name: "Organizador", icon: "label", xpReward: 25 },
    first_planning: { id: "first_planning", name: "Planejador Novato", icon: "event_note", xpReward: 50 },
    first_goal: { id: "first_goal", name: "Sonhador", icon: "flag", xpReward: 50 },
    first_invite: { id: "first_invite", name: "Anfitrião", icon: "person_add", xpReward: 75 },
    profile_complete: { id: "profile_complete", name: "Perfil Completo", icon: "verified", xpReward: 25 },
    first_income: { id: "first_income", name: "Receita Registrada", icon: "south_east", xpReward: 50 },
    first_expense: { id: "first_expense", name: "Gasto Registrado", icon: "north_west", xpReward: 50 },
    first_transfer: { id: "first_transfer", name: "Transferidor", icon: "swap_horiz", xpReward: 50 },
    workspace_named: { id: "workspace_named", name: "Identidade Própria", icon: "edit", xpReward: 25 },
    first_month: { id: "first_month", name: "Primeiro Mês", icon: "calendar_today", xpReward: 75 },

    // ── Simple Badges — Registro Consistente (10) ────────────────────────────
    five_transactions: { id: "five_transactions", name: "Ativo!", icon: "flash_on", xpReward: 50 },
    twenty_transactions: { id: "twenty_transactions", name: "Comprometido", icon: "trending_up", xpReward: 75 },
    fifty_transactions: { id: "fifty_transactions", name: "Vetarano", icon: "workspace_premium", xpReward: 100 },
    hundred_transactions: { id: "hundred_transactions", name: "Centenário", icon: "emoji_events", xpReward: 150 },
    week_complete: { id: "week_complete", name: "Semana Completa", icon: "date_range", xpReward: 100 },
    two_accounts: { id: "two_accounts", name: "Multi-Conta", icon: "account_balance_wallet", xpReward: 50 },
    three_accounts: { id: "three_accounts", name: "Gerenciador", icon: "dashboard", xpReward: 75 },
    five_accounts: { id: "five_accounts", name: "Portfólio", icon: "business_center", xpReward: 100 },
    five_categories: { id: "five_categories", name: "Categorizado", icon: "category", xpReward: 50 },
    ten_categories: { id: "ten_categories", name: "Mestre Categorizador", icon: "workspaces", xpReward: 75 },

    // ── Simple Badges — Gastos e Economias (10) ──────────────────────────────
    round_number: { id: "round_number", name: "Número Redondo", icon: "radio_button_checked", xpReward: 25 },
    big_transaction: { id: "big_transaction", name: "Grande Negócio", icon: "payments", xpReward: 75 },
    small_transactions_ten: { id: "small_transactions_ten", name: "Detalhe Minucioso", icon: "grain", xpReward: 75 },
    income_registered: { id: "income_registered", name: "Bem Documentado", icon: "receipt_long", xpReward: 50 },
    expense_under_income: { id: "expense_under_income", name: "Saldo Positivo", icon: "balance", xpReward: 100 },
    three_categories_month: { id: "three_categories_month", name: "Diversificado", icon: "donut_small", xpReward: 75 },
    five_categories_month: { id: "five_categories_month", name: "Abrangente", icon: "donut_large", xpReward: 100 },
    savings_10pct: { id: "savings_10pct", name: "Poupador Iniciante", icon: "percent", xpReward: 100 },
    savings_start: { id: "savings_start", name: "Primeiro Centavo", icon: "monetization_on", xpReward: 75 },
    no_credit_debt: { id: "no_credit_debt", name: "Livre de Juros", icon: "credit_score", xpReward: 75 },

    // ── Simple Badges — Metas (10) ───────────────────────────────────────────────────
    goal_halfway: { id: "goal_halfway", name: "Na Metade do Caminho", icon: "looks_two", xpReward: 50 },
    goal_75pct: { id: "goal_75pct", name: "Quase Lá", icon: "looks_3", xpReward: 75 },
    goal_under_deadline: { id: "goal_under_deadline", name: "No Prazo", icon: "timer", xpReward: 100 },
    two_active_goals: { id: "two_active_goals", name: "Ambicioso", icon: "offline_bolt", xpReward: 50 },
    five_active_goals: { id: "five_active_goals", name: "Multitarefas", icon: "dynamic_feed", xpReward: 100 },
    long_term_goal: { id: "long_term_goal", name: "Visão de Longo Prazo", icon: "public", xpReward: 75 },
    short_term_goal: { id: "short_term_goal", name: "Sprint Financeiro", icon: "bolt", xpReward: 75 },
    goal_deposit: { id: "goal_deposit", name: "Primeiro Depósito", icon: "add_card", xpReward: 50 },
    goal_debt_paid: { id: "goal_debt_paid", name: "Livre de Dívidas", icon: "free_cancellation", xpReward: 150 },
    goal_linked_account: { id: "goal_linked_account", name: "Meta Vinculada", icon: "link", xpReward: 50 },

    // ── Simple Badges — Equipe e Consistência (10) ───────────────────────────
    second_member: { id: "second_member", name: "Dupla!", icon: "group_add", xpReward: 50 },
    reconcile_second: { id: "reconcile_second", name: "Conciliador Frequente", icon: "refresh", xpReward: 75 },
    reconcile_five: { id: "reconcile_five", name: "Conciliador Hábil", icon: "sync_alt", xpReward: 100 },
    mission_first: { id: "mission_first", name: "Primeira Missão", icon: "task_alt", xpReward: 75 },
    mission_three: { id: "mission_three", name: "Triatleta Financeiro", icon: "sports_score", xpReward: 100 },
    planning_month: { id: "planning_month", name: "Planejamento do Mês", icon: "event_available", xpReward: 75 },
    two_months_active: { id: "two_months_active", name: "Constante", icon: "repeat", xpReward: 100 },
    workspace_one_year: { id: "workspace_one_year", name: "Aniversário!", icon: "cake", xpReward: 150 },
    invite_accepted: { id: "invite_accepted", name: "Bem-vindo ao Time", icon: "waving_hand", xpReward: 50 },
    all_missions_week: { id: "all_missions_week", name: "Semana Perfeita", icon: "star", xpReward: 100 },
};

export class GamificationService {
    constructor(
        private gamificationRepository: IGamificationRepository,
        private aiRepository?: IAIRepository,
        private idempotencyService?: IIdempotencyService
    ) { }

    async addXp(workspaceId: string, amount: number, reason: string): Promise<void> {
        await this.gamificationRepository.addXp(workspaceId, amount, reason);
    }

    async unlockBadge(workspaceId: string, badgeId: string): Promise<boolean> {
        const badge = BADGES[badgeId];
        if (!badge) {
            logger.error(`[GamificationService] Badge ${badgeId} not configured.`);
            return false;
        }

        return this.gamificationRepository.unlockBadge(
            workspaceId,
            badgeId,
            badge.xpReward,
            badge.name
        );
    }

    async checkFirstStep(workspaceId: string, onboardingCompleted: boolean): Promise<void> {
        if (onboardingCompleted) {
            await this.unlockBadge(workspaceId, "first_step");
        }
    }

    async checkUnitedFront(workspaceId: string, membersCount: number): Promise<void> {
        if (membersCount >= 3) {
            await this.unlockBadge(workspaceId, "united_front");
        }
    }

    async checkFirstAccount(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getAccountsCount(workspaceId);
        if (count >= 1) {
            await this.unlockBadge(workspaceId, "first_account");
        }
    }

    async checkFirstTransaction(workspaceId: string): Promise<void> {
        const hasTx = await this.gamificationRepository.hasPaidTransaction(workspaceId);
        if (hasTx) {
            await this.unlockBadge(workspaceId, "first_transaction");
        }
    }

    async checkPlanner(workspaceId: string): Promise<void> {
        const plannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let count = 0;
        for (const p of plannings) {
            if (p.amount > 0) {
                count++;
            }
        }

        if (count >= 5) {
            await this.unlockBadge(workspaceId, "planner");
        }
    }

    async checkGoldenRule(workspaceId: string): Promise<void> {
        const plannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let hasEssential = false;
        let hasComfort = false;
        let hasInvestment = false;

        for (const p of plannings) {
            if (p.amount > 0 && p.category) {
                const allocation = p.category.allocation;
                if (allocation === "essential") {
                    hasEssential = true;
                }
                if (allocation === "comfort") {
                    hasComfort = true;
                }
                if (allocation === "investment") {
                    hasInvestment = true;
                }
            }
        }

        if (hasEssential && hasComfort && hasInvestment) {
            await this.unlockBadge(workspaceId, "golden_rule");
        }
    }

    async checkReconciliationBadges(
        workspaceId: string,
        confirmedMatchesCount: number,
        totalTransactionsProcessed: number,
        createdTransactionsCount: number
    ): Promise<void> {
        if (totalTransactionsProcessed >= 1) {
            await this.unlockBadge(workspaceId, "reconcile_junior");
        }

        if (totalTransactionsProcessed >= 10) {
            await this.unlockBadge(workspaceId, "cash_detective");
        }

        if (createdTransactionsCount === 0 && totalTransactionsProcessed > 0) {
            await this.unlockBadge(workspaceId, "zero_friction");
        }

        const count = await this.gamificationRepository.getCompletedReconciliationsCount(workspaceId, 10);
        if (count >= 10) {
            await this.unlockBadge(workspaceId, "reconcile_master");
        }
    }

    async checkGoalBadges(workspaceId: string, goalDoc: any): Promise<void> {
        const data = goalDoc;
        const isCompleted = data.status === "completed" || (data.currentAmount >= data.targetAmount);

        if (isCompleted) {
            const completedSnapshot = await this.gamificationRepository.getGoals(workspaceId);
            let completedCount = 0;
            for (const g of completedSnapshot) {
                if (g.status === "completed" || (g.currentAmount >= g.targetAmount)) {
                    completedCount++;
                }
            }

            if (completedCount >= 1) {
                await this.unlockBadge(workspaceId, "savings_seed");
            }
            if (completedCount >= 3) {
                await this.unlockBadge(workspaceId, "goal_bronze");
            }
            if (completedCount >= 5) {
                await this.unlockBadge(workspaceId, "goal_silver");
            }

            if (data.type === "emergency") {
                await this.unlockBadge(workspaceId, "emergency_shield");
            }
        }
    }

    async checkDynamicDuo(workspaceId: string, paidDate: Date): Promise<void> {
        const startOfMonth = new Date(paidDate.getFullYear(), paidDate.getMonth(), 1);
        const endOfMonth = new Date(paidDate.getFullYear(), paidDate.getMonth() + 1, 0, 23, 59, 59);

        const snapshot = await this.gamificationRepository.getPaidInstallmentsInPeriod(
            workspaceId,
            startOfMonth,
            endOfMonth
        );

        const userIds = new Set<string>();
        for (const inst of snapshot) {
            if (inst.createdBy) {
                userIds.add(inst.createdBy);
            }
            if (inst.paidBy) {
                userIds.add(inst.paidBy);
            }
        }

        if (userIds.size >= 2) {
            await this.unlockBadge(workspaceId, "dynamic_duo");
        }
    }

    async updateWeeklyMissionsProgress(
        workspaceId: string,
        eventType: "transaction" | "reconciliation" | "planning",
        eventData: any
    ): Promise<void> {
        const now = new Date();
        // Fronteiras de semana calculadas no fuso America/Sao_Paulo (util único).
        const startOfWeek = startOfWeekInTz(now);
        const endOfWeek = endOfWeekFromStart(startOfWeek);
        const weekId = getWeekId(startOfWeek);
        const monthKey = getMonthKeyInTz(now);

        const consistencyDoc = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "consistency");
        if (!consistencyDoc) {
            const generateMissions = async () => {
                await this.generateWeeklyMissions(workspaceId, weekId, monthKey);
            };
            if (this.idempotencyService) {
                // Chave por workspace+semana: escritas paralelas de installments
                // não disparam geração (e chamadas de IA) duplicadas.
                await this.idempotencyService.runIdempotency(
                    `${workspaceId}_${weekId}`,
                    "generateWeeklyMissions",
                    generateMissions
                );
            }
            else {
                await generateMissions();
            }
        }

        if (eventType === "transaction" || eventType === "planning") {
            const categoryPlannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);

            // Apenas plannings cujo período cobre o mês corrente contam para a
            // missão de consistência (antes, qualquer planning histórico contava).
            const activePlannings = categoryPlannings.filter((p) => {
                return planningCoversMonth(p, monthKey);
            });

            let plannedCategoriesCount = 0;
            let targetCategory = "Alimentação";
            let maxAmount = 0;

            for (const p of activePlannings) {
                if (p.amount > 0) {
                    plannedCategoriesCount++;
                }
                if (p.category && p.category.name && p.amount > maxAmount) {
                    maxAmount = p.amount;
                    targetCategory = p.category.name;
                }
            }

            const constData = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "consistency");
            if (constData && constData.status !== "completed") {
                const target = constData.target || 3;
                if (plannedCategoriesCount >= target) {
                    // Checagem de "já concluída" + concessão de XP em uma única
                    // transação Firestore (sem corrida entre escritas paralelas).
                    await this.gamificationRepository.completeMissionAndAwardXp(
                        workspaceId,
                        weekId,
                        "consistency",
                        plannedCategoriesCount,
                        constData.rewardXp || 150,
                        "Missão Semanal de Consistência Concluída"
                    );
                }
                else {
                    await this.gamificationRepository.updateWeeklyMission(workspaceId, weekId, "consistency", {
                        progress: plannedCategoriesCount,
                        status: "pending",
                    });
                }
            }

            if (eventType === "transaction") {
                // Parcelas efetivamente pagas na semana (por paidDate) — antes a
                // busca era por dueDate mas o agrupamento por paidDate.
                const installments = await this.gamificationRepository.getPaidInstallmentsInPeriod(
                    workspaceId,
                    startOfWeek,
                    endOfWeek
                );

                const weeklyLimit = maxAmount || 250.0;
                const dailyLimit = weeklyLimit / 7;
                const expensesByDay: Record<number, number> = {};

                for (const inst of installments) {
                    if (inst.status === "removed") {
                        continue;
                    }
                    // paidDate consistentemente; dueDate apenas como fallback.
                    const rawDate = inst.paidDate ?? inst.dueDate;
                    if (!rawDate) {
                        continue;
                    }
                    const date = rawDate?.toDate ? rawDate.toDate() : new Date(rawDate);
                    const day = getDayIndexInTz(date);

                    if (inst.type === "expense") {
                        if (inst.category && inst.category.name && inst.category.name.toLowerCase() === targetCategory.toLowerCase()) {
                            const amount = inst.paidAmount || inst.amount || 0;
                            expensesByDay[day] = (expensesByDay[day] || 0) + amount;
                        }
                    }
                }

                // Conta apenas dias JÁ decorridos por completo (exclui o dia de
                // hoje, que ainda pode receber gastos). Antes, dias futuros
                // contavam como "dentro do orçamento" e a missão fechava na
                // primeira transação da semana.
                const elapsedFullDays = getDayIndexInTz(now);
                let daysWithinBudgetCount = 0;
                for (let d = 0; d < elapsedFullDays; d++) {
                    const spent = expensesByDay[d] || 0;
                    if (spent <= dailyLimit) {
                        daysWithinBudgetCount++;
                    }
                }

                const discData = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "discipline");
                if (discData && discData.status !== "completed") {
                    const target = discData.target || 5;
                    // Exige que pelo menos `target` dias tenham decorrido antes
                    // de permitir a conclusão.
                    if (daysWithinBudgetCount >= target && elapsedFullDays >= target) {
                        await this.gamificationRepository.completeMissionAndAwardXp(
                            workspaceId,
                            weekId,
                            "discipline",
                            daysWithinBudgetCount,
                            discData.rewardXp || 250,
                            "Missão Semanal de Disciplina Concluída"
                        );
                    }
                    else {
                        await this.gamificationRepository.updateWeeklyMission(workspaceId, weekId, "discipline", {
                            progress: daysWithinBudgetCount,
                            status: "pending",
                        });
                    }
                }
            }
        }
        else if (eventType === "reconciliation") {
            const recDoc = eventData;
            const orgData = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "organization");
            if (orgData && orgData.status !== "completed") {
                const target = orgData.target || 5;
                if (recDoc.status === "completed" && recDoc.totalTransactionsProcessed >= target) {
                    await this.gamificationRepository.completeMissionAndAwardXp(
                        workspaceId,
                        weekId,
                        "organization",
                        recDoc.totalTransactionsProcessed,
                        orgData.rewardXp || 200,
                        "Missão Semanal de Organização Concluída"
                    );
                }
            }
        }
    }

    /**
     * Gera as três missões semanais (com IA quando disponível) para a semana.
     * Deve ser invocada sob idempotência (workspaceId + weekId) para não
     * duplicar chamadas de IA em escritas paralelas.
     */
    private async generateWeeklyMissions(workspaceId: string, weekId: string, monthKey: string): Promise<void> {
        logger.info(`[GamificationService] Generating AI weekly missions for workspace ${workspaceId}, week ${weekId}`);

        let workspaceType = "personal";
        try {
            const workspaceDoc = await this.gamificationRepository.getWorkspaceById(workspaceId);
            if (workspaceDoc) {
                workspaceType = workspaceDoc.type || "personal";
            }
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching workspace type:", e);
        }

        const categoriesList: string[] = [];
        let maxCategory = "Alimentação";
        let maxAmount = 0;
        try {
            const categoryPlannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
            for (const p of categoryPlannings) {
                if (!planningCoversMonth(p, monthKey)) {
                    continue;
                }
                if (p.category && p.category.name) {
                    categoriesList.push(p.category.name);
                    if (p.amount > maxAmount) {
                        maxAmount = p.amount;
                        maxCategory = p.category.name;
                    }
                }
            }
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching category plannings:", e);
        }

        const goalsList: string[] = [];
        try {
            const goalsSnapshot = await this.gamificationRepository.getGoals(workspaceId);
            for (const g of goalsSnapshot) {
                if (g.status === "active" && g.name) {
                    goalsList.push(g.name);
                }
            }
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching goals:", e);
        }

        let aiMissions: any = null;
        if (this.aiRepository) {
            try {
                aiMissions = await this.aiRepository.generateWeeklyMissions(
                    workspaceId,
                    workspaceType,
                    categoriesList,
                    goalsList,
                    maxCategory
                );
            }
            catch (e) {
                logger.error("[GamificationService] Failed to generate weekly missions via Gemini. Using fallbacks.", e);
            }
        }

        const consistencyName = aiMissions?.consistency?.name || "Equipe planeja limites para pelo menos 3 categorias para organizar a semana.";
        const consistencyTarget = aiMissions?.consistency?.target || 3;

        const disciplineName = aiMissions?.discipline?.name || `Equipe mantém a categoria ${maxCategory} dentro do orçamento planejado por 5 dias.`;
        const disciplineTarget = aiMissions?.discipline?.target || 5;

        const organizationName = aiMissions?.organization?.name || "Fazer a conciliação bancária completa de um extrato contendo pelo menos 5 itens.";
        const organizationTarget = aiMissions?.organization?.target || 5;

        await this.gamificationRepository.createWeeklyMission(workspaceId, weekId, "consistency", {
            id: "consistency",
            name: consistencyName,
            type: "consistency",
            status: "pending",
            rewardXp: 150,
            progress: 0,
            target: consistencyTarget,
            weekId,
            createdAt: new Date().toISOString(),
        });

        await this.gamificationRepository.createWeeklyMission(workspaceId, weekId, "discipline", {
            id: "discipline",
            name: disciplineName,
            type: "discipline",
            status: "pending",
            rewardXp: 250,
            progress: 0,
            target: disciplineTarget,
            weekId,
            createdAt: new Date().toISOString(),
        });

        await this.gamificationRepository.createWeeklyMission(workspaceId, weekId, "organization", {
            id: "organization",
            name: organizationName,
            type: "organization",
            status: "pending",
            rewardXp: 200,
            progress: 0,
            target: organizationTarget,
            weekId,
            createdAt: new Date().toISOString(),
        });
    }

    async evaluateWeeklyMissionsCron(workspaceId: string): Promise<void> {
        const now = new Date();
        // O cron roda na virada da semana (segunda de madrugada): a semana a
        // avaliar é a ANTERIOR, já completa. Avaliar a semana corrente (recém
        // iniciada e vazia) zeraria a streak permanentemente.
        const currentWeekStart = startOfWeekInTz(now);
        const startOfWeek = addCalendarDays(currentWeekStart, -7);
        const endOfWeek = new Date(currentWeekStart.getTime() - 1);
        const weekId = getWeekId(startOfWeek);

        const snapshot = await this.gamificationRepository.getWeeklyMissionsByWeek(workspaceId, weekId);

        let allCompleted = true;
        let count = 0;
        for (const mission of snapshot) {
            count++;
            if (mission.status !== "completed") {
                allCompleted = false;
            }
        }

        if (count === 0) {
            allCompleted = false;
        }

        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        if (!workspaceData) {
            return;
        }

        let currentStreaks = workspaceData.weeklyStreaks || 0;

        if (allCompleted) {
            currentStreaks++;
            await this.gamificationRepository.updateWorkspaceStreaks(workspaceId, currentStreaks);

            if (currentStreaks >= 4) {
                await this.unlockBadge(workspaceId, "iron_consistency");
            }

            const activeMembers = workspaceData.members || [];

            const installments = await this.gamificationRepository.getPaidInstallmentsInPeriod(
                workspaceId,
                startOfWeek,
                endOfWeek
            );

            const transactingUsers = new Set<string>();
            for (const inst of installments) {
                if (inst.createdBy) {
                    transactingUsers.add(inst.createdBy);
                }
                if (inst.paidBy) {
                    transactingUsers.add(inst.paidBy);
                }
            }

            const allMembersTransacted = activeMembers.every((mId: string) => {
                return transactingUsers.has(mId);
            });
            if (allMembersTransacted && activeMembers.length > 0) {
                await this.unlockBadge(workspaceId, "financial_synapsis");
            }
        }
        else {
            await this.gamificationRepository.updateWorkspaceStreaks(workspaceId, 0);
        }

        // Badges de missões (mission_first, mission_three, all_missions_week):
        // antes estas checagens nunca eram invocadas.
        try {
            const completedMissionsTotal = await this.gamificationRepository.getCompletedMissionsCount(workspaceId);
            await this.checkMissionBadges(workspaceId, completedMissionsTotal, allCompleted ? 1 : 0);
        }
        catch (e) {
            logger.error("[GamificationService] Error checking mission badges:", e);
        }
    }

    async evaluateMonthlyMissionsCron(workspaceId: string): Promise<void> {
        const now = new Date();
        // Mês anterior completo, no fuso America/Sao_Paulo.
        const lastMonth = getMonthRangeInTz(now, -1);
        const year = lastMonth.year;

        const snapshot = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            year,
            lastMonth.month
        );

        let underControl = true;
        let summaryCount = 0;

        let totalComfortExpenses = 0;
        let totalInvestmentSavings = 0;
        let totalIncomes = 0;

        for (const summary of snapshot) {
            summaryCount++;
            const actual = summary.actualAmount || 0;
            const planned = summary.generalPlannedAmount || 0;

            if (summary.category) {
                const type = summary.category.type;
                const allocation = summary.category.allocation;

                if (type === CategoryType.expense) {
                    if (actual > planned) {
                        underControl = false;
                    }
                    if (allocation === "comfort") {
                        totalComfortExpenses += actual;
                    }
                    if (allocation === "investment") {
                        totalInvestmentSavings += actual;
                    }
                }
                else if (type === CategoryType.income) {
                    totalIncomes += actual;
                }
            }
        }

        if (underControl && summaryCount > 0) {
            await this.unlockBadge(workspaceId, "under_control");
        }

        if (totalIncomes > 0 && (totalInvestmentSavings / totalIncomes) >= 0.20) {
            await this.unlockBadge(workspaceId, "future_focus");
        }

        const prevMonth = getMonthRangeInTz(now, -2);

        const prevSnapshot = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            prevMonth.year,
            prevMonth.month
        );

        let prevComfortExpenses = 0;
        for (const summary of prevSnapshot) {
            if (summary.category && summary.category.type === CategoryType.expense && summary.category.allocation === "comfort") {
                prevComfortExpenses += (summary.actualAmount || 0);
            }
        }

        if (prevComfortExpenses > 0 && totalComfortExpenses <= 0.8 * prevComfortExpenses) {
            await this.unlockBadge(workspaceId, "cost_cutter");
        }
    }

    /**
     * Badge no_credit_debt ("Livre de Juros"): concedido no cron mensal quando
     * o workspace possui pelo menos uma conta de cartão de crédito e nenhuma
     * parcela PENDENTE vinculada a cartão com vencimento no mês anterior.
     */
    async checkNoCreditDebtBadge(workspaceId: string): Promise<void> {
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        if (!workspaceData) {
            return;
        }
        const unlockedBadges = workspaceData.unlockedBadges || {};
        if (unlockedBadges["no_credit_debt"]) {
            return;
        }

        const cardAccountIds = await this.gamificationRepository.getCreditCardAccountIds(workspaceId);
        if (cardAccountIds.length === 0) {
            // Sem cartão de crédito, o badge não faz sentido.
            return;
        }

        const lastMonth = getMonthRangeInTz(new Date(), -1);
        const hasDebt = await this.gamificationRepository.hasPendingInstallmentsForAccounts(
            workspaceId,
            cardAccountIds,
            lastMonth.start,
            lastMonth.end
        );

        if (!hasDebt) {
            await this.unlockBadge(workspaceId, "no_credit_debt");
        }
    }

    /**
     * Executa a rotina semanal para todos os workspaces (chamado pelo
     * scheduler toda segunda-feira, 03:00 America/Sao_Paulo).
     */
    async runWeeklyCronForAllWorkspaces(): Promise<void> {
        const workspaceIds = await this.gamificationRepository.getAllWorkspaceIds();
        logger.info(`[GamificationService] Weekly cron: processing ${workspaceIds.length} workspaces.`);
        for (const workspaceId of workspaceIds) {
            try {
                await this.evaluateWeeklyMissionsCron(workspaceId);
                await this.checkFinancialHealthBadges(workspaceId);
            }
            catch (e) {
                logger.error(`[GamificationService] Weekly cron failed for workspace ${workspaceId}:`, e);
            }
        }
    }

    /**
     * Executa a rotina mensal para todos os workspaces (chamado pelo
     * scheduler todo dia 1, 03:00 America/Sao_Paulo).
     */
    async runMonthlyCronForAllWorkspaces(): Promise<void> {
        const workspaceIds = await this.gamificationRepository.getAllWorkspaceIds();
        logger.info(`[GamificationService] Monthly cron: processing ${workspaceIds.length} workspaces.`);
        for (const workspaceId of workspaceIds) {
            try {
                await this.evaluateMonthlyMissionsCron(workspaceId);
                await this.checkFinancialHealthBadges(workspaceId);
                await this.checkNoCreditDebtBadge(workspaceId);
            }
            catch (e) {
                logger.error(`[GamificationService] Monthly cron failed for workspace ${workspaceId}:`, e);
            }
        }
    }

    async checkSimpleWorkspaceBadges(workspaceId: string, workspaceData: any): Promise<void> {
        const name: string = workspaceData.name || "";
        const type: string = workspaceData.type || "";
        const members: string[] = workspaceData.members || [];
        const unlockedBadges = workspaceData.unlockedBadges || {};
        const createdAt: Date = workspaceData.createdAt?.toDate
            ? workspaceData.createdAt.toDate()
            : new Date(workspaceData.createdAt || Date.now());

        if (!unlockedBadges["profile_complete"] && name.trim().length > 0 && type.trim().length > 0) {
            await this.unlockBadge(workspaceId, "profile_complete");
        }
        if (!unlockedBadges["workspace_named"] && name.trim().length > 0) {
            await this.unlockBadge(workspaceId, "workspace_named");
        }
        if (!unlockedBadges["second_member"] && members.length >= 2) {
            await this.unlockBadge(workspaceId, "second_member");
        }

        const oneYearAgo = new Date();
        oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
        if (!unlockedBadges["workspace_one_year"] && createdAt <= oneYearAgo) {
            await this.unlockBadge(workspaceId, "workspace_one_year");
        }
    }

    async checkSimpleCategoryBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getCategoriesCount(workspaceId);
        if (count >= 1) {
            await this.unlockBadge(workspaceId, "first_category");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "five_categories");
        }
        if (count >= 10) {
            await this.unlockBadge(workspaceId, "ten_categories");
        }
    }

    async checkSimplePlanningBadges(workspaceId: string): Promise<void> {
        const snap = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let activeCount = 0;
        for (const p of snap) {
            if ((p.amount || 0) > 0) {
                activeCount++;
            }
        }
        if (activeCount >= 1) {
            await this.unlockBadge(workspaceId, "first_planning");
        }
        if (activeCount >= 5) {
            await this.unlockBadge(workspaceId, "planning_month");
        }
    }

    async checkSimpleGoalBadges(workspaceId: string, goalDoc: any): Promise<void> {
        const data = goalDoc;

        // Early-return por badge já desbloqueado: evita abrir transações e
        // consultas desnecessárias em cada escrita de goal.
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        const unlockedBadges = workspaceData?.unlockedBadges || {};
        const isLocked = (badgeId: string) => {
            return !unlockedBadges[badgeId];
        };

        if (isLocked("first_goal")) {
            await this.unlockBadge(workspaceId, "first_goal");
        }

        if (isLocked("goal_linked_account") && (data.accountId || data.accountIdTarget)) {
            await this.unlockBadge(workspaceId, "goal_linked_account");
        }

        if (isLocked("long_term_goal") && data.targetDate) {
            const target = data.targetDate?.toDate ? data.targetDate.toDate() : new Date(data.targetDate);
            const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt || Date.now());
            const monthsDiff = (target.getFullYear() - createdAt.getFullYear()) * 12 + target.getMonth() - createdAt.getMonth();
            if (monthsDiff > 12) {
                await this.unlockBadge(workspaceId, "long_term_goal");
            }
        }

        // Só consulta a lista de goals se algum badge de contagem ainda falta.
        if (isLocked("two_active_goals") || isLocked("five_active_goals")) {
            const allGoals = await this.gamificationRepository.getGoals(workspaceId);
            let activeGoals = 0;
            for (const g of allGoals) {
                if (g.status === "active") {
                    activeGoals++;
                }
            }
            if (isLocked("two_active_goals") && activeGoals >= 2) {
                await this.unlockBadge(workspaceId, "two_active_goals");
            }
            if (isLocked("five_active_goals") && activeGoals >= 5) {
                await this.unlockBadge(workspaceId, "five_active_goals");
            }
        }

        const current = data.currentAmount || 0;
        const target = data.targetAmount || 1;
        const pct = current / target;

        if (current > 0) {
            if (isLocked("goal_deposit")) {
                await this.unlockBadge(workspaceId, "goal_deposit");
            }
            if (isLocked("savings_start")) {
                await this.unlockBadge(workspaceId, "savings_start");
            }
        }
        if (isLocked("goal_halfway") && pct >= 0.5) {
            await this.unlockBadge(workspaceId, "goal_halfway");
        }
        if (isLocked("goal_75pct") && pct >= 0.75) {
            await this.unlockBadge(workspaceId, "goal_75pct");
        }

        const isCompleted = data.status === "completed" || pct >= 1;
        if (isCompleted) {
            const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt || Date.now());
            const completedAt = data.completedAt?.toDate ? data.completedAt.toDate() : new Date();
            const daysDiff = (completedAt.getTime() - createdAt.getTime()) / 86400000;
            if (isLocked("short_term_goal") && daysDiff < 30) {
                await this.unlockBadge(workspaceId, "short_term_goal");
            }

            if (isLocked("goal_under_deadline") && data.targetDate) {
                const targetDate = data.targetDate?.toDate ? data.targetDate.toDate() : new Date(data.targetDate);
                if (completedAt <= targetDate) {
                    await this.unlockBadge(workspaceId, "goal_under_deadline");
                }
            }

            if (isLocked("goal_debt_paid") && data.type === "payDebt") {
                await this.unlockBadge(workspaceId, "goal_debt_paid");
            }
        }
    }

    async checkSimpleTransactionBadges(workspaceId: string, installmentData: any): Promise<void> {
        const type: string = installmentData.type || "";
        const amount: number = Math.abs(installmentData.referenceAmount || installmentData.amount || 0);

        // Early-return por badge já desbloqueado ANTES de qualquer consulta:
        // evita baixar todas as parcelas do workspace a cada transação.
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        const unlockedBadges = workspaceData?.unlockedBadges || {};
        const isLocked = (badgeId: string) => {
            return !unlockedBadges[badgeId];
        };

        if (isLocked("first_income") && type === "income") {
            await this.unlockBadge(workspaceId, "first_income");
        }
        if (isLocked("first_expense") && type === "expense") {
            await this.unlockBadge(workspaceId, "first_expense");
        }
        if (isLocked("first_transfer") && type === "transfer") {
            await this.unlockBadge(workspaceId, "first_transfer");
        }

        if (isLocked("round_number") && amount > 0 && amount % 1 === 0) {
            await this.unlockBadge(workspaceId, "round_number");
        }

        if (isLocked("big_transaction") && amount >= 1000) {
            await this.unlockBadge(workspaceId, "big_transaction");
        }

        if (isLocked("income_registered") && type === "income" && amount > 0) {
            await this.unlockBadge(workspaceId, "income_registered");
        }

        const countBadges: Array<[string, number]> = [
            ["five_transactions", 5],
            ["twenty_transactions", 20],
            ["fifty_transactions", 50],
            ["hundred_transactions", 100],
        ];
        const needsCount = countBadges.some(([badgeId]) => {
            return isLocked(badgeId);
        });
        const needsDocs = isLocked("small_transactions_ten") ||
            isLocked("first_month") ||
            isLocked("two_months_active");

        if (!needsCount && !needsDocs) {
            return;
        }

        if (needsCount) {
            // Só o número importa: aggregate count() em vez de baixar os docs.
            const settledCount = await this.gamificationRepository.getPaidInstallmentsCount(workspaceId);
            for (const [badgeId, threshold] of countBadges) {
                if (isLocked(badgeId) && settledCount >= threshold) {
                    await this.unlockBadge(workspaceId, badgeId);
                }
            }
        }

        if (needsDocs) {
            const settledSnap = await this.gamificationRepository.getPaidInstallments(workspaceId);

            if (isLocked("small_transactions_ten")) {
                let smallCount = 0;
                for (const d of settledSnap) {
                    const a = Math.abs(d.referenceAmount || d.amount || 0);
                    if (a < 10 && a > 0) {
                        smallCount++;
                    }
                }
                if (smallCount >= 10) {
                    await this.unlockBadge(workspaceId, "small_transactions_ten");
                }
            }

            if (isLocked("first_month") || isLocked("two_months_active")) {
                const paidDates = new Set<string>();
                for (const d of settledSnap) {
                    const pd = d.paidDate?.toDate
                        ? d.paidDate.toDate()
                        : (d.paidDate ? new Date(d.paidDate) : null);
                    if (pd) {
                        paidDates.add(getMonthKeyInTz(pd));
                    }
                }
                if (isLocked("first_month") && paidDates.size >= 1) {
                    await this.unlockBadge(workspaceId, "first_month");
                }
                if (isLocked("two_months_active") && paidDates.size >= 2) {
                    await this.unlockBadge(workspaceId, "two_months_active");
                }
            }
        }
    }

    async checkSimpleAccountBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getAccountsCount(workspaceId);
        if (count >= 2) {
            await this.unlockBadge(workspaceId, "two_accounts");
        }
        if (count >= 3) {
            await this.unlockBadge(workspaceId, "three_accounts");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "five_accounts");
        }
    }

    async checkSimpleReconciliationBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getCompletedReconciliationsCount(workspaceId);
        if (count >= 2) {
            await this.unlockBadge(workspaceId, "reconcile_second");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "reconcile_five");
        }
    }

    async checkInviteAcceptedBadge(workspaceId: string): Promise<void> {
        await this.unlockBadge(workspaceId, "invite_accepted");
        await this.unlockBadge(workspaceId, "first_invite");
    }

    async checkMissionBadges(workspaceId: string, completedMissionsTotal: number, perfectWeeks: number): Promise<void> {
        if (completedMissionsTotal >= 1) {
            await this.unlockBadge(workspaceId, "mission_first");
        }
        if (completedMissionsTotal >= 3) {
            await this.unlockBadge(workspaceId, "mission_three");
        }
        if (perfectWeeks >= 1) {
            await this.unlockBadge(workspaceId, "all_missions_week");
        }
    }

    async checkFinancialHealthBadges(workspaceId: string): Promise<void> {
        const now = new Date();
        const currentMonth = getMonthRangeInTz(now, 0);

        const snap = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            currentMonth.year,
            currentMonth.month
        );

        let totalIncome = 0;
        let totalExpenses = 0;
        const categoryIds = new Set<string>();

        for (const d of snap) {
            if (d.category?.type === "income") {
                totalIncome += d.actualAmount || 0;
            }
            else if (d.category?.type === "expense") {
                totalExpenses += d.actualAmount || 0;
                if (d.category?.id) {
                    categoryIds.add(d.category.id);
                }
            }
        }

        if (totalIncome > 0 && totalExpenses < totalIncome) {
            await this.unlockBadge(workspaceId, "expense_under_income");
        }
        if (categoryIds.size >= 3) {
            await this.unlockBadge(workspaceId, "three_categories_month");
        }
        if (categoryIds.size >= 5) {
            await this.unlockBadge(workspaceId, "five_categories_month");
        }

        const saved = totalIncome - totalExpenses;
        if (totalIncome > 0 && saved >= 0.1 * totalIncome) {
            await this.unlockBadge(workspaceId, "savings_10pct");
        }

        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
        const weekSnap = await this.gamificationRepository.getPaidInstallmentsSince(workspaceId, sevenDaysAgo);

        const activeDays = new Set<string>();
        for (const d of weekSnap) {
            const pd = d.paidDate?.toDate
                ? d.paidDate.toDate()
                : (d.paidDate ? new Date(d.paidDate) : null);
            if (pd) {
                const parts = getZonedParts(pd);
                activeDays.add(`${parts.year}-${parts.month}-${parts.day}`);
            }
        }
        if (activeDays.size >= 7) {
            await this.unlockBadge(workspaceId, "week_complete");
        }
    }
}