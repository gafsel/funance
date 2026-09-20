import * as admin from "firebase-admin";
import { WorkspaceModel } from "../../domain/models/workspace.model";
import { IWorkspaceRepository, WorkspaceMember } from "../../domain/repositories/workspace.repository";
import { stripUndefined } from "../../../../core/utils/firestore.utils";

export class WorkspaceRepositoryImpl implements IWorkspaceRepository {
    private collection = admin.firestore().collection("workspaces");

    async getWorkspaceById(id: string): Promise<WorkspaceModel | null> {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data()!;
        return {
            id: doc.id,
            ...data,
            createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : (data.createdAt ? new Date(data.createdAt) : new Date()),
            lastLevelUpAt: data.lastLevelUpAt?.toDate ? data.lastLevelUpAt.toDate() : (data.lastLevelUpAt ? new Date(data.lastLevelUpAt) : undefined),
        } as WorkspaceModel;
    }

    async getUserWorkspaces(userId: string): Promise<WorkspaceModel[]> {
        const snapshot = await this.collection.where("members", "array-contains", userId).get();
        return snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : (data.createdAt ? new Date(data.createdAt) : new Date()),
                lastLevelUpAt: data.lastLevelUpAt?.toDate ? data.lastLevelUpAt.toDate() : (data.lastLevelUpAt ? new Date(data.lastLevelUpAt) : undefined),
            } as WorkspaceModel;
        });
    }

    async createWorkspace(workspace: Omit<WorkspaceModel, "id">): Promise<string> {
        const docRef = await this.collection.add(stripUndefined({
            ...workspace,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }));
        return docRef.id;
    }

    async addMember(workspaceId: string, userId: string): Promise<void> {
        await this.collection.doc(workspaceId).update({
            members: admin.firestore.FieldValue.arrayUnion(userId),
        });
    }

    /**
     * Tira o usuário de `members`.
     *
     * `arrayRemove` é idempotente e não depende de ler a lista antes: dois
     * cliques no botão de remover não se atrapalham, e nenhuma escrita
     * concorrente (aceite de convite, gamificação) é perdida como aconteceria
     * com um `update` da lista inteira.
     */
    async removeMember(workspaceId: string, userId: string): Promise<void> {
        await this.collection.doc(workspaceId).update({
            members: admin.firestore.FieldValue.arrayRemove(userId),
        });
    }

    async getMembersByIds(userIds: string[]): Promise<WorkspaceMember[]> {
        if (userIds.length === 0) return [];

        const members: WorkspaceMember[] = [];
        const db = admin.firestore();
        
        // Firestore 'in' query supports up to 30 elements
        const chunks: string[][] = [];
        for (let i = 0; i < userIds.length; i += 30) {
            chunks.push(userIds.slice(i, i + 30));
        }

        for (const chunk of chunks) {
            const usersSnapshot = await db.collection("users")
                .where(admin.firestore.FieldPath.documentId(), "in", chunk)
                .get();

            usersSnapshot.forEach(doc => {
                const data = doc.data();
                members.push({
                    id: doc.id,
                    email: data.email,
                    displayName: data.displayName,
                    photoUrl: data.photoUrl,
                    avatar: data.avatar,
                    createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
                    lastLogin: data.lastLogin?.toDate?.()?.toISOString() || data.lastLogin,
                });
            });
        }

        return members;
    }

    async updateUploadProgress(
        workspaceId: string,
        uploadId: string,
        progress: { status: string; progress: number; message: string }
    ): Promise<void> {
        await this.collection
            .doc(workspaceId)
            .collection("uploads")
            .doc(uploadId)
            .set(progress, { merge: true });
    }
}
