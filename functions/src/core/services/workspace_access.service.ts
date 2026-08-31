import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Garante que o usuário autenticado é membro do workspace.
 * Lança HttpsError se o workspace não existir ou o uid não estiver em `members`.
 * Segue o mesmo padrão de validação de workspace.service.impl.ts.
 */
export async function assertWorkspaceMember(workspaceId: string, uid: string): Promise<void> {
    const doc = await admin.firestore().collection("workspaces").doc(workspaceId).get();

    if (!doc.exists) {
        throw new HttpsError("not-found", "Workspace não encontrado.");
    }

    const members: string[] = (doc.data()?.members as string[]) || [];

    if (!members.includes(uid)) {
        throw new HttpsError("permission-denied", "Você não tem permissão para acessar este workspace.");
    }
}
