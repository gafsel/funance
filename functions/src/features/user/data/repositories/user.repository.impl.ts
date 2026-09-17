import * as admin from "firebase-admin";
import { UserModel } from "../../domain/models/user.models";
import { IUserRepository } from "../../domain/repositories/user.repository";
import { stripUndefined } from "../../../../core/utils/firestore.utils";

export class UserRepositoryImpl implements IUserRepository {
    private firestore = admin.firestore();
    private collection = this.firestore.collection("users");

    async getUserById(id: string): Promise<UserModel | null> {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data()!;
        return {
            ...data,
            id: doc.id,
            createdAt: data.createdAt.toDate(),
            lastLogin: data.lastLogin?.toDate(),
        } as UserModel;
    }

    async getUserByEmail(email: string): Promise<UserModel | null> {
        const snapshot = await this.collection.where("email", "==", email).limit(1).get();
        if (snapshot.empty) return null;
        const doc = snapshot.docs[0];
        const data = doc.data()!;
        return {
            ...data,
            id: doc.id,
            createdAt: data.createdAt.toDate(),
            lastLogin: data.lastLogin?.toDate(),
        } as UserModel;
    }

    async createUser(user: UserModel): Promise<void> {
        await this.collection.doc(user.id).set(stripUndefined({
            ...user,
            createdAt: admin.firestore.Timestamp.fromDate(user.createdAt),
            lastLogin: user.lastLogin ? admin.firestore.Timestamp.fromDate(user.lastLogin) : null,
        }));
    }

    async updateUser(id: string, user: Partial<UserModel>): Promise<void> {
        const updateData: Record<string, unknown> = stripUndefined({ ...user });
        if (user.createdAt) {
            updateData.createdAt = admin.firestore.Timestamp.fromDate(user.createdAt);
        }
        if (user.lastLogin) {
            updateData.lastLogin = admin.firestore.Timestamp.fromDate(user.lastLogin);
        }
        await this.collection.doc(id).update(updateData);
    }
}
