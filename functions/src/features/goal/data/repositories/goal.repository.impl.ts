import * as admin from "firebase-admin";
import { IGoalRepository } from "../../domain/repositories/goal.repository";
import { GoalModel } from "../../domain/models/goal.model";

export class GoalRepositoryImpl implements IGoalRepository {
  private db = admin.firestore();

  async getGoals(workspaceId: string): Promise<GoalModel[]> {
    const snapshot = await this.db
      .collection("workspaces")
      .doc(workspaceId)
      .collection("goals")
      .where("isDeleted", "==", false)
      .get();

    return snapshot.docs.map((doc) => this.mapDocToModel(doc));
  }

  async getActiveGoalsByAccount(workspaceId: string, accountId: string): Promise<GoalModel[]> {
    const snapshot = await this.db
      .collection("workspaces")
      .doc(workspaceId)
      .collection("goals")
      .where("isDeleted", "==", false)
      .where("accountId", "==", accountId)
      .get();

    return snapshot.docs.map((doc) => this.mapDocToModel(doc));
  }

  async getGoal(workspaceId: string, goalId: string): Promise<GoalModel | null> {
    const doc = await this.db
      .collection("workspaces")
      .doc(workspaceId)
      .collection("goals")
      .doc(goalId)
      .get();

    if (!doc.exists) return null;
    return this.mapDocToModel(doc);
  }

  async updateGoal(workspaceId: string, goal: GoalModel): Promise<void> {
    await this.db
      .collection("workspaces")
      .doc(workspaceId)
      .collection("goals")
      .doc(goal.id)
      .set(goal, { merge: true });
  }

  private mapDocToModel(doc: admin.firestore.QueryDocumentSnapshot | admin.firestore.DocumentSnapshot): GoalModel {
    const data = doc.data()!;
    return {
      ...data,
      id: doc.id,
      startDate: data.startDate?.toDate() || new Date(),
      deadline: data.deadline.toDate(),
    } as GoalModel;
  }
}
