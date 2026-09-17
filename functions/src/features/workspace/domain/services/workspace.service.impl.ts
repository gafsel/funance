import { IWorkspaceService } from "./workspace.service";
import { IWorkspaceRepository, WorkspaceMember } from "../repositories/workspace.repository";
import { HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { assertWorkspaceOwner } from "../../../../core/services/workspace_access.service";

export class WorkspaceServiceImpl implements IWorkspaceService {
    constructor(private workspaceRepository: IWorkspaceRepository) {
    }

    async getWorkspaceMembers(workspaceId: string, requesterUserId: string): Promise<WorkspaceMember[]> {
        const workspace = await this.workspaceRepository.getWorkspaceById(workspaceId);

        if (!workspace) {
            throw new HttpsError("not-found", "Workspace não encontrado.");
        }

        const memberIds = workspace.members || [];

        if (!memberIds.includes(requesterUserId)) {
            throw new HttpsError("permission-denied", "Você não tem permissão para ver os membros deste workspace.");
        }

        return await this.workspaceRepository.getMembersByIds(memberIds);
    }

    /**
     * Tira um membro do workspace.
     *
     * Só o dono remove (`members[0]`, como em toda operação administrativa), e
     * ele não pode remover a si mesmo: o dono é quem as rules e o
     * `assertWorkspaceOwner` usam como âncora de permissão, e um workspace sem
     * dono ficaria sem quem administra. Sair de um workspace que não é seu é
     * outro fluxo, que não existe ainda.
     *
     * Os dados do workspace ficam como estão: lançamentos, contas e categorias
     * são do workspace, não de quem os criou.
     */
    async removeWorkspaceMember(
        workspaceId: string,
        memberId: string,
        requesterUserId: string
    ): Promise<void> {
        await assertWorkspaceOwner(workspaceId, requesterUserId);

        if (memberId === requesterUserId) {
            throw new HttpsError(
                "failed-precondition",
                "O dono do workspace não pode remover a si mesmo."
            );
        }

        const workspace = await this.workspaceRepository.getWorkspaceById(workspaceId);

        if (!workspace) {
            throw new HttpsError("not-found", "Workspace não encontrado.");
        }

        if (!(workspace.members || []).includes(memberId)) {
            throw new HttpsError("not-found", "Este usuário não é membro do workspace.");
        }

        await this.workspaceRepository.removeMember(workspaceId, memberId);

        logger.info(`[WORKSPACE] Membro removido do workspace ${workspaceId}.`);
    }
}
