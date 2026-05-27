export enum WorkspaceType {
  personal = "personal",
  business = "business",
}

export interface WorkspaceModel {
  id: string;
  name: string;
  type: WorkspaceType;
  members: string[];
  createdAt: Date;
}
