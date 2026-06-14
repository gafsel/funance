import { IWorkspaceService } from "./workspace.service";
import { IWorkspaceRepository } from "../repositories/workspace.repository";
import { HttpsError } from "firebase-functions/v2/https";

export class WorkspaceServiceImpl implements IWorkspaceService {
    constructor(private workspaceRepository: IWorkspaceRepository) {
    }

    async getWorkspaceMembers(workspaceId: string, requesterUserId: string): Promise<any[]> {
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
}
