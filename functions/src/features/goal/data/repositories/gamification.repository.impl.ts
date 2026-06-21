import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { IGamificationRepository } from "../../domain/repositories/gamification.repository";

export function calculateLevel(xp: number): number {
    if (xp <= 0) {
        return 1;
    }
    return Math.floor(Math.log2(xp / 300 + 1)) + 1;
}

export class GamificationRepositoryImpl implements IGamificationRepository {
    async getWorkspaceById(workspaceId: string): Promise<any | null> {
        const doc = await admin.firestore().collection("workspaces").doc(workspaceId).get();
        if (!doc.exists) {
            return null;
        }
        return { id: doc.id, ...doc.data() };
    }

    async addXp(workspaceId: string, amount: number, reason: string): Promise<void> {
        if (amount === 0) {
            return;
        }
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);

        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) {
                return;
            }

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

    async unlockBadge(
        workspaceId: string,
        badgeId: string,
        xpReward: number,
        badgeName: string
    ): Promise<boolean> {
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        let unlocked = false;

        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) {
                return;
            }

            const data = doc.data()!;
            const unlockedBadges = data.unlockedBadges || {};

            if (unlockedBadges[badgeId]) {
                return;
            }

            unlockedBadges[badgeId] = new Date().toISOString();
            transaction.update(workspaceRef, { unlockedBadges });
            unlocked = true;
        });

        if (unlocked) {
            logger.info(`[GamificationService] Badge ${badgeId} unlocked for Workspace ${workspaceId}!`);
            await this.addXp(workspaceId, xpReward, `Conquista desbloqueada: ${badgeName}`);
            return true;
        }

        return false;
    }

    async getAccountsCount(workspaceId: string): Promise<number> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/accounts`)
            .where("isDeleted", "==", false)
            .get();
        return snapshot.size;
    }

    async hasPaidTransaction(workspaceId: string): Promise<boolean> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .limit(1)
            .get();
        return snapshot.size >= 1;
    }

    async getCategoryPlannings(workspaceId: string): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/category_plannings`)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getCompletedReconciliationsCount(workspaceId: string, limit?: number): Promise<number> {
        let query = admin.firestore()
            .collection(`workspaces/${workspaceId}/reconciliations`)
            .where("status", "==", "completed");
        if (limit !== undefined) {
            query = query.limit(limit);
        }
        const snapshot = await query.get();
        return snapshot.size;
    }

    async getGoals(workspaceId: string): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/goals`)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getPaidInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .where("paidDate", ">=", start)
            .where("paidDate", "<=", end)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getWeeklyMission(workspaceId: string, weekId: string, type: string): Promise<any | null> {
        const doc = await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .get();
        if (!doc.exists) {
            return null;
        }
        return doc.data();
    }

    async createWeeklyMission(workspaceId: string, weekId: string, type: string, data: any): Promise<void> {
        await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .set(data);
    }

    async updateWeeklyMission(workspaceId: string, weekId: string, type: string, data: any): Promise<void> {
        await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .update(data);
    }

    async getInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("dueDate", ">=", start)
            .where("dueDate", "<=", end)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getWeeklyMissionsByWeek(workspaceId: string, weekId: string): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .where("weekId", "==", weekId)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async updateWorkspaceStreaks(workspaceId: string, streaks: number): Promise<void> {
        await admin.firestore()
            .collection("workspaces")
            .doc(workspaceId)
            .update({ weeklyStreaks: streaks });
    }

    async getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/period_summaries`)
            .where("year", "==", year)
            .where("month", "==", month)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getCategoriesCount(workspaceId: string): Promise<number> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/categories`)
            .get();
        return snapshot.size;
    }

    async getPaidInstallments(workspaceId: string): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }

    async getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .where("paidDate", ">=", since)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.data();
        });
    }
}
