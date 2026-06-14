export interface IWorkspaceService {
  getWorkspaceMembers(workspaceId: string, requesterUserId: string): Promise<any[]>;
}
