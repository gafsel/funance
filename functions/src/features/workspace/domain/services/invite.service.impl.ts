import { IInviteService } from "./invite.service";
import { InviteModel } from "../models/invite.model";
import { IUserRepository } from "../../../user/domain/repositories/user.repository";
import { IWorkspaceRepository } from "../repositories/workspace.repository";
import * as logger from "firebase-functions/logger";

export class InviteServiceImpl implements IInviteService {
  constructor(
        private userRepository: IUserRepository,
        private workspaceRepository: IWorkspaceRepository
  ) {}

  async handleInviteAccepted(invite: InviteModel): Promise<void> {
    const receiverEmail = invite.receiverEmail;

    // Buscar o usuário pelo e-mail
    const user = await this.userRepository.getUserByEmail(receiverEmail);

    if (user) {
      // Adicionar o usuário ao workspace
      await this.workspaceRepository.addMember(invite.workspace.id, user.id);
      logger.info(`[INVITE] Usuário ${user.id} adicionado ao workspace ${invite.workspace.id} via convite.`);
    }
    else {
      logger.warn(`[INVITE] Convite aceito por ${receiverEmail}, mas usuário não encontrado no sistema.`);
    }
  }
}
