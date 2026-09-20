import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
    AutomaticTransactionRow,
    GamificationGoal,
    GamificationInstallment,
    GamificationWorkspace,
    IGamificationRepository,
    PeriodSummaryRow,
    WeeklyMissionDocument,
    WeeklyMissionType,
    WeeklyMissionUpdate,
    WeeklyMissionWrite,
    WeeklySummaryRow,
    WorkspaceStreaks,
    XpOnceGroup,
    readWorkspaceStreaks,
} from "../../domain/repositories/gamification.repository";
import { MissionCapacity } from "../../domain/models/mission_catalog";
import { CategoryPlanningModel, toPeriodSummaryDocument } from "../../../finance/domain/models/finance.models";
import { calculateLevel } from "../../domain/services/gamification.service";
import { CategoryModel, isSystemCategory } from "../../../workspace/domain/models/category.model";
import { stripUndefined } from "../../../../core/utils/firestore.utils";
import { BadgeAudience, appliesToAudience, resolveAudience } from "../../domain/models/audience.model";
import { MonthlyVillagersReport } from "../../domain/models/monthly_report.model";

/** Subcoleção do retrato mensal da aldeia (HUD mensal). */
export const MONTHLY_REPORTS_COLLECTION = "monthly_reports";

export class GamificationRepositoryImpl implements IGamificationRepository {
    async getWorkspaceById(workspaceId: string): Promise<GamificationWorkspace | null> {
        const doc = await admin.firestore().collection("workspaces").doc(workspaceId).get();
        if (!doc.exists) {
            return null;
        }
        return { ...doc.data(), id: doc.id } as GamificationWorkspace;
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

            const updateData: Record<string, unknown> = {
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
        badgeName: string,
        audience: BadgeAudience
    ): Promise<boolean> {
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        let unlocked = false;

        // Badge + XP na MESMA transação: se qualquer parte falhar, nada é
        // persistido (antes, o addXp fora da transação podia se perder).
        await db.runTransaction(async (transaction) => {
            // O flag é RESETADO a cada tentativa. `runTransaction` reexecuta
            // este callback quando há disputa pelo documento, e uma tentativa
            // que só sai cedo (porque a concorrente já concedeu) não escreve
            // nada — sem o reset, o `true` da tentativa anterior sobreviveria e
            // o chamador acharia que concedeu duas vezes.
            unlocked = false;

            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) {
                return;
            }

            const data = doc.data()!;

            // O recorte por tipo de workspace mora AQUI, e não no serviço,
            // porque esta transação já leu o documento: o filtro sai de graça.
            // No serviço, cada checagem de badge custaria uma leitura extra do
            // workspace — e são dezenas por evento.
            if (!appliesToAudience(audience, resolveAudience(data.type))) {
                return;
            }

            const unlockedBadges: Record<string, string> = data.unlockedBadges || {};

            if (unlockedBadges[badgeId]) {
                return;
            }

            unlockedBadges[badgeId] = new Date().toISOString();

            const currentXp = data.xp || 0;
            const currentLevel = data.level || 1;
            const newXp = Math.max(0, currentXp + xpReward);
            const newLevel = calculateLevel(newXp);

            const updateData: Record<string, unknown> = {
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

    async hasPaidInstallmentSince(workspaceId: string, since: Date): Promise<boolean> {
        // MESMA consulta do coaching proativo
        // (`FinanceRepositoryImpl.hasPaidInstallmentSince`): só a faixa de
        // `paidDate`, sem filtro de status, e `limit(1)`. Uma parcela pendente
        // tem `paidDate: null`, e null fica fora de uma faixa de Timestamp —
        // a consulta não precisa do `status in [...]`, que exigiria índice
        // composto para devolver a MESMA resposta.
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("paidDate", ">=", admin.firestore.Timestamp.fromDate(since))
            .limit(1)
            .get();
        return !snapshot.empty;
    }

    async getMissionCapacity(
        workspaceId: string,
        automaticTransactionsSince: string
    ): Promise<MissionCapacity> {
        const db = admin.firestore();

        // Três consultas com `limit(1)`: a pergunta é sempre "existe ao menos
        // um?". Contar custaria uma leitura por documento para responder algo
        // que a peneira nem usa.
        const [cards, reconciliations, automatics] = await Promise.all([
            db.collection(`workspaces/${workspaceId}/accounts`)
                .where("runtimeType", "==", "creditCard")
                .where("isDeleted", "==", false)
                .limit(1)
                .get(),
            db.collection(`workspaces/${workspaceId}/reconciliations`)
                .where("status", "==", "completed")
                .limit(1)
                .get(),
            // `date` é string de relógio local (ver a interface do
            // repositório): faixa + `orderBy` no MESMO campo, resolvido pelo
            // índice de campo único que já existe.
            db.collection(`workspaces/${workspaceId}/automatic_transactions`)
                .where("date", ">=", automaticTransactionsSince)
                .orderBy("date")
                .limit(1)
                .get(),
        ]);

        return {
            hasCreditCardAccount: !cards.empty,
            hasReconciledStatementEver: !reconciliations.empty,
            hasRecentAutomaticTransaction: !automatics.empty,
        };
    }

    async getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]> {
        // A coleção real é `category_planning` (singular) — é o nome usado pelo
        // cliente, pelo category_planning_handler, pelas rules e pelos índices.
        // Enquanto isto lia `category_plannings`, os badges planner,
        // golden_rule, first_planning e planning_month nunca disparavam e a
        // missão semanal de consistência sempre via zero planejamentos.
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/category_planning`)
            .get();
        return snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as CategoryPlanningModel));
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

    async getGoals(workspaceId: string): Promise<GamificationGoal[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/goals`)
            .get();
        return snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as GamificationGoal));
    }

