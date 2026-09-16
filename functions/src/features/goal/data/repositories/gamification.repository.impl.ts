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

        // Badge + XP na MESMA transação: se qualquer parte falhar, nada é
        // persistido (antes, o addXp fora da transação podia se perder).
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

            const currentXp = data.xp || 0;
            const currentLevel = data.level || 1;
            const newXp = Math.max(0, currentXp + xpReward);
            const newLevel = calculateLevel(newXp);

            const updateData: any = {
                unlockedBadges,
                xp: newXp,
                level: newLevel,
            };
            if (newLevel > currentLevel) {
                updateData.lastLevelUpAt = admin.firestore.FieldValue.serverTimestamp();
            }

            transaction.update(workspaceRef, updateData);
            unlocked = true;
        });

        if (unlocked) {
            logger.info(
                `[GamificationService] Badge ${badgeId} unlocked for Workspace ${workspaceId} (+${xpReward} XP: ${badgeName}).`
            );
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
        try {
            // create() falha se o doc já existir — evita que escritas paralelas
            // sobrescrevam o progresso de uma missão já criada.
            await admin.firestore()
                .collection(`workspaces/${workspaceId}/weekly_missions`)
                .doc(`${weekId}_${type}`)
                .create(data);
        }
        catch (e: any) {
            // gRPC 6 = ALREADY_EXISTS
            if (e?.code === 6) {
                logger.info(`[GamificationRepository] Weekly mission ${weekId}_${type} already exists for ${workspaceId}. Skipping create.`);
                return;
            }
            throw e;
        }
    }

    async updateWeeklyMission(workspaceId: string, weekId: string, type: string, data: any): Promise<void> {
        await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .update(data);
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

    async getAllWorkspaceIds(): Promise<string[]> {
        // select() sem campos: retorna apenas as referências (payload mínimo).
        const snapshot = await admin.firestore()
            .collection("workspaces")
            .select()
            .get();
        return snapshot.docs.map((doc) => {
            return doc.id;
        });
    }

    async completeMissionAndAwardXp(
        workspaceId: string,
        weekId: string,
        type: string,
        progress: number,
        rewardXp: number,
        reason: string
    ): Promise<boolean> {
        const db = admin.firestore();
        const missionRef = db
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`);
        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        let completed = false;

        await db.runTransaction(async (transaction) => {
            const missionDoc = await transaction.get(missionRef);
            const workspaceDoc = await transaction.get(workspaceRef);

            if (!missionDoc.exists || !workspaceDoc.exists) {
                return;
            }
            if (missionDoc.data()!.status === "completed") {
                // Já concluída (possivelmente por uma escrita paralela):
                // não concede XP de novo.
                return;
            }

            const data = workspaceDoc.data()!;
            const currentXp = data.xp || 0;
            const currentLevel = data.level || 1;
            const newXp = Math.max(0, currentXp + rewardXp);
            const newLevel = calculateLevel(newXp);

            transaction.update(missionRef, {
                progress,
                status: "completed",
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            const updateData: any = { xp: newXp, level: newLevel };
            if (newLevel > currentLevel) {
                updateData.lastLevelUpAt = admin.firestore.FieldValue.serverTimestamp();
            }
            transaction.update(workspaceRef, updateData);
            completed = true;
        });

        if (completed) {
            logger.info(`[GamificationRepository] Mission ${weekId}_${type} completed for ${workspaceId} (+${rewardXp} XP: ${reason}).`);
        }
        return completed;
    }

    async getPaidInstallmentsCount(workspaceId: string): Promise<number> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .count()
            .get();
        return snapshot.data().count;
    }

    async getCompletedMissionsCount(workspaceId: string): Promise<number> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .where("status", "==", "completed")
            .count()
            .get();
        return snapshot.data().count;
    }

    async getCreditCardAccountIds(workspaceId: string): Promise<string[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/accounts`)
            .where("runtimeType", "==", "creditCard")
            .where("isDeleted", "==", false)
            .get();
        return snapshot.docs.map((doc) => {
            return doc.id;
        });
    }

    async hasPendingInstallmentsForAccounts(
        workspaceId: string,
        accountIds: string[],
        start: Date,
        end: Date
    ): Promise<boolean> {
        if (accountIds.length === 0) {
            return false;
        }
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "==", "pending")
            .where("dueDate", ">=", start)
            .where("dueDate", "<=", end)
            .get();

        const idSet = new Set(accountIds);
        for (const doc of snapshot.docs) {
            const ids: string[] = doc.data().accountIds || [];
            if (ids.some((id) => idSet.has(id))) {
                return true;
            }
        }
        return false;
    }
}
