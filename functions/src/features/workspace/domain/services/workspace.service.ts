import { WorkspaceMember } from "../repositories/workspace.repository";

export interface IWorkspaceService {
  getWorkspaceMembers(workspaceId: string, requesterUserId: string): Promise<WorkspaceMember[]>;
  removeWorkspaceMember(
    workspaceId: string,
    memberId: string,
    requesterUserId: string
  ): Promise<void>;
}
