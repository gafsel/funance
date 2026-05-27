import { InviteModel } from "../models/invite.model";

export interface IInviteService {
    handleInviteAccepted(invite: InviteModel): Promise<void>;
}
