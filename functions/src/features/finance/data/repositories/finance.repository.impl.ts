import { CategoryModel } from "../../../workspace/domain/models/category.model";
import * as admin from "firebase-admin";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    CategoryPlanningMarks,
    AccountModel,
    AccountBalanceModel,
    PeriodSummaryUpdateModel,
    OrderStatus,
    InstallmentType,
    OrderType, InstallmentStatus,
} from "../../domain/models/finance.models";
import {
    CategoryPlanningPage,
    CategoryPlanningRef,
    CategoryPlanningScanPage,
    IFinanceRepository,
} from "../../domain/repositories/finance.repository";
import { BatchOperation, commitInChunks, DEFAULT_CHUNK_SIZE, deleteByQueryInChunks } from "../../../../core/utils/batch.utils";
import { isDateKey, toDateKey } from "../../../../core/utils/date_key";

/**
 * Limite de escritas por transação do Firestore é 500. O cron agrupa parcelas
 * de várias orders numa transação só; deixamos folga para os `update` das
 * orders do mesmo grupo.
 */
const MAX_WRITES_PER_TRANSACTION = 450;

/**
 * Teto de parcelas de UMA order por transação: sobra uma escrita para o
 * `update` da própria order.
 */
const MAX_INSTALLMENTS_PER_UNIT = MAX_WRITES_PER_TRANSACTION - 1;

/**
 * Página da propagação de saldo: no máximo 400 documentos por volta, que é
 * também o teto de escritas por batch (`commitInChunks`).
 */
const BALANCE_PROPAGATION_PAGE_SIZE = DEFAULT_CHUNK_SIZE;

/** Dinheiro em centavos inteiros: evita que o saldo acumule erro de ponto flutuante. */
function roundCents(value: number): number {
    return Math.round(value * 100) / 100;
}

/** Abaixo disso o delta de planejamento é ruído de ponto flutuante. */
const PLANNING_DELTA_EPSILON = 1e-9;

interface PlanningCategoryBucket {
    category: CategoryModel;
    delta: number;
}

interface PlanningSummaryGroup {
    year: number;
    month?: number;
    week?: number;
    runtimeType: string;
    categories: Map<string, PlanningCategoryBucket>;
}

/** Agrupa os impactos por documento de sumário, somando os deltas por categoria. */
function groupPlanningUpdates(updates: PeriodSummaryUpdateModel[]): Map<string, PlanningSummaryGroup> {
    const groups = new Map<string, PlanningSummaryGroup>();

    for (const update of updates) {
        const docId = update.week !== undefined
            ? `${update.year}-W${String(update.week).padStart(2, "0")}`
            : update.month !== undefined
                ? `${update.year}-${String(update.month).padStart(2, "0")}`
                : `${update.year}`;

        let group = groups.get(docId);
        if (!group) {
            group = {
                year: update.year,
                month: update.month,
                week: update.week,
                runtimeType: update.week !== undefined ? "week" : update.month !== undefined ? "month" : "year",
                categories: new Map(),
            };
            groups.set(docId, group);
        }

        let bucket = group.categories.get(update.category.id);
        if (!bucket) {
            bucket = { category: update.category, delta: 0 };
            group.categories.set(update.category.id, bucket);
        }
        bucket.delta += update.generalPlannedDelta ?? 0;
    }

    return groups;
}

/** Número tolerante a campo ausente/sujo (documentos legados). */
function toNumber(value: unknown): number {
    const parsed = typeof value === "number" ? value : Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
}


/**
 * Formato canônico do documento de parcela. Extraído para que exista UMA
 * definição do schema, usada por toda criação de parcela.
 */
export function buildInstallmentDocument(
    installment: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">
): Record<string, any> {
    const referenceDate = installment.paidDate || installment.dueDate;
    const referenceAmount = installment.paidAmount !== undefined && installment.paidAmount !== null
        ? installment.paidAmount
        : installment.amount;

    return {
        ...installment,
        dueDate: admin.firestore.Timestamp.fromDate(installment.dueDate),
        paidDate: installment.paidDate ? admin.firestore.Timestamp.fromDate(installment.paidDate) : null,
        referenceDate: admin.firestore.Timestamp.fromDate(referenceDate),
        referenceAmount: referenceAmount,
    };
}

export class FinanceRepositoryImpl implements IFinanceRepository {
    private firestore = admin.firestore();

