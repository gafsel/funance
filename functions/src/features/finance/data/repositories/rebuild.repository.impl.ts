import * as admin from "firebase-admin";
import { AccountModel, CategoryPlanningModel, InstallmentModel } from "../../domain/models/finance.models";
import {
    ExistingBalanceData,
    ExistingDoc,
    ExistingSummaryData,
    ExistingWeeklyXpData,
    IRebuildRepository,
    RebuildWrite,
} from "../../domain/repositories/rebuild.repository";
import { BatchOperation, commitInChunks } from "../../../../core/utils/batch.utils";
import { RawFirestoreDate } from "../../../../core/utils/firestore.utils";

/** Converte um Timestamp/Date/string em Date, do mesmo jeito que o gatilho `onInstallmentWritten`. */
function toDate(raw: RawFirestoreDate | null | undefined): Date | undefined {
    if (raw === null || raw === undefined) return undefined;
    const timestamp = raw as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") return timestamp.toDate();
    const date = new Date(raw as string | number | Date);
    return isNaN(date.getTime()) ? undefined : date;
}

export class RebuildRepositoryImpl implements IRebuildRepository {
    private firestore = admin.firestore();

    private workspaceDoc(workspaceId: string) {
        return this.firestore.collection("workspaces").doc(workspaceId);
    }

    /**
     * Pagina uma coleção por documentId ASCENDENTE.
     *
     * Ascendente de propósito: o emulador do Firestore rejeita
     * `orderBy(documentId(), "desc")` ("Firestore does not support descending
     * key scans") — a mesma limitação documentada em
     * `finance_flow.integration.test.ts`.
     */
    private async paginate(
        collection: admin.firestore.CollectionReference,
        pageSize: number,
        visit: (doc: admin.firestore.QueryDocumentSnapshot) => void
    ): Promise<void> {
        const size = Math.max(1, pageSize);
        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = collection
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(size);

            if (cursor) {
                query = query.startAfter(cursor);
            }

            const snapshot = await query.get();
            if (snapshot.empty) return;

            for (const doc of snapshot.docs) {
                visit(doc);
            }

            if (snapshot.size < size) return;
            cursor = snapshot.docs[snapshot.size - 1];
        }
    }

    private async collectDocs<TData>(collection: admin.firestore.CollectionReference, pageSize: number): Promise<ExistingDoc<TData>[]> {
        const docs: ExistingDoc<TData>[] = [];
        await this.paginate(collection, pageSize, (doc) => {
            docs.push({ id: doc.id, data: doc.data() as TData });
        });
        return docs;
    }

    async forEachInstallment(
        workspaceId: string,
        pageSize: number,
        visit: (installment: InstallmentModel) => void
    ): Promise<void> {
        const collection = this.workspaceDoc(workspaceId).collection("installments");

        await this.paginate(collection, pageSize, (doc) => {
            const data = doc.data();

            // Mesma conversão do gatilho: Timestamp cru, SEM normalizar a hora.
            // `FinanceRepositoryImpl.getInstallments` faz `setHours(12)`, o que
            // mudaria o dia (e portanto o id do saldo) para parcelas gravadas
            // perto da virada do dia em UTC.
            visit({
                ...data,
                id: doc.id,
                dueDate: toDate(data.dueDate)!,
                paidDate: toDate(data.paidDate),
            } as InstallmentModel);
        });
    }

    async getAccounts(workspaceId: string): Promise<AccountModel[]> {
        // Sem filtro de `isDeleted`: contas apagadas logicamente ainda têm
        // subcoleção `balance` e precisam ser inspecionadas.
        const snapshot = await this.workspaceDoc(workspaceId).collection("accounts").get();
        return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as AccountModel));
    }

    async listAccountIds(workspaceId: string): Promise<string[]> {
        // listDocuments() traz também os documentos "fantasmas" (apagados, mas
        // com subcoleção `balance` sobrevivente), que um `get()` não retorna.
        const refs = await this.workspaceDoc(workspaceId).collection("accounts").listDocuments();
        return refs.map((ref) => ref.id);
    }

    async getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]> {
        const snapshot = await this.workspaceDoc(workspaceId).collection("category_planning").get();
        return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as CategoryPlanningModel));
    }

    async getExistingBalances(workspaceId: string, accountId: string, pageSize: number): Promise<ExistingDoc<ExistingBalanceData>[]> {
        return this.collectDocs<ExistingBalanceData>(
            this.workspaceDoc(workspaceId).collection("accounts").doc(accountId).collection("balance"),
            pageSize
        );
    }

    async getExistingPeriodSummaries(workspaceId: string, pageSize: number): Promise<ExistingDoc<ExistingSummaryData>[]> {
        return this.collectDocs<ExistingSummaryData>(this.workspaceDoc(workspaceId).collection("period_summaries"), pageSize);
    }

    async getExistingWeeklyXp(workspaceId: string, pageSize: number): Promise<ExistingDoc<ExistingWeeklyXpData>[]> {
        return this.collectDocs<ExistingWeeklyXpData>(this.workspaceDoc(workspaceId).collection("weekly_xp"), pageSize);
    }

    async applyWrites(workspaceId: string, writes: RebuildWrite[], chunkSize: number): Promise<number> {
        const workspace = this.workspaceDoc(workspaceId);

        const operations: BatchOperation[] = writes.map((write) => {
            const ref = write.kind === "balance"
                ? workspace.collection("accounts").doc(write.accountId).collection("balance").doc(write.docId)
                : write.kind === "summary"
                    ? workspace.collection("period_summaries").doc(write.docId)
                    : workspace.collection("weekly_xp").doc(write.docId);

            if (write.op === "delete") {
                return { op: "delete", ref };
            }

            // `set` sem merge: a reconstrução é a verdade, então campos/categorias
            // residuais precisam desaparecer do documento.
            if (write.kind === "balance") {
                return {
                    op: "set",
                    ref,
                    data: {
                        dateKey: write.data!.dateKey,
                        delta: write.data!.delta,
                        balance: write.data!.balance,
                        // F1.10 — os inteiros vão juntos, e o `set` sem merge
                        // garante que um documento reconstruído nunca fique com
                        // o espelho novo e o inteiro velho.
                        deltaCents: write.data!.deltaCents,
                        balanceCents: write.data!.balanceCents,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                };
            }

            if (write.kind === "summary") {
                return {
                    op: "set",
                    ref,
                    data: {
                        ...write.data!,
                        lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                    },
                };
            }

            return {
                op: "set",
                ref,
                data: {
                    ...write.data!,
                    lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                },
            };
        });

        return commitInChunks(this.firestore, operations, chunkSize);
    }
}
