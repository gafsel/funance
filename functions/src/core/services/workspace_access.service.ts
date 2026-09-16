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

/**
 * Garante que o usuário autenticado é o DONO do workspace.
 *
 * O projeto não tem um campo `ownerId`: o dono é o criador, e o criador é
 * `members[0]`. As security rules garantem isso na criação
 * (`request.resource.data.members == [request.auth.uid]`) e o cliente não pode
 * alterar `members`; o aceite de convite ACRESCENTA membros com
 * `FieldValue.arrayUnion` (workspace.repository.impl.addMember), que sempre
 * insere no fim da lista. Logo, `members[0]` continua sendo o criador.
 *
 * Usado por operações destrutivas/administrativas (ex.: `rebuildWorkspace`),
 * que não devem ficar disponíveis para um membro convidado.
 */
export async function assertWorkspaceOwner(workspaceId: string, uid: string): Promise<void> {
    const doc = await admin.firestore().collection("workspaces").doc(workspaceId).get();

    if (!doc.exists) {
        throw new HttpsError("not-found", "Workspace não encontrado.");
    }

    const members: string[] = (doc.data()?.members as string[]) || [];

    if (members[0] !== uid) {
        throw new HttpsError(
            "permission-denied",
            "Apenas o dono do workspace pode executar esta operação."
        );
    }
}
