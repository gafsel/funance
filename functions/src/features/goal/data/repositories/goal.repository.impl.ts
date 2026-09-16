import * as admin from "firebase-admin";
import { GoalBalances, IGoalRepository, InstallmentLike } from "../../domain/repositories/goal.repository";
import { GoalModel, toGoalDate } from "../../domain/models/goal.model";

/** Máximo de documentos por `getAll` — evita um lote gigante numa meta longa. */
const MAX_SUMMARY_DOCS_PER_BATCH = 100;

/** Página da varredura de saldos diários. */
const BALANCE_PAGE_SIZE = 500;

export class GoalRepositoryImpl implements IGoalRepository {
    private db = admin.firestore();

    private goalsCollection(workspaceId: string) {
        return this.db.collection("workspaces").doc(workspaceId).collection("goals");
    }

    async getGoals(workspaceId: string): Promise<GoalModel[]> {
        const snapshot = await this.goalsCollection(workspaceId)
            .where("isDeleted", "==", false)
            .get();

        return snapshot.docs.map((doc) => this.mapDocToModel(doc));
    }

    async getActiveGoalsByAccount(workspaceId: string, accountId: string): Promise<GoalModel[]> {
        const snapshot = await this.goalsCollection(workspaceId)
            .where("isDeleted", "==", false)
            .where("accountId", "==", accountId)
            .get();

        return snapshot.docs.map((doc) => this.mapDocToModel(doc));
    }

    async getActiveGoalsByCategory(workspaceId: string, categoryId: string): Promise<GoalModel[]> {
        // Duas igualdades: o Firestore resolve com os índices de campo único
        // (mesma forma da consulta por conta), sem índice composto.
        const snapshot = await this.goalsCollection(workspaceId)
            .where("isDeleted", "==", false)
            .where("category.id", "==", categoryId)
            .get();

        return snapshot.docs.map((doc) => this.mapDocToModel(doc));
    }

    async getGoal(workspaceId: string, goalId: string): Promise<GoalModel | null> {
        const doc = await this.goalsCollection(workspaceId).doc(goalId).get();

        if (!doc.exists) return null;
        return this.mapDocToModel(doc);
    }

    async updateGoal(workspaceId: string, goal: GoalModel): Promise<void> {
        await this.goalsCollection(workspaceId).doc(goal.id).set(goal, { merge: true });
    }

    async updateGoalProgress(
        workspaceId: string,
        goalId: string,
        currentAmount: number,
        completedAt?: Date
    ): Promise<void> {
        const payload: Record<string, any> = { currentAmount };
        if (completedAt) {
            payload.completedAt = admin.firestore.Timestamp.fromDate(completedAt);
        }

        await this.goalsCollection(workspaceId).doc(goalId).set(payload, { merge: true });
    }

    async getCategoryActualByMonths(
        workspaceId: string,
        categoryId: string,
        monthKeys: string[]
    ): Promise<number> {
        if (monthKeys.length === 0) {
            return 0;
        }

        const collection = this.db
            .collection("workspaces")
            .doc(workspaceId)
            .collection("period_summaries");

        // O documento mensal tem a forma {year, month, categories: {id: {...}}}.
        // A máscara traz só a entrada da categoria da meta: um mês com 40
        // categorias não vira 40x payload.
        const fieldPath = new admin.firestore.FieldPath("categories", categoryId, "actualAmount");

        let total = 0;
        for (let i = 0; i < monthKeys.length; i += MAX_SUMMARY_DOCS_PER_BATCH) {
            const chunk = monthKeys.slice(i, i + MAX_SUMMARY_DOCS_PER_BATCH);
            const refs = chunk.map((key) => collection.doc(key));
            const docs = await this.db.getAll(...refs, { fieldMask: [fieldPath] });

            for (const doc of docs) {
                const raw = doc.get(fieldPath);
                const value = Number(raw ?? 0);
                if (Number.isFinite(value)) {
                    total += value;
                }
            }
        }

        return total;
    }

