import * as admin from "firebase-admin";
import { WorkspaceModel } from "../../domain/models/workspace.model";
import { IWorkspaceRepository } from "../../domain/repositories/workspace.repository";

export class WorkspaceRepositoryImpl implements IWorkspaceRepository {
  private collection = admin.firestore().collection("workspaces");

  async getWorkspaceById(id: string): Promise<WorkspaceModel | null> {
    const doc = await this.collection.doc(id).get();
    if (!doc.exists) return null;
    const data = doc.data()!;
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt.toDate(),
    } as WorkspaceModel;
  }

  async getUserWorkspaces(userId: string): Promise<WorkspaceModel[]> {
    const snapshot = await this.collection.where("members", "array-contains", userId).get();
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt.toDate(),
      } as WorkspaceModel;
    });
  }

  async createWorkspace(workspace: Omit<WorkspaceModel, "id">): Promise<string> {
    const docRef = await this.collection.add({
      ...workspace,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  async addMember(workspaceId: string, userId: string): Promise<void> {
    await this.collection.doc(workspaceId).update({
      members: admin.firestore.FieldValue.arrayUnion(userId),
    });
  }
}
