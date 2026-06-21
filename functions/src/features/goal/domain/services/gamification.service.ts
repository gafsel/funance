import * as logger from "firebase-functions/logger";
import { CategoryType } from "../../../workspace/domain/models/category.model";
import { IAIRepository } from "../../../../core/services/ai.service";
import { IGamificationRepository } from "../repositories/gamification.repository";

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
        private aiRepository?: IAIRepository
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
        const startOfWeek = new Date(now.getTime() - (now.getDay() * 24 * 60 * 60 * 1000));
        startOfWeek.setHours(0, 0, 0, 0);
        const endOfWeek = new Date(startOfWeek.getTime() + (6 * 24 * 60 * 60 * 1000) + 23 * 3600 * 1000 + 59 * 60 * 1000 + 59 * 1000);

        const year = startOfWeek.getFullYear();
        const firstDayOfYear = new Date(year, 0, 1);
        const days = Math.floor((startOfWeek.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        const week = Math.floor(days / 7) + 1;
        const weekId = `${year}-W${String(week).padStart(2, "0")}`;

        const consistencyDoc = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "consistency");
        if (!consistencyDoc) {
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

        if (eventType === "transaction" || eventType === "planning") {
            const categoryPlannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);

            let plannedCategoriesCount = 0;
            let targetCategory = "Alimentação";
            let maxAmount = 0;

            for (const p of categoryPlannings) {
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
                const status = plannedCategoriesCount >= target ? "completed" : "pending";
                await this.gamificationRepository.updateWeeklyMission(workspaceId, weekId, "consistency", {
                    progress: plannedCategoriesCount,
                    status,
                });
                if (status === "completed") {
                    await this.addXp(workspaceId, constData.rewardXp, "Missão Semanal de Consistência Concluída");
                }
            }

            if (eventType === "transaction") {
                const installments = await this.gamificationRepository.getInstallmentsInPeriod(
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
                    const date = inst.paidDate?.toDate
                        ? inst.paidDate.toDate()
                        : (inst.paidDate ? new Date(inst.paidDate) : (inst.dueDate?.toDate ? inst.dueDate.toDate() : new Date(inst.dueDate)));
                    const day = date.getDay();

                    if (inst.type === "expense") {
                        if (inst.category && inst.category.name.toLowerCase() === targetCategory.toLowerCase()) {
                            const amount = inst.paidAmount || inst.amount || 0;
                            expensesByDay[day] = (expensesByDay[day] || 0) + amount;
                        }
                    }
                }

                let daysWithinBudgetCount = 0;
                for (let d = 0; d < 7; d++) {
                    const spent = expensesByDay[d] || 0;
                    if (spent <= dailyLimit) {
                        daysWithinBudgetCount++;
                    }
                }

                const discData = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "discipline");
                if (discData && discData.status !== "completed") {
                    const target = discData.target || 5;
                    const status = daysWithinBudgetCount >= target ? "completed" : "pending";
                    await this.gamificationRepository.updateWeeklyMission(workspaceId, weekId, "discipline", {
                        progress: daysWithinBudgetCount,
                        status,
                    });
                    if (status === "completed") {
                        await this.addXp(workspaceId, discData.rewardXp, "Missão Semanal de Disciplina Concluída");
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
                    await this.gamificationRepository.updateWeeklyMission(workspaceId, weekId, "organization", {
                        progress: recDoc.totalTransactionsProcessed,
                        status: "completed",
                    });
                    await this.addXp(workspaceId, orgData.rewardXp, "Missão Semanal de Organização Concluída");
                }
            }
        }
    }

    async evaluateWeeklyMissionsCron(workspaceId: string): Promise<void> {
        const now = new Date();
        const startOfWeek = new Date(now.getTime() - (now.getDay() * 24 * 60 * 60 * 1000));
        startOfWeek.setHours(0, 0, 0, 0);

        const year = startOfWeek.getFullYear();
        const firstDayOfYear = new Date(year, 0, 1);
        const days = Math.floor((startOfWeek.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        const week = Math.floor(days / 7) + 1;
        const weekId = `${year}-W${String(week).padStart(2, "0")}`;

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

            const endOfWeek = new Date(startOfWeek.getTime() + (6 * 24 * 60 * 60 * 1000) + 23 * 3600 * 1000 + 59 * 60 * 1000);
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
    }

    async evaluateMonthlyMissionsCron(workspaceId: string): Promise<void> {
        const now = new Date();
        const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 15);
        const year = lastMonthDate.getFullYear();

        const snapshot = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            year,
            lastMonthDate.getMonth() + 1
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

        const prevMonthDate = new Date(now.getFullYear(), now.getMonth() - 2, 15);
        const prevYear = prevMonthDate.getFullYear();
        const prevMonthVal = prevMonthDate.getMonth() + 1;

        const prevSnapshot = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            prevYear,
            prevMonthVal
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

    async checkSimpleWorkspaceBadges(workspaceId: string, workspaceData: any): Promise<void> {
        const name: string = workspaceData.name || "";
        const type: string = workspaceData.type || "";
        const members: string[] = workspaceData.members || [];
        const createdAt: Date = workspaceData.createdAt?.toDate
            ? workspaceData.createdAt.toDate()
            : new Date(workspaceData.createdAt || Date.now());

        if (name.trim().length > 0 && type.trim().length > 0) {
            await this.unlockBadge(workspaceId, "profile_complete");
        }
        if (name.trim().length > 0) {
            await this.unlockBadge(workspaceId, "workspace_named");
        }
        if (members.length >= 2) {
            await this.unlockBadge(workspaceId, "second_member");
        }

        const oneYearAgo = new Date();
        oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
        if (createdAt <= oneYearAgo) {
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

        await this.unlockBadge(workspaceId, "first_goal");

        if (data.accountId || data.accountIdTarget) {
            await this.unlockBadge(workspaceId, "goal_linked_account");
        }

        if (data.targetDate) {
            const target = data.targetDate?.toDate ? data.targetDate.toDate() : new Date(data.targetDate);
            const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt || Date.now());
            const monthsDiff = (target.getFullYear() - createdAt.getFullYear()) * 12 + target.getMonth() - createdAt.getMonth();
            if (monthsDiff > 12) {
                await this.unlockBadge(workspaceId, "long_term_goal");
            }
        }

        const allGoals = await this.gamificationRepository.getGoals(workspaceId);
        let activeGoals = 0;
        for (const g of allGoals) {
            if (g.status === "active") {
                activeGoals++;
            }
        }
        if (activeGoals >= 2) {
            await this.unlockBadge(workspaceId, "two_active_goals");
        }
        if (activeGoals >= 5) {
            await this.unlockBadge(workspaceId, "five_active_goals");
        }

        const current = data.currentAmount || 0;
        const target = data.targetAmount || 1;
        const pct = current / target;

        if (current > 0) {
            await this.unlockBadge(workspaceId, "goal_deposit");
            await this.unlockBadge(workspaceId, "savings_start");
        }
        if (pct >= 0.5) {
            await this.unlockBadge(workspaceId, "goal_halfway");
        }
        if (pct >= 0.75) {
            await this.unlockBadge(workspaceId, "goal_75pct");
        }

        const isCompleted = data.status === "completed" || pct >= 1;
        if (isCompleted) {
            const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : new Date(data.createdAt || Date.now());
            const completedAt = data.completedAt?.toDate ? data.completedAt.toDate() : new Date();
            const daysDiff = (completedAt.getTime() - createdAt.getTime()) / 86400000;
            if (daysDiff < 30) {
                await this.unlockBadge(workspaceId, "short_term_goal");
            }

            if (data.targetDate) {
                const targetDate = data.targetDate?.toDate ? data.targetDate.toDate() : new Date(data.targetDate);
                if (completedAt <= targetDate) {
                    await this.unlockBadge(workspaceId, "goal_under_deadline");
                }
            }

            if (data.type === "payDebt") {
                await this.unlockBadge(workspaceId, "goal_debt_paid");
            }
        }
    }

    async checkSimpleTransactionBadges(workspaceId: string, installmentData: any): Promise<void> {
        const type: string = installmentData.type || "";
        const amount: number = Math.abs(installmentData.referenceAmount || installmentData.amount || 0);

        if (type === "income") {
            await this.unlockBadge(workspaceId, "first_income");
        }
        if (type === "expense") {
            await this.unlockBadge(workspaceId, "first_expense");
        }
        if (type === "transfer") {
            await this.unlockBadge(workspaceId, "first_transfer");
        }

        if (amount > 0 && amount % 1 === 0) {
            await this.unlockBadge(workspaceId, "round_number");
        }

        if (amount >= 1000) {
            await this.unlockBadge(workspaceId, "big_transaction");
        }

        if (type === "income" && amount > 0) {
            await this.unlockBadge(workspaceId, "income_registered");
        }

        const settledSnap = await this.gamificationRepository.getPaidInstallments(workspaceId);
        const settledCount = settledSnap.length;

        if (settledCount >= 5) {
            await this.unlockBadge(workspaceId, "five_transactions");
        }
        if (settledCount >= 20) {
            await this.unlockBadge(workspaceId, "twenty_transactions");
        }
        if (settledCount >= 50) {
            await this.unlockBadge(workspaceId, "fifty_transactions");
        }
        if (settledCount >= 100) {
            await this.unlockBadge(workspaceId, "hundred_transactions");
        }

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

        const paidDates = new Set<string>();
        for (const d of settledSnap) {
            const pd = d.paidDate?.toDate
                ? d.paidDate.toDate()
                : (d.paidDate ? new Date(d.paidDate) : null);
            if (pd) {
                paidDates.add(`${pd.getFullYear()}-${pd.getMonth()}`);
            }
        }
        if (paidDates.size >= 1) {
            await this.unlockBadge(workspaceId, "first_month");
        }
        if (paidDates.size >= 2) {
            await this.unlockBadge(workspaceId, "two_months_active");
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
        const year = now.getFullYear();
        const month = now.getMonth() + 1;

        const snap = await this.gamificationRepository.getPeriodSummaries(workspaceId, year, month);

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
                activeDays.add(`${pd.getFullYear()}-${pd.getMonth()}-${pd.getDate()}`);
            }
        }
        if (activeDays.size >= 7) {
            await this.unlockBadge(workspaceId, "week_complete");
        }
    }
}