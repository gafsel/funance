import { CategoryModel } from "../../../workspace/domain/models/category.model";
import * as admin from "firebase-admin";
import {
  OrderModel,
  LedgerEntryModel,
  CategoryMonthSummaryModel,
  AccountModel,
  AccountBalanceModel,
} from "../../domain/models/finance.models";
import { IFinanceRepository } from "../../domain/repositories/finance.repository";

export class FinanceRepositoryImpl implements IFinanceRepository {
  private firestore = admin.firestore();

  private getOrdersCollection(workspaceId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/orders`);
  }

  private getLedgerCollection(workspaceId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/ledger_entries`);
  }

  private getSummariesCollection(workspaceId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/category_month_summaries`);
  }

  private getPlanningSummariesCollection(workspaceId: string, planningId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/plannings/${planningId}/summaries`);
  }

  private getAccountsCollection(workspaceId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/accounts`);
  }

  private getAccountBalanceCollection(workspaceId: string, accountId: string) {
    return this.firestore.collection(`workspaces/${workspaceId}/accounts/${accountId}/balance`);
  }

  async createOrder(workspaceId: string, order: Omit<OrderModel, "id">): Promise<string> {
    const docRef = await this.getOrdersCollection(workspaceId).add({
      ...order,
      date: admin.firestore.Timestamp.fromDate(order.date),
    });
    return docRef.id;
  }

  async getOrderById(workspaceId: string, orderId: string): Promise<OrderModel | null> {
    const doc = await this.getOrdersCollection(workspaceId).doc(orderId).get();
    if (!doc.exists) return null;
    const data = doc.data()!;
    return {
      id: doc.id,
      ...data,
      date: data.date.toDate(),
    } as OrderModel;
  }

  async updateOrder(workspaceId: string, orderId: string, order: Partial<OrderModel>): Promise<void> {
    const updateData: any = { ...order };
    if (order.date) {
      updateData.date = admin.firestore.Timestamp.fromDate(order.date);
    }
    await this.getOrdersCollection(workspaceId).doc(orderId).update(updateData);
  }

  async deleteOrder(workspaceId: string, orderId: string): Promise<void> {
    await this.getOrdersCollection(workspaceId).doc(orderId).delete();
  }

  async createLedgerEntries(workspaceId: string, entries: Omit<LedgerEntryModel, "id">[]): Promise<void> {
    const batch = this.firestore.batch();
    const collection = this.getLedgerCollection(workspaceId);

    entries.forEach((entry) => {
      const docRef = collection.doc();
      batch.set(docRef, {
        ...entry,
        dueDate: admin.firestore.Timestamp.fromDate(entry.dueDate),
      });
    });

    await batch.commit();
  }

  async updateLedgerEntry(workspaceId: string, entryId: string, entry: Partial<LedgerEntryModel>): Promise<void> {
    const data = { ...entry } as any;
    if (data.dueDate) {
      data.dueDate = admin.firestore.Timestamp.fromDate(data.dueDate as Date);
    }
    await this.getLedgerCollection(workspaceId).doc(entryId).update(data);
  }

  async deleteLedgerEntry(workspaceId: string, entryId: string): Promise<void> {
    await this.getLedgerCollection(workspaceId).doc(entryId).delete();
  }

  async getLedgerEntriesByOrderId(workspaceId: string, orderId: string): Promise<LedgerEntryModel[]> {
    const snapshot = await this.getLedgerCollection(workspaceId)
      .where("orderId", "==", orderId)
      .get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        dueDate: data.dueDate.toDate(),
      } as LedgerEntryModel;
    });
  }

  async deleteLedgerEntriesByOrderId(workspaceId: string, orderId: string): Promise<void> {
    const snapshot = await this.getLedgerCollection(workspaceId)
      .where("orderId", "==", orderId)
      .get();

    const batch = this.firestore.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  }

  async getLedgerEntries(workspaceId: string, filters: { accountId?: string }): Promise<LedgerEntryModel[]> {
    let query: admin.firestore.Query = this.getLedgerCollection(workspaceId);

    if (filters.accountId) {
      query = query.where("accountId", "==", filters.accountId);
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        dueDate: data.dueDate.toDate(),
      } as LedgerEntryModel;
    });
  }

  async updateCategoryMonthSummary(
    workspaceId: string,
    year: number,
    month: number,
    category: CategoryModel,
    data: { debitDelta: number, creditDelta: number, countDelta: number }
  ): Promise<void> {
    const summaryId = `${year}-${String(month).padStart(2, "0")}_${category.id}`;
    const docRef = this.getSummariesCollection(workspaceId).doc(summaryId);

    await this.firestore.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);
      if (!doc.exists) {
        transaction.set(docRef, {
          year,
          month,
          category: category,
          totalDebit: Math.max(0, data.debitDelta),
          totalCredit: Math.max(0, data.creditDelta),
          plannedAmount: 0,
          actualAmount: Math.max(0, data.debitDelta + data.creditDelta),
          count: Math.max(0, data.countDelta),
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      else {
        const currentData = doc.data()!;
        const newDebit = Math.max(0, (currentData.totalDebit || 0) + data.debitDelta);
        const newCredit = Math.max(0, (currentData.totalCredit || 0) + data.creditDelta);
        transaction.update(docRef, {
          category: category,
          totalDebit: newDebit,
          totalCredit: newCredit,
          actualAmount: newDebit + newCredit,
          count: Math.max(0, (currentData.count || 0) + data.countDelta),
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
  }

  async updateSummaryCategoryInfo(workspaceId: string, category: CategoryModel): Promise<void> {
    const snapshot = await this.getSummariesCollection(workspaceId)
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

  async getCategoryMonthSummaries(workspaceId: string, year: number, month: number): Promise<CategoryMonthSummaryModel[]> {
    const snapshot = await this.getSummariesCollection(workspaceId)
      .where("year", "==", year)
      .where("month", "==", month)
      .get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        lastUpdate: data.lastUpdate.toDate(),
      } as CategoryMonthSummaryModel;
    });
  }

  async updateCategoryMonthSummaryPlanning(
    workspaceId: string,
    year: number,
    month: number,
    category: CategoryModel,
    plannedDelta: number
  ): Promise<void> {
    const summaryId = `${year}-${String(month).padStart(2, "0")}_${category.id}`;
    const docRef = this.getSummariesCollection(workspaceId).doc(summaryId);

    await this.firestore.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);
      if (!doc.exists) {
        transaction.set(docRef, {
          year,
          month,
          category: category,
          totalDebit: 0,
          totalCredit: 0,
          plannedAmount: Math.max(0, plannedDelta),
          actualAmount: 0,
          count: 0,
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      else {
        const currentData = doc.data()!;
        transaction.update(docRef, {
          plannedAmount: Math.max(0, (currentData.plannedAmount || 0) + plannedDelta),
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
  }

  async updatePlanningMonthSummary(
    workspaceId: string,
    planningId: string,
    year: number,
    month: number,
    data: { plannedDelta: number, actualDelta: number }
  ): Promise<void> {
    const docId = `${year}-${month.toString().padStart(2, "0")}`;
    const docRef = this.getPlanningSummariesCollection(workspaceId, planningId).doc(docId);

    await this.firestore.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);
      if (!doc.exists) {
        transaction.set(docRef, {
          id: docId,
          year,
          month,
          plannedAmount: Math.max(0, data.plannedDelta),
          actualAmount: Math.max(0, data.actualDelta),
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      else {
        const currentData = doc.data() as any;
        transaction.update(docRef, {
          plannedAmount: Math.max(0, (currentData.plannedAmount || 0) + data.plannedDelta),
          actualAmount: Math.max(0, (currentData.actualAmount || 0) + data.actualDelta),
          lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
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
