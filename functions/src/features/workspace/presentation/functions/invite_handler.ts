import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { InviteModel, InviteStatus } from "../../domain/models/invite.model";
import * as logger from "firebase-functions/logger";

export const onInviteCreated = onDocumentCreated("invites/{inviteId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const invite = snapshot.data() as InviteModel;

    // No mundo real, aqui usaríamos algo como SendGrid, Mailgun ou o Firebase Extension "Trigger Email"
    logger.info(`[INVITE] Enviando e-mail de convite para ${invite.receiverEmail}`, {
        workspace: invite.workspace.name,
        sender: invite.senderName,
    });

    // Simulação de envio de e-mail bem sucedido
    return;
});

export const onInviteStatusChanged = onDocumentUpdated("invites/{inviteId}", async (event) => {
    const newValue = event.data?.after.data() as InviteModel | undefined;
    const previousValue = event.data?.before.data() as InviteModel | undefined;

    if (!newValue || !previousValue) return;

    // Se o status mudou de pending para accepted
    if (previousValue.status === InviteStatus.pending && newValue.status === InviteStatus.accepted) {
        await container.idempotencyService.runIdempotency(event.id, "handleInviteAccepted", async () => {
            await container.inviteService.handleInviteAccepted(newValue);
        });

        // Gamificação: badges de convite aceito (invite_accepted, first_invite)
        await container.idempotencyService.runIdempotency(event.id, "inviteAcceptedBadges", async () => {
            if (newValue.workspace?.id) {
                await container.gamificationService.checkInviteAcceptedBadge(newValue.workspace.id);
            }
        });
    }
});
