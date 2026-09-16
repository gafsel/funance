import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { InviteModel, InviteStatus } from "../../domain/models/invite.model";

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
