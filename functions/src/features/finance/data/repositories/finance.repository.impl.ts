import { CategoryModel, hasCategoryId } from "../../../workspace/domain/models/category.model";
import * as admin from "firebase-admin";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    CategoryPlanningMarks,
    AccountModel,
    AccountBalanceModel,
    INVOICE_CYCLE_FIELDS,
    NextInvoiceModel,
    PeriodSummaryUpdateModel,
    OrderStatus,
    InstallmentType,
    OrderType,
    InstallmentStatus,
    PeriodSummaryDocument,
    toPeriodSummaryDocument,
} from "../../domain/models/finance.models";
import {
    PlanningAnalysisDocument,
    PlanningAnalysisWrite,
    toPlanningAnalysisDocument,
} from "../../domain/models/planning_analysis.model";
import {
    CoachingAnalysisDocument,
    CoachingAnalysisWrite,
    toCoachingAnalysisDocument,
} from "../../../coaching/domain/models/coaching_analysis.model";
import {
    CategoryPlanningPage,
    CategoryPlanningRef,
    CategoryPlanningScanPage,
    IFinanceRepository,
} from "../../domain/repositories/finance.repository";
import { BatchOperation, commitInChunks, DEFAULT_CHUNK_SIZE, deleteByQueryInChunks } from "../../../../core/utils/batch.utils";
import { isDateKey, toDateKey } from "../../../../core/utils/date_key";
import { getZonedParts } from "../../../../core/utils/timezone.utils";
import { InvoiceService } from "../../domain/services/invoice.service";
import { RawFirestoreDate, TimestampLike, stripUndefined } from "../../../../core/utils/firestore.utils";
import { fromCents, readCents, resolveCents, toCents } from "../../../../core/utils/money";

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

/**
 * Dias por TRANSAÇÃO na propagação (F1.10).
 *
 * Menor que a página de leitura de propósito: cada transação lê e reescreve os
 * documentos, e quanto mais documentos ela toca, maior a chance de outro evento
 * mexer num deles e forçar o retry do lote inteiro. Um pagamento retroativo de
 * três anos vira ~10 transações em vez de uma.
 */
const BALANCE_PROPAGATION_CHUNK = 100;


/**
 * O que `updateInstallment` lê do documento JÁ GRAVADO para recalcular os
 * campos derivados. As datas são `Timestamp` (é o documento cru) e os valores
 * podem faltar — `paidAmount` só existe na parcela paga.
 */
interface StoredInstallmentDates {
    dueDate: TimestampLike;
    paidDate?: TimestampLike | null;
    amount?: number;
    paidAmount?: number | null;
    amountCents?: number;
    paidAmountCents?: number | null;
}

interface PlanningCategoryBucket {
    category: CategoryModel;
    /** F1.10 — o delta acumulado em CENTAVOS INTEIROS. */
    deltaCents: number;
}

/**
 * Delta monetário de UMA categoria num documento de sumário, em centavos
 * inteiros. Os três totais juntos porque a escrita é uma só.
 */
interface SummaryCategoryDelta {
    category: CategoryModel;
    generalCents: number;
    specificCents: number;
    actualCents: number;
}

/** Os deltas de UM documento de `period_summaries`, agrupados por categoria. */
interface SummaryDocDelta {
    year: number;
    month: number | null;
    week: number | null;
    runtimeType: string;
    categories: Map<string, SummaryCategoryDelta>;
}

/**
 * Documentos de sumário lidos e escritos por TRANSAÇÃO.
 *
 * Um horizonte de planejamento de 12 meses gera ~66 documentos, que assim cabem
 * numa transação só. O teto do Firestore é 500 ESCRITAS por transação; 100
 * deixa folga e mantém estreita a janela de contenção — quanto mais documentos
 * numa transação, maior a chance de outro gatilho tocar um deles e forçar o
 * retry do lote inteiro.
 */