    async getPaidInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<GamificationInstallment[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .where("paidDate", ">=", start)
            .where("paidDate", "<=", end)
            .get();
        return snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as GamificationInstallment));
    }

    async getWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType): Promise<WeeklyMissionDocument | null> {
        const doc = await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .get();
        if (!doc.exists) {
            return null;
        }
        return doc.data() as WeeklyMissionDocument;
    }

    async createWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType, data: WeeklyMissionWrite): Promise<void> {
        try {
            // create() falha se o doc já existir — evita que escritas paralelas
            // sobrescrevam o progresso de uma missão já criada.
            await admin.firestore()
                .collection(`workspaces/${workspaceId}/weekly_missions`)
                .doc(`${weekId}_${type}`)
                .create(stripUndefined(data));
        }
        catch (e: unknown) {
            // gRPC 6 = ALREADY_EXISTS
            if ((e as { code?: number } | null)?.code === 6) {
                logger.info(`[GamificationRepository] Weekly mission ${weekId}_${type} already exists for ${workspaceId}. Skipping create.`);
                return;
            }
            throw e;
        }
    }

    async updateWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType, data: WeeklyMissionUpdate): Promise<void> {
        await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .doc(`${weekId}_${type}`)
            .update(stripUndefined(data));
    }

    async getWeeklyMissionsByWeek(workspaceId: string, weekId: string): Promise<WeeklyMissionDocument[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/weekly_missions`)
            .where("weekId", "==", weekId)
            .get();
        return snapshot.docs.map((doc) => doc.data() as WeeklyMissionDocument);
    }

    async updateWorkspaceStreaks(workspaceId: string, streaks: Partial<WorkspaceStreaks>): Promise<void> {
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);

        // DOIS campos, UMA transação:
        //
        //  - `streaks` é o mapa novo (`{missions, plan}`), que o app novo lê;
        //  - `weeklyStreaks` continua sendo o NÚMERO de missões, porque o app
        //    instalado o desserializa como `num?` e trocar o tipo faria toda
        //    build em campo lançar `TypeError` ao abrir o workspace. Este cron
        //    escreve em TODOS os workspaces: a quebra chegaria a todo mundo na
        //    segunda-feira seguinte ao deploy, sem ação do usuário.
        //
        // A transação é o que mantém os dois consistentes e o que impede que o
        // cron de missões e o de plano — que rodam na mesma execução — se
        // sobrescrevam.
        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) {
                return;
            }

            const current = readWorkspaceStreaks(doc.data()!);
            const next: WorkspaceStreaks = {
                missions: streaks.missions ?? current.missions,
                plan: streaks.plan ?? current.plan,
            };

            transaction.update(workspaceRef, {
                streaks: next,
                // INVARIANTE: weeklyStreaks === streaks.missions.
                weeklyStreaks: next.missions,
            });
        });
    }

    async getWeeklySummaryRows(workspaceId: string, weekId: string): Promise<WeeklySummaryRow[]> {
        const firestore = admin.firestore();

        // O documento semanal é lido pelo ID (`{YYYY-Www}`), não por
        // `where(year, week)`: o id É a chave e uma leitura direta não precisa
        // de índice nenhum.
        const summary = await firestore.doc(`workspaces/${workspaceId}/period_summaries/${weekId}`).get();
        if (!summary.exists) {
            return [];
        }

        const { categories } = toPeriodSummaryDocument(summary.id, summary.data());
        const categoryIds = Object.keys(categories);
        if (categoryIds.length === 0) {
            return [];
        }

        // Join APENAS nas categorias que aparecem no sumário da semana, via
        // `getAll`. Antes esta leitura varria a coleção INTEIRA de categorias
        // do workspace — o que era barato no cron semanal (uma vez por
        // workspace) e caro depois que as missões corporativas passaram a
        // avaliar margem e receita a cada evento de transação: um workspace
        // com 40 categorias pagava 40 leituras para classificar as 6 que se
        // moveram na semana.
        const categoryDocs = await firestore.getAll(
            ...categoryIds.map((id) => firestore.doc(`workspaces/${workspaceId}/categories/${id}`))
        );

        const categoriesById = new Map<string, CategoryModel>();
        for (const doc of categoryDocs) {
            if (!doc.exists) {
                continue;
            }
            const data = doc.data() as CategoryModel;
            if (data.isDeleted === true) {
                continue;
            }
            categoriesById.set(doc.id, data);
        }

        const rows: WeeklySummaryRow[] = [];
        for (const [categoryId, raw] of Object.entries(categories)) {
            const category = categoriesById.get(categoryId);
            if (!category) {
                // Sem o documento da categoria não há como classificar a linha.
                continue;
            }
            rows.push({
                categoryId,
                type: category.type,
                isSystem: isSystemCategory(categoryId, category),
                actualAmount: raw.actualAmount,
                generalPlannedAmount: raw.generalPlannedAmount,
                specificPlannedAmount: raw.specificPlannedAmount,
                // `toPeriodSummaryDocument` já resolveu o inteiro a partir do
                // `double` num documento ainda não migrado.
                actualAmountCents: raw.actualAmountCents ?? 0,
                generalPlannedAmountCents: raw.generalPlannedAmountCents ?? 0,
                specificPlannedAmountCents: raw.specificPlannedAmountCents ?? 0,
            });
        }

        // Ordem estável: o XP concedido não pode depender da ordem em que o
        // Firestore devolveu as chaves do mapa.
        rows.sort((a, b) => a.categoryId.localeCompare(b.categoryId));
        return rows;
    }

    async awardXpOnce(
        workspaceId: string,
        group: XpOnceGroup,
        key: string,
        xp: number,
        reason: string
    ): Promise<boolean> {
        const db = admin.firestore();
        const workspaceRef = db.collection("workspaces").doc(workspaceId);
        let awarded = false;

        // Marcador + XP na MESMA transação, igual ao `unlockBadge`. O marcador
        // é o que torna a concessão única por categoria: sem ele, apagar e
        // recriar o mesmo limite renderia 30 XP a cada vez, e o jogo passaria a
        // premiar mexer no formulário em vez de planejar.
        //
        // O mapa `xpAwardedFor` é reescrito INTEIRO (nunca por caminho
        // pontilhado): um id de categoria com ponto viraria dois níveis de
        // aninhamento e o marcador nunca mais casaria.
        await db.runTransaction(async (transaction) => {
            // O flag é RESETADO a cada tentativa. `runTransaction` reexecuta
            // este callback quando há disputa pelo documento, e uma tentativa
            // que só sai cedo (porque a concorrente já concedeu) não escreve
            // nada — sem o reset, o `true` da tentativa anterior sobreviveria e
            // o chamador acharia que concedeu duas vezes.
            awarded = false;

            const doc = await transaction.get(workspaceRef);
            if (!doc.exists) {
                return;
            }

            const data = doc.data()!;
            const awardedFor: Record<string, Record<string, string>> = { ...(data.xpAwardedFor || {}) };
            const groupMap: Record<string, string> = { ...(awardedFor[group] || {}) };

            if (groupMap[key]) {
                return;
            }

            groupMap[key] = new Date().toISOString();
            awardedFor[group] = groupMap;

            const currentXp = data.xp || 0;
            const currentLevel = data.level || 1;
            const newXp = Math.max(0, currentXp + xp);
            const newLevel = calculateLevel(newXp);

            const updateData: Record<string, unknown> = { xpAwardedFor: awardedFor, xp: newXp, level: newLevel };
            if (newLevel > currentLevel) {
                updateData.lastLevelUpAt = admin.firestore.FieldValue.serverTimestamp();
            }

            transaction.update(workspaceRef, updateData);
            awarded = true;
        });

        if (awarded) {
            logger.info(`[GamificationRepository] XP único ${group}/${key} para ${workspaceId} (+${xp} XP: ${reason}).`);
        }
        return awarded;
    }

    async getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<PeriodSummaryRow[]> {
        // O documento de period_summary tem a forma
        // {year, month, week, categories: {categoryId: {generalPlannedAmount,
        // specificPlannedAmount, actualAmount}}, runtimeType} — há um único
        // documento por mês. Antes devolvíamos o documento inteiro e o serviço
        // lia `summary.actualAmount`/`summary.category.type`, sempre undefined.
        // Aqui achatamos em uma linha por categoria, com join em `categories`
        // para recuperar `type` e `allocation`.
        const firestore = admin.firestore();

        const [snapshot, categoriesSnapshot] = await Promise.all([
            firestore
                .collection(`workspaces/${workspaceId}/period_summaries`)
                .where("year", "==", year)
                .where("month", "==", month)
                .get(),
            firestore.collection(`workspaces/${workspaceId}/categories`).get(),
        ]);

        const categoriesById = new Map<string, CategoryModel>();
        for (const doc of categoriesSnapshot.docs) {
            const data = doc.data() as CategoryModel;
            if (data.isDeleted === true) {
                // Categorias excluídas não entram nas checagens de badge.
                continue;
            }
            categoriesById.set(doc.id, data);
        }

        const rows: PeriodSummaryRow[] = [];
        for (const doc of snapshot.docs) {
            const { categories } = toPeriodSummaryDocument(doc.id, doc.data());
            for (const [categoryId, raw] of Object.entries(categories)) {
                const category = categoriesById.get(categoryId);
                if (!category) {
                    // Sem o documento da categoria não há como classificar a
                    // linha (income/expense, allocation): ignoramos.
                    continue;
                }

                rows.push({
                    categoryId,
                    type: category.type,
                    allocation: category.allocation,
                    isSystem: isSystemCategory(categoryId, category),
                    actualAmount: raw.actualAmount,
                    generalPlannedAmount: raw.generalPlannedAmount,
                    specificPlannedAmount: raw.specificPlannedAmount,
                    // `toPeriodSummaryDocument` já resolveu o inteiro a partir
                    // do `double` num documento ainda não migrado.
                    actualAmountCents: raw.actualAmountCents ?? 0,
                    generalPlannedAmountCents: raw.generalPlannedAmountCents ?? 0,
                    specificPlannedAmountCents: raw.specificPlannedAmountCents ?? 0,
                });
            }
        }

        return rows;
    }

    async saveMonthlyReport(workspaceId: string, report: MonthlyVillagersReport): Promise<void> {
        await admin.firestore()
            .collection(`workspaces/${workspaceId}/${MONTHLY_REPORTS_COLLECTION}`)
            .doc(report.monthKey)
            // `stripUndefined` porque `ignoreUndefinedProperties` está
            // DESLIGADO (F1.11): um campo opcional que chegue `undefined` —
            // hoje não existe nenhum, amanhã pode existir — derrubaria a
            // escrita inteira do retrato em vez de simplesmente não existir no
            // documento.
            .set(stripUndefined({ ...report }));
    }

    async getMonthlyReport(workspaceId: string, monthKey: string): Promise<MonthlyVillagersReport | null> {
        const doc = await admin.firestore()
            .collection(`workspaces/${workspaceId}/${MONTHLY_REPORTS_COLLECTION}`)
            .doc(monthKey)
            .get();

        if (!doc.exists) return null;
        return doc.data() as MonthlyVillagersReport;
    }

    async getCategoriesCount(workspaceId: string): Promise<number> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/categories`)
            .get();
        return snapshot.size;
    }

    async getPaidInstallments(workspaceId: string): Promise<GamificationInstallment[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .get();
        return snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as GamificationInstallment));
    }

    async getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<GamificationInstallment[]> {
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/installments`)
            .where("status", "in", ["paid", "settled"])
            .where("paidDate", ">=", since)
            .get();
        return snapshot.docs.map((doc) => ({ ...doc.data(), id: doc.id } as GamificationInstallment));
    }


    async completeMissionAndAwardXp(
        workspaceId: string,
        weekId: string,
        type: WeeklyMissionType,
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
            // O flag é RESETADO a cada tentativa. `runTransaction` reexecuta
            // este callback quando há disputa pelo documento, e uma tentativa
            // que só sai cedo (porque a concorrente já concedeu) não escreve
            // nada — sem o reset, o `true` da tentativa anterior sobreviveria e
            // o chamador acharia que concedeu duas vezes.
            completed = false;

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

            const updateData: Record<string, unknown> = { xp: newXp, level: newLevel };
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

    async getCompletedReconciliationsInPeriod(workspaceId: string, start: Date, end: Date): Promise<number> {
        // `count()` em vez de `get()`: o documento de conciliação não interessa,
        // só quantos fecharam na semana. Exige o índice composto
        // (status ASC, createdAt ASC) declarado em firestore.indexes.json.
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/reconciliations`)
            .where("status", "==", "completed")
            .where("createdAt", ">=", start)
            .where("createdAt", "<=", end)
            .count()
            .get();
        return snapshot.data().count;
    }

    async getAutomaticTransactions(
        workspaceId: string,
        startIso: string,
        endIso: string,
        limit: number
    ): Promise<AutomaticTransactionRow[]> {
        // Faixa + `orderBy` no MESMO campo: o Firestore resolve com o índice
        // de campo único que já existe, sem índice composto novo.
        //
        // Os limites são strings de relógio local, não Timestamps — ver a
        // interface. Sem o `orderBy`, a página vinha ordenada por id (UUID) e
        // o recorte da semana caía fora dela.
        const snapshot = await admin.firestore()
            .collection(`workspaces/${workspaceId}/automatic_transactions`)
            .where("date", ">=", startIso)
            .where("date", "<", endIso)
            .orderBy("date")
            .limit(limit)
            .get();
        return snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                date: data.date ?? null,
                isConsolidated: data.isConsolidated === true,
                isIgnored: data.isIgnored === true,
            };
        });
    }
}