    private getOrdersCollection(workspaceId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/orders`);
    }

    private getInstallmentsCollection(workspaceId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/installments`);
    }

    private getCategoryPlanningCollection(workspaceId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/category_planning`);
    }

    private getPeriodSummariesCollection(workspaceId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/period_summaries`);
    }

    private getAccountsCollection(workspaceId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/accounts`);
    }

    private getAccountBalanceCollection(workspaceId: string, accountId: string) {
        return this.firestore.collection(`workspaces/${workspaceId}/accounts/${accountId}/balance`);
    }

    async createOrder(workspaceId: string, order: Omit<OrderModel, "id">, id?: string): Promise<string> {
        const collection = this.getOrdersCollection(workspaceId);
        if (id) {
            await collection.doc(id).set(order);
            return id;
        }
        const docRef = await collection.add(order);
        return docRef.id;
    }

    async getOrderById(workspaceId: string, orderId: string): Promise<OrderModel | null> {
        const doc = await this.getOrdersCollection(workspaceId).doc(orderId).get();
        if (!doc.exists) return null;
        const data = doc.data()!;
        const lastGeneratedDueDate = data.lastGeneratedDueDate?.toDate();
        if (lastGeneratedDueDate) lastGeneratedDueDate.setHours(12, 0, 0, 0);

        return {
            id: doc.id,
            ...data,
            lastGeneratedDueDate: lastGeneratedDueDate,
        } as OrderModel;
    }

    async updateOrder(workspaceId: string, orderId: string, order: Partial<OrderModel>): Promise<void> {
        await this.getOrdersCollection(workspaceId).doc(orderId).update(order);
    }

    /**
     * O Firestore NÃO apaga subcoleções em cascata: sem isto, os documentos de
     * `orders/{orderId}/history` ficariam órfãos e inacessíveis (as rules só
     * permitem leitura via workspace). O trigger onOrderWritten não regrava
     * histórico numa exclusão (só o faz quando `after` existe).
     */
    private async deleteOrderHistory(orderRef: admin.firestore.DocumentReference): Promise<number> {
        const deleted = await deleteByQueryInChunks(this.firestore, orderRef.collection("history"));
        if (deleted > 0) {
            console.log(`deleteOrderHistory: ${deleted} registros removidos da order ${orderRef.id}.`);
        }
        return deleted;
    }

    async deleteOrder(workspaceId: string, orderId: string): Promise<void> {
        const docRef = this.getOrdersCollection(workspaceId).doc(orderId);

        await this.deleteOrderHistory(docRef);
        await docRef.delete();
    }

    async getOrders(workspaceId: string, limit?: number): Promise<OrderModel[]> {
        let query = this.getOrdersCollection(workspaceId)
            .orderBy("startMonth", "desc");

        if (limit) {
            query = query.limit(limit);
        }

        const snapshot = await query.get();
        return snapshot.docs.map((doc) => {
            const data = doc.data();
            const lastGeneratedDueDate = data.lastGeneratedDueDate?.toDate();
            if (lastGeneratedDueDate) lastGeneratedDueDate.setHours(12, 0, 0, 0);

            return {
                id: doc.id,
                ...data,
                lastGeneratedDueDate: lastGeneratedDueDate,
            } as OrderModel;
        });
    }

    async createOrderHistory(workspaceId: string, orderId: string, snapshot: any): Promise<void> {
        await this.getOrdersCollection(workspaceId)
            .doc(orderId)
            .collection("history")
            .add({
                snapshot: snapshot,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
    }

    async deleteOrdersByAccountId(workspaceId: string, accountId: string): Promise<void> {
        // `accounts` é um MAPA {accountId: 'debt'|'credit'}, portanto
        // "array-contains" nunca casa. E o campo espelho `accountIds` NÃO serve
        // para orders: o cliente Flutter não o serializa (order_model.g.dart só
        // grava `accounts`) — apenas faturas e saldo inicial, criados pelo
        // servidor, o possuem. Consultamos a chave do mapa diretamente, que é
        // exatamente a semântica desejada: accounts.{accountId} IN ['debt','credit'].
        // FieldPath (em vez de interpolar "accounts.${accountId}") evita que um
        // id com ponto, crase ou asterisco seja interpretado como caminho.
        // Chaves de mapa entram no índice single-field automático do Firestore,
        // então esta query não exige índice composto.
        const query = this.getOrdersCollection(workspaceId)
            .where(new admin.firestore.FieldPath("accounts", accountId), "in", ["debt", "credit"]);

        // Paginamos aqui em vez de usar deleteByQueryInChunks direto porque cada
        // order precisa ter a subcoleção `history` apagada antes do documento.
        let deleted = 0;
        for (;;) {
            const snapshot = await query.limit(DEFAULT_CHUNK_SIZE).get();
            if (snapshot.empty) {
                break;
            }

            for (const doc of snapshot.docs) {
                await this.deleteOrderHistory(doc.ref);
            }

            await commitInChunks(this.firestore, snapshot.docs.map((doc) => doc.ref));
            deleted += snapshot.size;

            if (snapshot.size < DEFAULT_CHUNK_SIZE) {
                break;
            }
        }

        console.log(`deleteOrdersByAccountId: ${deleted} orders removidas da conta ${accountId} no workspace ${workspaceId}.`);
    }

    /**
     * ÚNICO ponto de criação de parcela do backend — tanto o fluxo normal
     * (`syncInstallments`) quanto o cron de recorrência passam por aqui, para
     * que o documento gravado tenha sempre o mesmo formato (Timestamp em todas
     * as datas, `paidDate: null` explícito, `referenceDate`/`referenceAmount`).
     *
     * Com `transaction`, as escritas entram na transação do chamador em vez de
     * um batch próprio (é o caso do cron, que cria as parcelas e avança o
     * `lastGeneratedDueDate` da order atomicamente).
     */
    async createInstallments(
        workspaceId: string,
        installments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[],
        transaction?: admin.firestore.Transaction
    ): Promise<void> {
        const collection = this.getInstallmentsCollection(workspaceId);

        // Uma order parcelada pode ter até 1200 parcelas (limite das rules):
        // sem chunking o batch estoura o limite de 500 e nada é criado.
        const documents = installments.map((installment) => ({
            ref: collection.doc(),
            data: buildInstallmentDocument(installment),
        }));

        if (transaction) {
            for (const document of documents) {
                transaction.set(document.ref, document.data);
            }
            return;
        }

        const operations: BatchOperation[] = documents.map((document) => ({
            op: "set",
            ref: document.ref,
            data: document.data,
        }));

        await commitInChunks(this.firestore, operations);
    }

    async updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void> {
        const docRef = this.getInstallmentsCollection(workspaceId).doc(installmentId);

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            if (!doc.exists) return;

            const currentData = doc.data() as any;
            const data = { ...installment } as any;

            if (data.dueDate) {
                data.dueDate = admin.firestore.Timestamp.fromDate(data.dueDate as Date);
            }
            if (data.paidDate) {
                data.paidDate = admin.firestore.Timestamp.fromDate(data.paidDate as Date);
            }

            // Recalcular referenceDate se dueDate ou paidDate mudarem
            if (installment.paidDate !== undefined || installment.dueDate !== undefined) {
                const paidDate = installment.paidDate !== undefined ? installment.paidDate : currentData.paidDate?.toDate();
                const dueDate = installment.dueDate !== undefined ? installment.dueDate : currentData.dueDate.toDate();
                const referenceDate = paidDate || dueDate;
                data.referenceDate = admin.firestore.Timestamp.fromDate(referenceDate);
            }

            // Recalcular referenceAmount se paidAmount ou amount mudarem
            if (installment.paidAmount !== undefined || installment.amount !== undefined) {
                const paidAmount = installment.paidAmount !== undefined ? installment.paidAmount : currentData.paidAmount;
                const amount = installment.amount !== undefined ? installment.amount : currentData.amount;
                data.referenceAmount = (paidAmount !== undefined && paidAmount !== null) ? paidAmount : amount;
            }

            // Sincronizar accountIds se accounts mudar
            if (installment.accounts !== undefined) {
                data.accountIds = Object.keys(installment.accounts || {});
            }

            transaction.update(docRef, data);
        });
    }

    async deleteInstallment(workspaceId: string, installmentId: string): Promise<void> {
        await this.getInstallmentsCollection(workspaceId).doc(installmentId).delete();
    }

    async deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void> {
        const query = this.getInstallmentsCollection(workspaceId)
            .where("orderId", "==", orderId);

        const deleted = await deleteByQueryInChunks(this.firestore, query);
        if (deleted > 0) {
            console.log(`deleteInstallmentsByOrderId: ${deleted} parcelas removidas da order ${orderId} (workspace ${workspaceId}).`);
        }
    }

    async getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]> {
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("orderId", "==", orderId)
            .get();

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            const dueDate = data.dueDate.toDate();
            dueDate.setHours(12, 0, 0, 0);

            const paidDate = data.paidDate?.toDate();
            if (paidDate) paidDate.setHours(12, 0, 0, 0);

            return {
                id: doc.id,
                ...data,
                dueDate: dueDate,
                paidDate: paidDate,
            } as InstallmentModel;
        });
    }

    async getInstallments(workspaceId: string, filters: {
        accountId?: string,
        startDate?: Date,
        endDate?: Date,
        status?: InstallmentStatus[],
        includeRemoved?: boolean
    }): Promise<InstallmentModel[]> {
        let query: admin.firestore.Query = this.getInstallmentsCollection(workspaceId);

        if (filters.accountId) {
            query = query.where("accountIds", "array-contains", filters.accountId);
        }

        if (filters.startDate) {
            query = query.where("referenceDate", ">=", admin.firestore.Timestamp.fromDate(filters.startDate));
        }

        if (filters.endDate) {
            query = query.where("referenceDate", "<=", admin.firestore.Timestamp.fromDate(filters.endDate));
        }

        if (filters.status && filters.status.length > 0) {
            const status = filters.includeRemoved
                ? filters.status
                : filters.status.filter((s) => s !== InstallmentStatus.removed);

            // Filtro explícito que só pedia 'removed' com includeRemoved=false:
            // nada pode ser retornado (um `in` vazio é inválido no Firestore).
            if (status.length === 0) {
                return [];
            }

            query = query.where("status", "in", status);
        }
        else if (!filters.includeRemoved) {
            // Parcelas 'removed' são exclusões lógicas: por padrão nunca entram
            // em relatórios/agregações. Use includeRemoved para incluí-las.
            query = query.where("status", "in", [
                InstallmentStatus.pending,
                InstallmentStatus.paid,
                InstallmentStatus.settled,
            ]);
        }

        const snapshot = await query.get();

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            const dueDate = data.dueDate.toDate();
            dueDate.setHours(12, 0, 0, 0);

            const paidDate = data.paidDate?.toDate();
            if (paidDate) paidDate.setHours(12, 0, 0, 0);

            const referenceDate = data.referenceDate?.toDate();
            if (referenceDate) referenceDate.setHours(12, 0, 0, 0);

            return {
                id: doc.id,
                ...data,
                dueDate: dueDate,
                paidDate: paidDate,
                referenceDate: referenceDate,
            } as InstallmentModel;
        });
    }

    async getOrdersByRecurringNextGenerationGroup(dateThreshold: Date, limit: number): Promise<(OrderModel & { workspaceId: string })[]> {
        const snapshot = await this.firestore.collectionGroup("orders")
            .where("installmentType", "==", "recurring")
            .where("status", "==", "active")
            .where("lastGeneratedDueDate", "<", dateThreshold)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            const workspaceId = doc.ref.parent.parent!.id;
            const lastGeneratedDueDate = data.lastGeneratedDueDate?.toDate();
            if (lastGeneratedDueDate) lastGeneratedDueDate.setHours(12, 0, 0, 0);

            return {
                id: doc.id,
                workspaceId: workspaceId,
                ...data,
                lastGeneratedDueDate: lastGeneratedDueDate,
            } as OrderModel & { workspaceId: string };
        });
    }

    async processRecurringInstallmentsChunk(
        chunk: (OrderModel & { workspaceId: string })[],
        installmentFactory: (order: OrderModel) => Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]
    ): Promise<void> {
        // A fábrica é pura (depende só da order e do horizonte), então roda
        // FORA da transação: assim sabemos quantas escritas cada order custa e
        // podemos fechar a transação antes do limite de 500.
        const planned = chunk
            .map((order) => ({ order, installments: installmentFactory(order) }))
            .filter((entry) => entry.installments.length > 0);

        if (planned.length === 0) return;

        // Uma order sozinha pode estourar o teto (série muito atrasada). Nesse
        // caso ela é dividida em várias transações, cada uma avançando o
        // `lastGeneratedDueDate` até a última parcela que ELA criou: se uma
        // falhar no meio, a marca da order continua batendo com o que existe, e
        // a execução seguinte retoma de onde parou sem duplicar nada.
        const units: typeof planned = [];
        for (const entry of planned) {
            if (entry.installments.length <= MAX_INSTALLMENTS_PER_UNIT) {
                units.push(entry);
                continue;
            }

            console.warn(`processRecurringInstallmentsChunk: order ${entry.order.id} (workspace ${entry.order.workspaceId}) precisa de ${entry.installments.length} parcelas, acima do teto de ${MAX_INSTALLMENTS_PER_UNIT} por transação: será dividida.`);

            for (let i = 0; i < entry.installments.length; i += MAX_INSTALLMENTS_PER_UNIT) {
                units.push({
                    order: entry.order,
                    installments: entry.installments.slice(i, i + MAX_INSTALLMENTS_PER_UNIT),
                });
            }
        }

        let batch: typeof planned = [];
        let writes = 0;

        const flush = async () => {
            if (batch.length === 0) return;
            const current = batch;
            batch = [];
            writes = 0;

            await this.firestore.runTransaction(async (transaction) => {
                for (const { order, installments } of current) {
                    // Mesma função de criação do fluxo normal: schema idêntico.
                    await this.createInstallments(order.workspaceId, installments, transaction);

                    // Avança a order: o último vencimento gerado vira a marca
                    // de onde a próxima execução continua.
                    const lastGeneratedDueDate = installments[installments.length - 1].dueDate;
                    const orderRef = this.getOrdersCollection(order.workspaceId).doc(order.id);
                    transaction.update(orderRef, {
                        lastGeneratedDueDate: admin.firestore.Timestamp.fromDate(lastGeneratedDueDate),
                    });
                }
            });
        };

        for (const entry of units) {
            const cost = entry.installments.length + 1; // parcelas + update da order
            if (writes > 0 && writes + cost > MAX_WRITES_PER_TRANSACTION) {
                await flush();
            }
            batch.push(entry);
            writes += cost;
        }

        await flush();
    }

    async deleteCategoryPlanningsByCategoryId(workspaceId: string, categoryId: string): Promise<void> {
        const query = this.getCategoryPlanningCollection(workspaceId)
            .where("category.id", "==", categoryId);

        await deleteByQueryInChunks(this.firestore, query);
    }

    async getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]> {
        const snapshot = await this.getCategoryPlanningCollection(workspaceId).get();
        return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as CategoryPlanningModel));
    }

    getCategoryPlanningRef(workspaceId: string, planningId: string): admin.firestore.DocumentReference {
        return this.getCategoryPlanningCollection(workspaceId).doc(planningId);
    }

    private toCategoryPlanningRef(doc: admin.firestore.QueryDocumentSnapshot): CategoryPlanningRef {
        return {
            id: doc.id,
            workspaceId: doc.ref.parent.parent!.id,
            ref: doc.ref,
            ...doc.data(),
        } as CategoryPlanningRef;
    }

    /**
     * Planejamentos atrasados em relação ao horizonte (F1.5).
     *
     * A query antiga (`lastSummaryMonth < mês`) buscava um campo que ninguém
     * gravava: o cron era inerte para todo planejamento criado pelo app. Agora
     * o campo é `summarizedUntil`, escrito pelo gatilho e por este mesmo cron,
     * e a leitura é paginada por cursor — sem o GLOBAL_LIMIT de 500 que
     * silenciosamente ignorava o resto da base.
     */
    async getCategoryPlanningsPendingSummary(
        horizon: string,
        pageSize: number,
        cursor?: admin.firestore.QueryDocumentSnapshot | null
    ): Promise<CategoryPlanningPage> {
        let query: admin.firestore.Query = this.firestore.collectionGroup("category_planning")
            .where("summarizedUntil", "<", horizon)
            .orderBy("summarizedUntil")
            .limit(pageSize);

        if (cursor) query = query.startAfter(cursor);

        const snapshot = await query.get();

        return {
            items: snapshot.docs.map((doc) => this.toCategoryPlanningRef(doc)),
            cursor: snapshot.size < pageSize ? null : snapshot.docs[snapshot.size - 1],
        };
    }

    /**
     * Varredura paginada por id — única forma de achar quem NÃO tem o campo.
     *
     * O cursor entra e sai como CAMINHO de documento para poder ser guardado no
     * checkpoint entre execuções do cron. Num `collectionGroup` ordenado por
     * `documentId()` o cursor é o caminho completo, por isso ele é reconstruído
     * como `DocumentReference`.
     */
    async scanCategoryPlannings(pageSize: number, afterPath?: string | null): Promise<CategoryPlanningScanPage> {
        let query: admin.firestore.Query = this.firestore.collectionGroup("category_planning")
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pageSize);

        if (afterPath) query = query.startAfter(this.firestore.doc(afterPath));

        const snapshot = await query.get();

        return {
            items: snapshot.docs.map((doc) => this.toCategoryPlanningRef(doc)),
            // Página incompleta = fim da coleção; o checkpoint é zerado e a
            // próxima execução recomeça do início.
            nextPath: snapshot.size < pageSize ? null : snapshot.docs[snapshot.size - 1].ref.path,
        };
    }

    private getCronCheckpointsDocRef() {
        return this.firestore.collection("config").doc("cron_checkpoints");
    }

    async getCronCheckpoint(field: string): Promise<string | null> {
        const doc = await this.getCronCheckpointsDocRef().get();
        const value = doc.exists ? doc.data()?.[field] : null;
        return typeof value === "string" && value.length > 0 ? value : null;
    }

    async setCronCheckpoint(field: string, value: string | null): Promise<void> {
        await this.getCronCheckpointsDocRef().set({
            [field]: value,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }

    /**
     * Aplica os impactos de planejamento e grava os marcadores.
     *
     * Os deltas são AGRUPADOS por documento de sumário antes de virarem
     * escrita: um horizonte de 12 meses gera ~70 impactos que caem em ~66
     * documentos, e o código antigo fazia um `set` sequencial por impacto.
     * Deltas que se anulam (estorno + reaplicação do mesmo mês) somem — editar
     * só o fim do período escreve apenas os meses que mudaram.
     *
     * Os marcadores vão no FIM da lista: se um lote falhar no meio, o
     * planejamento não fica marcado como sumarizado sem os impactos.
     */
    async applyPlanningImpacts(
        workspaceId: string,
        updates: PeriodSummaryUpdateModel[],
        marks?: { ref: admin.firestore.DocumentReference, data: CategoryPlanningMarks }
    ): Promise<void> {
        const operations: BatchOperation[] = [];

        for (const [docId, group] of groupPlanningUpdates(updates)) {
            const categories: Record<string, any> = {};

            for (const bucket of group.categories.values()) {
                if (Math.abs(bucket.delta) < PLANNING_DELTA_EPSILON) continue;
                categories[bucket.category.id] = {
                    generalPlannedAmount: admin.firestore.FieldValue.increment(bucket.delta),
                };
            }

            if (Object.keys(categories).length === 0) continue;

            operations.push({
                op: "set",
                ref: this.getPeriodSummariesCollection(workspaceId).doc(docId),
                data: {
                    year: group.year,
                    month: group.month ?? null,
                    week: group.week ?? null,
                    categories,
                    lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                    runtimeType: group.runtimeType,
                },
                options: { merge: true },
            });
        }

        if (marks) {
            operations.push({ op: "set", ref: marks.ref, data: { ...marks.data }, options: { merge: true } });
        }

        await commitInChunks(this.firestore, operations);
    }

    private getPeriodSummaryDocRef(workspaceId: string, year: number, month?: number, week?: number): { docRef: admin.firestore.DocumentReference, runtimeType: string } {
        let summaryId = "";
        let runtimeType = "";

        if (week !== undefined) {
            summaryId = `${year}-W${String(week).padStart(2, "0")}`;
            runtimeType = "week";
        }
        else if (month !== undefined) {
            summaryId = `${year}-${String(month).padStart(2, "0")}`;
            runtimeType = "month";
        }
        else {
            summaryId = `${year}`;
            runtimeType = "year";
        }

        return {
            docRef: this.getPeriodSummariesCollection(workspaceId).doc(summaryId),
            runtimeType
        };
    }

    private buildPeriodSummaryUpdateData(
        year: number,
        month: number | undefined,
        week: number | undefined,
        category: CategoryModel,
        data: {
            generalPlannedDelta?: number,
            specificPlannedDelta?: number,
            actualDelta?: number
        },
        runtimeType: string
    ): any {
        return {
            year,
            month: month ?? null,
            week: week ?? null,
            categories: {
                [category.id]: {
                    generalPlannedAmount: admin.firestore.FieldValue.increment(data.generalPlannedDelta ?? 0),
                    specificPlannedAmount: admin.firestore.FieldValue.increment(data.specificPlannedDelta ?? 0),
                    actualAmount: admin.firestore.FieldValue.increment(data.actualDelta ?? 0),
                },
            },
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
            runtimeType: runtimeType,
        };
    }

    async updatePeriodSummary(
        workspaceId: string,
        year: number,
        month: number | undefined,
        category: CategoryModel,
        data: {
            generalPlannedDelta?: number,
            specificPlannedDelta?: number,
            actualDelta?: number
        },
        week?: number
    ): Promise<void> {
        const { docRef, runtimeType } = this.getPeriodSummaryDocRef(workspaceId, year, month, week);
        const updateData = this.buildPeriodSummaryUpdateData(year, month, week, category, data, runtimeType);

        await docRef.set(updateData, { merge: true });
    }

    async getPeriodSummary(workspaceId: string, year: number, month?: number, week?: number): Promise<any | null> {
        const { docRef } = this.getPeriodSummaryDocRef(workspaceId, year, month, week);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        return { id: doc.id, ...doc.data() };
    }

    async getAccountById(workspaceId: string, accountId: string): Promise<AccountModel | null> {
        const doc = await this.getAccountsCollection(workspaceId).doc(accountId).get();
        if (!doc.exists) return null;
        return { id: doc.id, ...doc.data() } as AccountModel;
    }

    /**
     * Aplica `delta` no saldo do dia e propaga para os dias seguintes (F1.4).
     *
     * O modelo antigo fazia TUDO numa transação só: lia o documento do dia, lia
     * TODOS os saldos futuros e atualizava um por um lá dentro. Um pagamento
     * retroativo de três anos atrás estourava o limite de 500 escritas por
     * transação e nada era gravado. Pior: o saldo inicial do dia vinha de
     * `getLastBalanceBefore`, chamado FORA da transação e com
     * `orderBy(documentId(), "desc")` — rejeitado pelo emulador e dependente de
     * um índice `balance __name__ DESC` em produção.
     *
     * Agora são duas fases:
     *
     *  1. **transação pequena** (2 leituras, 1 escrita): o documento do dia e o
     *     último documento anterior. Grava `delta` (soma dos movimentos do dia)
     *     e `balance = anterior.balance + delta`;
     *  2. **propagação fora da transação**, paginando os dias seguintes e
     *     somando `delta` ao `balance` de cada um em lotes de no máximo 400
     *     escritas (`commitInChunks`).
     *
     * Entre as duas fases o saldo dos dias seguintes fica momentaneamente
     * defasado — é o preço de não estourar a transação. A operação inteira é
     * idempotente por evento: quem garante que ela não roda duas vezes para o
     * mesmo evento é o `runIdempotency` do handler.
     *
     * CONCORRÊNCIA: o `delta` de cada dia é sempre exato (a transação serializa
     * o dia) e a propagação usa `FieldValue.increment`, que é atômico. Resta uma
     * janela estreita: se um segundo evento CRIAR um dia posterior no intervalo
     * entre o commit desta transação e a consulta de propagação, esse dia nasce
     * já com o efeito deste evento e recebe o incremento de novo. A janela é de
     * milissegundos, só afeta o acumulado (nunca o `delta`) e o
     * `rebuild_workspace.ts` recalcula a série inteira a partir das parcelas —
     * é ele o conserto, e o teste de propriedade de
     * `rebuild.integration.test.ts` é quem vigia.
     */
    async updateAccountBalance(
        workspaceId: string,
        accountId: string,
        date: Date,
        delta: number
    ): Promise<void> {
        const dateKey = toDateKey(date);
        const balancesColl = this.getAccountBalanceCollection(workspaceId, accountId);
        const docRef = balancesColl.doc(dateKey);

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            const previous = await this.readPreviousBalanceDoc(balancesColl, dateKey, transaction);
            const previousBalance = toNumber(previous?.balance);

            const data = doc.exists ? doc.data() ?? {} : null;
            // Documento legado (só `balance`, sem `delta`): o movimento do dia é
            // a diferença para o saldo do dia anterior — a mesma conta que o
            // script de migração faz.
            const currentDelta = data
                ? (typeof data.delta === "number" ? data.delta : toNumber(data.balance) - previousBalance)
                : 0;

            const newDelta = roundCents(currentDelta + delta);

            transaction.set(docRef, {
                dateKey,
                delta: newDelta,
                balance: roundCents(previousBalance + newDelta),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        });

        await this.propagateBalanceDelta(balancesColl, dateKey, delta);
    }

    /**
     * Soma `delta` ao saldo acumulado de todos os dias POSTERIORES a `dateKey`.
     *
     * Pagina por documentId ascendente: o id do documento É o `dateKey` (é o
     * contrato que o app usa para ler os últimos saldos), então a ordem é a
     * mesma de `orderBy("dateKey")` e a varredura enxerga também os documentos
     * legados, que ainda não têm o campo. Varredura ascendente não precisa de
     * índice e é aceita pelo emulador.
     *
     * A soma usa `FieldValue.increment`: a propagação roda fora de transação e
     * dois eventos concorrentes podem tocar o mesmo dia futuro. Aproveita a
     * passagem para preencher o `dateKey` dos documentos legados.
     */
    private async propagateBalanceDelta(
        balancesColl: admin.firestore.CollectionReference,
        dateKey: string,
        delta: number
    ): Promise<void> {
        if (!delta) return;

        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = balancesColl
                .where(admin.firestore.FieldPath.documentId(), ">", dateKey)
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(BALANCE_PROPAGATION_PAGE_SIZE);

            if (cursor) query = query.startAfter(cursor);

            const snapshot = await query.get();
            if (snapshot.empty) return;

            const operations: BatchOperation[] = snapshot.docs.map((doc) => {
                const data: Record<string, any> = {
                    balance: admin.firestore.FieldValue.increment(delta),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                };
                if (!isDateKey(doc.data()?.dateKey)) {
                    data.dateKey = doc.id;
                }
                return { op: "update", ref: doc.ref, data };
            });

            await commitInChunks(this.firestore, operations, BALANCE_PROPAGATION_PAGE_SIZE);

            if (snapshot.size < BALANCE_PROPAGATION_PAGE_SIZE) return;
            cursor = snapshot.docs[snapshot.size - 1];
        }
    }

    /**
     * Último documento de saldo ANTERIOR a `dateKey`.
     *
     * Caminho rápido: `where("dateKey", "<", key).orderBy("dateKey", "desc")`,
     * um campo indexado — nada de `documentId()` descendente.
     *
     * Compatibilidade: enquanto `migrate_balance_date_key.ts` não rodar, existem
     * documentos sem o campo `dateKey`, que a query acima NÃO casa. Como o id é
     * o próprio dateKey, uma varredura ASCENDENTE por id no intervalo
     * `(candidato, key)` encontra qualquer documento legado mais recente que o
     * candidato. Numa base já migrada esse intervalo é vazio e custa uma
     * leitura; numa base legada ele paga o preço até a migração rodar.
     */
    private async readPreviousBalanceDoc(
        balancesColl: admin.firestore.CollectionReference,
        dateKey: string,
        transaction?: admin.firestore.Transaction
    ): Promise<{ id: string, balance: number, data: Record<string, any> } | null> {
        const run = async (query: admin.firestore.Query) =>
            (transaction ? transaction.get(query) : query.get());

        const indexed = await run(
            balancesColl
                .where("dateKey", "<", dateKey)
                .orderBy("dateKey", "desc")
                .limit(1)
        );

        const candidate = indexed.empty ? null : indexed.docs[0];
        const legacy = await this.findLastLegacyBalanceDoc(balancesColl, candidate?.id ?? null, dateKey, run);
        const chosen = legacy ?? candidate;

        if (!chosen) return null;
        const data = chosen.data() ?? {};
        return { id: chosen.id, balance: toNumber(data.balance), data };
    }

    /** Último documento por id no intervalo aberto `(after, before)`, varrendo ascendente. */
    private async findLastLegacyBalanceDoc(
        balancesColl: admin.firestore.CollectionReference,
        after: string | null,
        before: string,
        run: (query: admin.firestore.Query) => Promise<admin.firestore.QuerySnapshot>
    ): Promise<admin.firestore.QueryDocumentSnapshot | null> {
        let last: admin.firestore.QueryDocumentSnapshot | null = null;
        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = balancesColl
                .where(admin.firestore.FieldPath.documentId(), "<", before);

            if (after !== null) {
                query = query.where(admin.firestore.FieldPath.documentId(), ">", after);
            }

            query = query
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(BALANCE_PROPAGATION_PAGE_SIZE);

            if (cursor) query = query.startAfter(cursor);

            const snapshot = await run(query);
            if (snapshot.empty) return last;

            last = snapshot.docs[snapshot.size - 1];

            if (snapshot.size < BALANCE_PROPAGATION_PAGE_SIZE) return last;
            cursor = last;
        }
    }

    async getLastBalanceBefore(
        workspaceId: string,
        accountId: string,
        date: Date
    ): Promise<AccountBalanceModel | null> {
        const balancesColl = this.getAccountBalanceCollection(workspaceId, accountId);
        const previous = await this.readPreviousBalanceDoc(balancesColl, toDateKey(date));
        if (!previous) return null;

        const data = previous.data;
        return {
            ...data,
            id: previous.id,
            dateKey: isDateKey(data.dateKey) ? data.dateKey : previous.id,
            balance: previous.balance,
            updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(data.updatedAt),
        } as AccountBalanceModel;
    }

    async getAllWorkspaces(): Promise<string[]> {
        const snapshot = await admin.firestore().collection("workspaces").get();
        return snapshot.docs.map((doc) => doc.id);
    }

    async updateOrderCategory(workspaceId: string, category: CategoryModel) {
        const snapshot = await this.getOrdersCollection(workspaceId)
            .where("category.id", "==", category.id)
            .get();

        if (snapshot.empty) return;

        const operations: BatchOperation[] = snapshot.docs.map((doc) => ({
            op: "update",
            ref: doc.ref,
            data: { category: category },
        }));
        await commitInChunks(this.firestore, operations);
    }

    async updateInstallmentCategory(workspaceId: string, category: CategoryModel) {
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("category.id", "==", category.id)
            .get();

        if (snapshot.empty) return;

        const operations: BatchOperation[] = snapshot.docs.map((doc) => ({
            op: "update",
            ref: doc.ref,
            data: { category: category },
        }));
        await commitInChunks(this.firestore, operations);
    }

    async updateInvoiceWithDelta(
        workspaceId: string,
        account: AccountModel,
        dueDate: Date,
        delta: number
    ): Promise<void> {
        if (delta === 0) return;

        const dueDateStr = dueDate.toISOString().split("T")[0];
        const orderId = `invoice-${account.id}-${dueDateStr}`;

        const orderRef = this.getOrdersCollection(workspaceId).doc(orderId);

        const orderData = {
            amount: admin.firestore.FieldValue.increment(delta),
            dueDay: dueDate.getDate(),
            description: `Fatura ${account.name}`,
            startMonth: `${dueDate.getFullYear()}-${(dueDate.getMonth() + 1).toString().padStart(2, "0")}`,
            endMonth: `${dueDate.getFullYear()}-${(dueDate.getMonth() + 1).toString().padStart(2, "0")}`,
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.transfer,
            accountIds: [account.id],
            accounts: { [account.id]: "credit" },
            isInvoice: true,
        };

        await orderRef.set(orderData, { merge: true });
    }

    async getLastCoachingAnalyses(workspaceId: string, limit: number): Promise<any[]> {
        const snapshot = await admin.firestore()
            .collection("workspaces")
            .doc(workspaceId)
            .collection("financial_coaching")
            .orderBy("date", "desc")
            .limit(limit)
            .get();

        return snapshot.docs.map(doc => {
            const data = doc.data() as any;
            let date = data.date;
            if (date && typeof date.toDate === "function") {
                date = date.toDate();
            }
            return {
                id: doc.id,
                ...data,
                date
            };
        });
    }

    async saveCoachingAnalysis(workspaceId: string, analysis: any): Promise<string> {
        const docRef = await admin.firestore()
            .collection("workspaces")
            .doc(workspaceId)
            .collection("financial_coaching")
            .add({
                ...analysis,
                date: analysis.date instanceof Date
                    ? admin.firestore.Timestamp.fromDate(analysis.date)
                    : admin.firestore.FieldValue.serverTimestamp(),
            });
        return docRef.id;
    }

    private getCoachingMetaDocRef(workspaceId: string) {
        return this.firestore
            .collection("workspaces")
            .doc(workspaceId)
            .collection("coaching_meta")
            .doc("category_groups");
    }

    async getCoachingCategoryGroups(workspaceId: string): Promise<Record<string, { group: string; name: string }> | null> {
        const doc = await this.getCoachingMetaDocRef(workspaceId).get();
        if (!doc.exists) return null;
        const data = doc.data() as any;
        return data?.groups || null;
    }

    async saveCoachingCategoryGroups(
        workspaceId: string,
        entries: Record<string, { group: string; name: string }>
    ): Promise<void> {
        if (Object.keys(entries).length === 0) return;
        await this.getCoachingMetaDocRef(workspaceId).set({
            groups: entries,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }

    private getPlanningAnalysisDocRef(workspaceId: string, monthKey: string) {
        return this.firestore
            .collection("workspaces")
            .doc(workspaceId)
            .collection("planning_analysis")
            .doc(monthKey);
    }

    async getPlanningAnalysis(workspaceId: string, monthKey: string): Promise<any | null> {
        const doc = await this.getPlanningAnalysisDocRef(workspaceId, monthKey).get();
        if (!doc.exists) return null;
        return { id: doc.id, ...doc.data() };
    }

    async savePlanningAnalysis(workspaceId: string, monthKey: string, analysis: any): Promise<void> {
        await this.getPlanningAnalysisDocRef(workspaceId, monthKey).set({
            ...analysis,
            createdAt: analysis.createdAt instanceof Date
                ? admin.firestore.Timestamp.fromDate(analysis.createdAt)
                : admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    async hasPaidInstallmentSince(workspaceId: string, since: Date): Promise<boolean> {
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("paidDate", ">=", admin.firestore.Timestamp.fromDate(since))
            .limit(1)
            .get();
        return !snapshot.empty;
    }

    async getAccounts(workspaceId: string): Promise<AccountModel[]> {
        const snapshot = await this.getAccountsCollection(workspaceId).where("isDeleted", "==", false).get();
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as AccountModel));
    }
}
