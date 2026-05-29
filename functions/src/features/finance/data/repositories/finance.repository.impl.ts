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

    async createOrder(workspaceId: string, order: Omit<OrderModel, "id">): Promise<string> {
        const docRef = await this.getOrdersCollection(workspaceId).add(order);
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

    async deleteOrdersByAccountId(workspaceId: string, accountId: string): Promise<void> {
        const ordersCollection = this.getOrdersCollection(workspaceId);

        const snapshot = await ordersCollection.orderBy(`accounts.${accountId}`).get();
        const batch = this.firestore.batch();

        snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
    }

    async createInstallments(workspaceId: string, installments: Omit<InstallmentModel, "id">[]): Promise<void> {
        const batch = this.firestore.batch();
        const collection = this.getInstallmentsCollection(workspaceId);

        installments.forEach((installment) => {
            const docRef = collection.doc();
            batch.set(docRef, {
                ...installment,
                dueDate: admin.firestore.Timestamp.fromDate(installment.dueDate),
                paidDate: installment.paidDate ? admin.firestore.Timestamp.fromDate(installment.paidDate) : null,
            });
        });

        await batch.commit();
    }

    async updateInstallment(workspaceId: string, installmentId: string, installment: Partial<InstallmentModel>): Promise<void> {
        const data = { ...installment } as any;
        if (data.dueDate) {
            data.dueDate = admin.firestore.Timestamp.fromDate(data.dueDate as Date);
        }
        if (data.paidDate) {
            data.paidDate = admin.firestore.Timestamp.fromDate(data.paidDate as Date);
        }
        await this.getInstallmentsCollection(workspaceId).doc(installmentId).update(data);
    }

    async deleteInstallment(workspaceId: string, installmentId: string): Promise<void> {
        await this.getInstallmentsCollection(workspaceId).doc(installmentId).delete();
    }

    async getInstallmentsByOrderId(workspaceId: string, orderId: string): Promise<InstallmentModel[]> {
        const snapshot = await this.getInstallmentsCollection(workspaceId)
            .where("orderId", "==", orderId)
            .get();

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                dueDate: data.dueDate.toDate(),
                paidDate: data.paidDate?.toDate(),
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
            query = query.orderBy(`accounts.${filters.accountId}`);
        }

        const snapshot = await query.get();

        return snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                dueDate: data.dueDate.toDate(),
                paidDate: data.paidDate?.toDate(),
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

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            if (!doc.exists) {
                transaction.set(docRef, {
                    year,
                    month: month ?? null,
                    category,
                    generalPlannedAmount: Math.max(0, data.generalPlannedDelta ?? 0),
                    specificPlannedAmount: Math.max(0, data.specificPlannedDelta ?? 0),
                    actualAmount: Math.max(0, data.actualDelta ?? 0),
                    lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            else {
                const currentData = doc.data()!;
                transaction.update(docRef, {
                    category,
                    generalPlannedAmount: Math.max(0, (currentData.generalPlannedAmount || 0) + (data.generalPlannedDelta ?? 0)),
                    specificPlannedAmount: Math.max(0, (currentData.specificPlannedAmount || 0) + (data.specificPlannedDelta ?? 0)),
                    actualAmount: Math.max(0, (currentData.actualAmount || 0) + (data.actualDelta ?? 0)),
                    lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });
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
        const docRef = this.getAccountBalanceCollection(workspaceId, accountId).doc(dateId);

        await this.firestore.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            if (!doc.exists) {
                // Se não existe saldo no dia, precisamos buscar o último saldo anterior para compor o inicial
                const lastBalanceDoc = await this.getLastBalanceBefore(workspaceId, accountId, date);
                const initialBalance = lastBalanceDoc ? lastBalanceDoc.balance : 0;

                transaction.set(docRef, {
                    balance: initialBalance + delta,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            else {
                const currentBalance = doc.data()!.balance;
                transaction.update(docRef, {
                    balance: currentBalance + delta,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });

        // Impactar saldos futuros
        const futureBalances = await this.getAccountBalanceCollection(workspaceId, accountId)
            .where(admin.firestore.FieldPath.documentId(), ">", dateId)
            .get();

        if (!futureBalances.empty) {
            const batch = this.firestore.batch();
            futureBalances.docs.forEach((doc) => {
                batch.update(doc.ref, {
                    balance: admin.firestore.FieldValue.increment(delta),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });
            await batch.commit();
        }
    }

    async getLastBalanceBefore(
        workspaceId: string,
        accountId: string,
        date: Date
    ): Promise<AccountBalanceModel | null> {
        const dateId = date.toISOString().split("T")[0];
        const snapshot = await this.getAccountBalanceCollection(workspaceId, accountId)
            .where(admin.firestore.FieldPath.documentId(), "<", dateId)
            .orderBy(admin.firestore.FieldPath.documentId(), "desc")
            .limit(1)
            .get();

        if (snapshot.empty) return null;
        const doc = snapshot.docs[0];
        return {
            id: doc.id,
            ...doc.data(),
            updatedAt: doc.data().updatedAt.toDate(),
        } as AccountBalanceModel;
    }

    async getAllWorkspaces(): Promise<string[]> {
        const snapshot = await admin.firestore().collection("workspaces").get();
        return snapshot.docs.map((doc) => doc.id);
    }
}
