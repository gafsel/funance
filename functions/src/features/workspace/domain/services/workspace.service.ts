export interface IWorkspaceService {
  getWorkspaceMembers(workspaceId: string, requesterUserId: string): Promise<any[]>;
  removeWorkspaceMember(
    workspaceId: string,
    memberId: string,
    requesterUserId: string
  ): Promise<void>;
}
