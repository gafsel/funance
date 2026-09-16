import { WorkspaceModel } from "../models/workspace.model";

export interface IWorkspaceRepository {
  getWorkspaceById(id: string): Promise<WorkspaceModel | null>;
  getUserWorkspaces(userId: string): Promise<WorkspaceModel[]>;
  createWorkspace(workspace: Omit<WorkspaceModel, "id">): Promise<string>;
  addMember(workspaceId: string, userId: string): Promise<void>;
  removeMember(workspaceId: string, userId: string): Promise<void>;
  getMembersByIds(userIds: string[]): Promise<any[]>;
  updateUploadProgress(
    workspaceId: string,
    uploadId: string,
    progress: { status: string; progress: number; message: string }
  ): Promise<void>;
}