    /**
     * Saldos de início e atuais numa varredura ASCENDENTE única.
     *
     * Por que não `orderBy(documentId(), "desc")` nem `limitToLast(1)`: o
     * Firestore responde `FAILED_PRECONDITION: Firestore does not support
     * descending key scans` às duas formas (a segunda é implementada como uma
     * varredura descendente). A saída é percorrer para a frente e ficar com o
     * último documento visto — como os ids são `YYYY-MM-DD`, a ordem
     * lexicográfica é a cronológica.
     *
     * Custo: uma leitura por dia de movimento da conta, e só para metas
     * `payDebt`. `select("balance")` mantém o payload mínimo. Por isso a
     * varredura resolve os DOIS saldos de uma vez, em vez de uma consulta para
     * cada.
     */
    async getBalancesForGoal(
        workspaceId: string,
        accountId: string,
        startDate: Date
    ): Promise<GoalBalances> {
        const startKey = toDateKey(startDate);
        const collection = this.balanceCollection(workspaceId, accountId);

        let startBalance: number | null = null;
        let currentBalance: number | null = null;
        let cursor: admin.firestore.QueryDocumentSnapshot | undefined;

        for (;;) {
            let query = collection
                .orderBy(admin.firestore.FieldPath.documentId())
                .select("balance")
                .limit(BALANCE_PAGE_SIZE);
            if (cursor) {
                query = query.startAfter(cursor);
            }

            const snapshot = await query.get();
            if (snapshot.empty) {
                break;
            }

            for (const doc of snapshot.docs) {
                const value = Number(doc.data()?.balance ?? 0);
                if (!Number.isFinite(value)) {
                    continue;
                }
                if (doc.id <= startKey) {
                    startBalance = value;
                }
                currentBalance = value;
            }

            if (snapshot.size < BALANCE_PAGE_SIZE) {
                break;
            }
            cursor = snapshot.docs[snapshot.docs.length - 1];
        }

        return { startBalance, currentBalance };
    }

    async getPaidInstallmentsByAccountSince(
        workspaceId: string,
        accountId: string,
        since: Date
    ): Promise<InstallmentLike[]> {
        // Só `array-contains` na consulta: filtrar status e `paidDate` aqui
        // exigiria um índice composto novo, e este caminho é do recálculo
        // total (script/criação de meta), não do gatilho de cada parcela.
        const snapshot = await this.db
            .collection("workspaces")
            .doc(workspaceId)
            .collection("installments")
            .where("accountIds", "array-contains", accountId)
            .get();

        const result: InstallmentLike[] = [];
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const paidDate = toGoalDate(data.paidDate);
            if (!paidDate || paidDate.getTime() < since.getTime()) {
                continue;
            }
            if (data.status !== "paid" && data.status !== "settled") {
                continue;
            }
            result.push({
                amount: data.amount,
                paidAmount: data.paidAmount,
                paidDate,
                status: data.status,
                accounts: data.accounts,
            });
        }
        return result;
    }

    private balanceCollection(workspaceId: string, accountId: string) {
        return this.db
            .collection("workspaces")
            .doc(workspaceId)
            .collection("accounts")
            .doc(accountId)
            .collection("balance");
    }

    private mapDocToModel(doc: admin.firestore.QueryDocumentSnapshot | admin.firestore.DocumentSnapshot): GoalModel {
        const data = doc.data()!;
        return {
            ...data,
            id: doc.id,
            startDate: toGoalDate(data.startDate) || new Date(),
            // Documento legado pode não ter `deadline`; antes isso lançava.
            deadline: toGoalDate(data.deadline) || undefined,
            completedAt: toGoalDate(data.completedAt),
        } as GoalModel;
    }
}

/**
 * Id do documento de saldo do dia (`YYYY-MM-DD`).
 *
 * Usa UTC porque é assim que o id é GERADO na escrita
 * (`FinanceRepositoryImpl.updateAccountBalance` faz
 * `date.toISOString().split("T")[0]`). Formatar aqui no fuso local faria a
 * leitura procurar um dia que não existe.
 */
function toDateKey(date: Date): string {
    return date.toISOString().split("T")[0];
}
