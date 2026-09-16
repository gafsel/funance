import * as admin from "firebase-admin";
import { GoalBalances, IGoalRepository, InstallmentLike } from "../../domain/repositories/goal.repository";
import { GoalModel, toGoalDate } from "../../domain/models/goal.model";

/** Máximo de documentos por `getAll` — evita um lote gigante numa meta longa. */
const MAX_SUMMARY_DOCS_PER_BATCH = 100;

/** Página da varredura de saldos diários. */
const BALANCE_PAGE_SIZE = 500;

/** Limite superior que casa com qualquer id `YYYY-MM-DD` — "o saldo mais recente". */
const MAX_DATE_KEY = "9999-12-31";

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
     * Saldo no início da meta e saldo atual, numa chamada só.
     *
     * Duas coisas que esta consulta NÃO pode fazer:
     *
     * - `orderBy(documentId(), "desc")` e `limitToLast(1)`: o Firestore recusa
     *   as duas com `FAILED_PRECONDITION: Firestore does not support descending
     *   key scans` (a segunda é implementada como varredura descendente).
     * - confiar só no campo `dateKey`: ele é recente e os documentos legados
     *   não o têm, então a query indexada simplesmente não casa com eles.
     *
     * Daí o caminho duplo, o mesmo que o repositório de finanças usa: a query
     * indexada por `dateKey` descendente responde em uma leitura numa base já
     * migrada, e uma varredura ASCENDENTE por id no intervalo aberto
     * `(candidato, limite]` recupera qualquer documento legado mais novo que o
     * candidato. Numa base migrada esse intervalo é vazio; numa base legada ele
     * paga o preço da varredura até a migração de `dateKey` rodar — e é o único
     * caminho hoje, porque nada nesta base grava `dateKey` ainda.
     */
    async getBalancesForGoal(
        workspaceId: string,
        accountId: string,
        startDate: Date
    ): Promise<GoalBalances> {
        const collection = this.balanceCollection(workspaceId, accountId);

        const [startBalance, currentBalance] = await Promise.all([
            this.lastBalanceUpTo(collection, toDateKey(startDate)),
            this.lastBalanceUpTo(collection, MAX_DATE_KEY),
        ]);

        return { startBalance, currentBalance };
    }

    /** Saldo do último documento com id/`dateKey` <= `limitKey`. */
    private async lastBalanceUpTo(
        collection: admin.firestore.CollectionReference,
        limitKey: string
    ): Promise<number | null> {
        const indexed = await collection
            .where("dateKey", "<=", limitKey)
            .orderBy("dateKey", "desc")
            .limit(1)
            .get();

        const candidate = indexed.empty ? null : indexed.docs[0];
        const legacy = await this.lastLegacyBalanceDoc(
            collection,
            candidate?.id ?? null,
            limitKey
        );

        const chosen = legacy ?? candidate;
        if (!chosen) return null;

        const value = Number(chosen.data()?.balance ?? 0);
        return Number.isFinite(value) ? value : null;
    }

    /** Último documento por id no intervalo `(after, upTo]`, varrendo ascendente. */
    private async lastLegacyBalanceDoc(
        collection: admin.firestore.CollectionReference,
        after: string | null,
        upTo: string
    ): Promise<admin.firestore.QueryDocumentSnapshot | null> {
        const id = admin.firestore.FieldPath.documentId();
        let last: admin.firestore.QueryDocumentSnapshot | null = null;
        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = collection.where(id, "<=", upTo);
            if (after !== null) {
                query = query.where(id, ">", after);
            }
            query = query.orderBy(id).select("balance").limit(BALANCE_PAGE_SIZE);
            if (cursor) {
                query = query.startAfter(cursor);
            }

            const snapshot = await query.get();
            if (snapshot.empty) {
                return last;
            }

            last = snapshot.docs[snapshot.size - 1];
            if (snapshot.size < BALANCE_PAGE_SIZE) {
                return last;
            }
            cursor = last;
        }
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