const SUMMARY_TRANSACTION_CHUNK = 100;

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

        // `?? ""` para uma categoria ausente cair no MESMO balde do id vazio, e
        // ser descartada com aviso em `applyPlanningImpacts` — em vez de
        // estourar aqui e derrubar o lote inteiro.
        const categoryKey = update.category?.id ?? "";
        let bucket = group.categories.get(categoryKey);
        if (!bucket) {
            bucket = { category: update.category, deltaCents: 0 };
            group.categories.set(categoryKey, bucket);
        }
        // F1.10 — o agrupamento soma CENTAVOS. Somando os `double`, o estorno
        // de um planejamento raramente cancelava a aplicação exatamente, e
        // sobrava um resto de 1e-13 que virava escrita: era por isso que
        // existia o `PLANNING_DELTA_EPSILON = 1e-9` logo abaixo. Em inteiros o
        // par estorno + reaplicação do mesmo mês dá zero e some.
        bucket.deltaCents += toCents(update.generalPlannedDelta ?? 0);
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
): Record<string, unknown> {
    const referenceDate = installment.paidDate || installment.dueDate;
    const referenceAmount = installment.paidAmount !== undefined && installment.paidAmount !== null
        ? installment.paidAmount
        : installment.amount;

    // `stripUndefined`: a parcela tem uma dúzia de campos opcionais
    // (`installmentNumber`, `category`, `isInvoice`, a janela do ciclo...) e o
    // chamador monta o objeto com os que valem para o caso dele. Sem o
    // descarte explícito, uma chave ausente chegaria ao SDK como `undefined` e
    // — desligado o `ignoreUndefinedProperties` — derrubaria a criação inteira.
    return stripUndefined({
        ...installment,
        dueDate: admin.firestore.Timestamp.fromDate(installment.dueDate),
        paidDate: installment.paidDate ? admin.firestore.Timestamp.fromDate(installment.paidDate) : null,
        referenceDate: admin.firestore.Timestamp.fromDate(referenceDate),
        referenceAmount: referenceAmount,
        // F1.10 — DUPLA ESCRITA: toda parcela criada pelo servidor já nasce com
        // os espelhos inteiros. `paidAmountCents` só existe quando a parcela
        // nasce paga: ausente continua significando ausente, nunca zero.
        amountCents: toCents(installment.amount),
        referenceAmountCents: toCents(referenceAmount),
        paidAmountCents: installment.paidAmount !== undefined && installment.paidAmount !== null
            ? toCents(installment.paidAmount)
            : undefined,
    });
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
        // `OrderModel` tem campos opcionais (`endMonth`, `installmentCount`,
        // `category`, a janela do ciclo da fatura): o que o chamador não
        // preencheu não vai para o documento.
        // F1.10 — a order criada pelo servidor já nasce com o espelho inteiro.
        const data = stripUndefined({ ...order, amountCents: toCents(order.amount) });
        if (id) {
            await collection.doc(id).set(data);
            return id;
        }
        const docRef = await collection.add(data);
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
            ...toInvoiceCycle(data),
        } as OrderModel;
    }

    async updateOrder(workspaceId: string, orderId: string, order: Partial<OrderModel>): Promise<void> {
        // `Partial<OrderModel>`: as chaves ausentes vêm como `undefined` e
        // significam "não mexer neste campo", nunca "apagar".
        // F1.10 — quem mexe no `amount` mexe no espelho inteiro na MESMA
        // escrita. `updateInvoiceWithDelta` não passa por aqui: lá o total é
        // lido e regravado dentro de uma transação, com os dois campos juntos.
        const patch: Partial<OrderModel> = order.amount !== undefined
            ? { ...order, amountCents: toCents(order.amount) }
            : order;

        await this.getOrdersCollection(workspaceId).doc(orderId).update(stripUndefined(patch));
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

    async createOrderHistory(workspaceId: string, orderId: string, snapshot: Record<string, unknown>): Promise<void> {
        await this.getOrdersCollection(workspaceId)
            .doc(orderId)
            .collection("history")
            .add({
                snapshot: stripUndefined(snapshot),
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

            const currentData = doc.data() as StoredInstallmentDates;
            const data: Record<string, unknown> = { ...installment };

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
                data.referenceAmountCents = toCents(data.referenceAmount as number);
            }

            // F1.10 — o espelho inteiro acompanha SEMPRE o valor em reais, na
            // MESMA escrita: um `amount` novo com um `amountCents` velho é
            // exatamente a divergência que a etapa existe para impedir.
            if (installment.amount !== undefined) {
                data.amountCents = toCents(installment.amount);
            }
            if (installment.paidAmount !== undefined) {
                data.paidAmountCents = installment.paidAmount === null
                    ? null
                    : toCents(installment.paidAmount);
            }

            // Sincronizar accountIds se accounts mudar
            if (installment.accounts !== undefined) {
                data.accountIds = Object.keys(installment.accounts || {});
            }

            // `Partial<InstallmentModel>`: chave ausente é "não mexer".
            transaction.update(docRef, stripUndefined(data));
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
                ...toInvoiceCycle(data),
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
                ...toInvoiceCycle(data),
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
        const deltas = new Map<string, SummaryDocDelta>();

        for (const [docId, group] of groupPlanningUpdates(updates)) {
            const categories = new Map<string, SummaryCategoryDelta>();

            for (const bucket of group.categories.values()) {
                // Delta ZERO exato — sem épsilon: em centavos inteiros não há
                // ruído a tolerar.
                if (bucket.deltaCents === 0) continue;

                // MESMA REGRA DO SUMÁRIO (`hasCategoryId`): id vazio vira um
                // segmento vazio de FieldPath e o SDK rejeita o documento
                // inteiro. Aqui o estrago seria maior do que uma linha perdida:
                // um único `category_planning` com `category.id` vazio derruba o
                // lote inteiro e, com ele, o gatilho de planejamento e o cron
                // mensal — todos os outros meses e categorias junto. Pula com
                // aviso; o planejamento quebrado é que fica de fora.
                if (!hasCategoryId(bucket.category)) {
                    const name = (bucket.category as CategoryModel | undefined)?.name ?? "";
                    console.warn(`[applyPlanningImpacts] planejamento com categoria sem id: workspace=${workspaceId} documento=${docId} categoria="${name}". Fora do generalPlannedAmount; os demais impactos seguem. Corrija o category_planning.`);
                    continue;
                }

                categories.set(bucket.category.id, {
                    category: bucket.category,
                    generalCents: bucket.deltaCents,
                    specificCents: 0,
                    actualCents: 0,
                });
            }

            if (categories.size === 0) continue;

            deltas.set(docId, {
                year: group.year,
                month: group.month ?? null,
                week: group.week ?? null,
                runtimeType: group.runtimeType,
                categories,
            });
        }

        // Os impactos PRIMEIRO, os marcadores depois: se a aplicação falhar no
        // meio, o planejamento não fica marcado como sumarizado sem eles.
        await this.applySummaryDeltas(workspaceId, deltas);

        if (marks) {
            await marks.ref.set({ ...marks.data }, { merge: true });
        }
    }

    /**
     * Aplica deltas monetários em `period_summaries` por LEITURA + ESCRITA
     * ABSOLUTA, dentro de uma transação — e não por `FieldValue.increment`.
     *
     * **Por que o `increment` teve de sair (F1.10).** Incrementar um campo que
     * não existe começa do ZERO. Num documento anterior à migração, que tem
     * `actualAmount: 1000` e nenhum `actualAmountCents`, um delta de +25
     * produzia `actualAmount: 1025` (certo) e `actualAmountCents: 2500`
     * (errado) — e o inteiro é a FONTE DA VERDADE, então o número errado é
     * justamente o que manda. Semear fora da transação não resolve: entre a
     * leitura da semente e o commit, outro evento pode ter criado o campo.
     *
     * Dentro da transação, o valor lido e o valor escrito pertencem ao mesmo
     * instante lógico: o Firestore aborta e repete a transação se qualquer
     * documento lido mudar antes do commit. O preço é contenção onde antes não
     * havia — um documento mensal tocado por dois pagamentos simultâneos faz um
     * dos dois repetir. É um preço pequeno perto de gravar um total errado, e o
     * `increment` continua onde não há dinheiro (o `xp` semanal).
     *
     * A escrita é `set(..., {merge: true})` com o mapa de categorias: só as
     * categorias presentes no delta são tocadas, as demais ficam intactas.
     */
    private async applySummaryDeltas(
        workspaceId: string,
        deltas: Map<string, SummaryDocDelta>
    ): Promise<void> {
        if (deltas.size === 0) return;

        const collection = this.getPeriodSummariesCollection(workspaceId);
        const entries = [...deltas.entries()];

        for (let i = 0; i < entries.length; i += SUMMARY_TRANSACTION_CHUNK) {
            const chunk = entries.slice(i, i + SUMMARY_TRANSACTION_CHUNK);

            await this.firestore.runTransaction(async (transaction) => {
                const refs = chunk.map(([docId]) => collection.doc(docId));
                // Numa transação TODAS as leituras vêm antes de qualquer
                // escrita: `getAll` resolve o lote inteiro de uma vez.
                const snapshots = await transaction.getAll(...refs);

                chunk.forEach(([, delta], index) => {
                    const snapshot = snapshots[index];
                    const current = (snapshot.data()?.categories ?? {}) as Record<string, Record<string, unknown> | undefined>;
                    const categories: Record<string, Record<string, number>> = {};

                    for (const [categoryId, bucket] of delta.categories) {
                        const stored = current[categoryId] ?? {};

                        // O inteiro gravado manda; num documento ainda não
                        // migrado ele não existe e o `double` responde.
                        const general = resolveCents(toNumber(stored.generalPlannedAmount), stored.generalPlannedAmountCents)
                            + bucket.generalCents;
                        const specific = resolveCents(toNumber(stored.specificPlannedAmount), stored.specificPlannedAmountCents)
                            + bucket.specificCents;
                        const actual = resolveCents(toNumber(stored.actualAmount), stored.actualAmountCents)
                            + bucket.actualCents;

                        categories[categoryId] = {
                            generalPlannedAmount: fromCents(general),
                            specificPlannedAmount: fromCents(specific),
                            actualAmount: fromCents(actual),
                            generalPlannedAmountCents: general,
                            specificPlannedAmountCents: specific,
                            actualAmountCents: actual,
                        };
                    }

                    transaction.set(refs[index], {
                        year: delta.year,
                        month: delta.month,
                        week: delta.week,
                        categories,
                        lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                        runtimeType: delta.runtimeType,
                    }, { merge: true });
                });
            });
        }
    }

    private getPeriodSummaryDocRef(workspaceId: string, year: number, month?: number, week?: number): { docRef: admin.firestore.DocumentReference, docId: string, runtimeType: string } {
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
            docId: summaryId,
            runtimeType
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
        // DEFESA FINAL (categoria sem id). `categories.<id>` com id vazio vira
        // um segmento vazio de FieldPath e o SDK rejeita o documento inteiro
        // com "Element at index 0 should not be an empty string" — mensagem que
        // não diz nem qual workspace nem qual período. Quem chama já trata
        // categoria sem id como "sem categoria" (ver `hasCategoryId`); se algo
        // chegar aqui assim, é bug de chamador e o erro precisa apontar para
        // ele.
        if (!hasCategoryId(category)) {
            const name = (category as CategoryModel | undefined)?.name ?? "";
            throw new Error(`[updatePeriodSummary] categoria sem id: workspace=${workspaceId} período=${year}/${month ?? "-"}/W${week ?? "-"} categoria="${name}". Categoria sem id não entra em period_summaries.`);
        }

        const { docId, runtimeType } = this.getPeriodSummaryDocRef(workspaceId, year, month, week);

        // F1.10 — o delta chega em reais JÁ arredondado a duas casas por quem o
        // produziu, então `toCents` é exato.
        await this.applySummaryDeltas(workspaceId, new Map([[docId, {
            year,
            month: month ?? null,
            week: week ?? null,
            runtimeType,
            categories: new Map([[category.id, {
                category,
                generalCents: toCents(data.generalPlannedDelta ?? 0),
                specificCents: toCents(data.specificPlannedDelta ?? 0),
                actualCents: toCents(data.actualDelta ?? 0),
            }]]),
        }]]));
    }

    async getPeriodSummary(workspaceId: string, year: number, month?: number, week?: number): Promise<PeriodSummaryDocument | null> {
        const { docRef } = this.getPeriodSummaryDocRef(workspaceId, year, month, week);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        return toPeriodSummaryDocument(doc.id, doc.data());
    }

    async getAccountById(workspaceId: string, accountId: string): Promise<AccountModel | null> {
        const doc = await this.getAccountsCollection(workspaceId).doc(accountId).get();
        if (!doc.exists) return null;
        return toAccountModel(doc.id, doc.data()!);
    }

    async getNextPendingInvoice(workspaceId: string, accountId: string): Promise<InstallmentModel | null> {
        // Mesma consulta que o app fazia em `watchNextInvoice` — e o mesmo
        // índice composto (accountIds CONTAINS, isInvoice, status, dueDate).
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("isInvoice", "==", true)
            .where("accountIds", "array-contains", accountId)
            .where("status", "==", InstallmentStatus.pending)
            .orderBy("dueDate")
            .limit(1)
            .get();

        const doc = snapshot.docs[0];
        if (!doc) return null;

        const data = doc.data();
        // Sem `setHours(12)` aqui de propósito: o instante gravado é o que vai
        // para `nextInvoice.dueDate` e para a janela do ciclo. Normalizar a
        // hora no fuso do SERVIDOR é o que deslocava o dia da fatura.
        return {
            id: doc.id,
            ...data,
            dueDate: data.dueDate?.toDate ? data.dueDate.toDate() : new Date(data.dueDate),
            paidDate: data.paidDate?.toDate ? data.paidDate.toDate() : undefined,
            ...toInvoiceCycle(data),
        } as InstallmentModel;
    }

    async setAccountNextInvoice(
        workspaceId: string,
        accountId: string,
        nextInvoice: NextInvoiceModel | null
    ): Promise<void> {
        const docRef = this.getAccountsCollection(workspaceId).doc(accountId);

        if (!nextInvoice) {
            await docRef.set({ nextInvoice: admin.firestore.FieldValue.delete() }, { merge: true });
            return;
        }

        await docRef.set({
            nextInvoice: {
                dueDate: admin.firestore.Timestamp.fromDate(nextInvoice.dueDate),
                closingDate: admin.firestore.Timestamp.fromDate(nextInvoice.closingDate),
                cycleStart: admin.firestore.Timestamp.fromDate(nextInvoice.cycleStart),
                cycleEnd: admin.firestore.Timestamp.fromDate(nextInvoice.cycleEnd),
                amount: fromCents(nextInvoice.amountCents),
                amountCents: nextInvoice.amountCents,
                orderId: nextInvoice.orderId,
                installmentId: nextInvoice.installmentId,
                status: nextInvoice.status,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
        }, { merge: true });
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
     * o dia), e desde F1.10 a propagação também é transacional — cada página de
     * dias é lida e reescrita no mesmo instante lógico. Resta a MESMA janela
     * estreita de antes, que nenhuma das duas fecha: se um segundo evento CRIAR
     * um dia posterior no intervalo entre o commit desta transação e a consulta
     * de propagação, esse dia nasce já com o efeito deste evento e recebe o
     * ajuste de novo. A janela é de milissegundos, só afeta o acumulado (nunca
     * o `delta`) e o `rebuild_workspace.ts` recalcula a série inteira a partir
     * das parcelas — é ele o conserto, e o teste de propriedade de
     * `rebuild.integration.test.ts` é quem vigia.
     */
    async updateAccountBalance(
        workspaceId: string,
        accountId: string,
        date: Date,
        deltaCents: number
    ): Promise<void> {
        const dateKey = toDateKey(date);
        const balancesColl = this.getAccountBalanceCollection(workspaceId, accountId);
        const docRef = balancesColl.doc(dateKey);

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            const previous = await this.readPreviousBalanceDoc(balancesColl, dateKey, transaction);
            const previousBalanceCents = previous?.balanceCents ?? 0;

            const data = doc.exists ? doc.data() ?? {} : null;
            // Documento legado (só `balance`, sem `delta`): o movimento do dia é
            // a diferença para o saldo do dia anterior — a mesma conta que o
            // script de migração faz. Em centavos a subtração é exata.
            const currentDeltaCents = data
                ? (readCents(data.deltaCents) ?? (typeof data.delta === "number"
                    ? toCents(data.delta)
                    : toCents(toNumber(data.balance)) - previousBalanceCents))
                : 0;

            const newDeltaCents = currentDeltaCents + deltaCents;
            const newBalanceCents = previousBalanceCents + newDeltaCents;

            transaction.set(docRef, {
                dateKey,
                // F1.10 — o INTEIRO é a verdade; o `double` é o espelho round2.
                deltaCents: newDeltaCents,
                balanceCents: newBalanceCents,
                delta: fromCents(newDeltaCents),
                balance: fromCents(newBalanceCents),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        });

        await this.propagateBalanceDelta(balancesColl, dateKey, deltaCents);
    }

    /**
     * Soma `deltaCents` ao saldo acumulado de todos os dias POSTERIORES a
     * `dateKey`.
     *
     * Pagina por documentId ascendente: o id do documento É o `dateKey` (é o
     * contrato que o app usa para ler os últimos saldos), então a ordem é a
     * mesma de `orderBy("dateKey")` e a varredura enxerga também os documentos
     * legados, que ainda não têm o campo. Varredura ascendente não precisa de
     * índice e é aceita pelo emulador. Aproveita a passagem para preencher o
     * `dateKey` dos documentos legados.
     *
     * **F1.10 — cada página é uma TRANSAÇÃO, e não mais um lote de
     * `FieldValue.increment`.** O `increment` era atômico, mas num documento
     * anterior à migração o `balanceCents` não existe e o incremento nasceria
     * do ZERO: o inteiro — que é a fonte da verdade — passaria a discordar do
     * `double` para sempre. A semente tem de vir do `double` GRAVADO, e ler a
     * semente fora da escrita reabre a corrida que o `increment` fechava.
     * Dentro da transação o valor lido e o gravado são do mesmo instante
     * lógico: o Firestore aborta e repete se algum documento lido mudar antes
     * do commit. As páginas são pequenas (100 dias) para manter estreita a
     * janela de contenção.
     */
    private async propagateBalanceDelta(
        balancesColl: admin.firestore.CollectionReference,
        dateKey: string,
        deltaCents: number
    ): Promise<void> {
        if (!deltaCents) return;

        let cursorId: string | null = null;

        for (;;) {
            // Uma página = uma TRANSAÇÃO. A consulta que escolhe os dias roda
            // fora dela (uma query dentro da transação travaria o intervalo
            // inteiro); o que a transação garante é que o valor LIDO de cada
            // documento e o valor gravado são do mesmo instante lógico.
            let query: admin.firestore.Query = balancesColl
                .where(admin.firestore.FieldPath.documentId(), ">", dateKey)
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(BALANCE_PROPAGATION_CHUNK);

            if (cursorId !== null) query = query.startAfter(cursorId);

            const page = await query.get();
            if (page.empty) return;

            const refs = page.docs.map((doc) => doc.ref);

            await this.firestore.runTransaction(async (transaction) => {
                const snapshots = await transaction.getAll(...refs);

                snapshots.forEach((snapshot, index) => {
                    // Documento apagado entre a consulta e a transação: não há
                    // saldo a propagar, e um `set` o ressuscitaria.
                    if (!snapshot.exists) return;

                    const current = snapshot.data() ?? {};
                    // F1.10 — o inteiro é a verdade. Num documento anterior à
                    // migração ele não existe, e a SEMENTE vem do espelho —
                    // dentro da transação, para que nenhuma escrita concorrente
                    // caiba entre ler a semente e gravar o resultado. Fora da
                    // transação (como era antes) o inteiro podia nascer do
                    // delta e divergir do `double` para sempre.
                    const balanceCents = resolveCents(toNumber(current.balance), current.balanceCents) + deltaCents;

                    const data: Record<string, unknown> = {
                        balance: fromCents(balanceCents),
                        balanceCents,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    };
                    if (!isDateKey(current.dateKey)) {
                        data.dateKey = snapshot.id;
                    }

                    transaction.set(refs[index], data, { merge: true });
                });
            });

            if (page.size < BALANCE_PROPAGATION_CHUNK) return;
            cursorId = page.docs[page.size - 1].id;
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
    ): Promise<{ id: string, balance: number, balanceCents: number, data: admin.firestore.DocumentData } | null> {
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
        const balanceCents = resolveCents(toNumber(data.balance), data.balanceCents);
        return { id: chosen.id, balance: fromCents(balanceCents), balanceCents, data };
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
            balanceCents: previous.balanceCents,
            updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(data.updatedAt),
        } as AccountBalanceModel;
    }


    async updateOrderCategory(workspaceId: string, category: CategoryModel): Promise<void> {
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

    async updateInstallmentCategory(workspaceId: string, category: CategoryModel): Promise<void> {
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
        deltaCents: number
    ): Promise<void> {
        if (deltaCents === 0) return;

        const orderRef = await this.resolveInvoiceOrderRef(workspaceId, account.id, dueDate);

        // Dia e mês da fatura vêm do fuso do PRODUTO. `getDate()/getMonth()` é
        // o fuso do servidor (UTC nas Cloud Functions): um vencimento gravado
        // às 21h de São Paulo virava o dia seguinte no `dueDay` da order, e a
        // parcela nascia com o vencimento errado.
        const p = getZonedParts(dueDate);
        const monthKey = `${p.year}-${p.month.toString().padStart(2, "0")}`;

        // A janela do ciclo vai GRAVADA na order (e daí para a parcela): é o
        // que permite ao app listar as compras desta fatura sem recalcular a
        // regra — inclusive de uma fatura antiga, aberta pelo histórico.
        const cycle = InvoiceService.calculateInvoiceCycleRange(dueDate, account);

        const orderData = {
            dueDay: p.day,
            description: `Fatura ${account.name}`,
            startMonth: monthKey,
            endMonth: monthKey,
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.transfer,
            accountIds: [account.id],
            accounts: { [account.id]: "credit" },
            isInvoice: true,
            cycleStart: admin.firestore.Timestamp.fromDate(cycle.start),
            cycleEnd: admin.firestore.Timestamp.fromDate(cycle.end),
            closingDate: admin.firestore.Timestamp.fromDate(cycle.closingDate),
        };

        // F1.10 — LEITURA + ESCRITA ABSOLUTA numa transação, pelo mesmo motivo
        // dos sumários: `increment` num `amountCents` que ainda não existe
        // (order de fatura anterior à migração) faria o inteiro nascer do
        // delta, e é o inteiro que manda. Dentro da transação o valor lido e o
        // gravado são do mesmo instante lógico.
        await this.firestore.runTransaction(async (transaction) => {
            const snapshot = await transaction.get(orderRef);
            const current = snapshot.data() ?? {};
            const amountCents = resolveCents(toNumber(current.amount), current.amountCents) + deltaCents;

            transaction.set(orderRef, {
                ...orderData,
                amount: fromCents(amountCents),
                amountCents,
            }, { merge: true });
        });
    }

    /**
     * Referência da order de fatura do vencimento, reconhecendo os DOIS
     * formatos de id.
     *
     * O id canônico passou a usar `toDateKey` (dia no fuso do produto); o
     * antigo usava `toISOString()` (dia em UTC). Enquanto o servidor rodou em
     * UTC com o vencimento ao meio-dia os dois coincidiam, mas nem toda order
     * da base nasceu assim. Quando os ids DIFEREM e só o antigo existe,
     * continuamos escrevendo nele: criar a order canônica ao lado
     * DUPLICARIA a fatura daquele mês.
     */
    private async resolveInvoiceOrderRef(
        workspaceId: string,
        accountId: string,
        dueDate: Date
    ): Promise<admin.firestore.DocumentReference> {
        const collection = this.getOrdersCollection(workspaceId);
        const canonicalId = InvoiceService.invoiceOrderId(accountId, dueDate);
        const legacyId = InvoiceService.legacyInvoiceOrderId(accountId, dueDate);

        if (canonicalId === legacyId) {
            return collection.doc(canonicalId);
        }

        const [canonical, legacy] = await Promise.all([
            collection.doc(canonicalId).get(),
            collection.doc(legacyId).get(),
        ]);

        if (!canonical.exists && legacy.exists) {
            return collection.doc(legacyId);
        }

        return collection.doc(canonicalId);
    }

    async getLastCoachingAnalyses(workspaceId: string, limit: number): Promise<CoachingAnalysisDocument[]> {
        const snapshot = await admin.firestore()
            .collection("workspaces")
            .doc(workspaceId)
            .collection("financial_coaching")
            .orderBy("date", "desc")
            .limit(limit)
            .get();

        return snapshot.docs.map(doc => toCoachingAnalysisDocument(doc.id, doc.data()));
    }

    async saveCoachingAnalysis(workspaceId: string, analysis: CoachingAnalysisWrite): Promise<string> {
        const docRef = await admin.firestore()
            .collection("workspaces")
            .doc(workspaceId)
            .collection("financial_coaching")
            .add({
                // `stripUndefined`: um slide sem botão não tem `actionPath` nem
                // `actionLabel`, e as chaves ausentes não podem ir ao SDK.
                ...stripUndefined(analysis),
                date: admin.firestore.Timestamp.fromDate(analysis.date),
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
        const data = doc.data();
        return (data?.groups as Record<string, { group: string; name: string }> | undefined) || null;
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

    async getPlanningAnalysis(workspaceId: string, monthKey: string): Promise<PlanningAnalysisDocument | null> {
        const doc = await this.getPlanningAnalysisDocRef(workspaceId, monthKey).get();
        if (!doc.exists) return null;
        return toPlanningAnalysisDocument(doc.id, doc.data());
    }

    async savePlanningAnalysis(workspaceId: string, monthKey: string, analysis: PlanningAnalysisWrite): Promise<void> {
        await this.getPlanningAnalysisDocRef(workspaceId, monthKey).set({
            // `stripUndefined`: `suggestedAllocation` e `savingTip` são `null`
            // explícitos, mas o payload passa por aqui inteiro e uma chave
            // opcional futura não pode derrubar a gravação.
            ...stripUndefined(analysis),
            createdAt: admin.firestore.Timestamp.fromDate(analysis.createdAt),
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
        return snapshot.docs.map(doc => toAccountModel(doc.id, doc.data()));
    }
}

/**
 * Converte o documento cru da conta no modelo, normalizando os `Timestamp` de
 * `nextInvoice` para `Date`. Sem isso, quem compara o resumo já gravado com o
 * recém-calculado compararia `Timestamp` com `Date` e reescreveria sempre —
 * e cada escrita dispara `onAccountUpdated` de novo.
 */
function toAccountModel(id: string, data: admin.firestore.DocumentData): AccountModel {
    const account = { id, ...data } as AccountModel;
    const raw = data.nextInvoice;

    if (raw && typeof raw === "object") {
        account.nextInvoice = {
            dueDate: toDateOrNull(raw.dueDate)!,
            closingDate: toDateOrNull(raw.closingDate)!,
            cycleStart: toDateOrNull(raw.cycleStart)!,
            cycleEnd: toDateOrNull(raw.cycleEnd)!,
            amount: fromCents(resolveCents(typeof raw.amount === "number" ? raw.amount : 0, raw.amountCents)),
            amountCents: resolveCents(typeof raw.amount === "number" ? raw.amount : 0, raw.amountCents),
            orderId: typeof raw.orderId === "string" ? raw.orderId : "",
            installmentId: typeof raw.installmentId === "string" ? raw.installmentId : null,
            status: raw.status ?? InstallmentStatus.pending,
        };

        // A chave só entra quando existe. `updatedAt: undefined` (o que este
        // trecho fazia com `?? undefined`) é diferente de chave ausente: o
        // modelo volta a ser gravado tal como veio em
        // `automatic_transactions.suggestedAccount`, e com o
        // `ignoreUndefinedProperties` desligado a escrita LANÇA. Como aquele
        // enriquecimento engole os próprios erros, a sugestão sumia calada.
        const updatedAt = toDateOrNull(raw.updatedAt);
        if (updatedAt) {
            account.nextInvoice.updatedAt = updatedAt;
        }
    }

    return account;
}

/**
 * Janela do ciclo da fatura (`cycleStart`/`cycleEnd`/`closingDate`) como
 * `Date`. Ausente em orders e parcelas anteriores a F1.8 — e em tudo que não é
 * fatura —, por isso as chaves só entram quando existem: um `undefined`
 * explícito sobrescreveria o spread anterior.
 */
function toInvoiceCycle(data: admin.firestore.DocumentData): Record<string, Date> {
    const cycle: Record<string, Date> = {};
    for (const field of INVOICE_CYCLE_FIELDS) {
        const value = toDateOrNull(data[field]);
        if (value) cycle[field] = value;
    }
    return cycle;
}

function toDateOrNull(value: RawFirestoreDate | null | undefined): Date | null {
    if (!value) return null;
    const timestamp = value as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") return timestamp.toDate();
    const date = new Date(value as string | number | Date);
    return Number.isNaN(date.getTime()) ? null : date;
}
