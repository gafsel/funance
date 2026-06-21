import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { CategoryType } from "../../../workspace/domain/models/category.model";
import { IAIRepository } from "../../../../core/services/ai.service";

export function calculateLevel(xp: number): number {
    if (xp <= 0) return 1;
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
};

export class GamificationService {
    constructor(private aiRepository?: IAIRepository) { }

    async addXp(workspaceId: string, amount: number, reason: string): Promise<void> {
        if (amount === 0) return;
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);

        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) return;

            const data = doc.data()!;
            const currentXp = data.xp || 0;
            const currentLevel = data.level || 1;

            const newXp = Math.max(0, currentXp + amount);
            const newLevel = calculateLevel(newXp);

            const updateData: any = {
                xp: newXp,
                level: newLevel,
            };

            if (newLevel > currentLevel) {
                updateData.lastLevelUpAt = admin.firestore.FieldValue.serverTimestamp();
                logger.info(`[GamificationService] Workspace ${workspaceId} UP to Level ${newLevel}!`);
            }

            transaction.update(workspaceRef, updateData);
            logger.info(`[GamificationService] Workspace ${workspaceId}: Added ${amount} XP. Reason: ${reason}. Total XP: ${newXp}.`);
        });
    }

    async unlockBadge(workspaceId: string, badgeId: string): Promise<boolean> {
        const badge = BADGES[badgeId];
        if (!badge) {
            logger.error(`[GamificationService] Badge ${badgeId} not configured.`);
            return false;
        }

        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        let unlocked = false;

        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) return;

            const data = doc.data()!;
            const unlockedBadges = data.unlockedBadges || {};

            if (unlockedBadges[badgeId]) {
                // Already unlocked
                return;
            }

            unlockedBadges[badgeId] = new Date().toISOString();
            transaction.update(workspaceRef, { unlockedBadges });
            unlocked = true;
        });

        if (unlocked) {
            logger.info(`[GamificationService] Badge ${badgeId} unlocked for Workspace ${workspaceId}!`);
            await this.addXp(workspaceId, badge.xpReward, `Conquista desbloqueada: ${badge.name}`);
            return true;
        }

        return false;
    }

    // Checking Rules

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
        const db = admin.firestore();
        const snapshot = await db.collection(`workspaces/${workspaceId}/accounts`)
            .where("isDeleted", "==", false)
            .get();

        if (snapshot.size >= 1) {
            await this.unlockBadge(workspaceId, "first_account");
        }
    }

    async checkFirstTransaction(workspaceId: string): Promise<void> {
        const db = admin.firestore();
        const snapshot = await db.collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .limit(1)
            .get();

        if (snapshot.size >= 1) {
            await this.unlockBadge(workspaceId, "first_transaction");
        }
    }

    async checkPlanner(workspaceId: string): Promise<void> {
        const db = admin.firestore();
        const snapshot = await db.collection(`workspaces/${workspaceId}/category_plannings`)
            .get();

        let count = 0;
        snapshot.forEach((doc) => {
            const data = doc.data();
            if (data.amount > 0) count++;
        });

        if (count >= 5) {
            await this.unlockBadge(workspaceId, "planner");
        }
    }

    async checkGoldenRule(workspaceId: string): Promise<void> {
        const db = admin.firestore();
        const snapshot = await db.collection(`workspaces/${workspaceId}/category_plannings`)
            .get();

        let hasEssential = false;
        let hasComfort = false;
        let hasInvestment = false;

        snapshot.forEach((doc) => {
            const data = doc.data();
            if (data.amount > 0 && data.category) {
                const allocation = data.category.allocation;
                if (allocation === "essential") hasEssential = true;
                if (allocation === "comfort") hasComfort = true;
                if (allocation === "investment") hasInvestment = true;
            }
        });

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
        if (confirmedMatchesCount >= 1) {
            await this.unlockBadge(workspaceId, "reconcile_junior");
        }

        if (totalTransactionsProcessed >= 10) {
            await this.unlockBadge(workspaceId, "cash_detective");
        }

        if (createdTransactionsCount === 0 && totalTransactionsProcessed > 0) {
            await this.unlockBadge(workspaceId, "zero_friction");
        }

        const db = admin.firestore();
        const snapshot = await db.collection(`workspaces/${workspaceId}/reconciliations`)
            .where("status", "==", "completed")
            .limit(10)
            .get();

        if (snapshot.size >= 10) {
            await this.unlockBadge(workspaceId, "reconcile_master");
        }
    }

    async checkGoalBadges(workspaceId: string, goalDoc: any): Promise<void> {
        const db = admin.firestore();
        const data = goalDoc;
        const isCompleted = data.status === "completed" || (data.currentAmount >= data.targetAmount);

        if (isCompleted) {
            // savings_seed: first goal completed
            const completedSnapshot = await db.collection(`workspaces/${workspaceId}/goals`)
                .get();

            let completedCount = 0;
            completedSnapshot.forEach((doc) => {
                const g = doc.data();
                if (g.status === "completed" || (g.currentAmount >= g.targetAmount)) {
                    completedCount++;
                }
            });

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
        const db = admin.firestore();
        const startOfMonth = new Date(paidDate.getFullYear(), paidDate.getMonth(), 1);
        const endOfMonth = new Date(paidDate.getFullYear(), paidDate.getMonth() + 1, 0, 23, 59, 59);

        const snapshot = await db.collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .where("paidDate", ">=", startOfMonth)
            .where("paidDate", "<=", endOfMonth)
            .get();

        const userIds = new Set<string>();
        snapshot.forEach((doc) => {
            const data = doc.data();
            if (data.createdBy) userIds.add(data.createdBy);
            if (data.paidBy) userIds.add(data.paidBy);
        });

        if (userIds.size >= 2) {
            await this.unlockBadge(workspaceId, "dynamic_duo");
        }
    }

    // Weekly Missions Progress Evaluation
    async updateWeeklyMissionsProgress(
        workspaceId: string,
        eventType: "transaction" | "reconciliation" | "planning",
        eventData: any
    ): Promise<void> {
        const db = admin.firestore();
        const now = new Date();
        const startOfWeek = new Date(now.getTime() - (now.getDay() * 24 * 60 * 60 * 1000));
        startOfWeek.setHours(0, 0, 0, 0);
        const endOfWeek = new Date(startOfWeek.getTime() + (6 * 24 * 60 * 60 * 1000) + 23 * 3600 * 1000 + 59 * 60 * 1000 + 59 * 1000);

        const year = startOfWeek.getFullYear();
        const firstDayOfYear = new Date(year, 0, 1);
        const days = Math.floor((startOfWeek.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        const week = Math.floor(days / 7) + 1;
        const weekId = `${year}-W${String(week).padStart(2, "0")}`;

        const missionsCollectionRef = db.collection(`workspaces/${workspaceId}/weekly_missions`);

        const consistencyDocRef = missionsCollectionRef.doc(`${weekId}_consistency`);
        const disciplineDocRef = missionsCollectionRef.doc(`${weekId}_discipline`);
        const organizationDocRef = missionsCollectionRef.doc(`${weekId}_organization`);

        const consistencyDoc = await consistencyDocRef.get();
        if (!consistencyDoc.exists) {
            logger.info(`[GamificationService] Generating AI weekly missions for workspace ${workspaceId}, week ${weekId}`);

            // Retrieve workspace info
            let workspaceType = "personal";
            try {
                const workspaceDoc = await db.collection("workspaces").doc(workspaceId).get();
                if (workspaceDoc.exists) {
                    workspaceType = workspaceDoc.data()?.type || "personal";
                }
            }
            catch (e) {
                logger.error("[GamificationService] Error fetching workspace type:", e);
            }

            // Retrieve category plannings for categories context
            const categoriesList: string[] = [];
            let maxCategory = "Alimentação";
            let maxAmount = 0;
            try {
                const categoryPlannings = await db.collection(`workspaces/${workspaceId}/category_plannings`).get();
                categoryPlannings.forEach(pDoc => {
                    const p = pDoc.data();
                    if (p.category && p.category.name) {
                        categoriesList.push(p.category.name);
                        if (p.amount > maxAmount) {
                            maxAmount = p.amount;
                            maxCategory = p.category.name;
                        }
                    }
                });
            }
            catch (e) {
                logger.error("[GamificationService] Error fetching category plannings:", e);
            }

            // Retrieve active goals context
            const goalsList: string[] = [];
            try {
                const goalsSnapshot = await db.collection(`workspaces/${workspaceId}/goals`).get();
                goalsSnapshot.forEach(gDoc => {
                    const g = gDoc.data();
                    if (g.status === "active" && g.name) {
                        goalsList.push(g.name);
                    }
                });
            }
            catch (e) {
                logger.error("[GamificationService] Error fetching goals:", e);
            }

            // Generate weekly missions using AI
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

            const disciplineName = aiMissions?.discipline?.name || "Equipe mantém a categoria ${maxCategory} dentro do orçamento planejado por 5 dias.";
            const disciplineTarget = aiMissions?.discipline?.target || 5;

            const organizationName = aiMissions?.organization?.name || "Fazer a conciliação bancária completa de um extrato contendo pelo menos 5 itens.";
            const organizationTarget = aiMissions?.organization?.target || 5;

            await consistencyDocRef.set({
                id: "consistency",
                name: consistencyName,
                type: "consistency",
                status: "pending",
                rewardXp: 150,
                progress: 0,
                target: consistencyTarget,
                weekId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            await disciplineDocRef.set({
                id: "discipline",
                name: disciplineName,
                type: "discipline",
                status: "pending",
                rewardXp: 250,
                progress: 0,
                target: disciplineTarget,
                weekId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            await organizationDocRef.set({
                id: "organization",
                name: organizationName,
                type: "organization",
                status: "pending",
                rewardXp: 200,
                progress: 0,
                target: organizationTarget,
                weekId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        // --- Recalculate/Evaluate consistency & discipline ---
        if (eventType === "transaction" || eventType === "planning") {
            const categoryPlannings = await db.collection(`workspaces/${workspaceId}/category_plannings`).get();

            // 1. Evaluate consistency (Count planned categories)
            let plannedCategoriesCount = 0;
            let targetCategory = "Alimentação";
            let maxAmount = 0;

            categoryPlannings.forEach(pDoc => {
                const p = pDoc.data();
                if (p.amount > 0) {
                    plannedCategoriesCount++;
                }
                if (p.category && p.category.name && p.amount > maxAmount) {
                    maxAmount = p.amount;
                    targetCategory = p.category.name;
                }
            });

            const constDoc = await consistencyDocRef.get();
            const constData = constDoc.data()!;
            if (constData.status !== "completed") {
                const target = constData.target || 3;
                const status = plannedCategoriesCount >= target ? "completed" : "pending";
                await consistencyDocRef.update({ progress: plannedCategoriesCount, status });
                if (status === "completed") {
                    await this.addXp(workspaceId, constData.rewardXp, "Missão Semanal de Consistência Concluída");
                }
            }

            // 2. Evaluate discipline (Check daily expenses on targetCategory)
            if (eventType === "transaction") {
                const installments = await db.collection(`workspaces/${workspaceId}/installments`)
                    .where("dueDate", ">=", startOfWeek)
                    .where("dueDate", "<=", endOfWeek)
                    .get();

                const weeklyLimit = maxAmount || 250.0;
                const dailyLimit = weeklyLimit / 7;
                const expensesByDay: Record<number, number> = {};

                installments.forEach(instDoc => {
                    const inst = instDoc.data();
                    if (inst.status === "removed") return;
                    const date = inst.paidDate?.toDate ? inst.paidDate.toDate() : (inst.paidDate ? new Date(inst.paidDate) : (inst.dueDate?.toDate ? inst.dueDate.toDate() : new Date(inst.dueDate)));
                    const day = date.getDay();

                    if (inst.type === "expense") {
                        if (inst.category && inst.category.name.toLowerCase() === targetCategory.toLowerCase()) {
                            const amount = inst.paidAmount || inst.amount || 0;
                            expensesByDay[day] = (expensesByDay[day] || 0) + amount;
                        }
                    }
                });

                let daysWithinBudgetCount = 0;
                for (let d = 0; d < 7; d++) {
                    const spent = expensesByDay[d] || 0;
                    if (spent <= dailyLimit) {
                        daysWithinBudgetCount++;
                    }
                }

                const discDoc = await disciplineDocRef.get();
                const discData = discDoc.data()!;
                if (discData.status !== "completed") {
                    const target = discData.target || 5;
                    const status = daysWithinBudgetCount >= target ? "completed" : "pending";
                    await disciplineDocRef.update({ progress: daysWithinBudgetCount, status });
                    if (status === "completed") {
                        await this.addXp(workspaceId, discData.rewardXp, "Missão Semanal de Disciplina Concluída");
                    }
                }
            }
        }
        else if (eventType === "reconciliation") {
            const recDoc = eventData;
            const orgDoc = await organizationDocRef.get();
            if (orgDoc.exists) {
                const orgData = orgDoc.data()!;
                if (orgData.status !== "completed") {
                    const target = orgData.target || 5;
                    if (recDoc.status === "completed" && recDoc.totalTransactionsProcessed >= target) {
                        await organizationDocRef.update({
                            progress: recDoc.totalTransactionsProcessed,
                            status: "completed"
                        });
                        await this.addXp(workspaceId, orgData.rewardXp, "Missão Semanal de Organização Concluída");
                    }
                }
            }
        }
    }

    // Cron tasks
    async evaluateWeeklyMissionsCron(workspaceId: string): Promise<void> {
        const db = admin.firestore();
        const now = new Date();
        const startOfWeek = new Date(now.getTime() - (now.getDay() * 24 * 60 * 60 * 1000));
        startOfWeek.setHours(0, 0, 0, 0);

        const year = startOfWeek.getFullYear();
        const firstDayOfYear = new Date(year, 0, 1);
        const days = Math.floor((startOfWeek.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        const week = Math.floor(days / 7) + 1;
        const weekId = `${year}-W${String(week).padStart(2, "0")}`;

        const missionsCollectionRef = db.collection(`workspaces/${workspaceId}/weekly_missions`);
        const snapshot = await missionsCollectionRef.where("weekId", "==", weekId).get();

        let allCompleted = true;
        let count = 0;
        snapshot.forEach((doc) => {
            count++;
            const mission = doc.data();
            if (mission.status !== "completed") {
                allCompleted = false;
            }
        });

        // If no missions exist, it is not all completed
        if (count === 0) allCompleted = false;

        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        const workspaceDoc = await workspaceRef.get();
        if (!workspaceDoc.exists) return;
        const workspaceData = workspaceDoc.data()!;

        let currentStreaks = workspaceData.weeklyStreaks || 0;

        if (allCompleted) {
            currentStreaks++;
            await workspaceRef.update({ weeklyStreaks: currentStreaks });

            if (currentStreaks >= 4) {
                await this.unlockBadge(workspaceId, "iron_consistency");
            }

            // Check financial_synapsis: mission completed and all active members recorded at least 1 transaction
            const endOfWeek = new Date(startOfWeek.getTime() + (6 * 24 * 60 * 60 * 1000) + 23 * 3600 * 1000 + 59 * 60 * 1000);
            const activeMembers = workspaceData.members || [];

            const installments = await db.collection(`workspaces/${workspaceId}/installments`)
                .where("status", "in", ["paid", "settled"])
                .where("paidDate", ">=", startOfWeek)
                .where("paidDate", "<=", endOfWeek)
                .get();

            const transactingUsers = new Set<string>();
            installments.forEach((doc) => {
                const inst = doc.data();
                if (inst.createdBy) transactingUsers.add(inst.createdBy);
                if (inst.paidBy) transactingUsers.add(inst.paidBy);
            });

            const allMembersTransacted = activeMembers.every((mId: string) => transactingUsers.has(mId));
            if (allMembersTransacted && activeMembers.length > 0) {
                await this.unlockBadge(workspaceId, "financial_synapsis");
            }
        }
        else {
            // Reset streaks if not completed
            await workspaceRef.update({ weeklyStreaks: 0 });
        }
    }

    async evaluateMonthlyMissionsCron(workspaceId: string): Promise<void> {
        const db = admin.firestore();
        const now = new Date();
        // We evaluate for last month (month M-1)
        const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 15);
        const year = lastMonthDate.getFullYear();

        // under_control
        // Period summaries are stored in workspaces/{wid}/period_summaries/
        // Document ID format: YYYY-MM-categoryId (checked in period_summary_repository_impl.dart)
        const summariesRef = db.collection(`workspaces/${workspaceId}/period_summaries`);
        const snapshot = await summariesRef
            .where("year", "==", year)
            .where("month", "==", lastMonthDate.getMonth() + 1)
            .get();

        let underControl = true;
        let summaryCount = 0;

        let totalComfortExpenses = 0;
        let totalInvestmentSavings = 0;
        let totalIncomes = 0;

        snapshot.forEach((doc) => {
            summaryCount++;
            const summary = doc.data();
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
        });

        if (underControl && summaryCount > 0) {
            await this.unlockBadge(workspaceId, "under_control");
        }

        // future_focus
        if (totalIncomes > 0 && (totalInvestmentSavings / totalIncomes) >= 0.20) {
            await this.unlockBadge(workspaceId, "future_focus");
        }

        // cost_cutter
        // We compare Comfort expenses in last month M-1 to M-2
        const prevMonthDate = new Date(now.getFullYear(), now.getMonth() - 2, 15);
        const prevYear = prevMonthDate.getFullYear();
        const prevMonthVal = prevMonthDate.getMonth() + 1;

        const prevSnapshot = await summariesRef
            .where("year", "==", prevYear)
            .where("month", "==", prevMonthVal)
            .get();

        let prevComfortExpenses = 0;
        prevSnapshot.forEach((doc) => {
            const summary = doc.data();
            if (summary.category && summary.category.type === CategoryType.expense && summary.category.allocation === "comfort") {
                prevComfortExpenses += (summary.actualAmount || 0);
            }
        });

        if (prevComfortExpenses > 0 && totalComfortExpenses <= 0.8 * prevComfortExpenses) {
            await this.unlockBadge(workspaceId, "cost_cutter");
        }
    }
}
