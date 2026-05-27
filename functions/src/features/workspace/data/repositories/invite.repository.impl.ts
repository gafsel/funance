import * as admin from "firebase-admin";
import { InviteModel } from "../../domain/models/invite.model";
import { IInviteRepository } from "../../domain/repositories/invite.repository";

export class InviteRepositoryImpl implements IInviteRepository {
  private collection = admin.firestore().collection("invites");

  async getInviteById(id: string): Promise<InviteModel | null> {
    const doc = await this.collection.doc(id).get();
    if (!doc.exists) return null;
    const data = doc.data()!;
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt.toDate(),
    } as InviteModel;
  }

  async updateInviteStatus(id: string, status: InviteModel["status"]): Promise<void> {
    await this.collection.doc(id).update({ status });
  }
}
