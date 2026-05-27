import { WorkspaceModel } from "./workspace.model";

export enum InviteStatus {
  pending = "pending",
  accepted = "accepted",
  declined = "declined",
}

export interface InviteModel {
  id: string;
  workspace: WorkspaceModel;
  senderId: string;
  senderName: string;
  receiverEmail: string;
  status: InviteStatus;
  createdAt: Date;
}
