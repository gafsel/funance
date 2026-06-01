import { CategoryModel } from "../../../workspace/domain/models/category.model";
import * as admin from "firebase-admin";
import {
    OrderModel,
    InstallmentModel,
    CategoryPlanningModel,
    AccountModel,
    AccountBalanceModel,
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
        return {
            id: doc.id,
            ...data,
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
        return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as OrderModel));
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

    async getInstallments(workspaceId: string, filters: { accountId?: string }): Promise<InstallmentModel[]> {
        let query: admin.firestore.Query = this.getInstallmentsCollection(workspaceId);

        if (filters.accountId) {
            query = query.where("accountIds", "array-contains", filters.accountId);
        }

        const snapshot = await query.get();

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

    async updatePeriodSummary(
        workspaceId: string,
        year: number,
        month: number | undefined,
        category: CategoryModel,
        data: {
            generalPlannedDelta?: number,
            specificPlannedDelta?: number,
            actualDelta?: number
        }
    ): Promise<void> {
        const monthStr = month !== undefined ? `-${String(month).padStart(2, "0")}` : "";
        const summaryId = `${year}${monthStr}-${category.id}`;
        const docRef = this.getPeriodSummariesCollection(workspaceId).doc(summaryId);

        await docRef.set({
            year,
            month: month ?? null,
            category,
            generalPlannedAmount: admin.firestore.FieldValue.increment(data.generalPlannedDelta ?? 0),
            specificPlannedAmount: admin.firestore.FieldValue.increment(data.specificPlannedDelta ?? 0),
            actualAmount: admin.firestore.FieldValue.increment(data.actualDelta ?? 0),
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
            runtimeType: month !== undefined ? "month" : "year",
        }, { merge: true });
    }

    async updateSummaryCategoryInfo(workspaceId: string, category: CategoryModel): Promise<void> {
        const snapshot = await this.getPeriodSummariesCollection(workspaceId)
            .where("category.id", "==", category.id)
            .get();

        if (snapshot.empty) return;

        const batch = this.firestore.batch();
        snapshot.docs.forEach((doc) => {
            batch.update(doc.ref, {
                category: category,
                lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
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
                // Passamos a transaction para garantir leitura consistente
                const lastBalanceDoc = await this.getLastBalanceBefore(workspaceId, accountId, date, transaction);
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
        date: Date,
        transaction?: admin.firestore.Transaction
    ): Promise<AccountBalanceModel | null> {
        const dateId = date.toISOString().split("T")[0];
        const query = this.getAccountBalanceCollection(workspaceId, accountId)
            .where(admin.firestore.FieldPath.documentId(), "<", dateId)
            .orderBy(admin.firestore.FieldPath.documentId(), "desc")
            .limit(1);

        const snapshot = transaction ? await transaction.get(query) : await query.get();

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
}
