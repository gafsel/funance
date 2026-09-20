import { WorkspaceModel } from "../models/workspace.model";

/**
 * Um membro do workspace, como a callable `getWorkspaceMembers` o entrega ao
 * app: o documento de `users/{uid}` reduzido aos campos de EXIBIÇÃO.
 *
 * É uma projeção deliberada, e não o documento inteiro: a lista de membros é
 * lida por qualquer participante do workspace, e o que estiver aqui é o que
 * todos passam a ver um do outro.
 *
 * Tudo além do `id` é opcional porque um usuário pode ter entrado por um
 * provedor que não devolveu nome ou foto. As datas saem em ISO-8601 (ou como
 * estavam gravadas, num documento legado sem `Timestamp`).
 */
export interface WorkspaceMember {
    id: string;
    email?: string;
    displayName?: string;
    photoUrl?: string;
    /**
     * O herói do membro na Arena — o `name` de um `HeroSkin` do app
     * (`knight`, `mage`, `ranger`, `warrior`, `healer`, `barbarian`, `monk`,
     * `smith`).
     *
     * Entra na projeção porque a Arena desenha o elenco INTEIRO do
     * workspace, e o app só lê `users/{uid}` do próprio usuário (as rules
     * não deixam ler o do parceiro). Sem este campo aqui, a escolha do outro
     * membro existiria no Firestore e nunca chegaria à cena.
     *
     * Valor desconhecido não é validado no servidor: quem decide o que fazer
     * com um avatar que saiu do catálogo é o app, que tem um padrão.
     */
    avatar?: string;
    createdAt?: string;
    lastLogin?: string;
}

export interface IWorkspaceRepository {
  getWorkspaceById(id: string): Promise<WorkspaceModel | null>;
  getUserWorkspaces(userId: string): Promise<WorkspaceModel[]>;
  createWorkspace(workspace: Omit<WorkspaceModel, "id">): Promise<string>;
  addMember(workspaceId: string, userId: string): Promise<void>;
  removeMember(workspaceId: string, userId: string): Promise<void>;
  getMembersByIds(userIds: string[]): Promise<WorkspaceMember[]>;
  updateUploadProgress(
    workspaceId: string,
    uploadId: string,
    progress: { status: string; progress: number; message: string }
  ): Promise<void>;
}
