import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { InstallmentModel } from "../../domain/models/finance.models";

export const onInstallmentWritten = onDocumentWritten(
    "workspaces/{workspaceId}/installments/{installmentId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const installmentId = event.params.installmentId;

        logger.info(`[onInstallmentWritten] Início do processamento: workspaceId=${workspaceId}, installmentId=${installmentId}`);

        const beforeData = event.data?.before.exists ? event.data.before.data() : null;
        const afterData = event.data?.after.exists ? event.data.after.data() : null;

        const before = beforeData ? {
            ...beforeData,
            id: event.data?.before.id,
            dueDate: (beforeData.dueDate?.toDate ? beforeData.dueDate.toDate() : new Date(beforeData.dueDate)),
            paidDate: beforeData.paidDate?.toDate ? beforeData.paidDate.toDate() : (beforeData.paidDate ? new Date(beforeData.paidDate) : null),
        } as InstallmentModel : null;

        const after = afterData ? {
            ...afterData,
            id: event.data?.after.id,
            dueDate: afterData.dueDate?.toDate ? afterData.dueDate.toDate() : new Date(afterData.dueDate),
            paidDate: afterData.paidDate?.toDate ? afterData.paidDate.toDate() : (afterData.paidDate ? new Date(afterData.paidDate) : null),
        } as InstallmentModel : null;

        const idempotencyService = container.idempotencyService;
        const eventId = event.id;

        // Atualizar sumários mensais por categoria
        await idempotencyService.runIdempotency(eventId, "processSummaryChange", async () => {
            logger.debug(`[onInstallmentWritten] Executando processSummaryChange: ${installmentId}`);
            await container.summaryService.processInstallmentChange(workspaceId, before, after);
        });

        // Atualizar metas baseadas no Installment
        await idempotencyService.runIdempotency(eventId, "processGoalChange", async () => {
            logger.debug(`[onInstallmentWritten] Executando processGoalChange: ${installmentId}`);
            await container.goalService.processInstallmentChange(workspaceId, before, after);
        });

        // Atualiza o balance das accounts relacionadas ao Installment
        await idempotencyService.runIdempotency(eventId, "updateAccountBalance", async () => {
            logger.debug(`[onInstallmentWritten] Executando updateAccountBalance: ${installmentId}`);
            await container.financeService.updateAccountBalanceOnInstallmentChange(workspaceId, before, after);
        });

        // Atualiza as faturas de cartão de crédito
        await idempotencyService.runIdempotency(eventId, "processInvoiceUpdate", async () => {
            logger.debug(`[onInstallmentWritten] Executando processInvoiceUpdate: ${installmentId}`);
            await container.financeService.processInvoiceUpdate(workspaceId, before, after);
        });

        // Atualiza o XP das missões semanais
        await idempotencyService.runIdempotency(eventId, "updateXp", async () => {
            logger.debug(`[onInstallmentWritten] Executando updateXp: ${installmentId}`);
            await container.financeService.updateXpOnInstallmentChange(workspaceId, before, after);
        });

        // Processar cascata se necessário
        if (before && after) {
            await idempotencyService.runIdempotency(eventId, "processInstallmentCascade", async () => {
                logger.debug(`[onInstallmentWritten] Executando processInstallmentCascade: ${installmentId}`);
                await container.financeService.processInstallmentCascade(workspaceId, before, after);
            });
        }

        logger.info(`[onInstallmentWritten] Fim do processamento: ${installmentId}`);
    });
