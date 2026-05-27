import { InviteModel } from "../models/invite.model";

export interface IInviteRepository {
  getInviteById(id: string): Promise<InviteModel | null>;
  updateInviteStatus(id: string, status: InviteModel["status"]): Promise<void>;
}
