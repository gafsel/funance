import { CategoryModel } from "../../../workspace/domain/models/category.model";
import * as admin from "firebase-admin";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    AccountModel,
    AccountBalanceModel,
    PeriodSummaryUpdateModel,
    OrderStatus,
    InstallmentType,
    OrderType, InstallmentStatus,
} from "../../domain/models/finance.models";
import { IFinanceRepository } from "../../domain/repositories/finance.repository";

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

    async deleteOrder(workspaceId: string, orderId: string): Promise<void> {
        await this.getOrdersCollection(workspaceId).doc(orderId).delete();
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
        const ordersCollection = this.getOrdersCollection(workspaceId);

        const snapshot = await ordersCollection.where("accounts", "array-contains", accountId).get();
        const batch = this.firestore.batch();

        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
    }

    async createInstallments(workspaceId: string, installments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[]): Promise<void> {
        const batch = this.firestore.batch();
        const collection = this.getInstallmentsCollection(workspaceId);

        installments.forEach((installment) => {
            const docRef = collection.doc();
            const referenceDate = installment.paidDate || installment.dueDate;
            const referenceAmount = installment.paidAmount !== undefined && installment.paidAmount !== null
                ? installment.paidAmount
                : installment.amount;

            batch.set(docRef, {
                ...installment,
                dueDate: admin.firestore.Timestamp.fromDate(installment.dueDate),
                paidDate: installment.paidDate ? admin.firestore.Timestamp.fromDate(installment.paidDate) : null,
                referenceDate: admin.firestore.Timestamp.fromDate(referenceDate),
                referenceAmount: referenceAmount,
            });
        });

        await batch.commit();
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

    async getInstallmentById(workspaceId: string, installmentId: string): Promise<InstallmentModel | null> {
        const doc = await this.getInstallmentsCollection(workspaceId).doc(installmentId).get();
        if (!doc.exists) return null;
        const data = doc.data() as any;
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

    async deleteInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<void> {
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("orderId", "==", orderId)
            .get();

        const batch = this.firestore.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
    }

    async getInstallments(workspaceId: string, filters: {
        accountId?: string,
        startDate?: Date,
        endDate?: Date,
        status?: InstallmentStatus[]
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
            query = query.where("status", "in", filters.status);
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

    async getOrdersByRecurringNextGeneration(workspaceId: string, dateThreshold: Date): Promise<OrderModel[]> {
        const snapshot = await this.getOrdersCollection(workspaceId)
            .where("installmentType", "==", "recurring")
            .where("status", "==", "active")
            .where("lastGeneratedDueDate", "<", dateThreshold)
            .get();

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
        await this.firestore.runTransaction(async (transaction) => {
            for (const order of chunk) {
                const installments = installmentFactory(order);
                if (installments.length === 0) continue;

                const workspaceId = order.workspaceId;
                const installmentsCollection = this.getInstallmentsCollection(workspaceId);

                // Criar parcelas
                installments.forEach((installment) => {
                    const docRef = installmentsCollection.doc();
                    transaction.set(docRef, {
                        ...installment,
                        referenceDate: installment.dueDate,
                        referenceAmount: installment.amount,
                    });
                });

                // Atualizar order
                const lastGeneratedDueDate = installments[installments.length - 1].dueDate;
                const orderRef = this.getOrdersCollection(workspaceId).doc(order.id);
                transaction.update(orderRef, {
                    lastGeneratedDueDate: lastGeneratedDueDate,
                });
            }
        });
    }

    async getCategoryPlanningById(workspaceId: string, id: string): Promise<CategoryPlanningModel | null> {
        const doc = await this.getCategoryPlanningCollection(workspaceId).doc(id).get();
        if (!doc.exists) return null;
        return { id: doc.id, ...doc.data() } as CategoryPlanningModel;
    }

    async createCategoryPlanning(workspaceId: string, planning: Omit<CategoryPlanningModel, "id">): Promise<string> {
        const docRef = await this.getCategoryPlanningCollection(workspaceId).add(planning);
        return docRef.id;
    }

    async updateCategoryPlanning(workspaceId: string, id: string, planning: Partial<CategoryPlanningModel>): Promise<void> {
        await this.getCategoryPlanningCollection(workspaceId).doc(id).update(planning);
    }

    async deleteCategoryPlanning(workspaceId: string, id: string): Promise<void> {
        await this.getCategoryPlanningCollection(workspaceId).doc(id).delete();
    }

    async deleteCategoryPlanningsByCategoryId(workspaceId: string, categoryId: string): Promise<void> {
        const snapshot = await this.getCategoryPlanningCollection(workspaceId)
            .where("category.id", "==", categoryId)
            .get();

        if (snapshot.empty) return;

        const batch = this.firestore.batch();
        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
    }

    async getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]> {
        const snapshot = await this.getCategoryPlanningCollection(workspaceId).get();
        return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as CategoryPlanningModel));
    }

    async getCategoryPlanningsByLastSummaryMonthGroup(nowStr: string, limit: number): Promise<(CategoryPlanningModel & { workspaceId: string, ref: admin.firestore.DocumentReference })[]> {
        let snapshot = await this.firestore.collectionGroup("category_planning")
            .where("lastSummaryMonth", "<", nowStr)
            .limit(limit)
            .get();

        if (snapshot.empty) {
            snapshot = await this.firestore.collectionGroup("category_planning")
                .where("lastSummaryMonth", "==", null)
                .limit(limit)
                .get();
        }

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            const workspaceId = doc.ref.parent.parent!.id;

            return {
                id: doc.id,
                workspaceId: workspaceId,
                ref: doc.ref,
                ...data,
            } as CategoryPlanningModel & { workspaceId: string, ref: admin.firestore.DocumentReference };
        });
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

    async processCategoryPlanningSummariesChunk(
        chunk: (CategoryPlanningModel & { workspaceId: string, ref: admin.firestore.DocumentReference })[],
        nowStr: string,
        summaryFactory: (workspaceId: string, planning: CategoryPlanningModel) => PeriodSummaryUpdateModel[]
    ): Promise<void> {
        await this.firestore.runTransaction(async (transaction) => {
            for (const item of chunk) {
                const updates = summaryFactory(item.workspaceId, item);

                for (const update of updates) {
                    const { docRef, runtimeType } = this.getPeriodSummaryDocRef(item.workspaceId, update.year, update.month, update.week);
                    const updateData = this.buildPeriodSummaryUpdateData(
                        update.year,
                        update.month,
                        update.week,
                        update.category,
                        {
                            generalPlannedDelta: update.generalPlannedDelta,
                            specificPlannedDelta: update.specificPlannedDelta,
                            actualDelta: update.actualDelta
                        },
                        runtimeType
                    );
                    transaction.set(docRef, updateData, { merge: true });
                }
                transaction.update(item.ref, { lastSummaryMonth: nowStr });
            }
        });
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

    async updateAccountBalance(
        workspaceId: string,
        accountId: string,
        date: Date,
        delta: number
    ): Promise<void> {
        const dateId = date.toISOString().split("T")[0];
        const balancesColl = this.getAccountBalanceCollection(workspaceId, accountId);
        const docRef = balancesColl.doc(dateId);

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);

            // Impactar saldos futuros dentro da mesma transação para garantir atomicidade
            // IMPORTANTE: Usar transaction.get() para garantir que a leitura seja parte da transação
            const futureBalancesQuery = balancesColl.where(admin.firestore.FieldPath.documentId(), ">", dateId);
            const futureBalances = await transaction.get(futureBalancesQuery);

            if (!doc.exists) {
                // Se não existe saldo no dia, precisamos buscar o último saldo anterior para compor o inicial
                // Passamos a transaction internamente se houver uma ativa
                const lastBalanceDoc = await this.getLastBalanceBefore(workspaceId, accountId, date);
                const initialBalance = lastBalanceDoc ? lastBalanceDoc.balance : 0;

                transaction.set(docRef, {
                    balance: initialBalance + delta,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            }
            else {
                transaction.update(docRef, {
                    balance: admin.firestore.FieldValue.increment(delta),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            if (!futureBalances.empty) {
                futureBalances.docs.forEach((d) => {
                    transaction.update(d.ref, {
                        balance: admin.firestore.FieldValue.increment(delta),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                });
            }
        });
    }

    async getLastBalanceBefore(
        workspaceId: string,
        accountId: string,
        date: Date
    ): Promise<AccountBalanceModel | null> {
        const dateId = date.toISOString().split("T")[0];
        const query = this.getAccountBalanceCollection(workspaceId, accountId)
            .where(admin.firestore.FieldPath.documentId(), "<", dateId)
            .orderBy(admin.firestore.FieldPath.documentId(), "desc")
            .limit(1);

        const snapshot = await query.get();

        if (snapshot.empty) return null;
        const doc = snapshot.docs[0];
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : new Date(data.updatedAt),
        } as AccountBalanceModel;
    }

    async getAllWorkspaces(): Promise<string[]> {
        const snapshot = await admin.firestore().collection("workspaces").get();
        return snapshot.docs.map((doc) => doc.id);
    }

    async updateOrderCategory(workspaceId: string, category: CategoryModel) {
        const db = admin.firestore();
        const ordersSnapshot = await db.collection("workspaces").doc(workspaceId)
            .collection("orders").where("category.id", "==", category.id).get();

        if (ordersSnapshot.empty) return;

        const batch = db.batch();
        ordersSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, { category: category });
        });
        await batch.commit();
    }

    async updateInstallmentCategory(workspaceId: string, category: CategoryModel) {
        const db = admin.firestore();
        const ordersSnapshot = await db.collection("workspaces").doc(workspaceId)
            .collection("installments").where("category.id", "==", category.id).get();

        if (ordersSnapshot.empty) return;

        const batch = db.batch();
        ordersSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, { category: category });
        });
        await batch.commit();
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

        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
    }

    async getAccounts(workspaceId: string): Promise<AccountModel[]> {
        const snapshot = await this.getAccountsCollection(workspaceId).where("isDeleted", "==", false).get();
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as AccountModel));
    }
}
