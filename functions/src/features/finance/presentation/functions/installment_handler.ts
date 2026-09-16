import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import { INSTALLMENT_DERIVED_FIELDS, InstallmentModel } from "../../domain/models/finance.models";

// Reexportado por compatibilidade: a definição vive no modelo da parcela,
// porque o gatilho de gamificação observa a mesma coleção e usa a mesma guarda.
export { INSTALLMENT_DERIVED_FIELDS };

export interface InstallmentEventContext {
    workspaceId: string;
    installmentId: string;
    eventId: string;
}

/** Converte o payload cru do evento no modelo de domínio. */
function toInstallmentModel(data: Record<string, any> | null, id: string | undefined): InstallmentModel | null {
    if (!data) return null;

    return {
        ...data,
        id,
        dueDate: (data.dueDate?.toDate ? data.dueDate.toDate() : new Date(data.dueDate)),
        paidDate: data.paidDate?.toDate ? data.paidDate.toDate() : (data.paidDate ? new Date(data.paidDate) : null),
    } as InstallmentModel;
}

/**
 * Corpo do gatilho de parcela, como função pura (sem `CloudEvent`): o
 * `onDocumentWritten` abaixo só desembrulha o evento e delega.
 *
 * Isolada assim ela pode ser chamada direto nos testes de integração — o
 * emulador do Firestore não dispara triggers, então a única forma de verificar
 * o encadeamento evento -> escrita derivada -> evento é invocar o handler com o
 * par (before, after) que a escrita derivada produziria.
 */
export async function handleInstallmentWritten(
    beforeData: Record<string, any> | null,
    afterData: Record<string, any> | null,
    ctx: InstallmentEventContext
): Promise<void> {
    const { workspaceId, installmentId, eventId } = ctx;

    logger.info(`[onInstallmentWritten] Início do processamento: workspaceId=${workspaceId}, installmentId=${installmentId}`);

    // GUARDA POR CONTEÚDO: numa atualização (before e after existem), se o
    // conjunto de campos alterados couber dentro dos campos derivados, nada de
    // interessante para o usuário mudou.
    if (beforeData && afterData) {
        const changedFields = getChangedFields(beforeData, afterData);
        const onlyDerived = changedFields.every((field) => INSTALLMENT_DERIVED_FIELDS.has(field));

        if (onlyDerived) {
            logger.info(`[onInstallmentWritten] Saída antecipada: ${installmentId} mudou apenas campos derivados [${changedFields.join(", ")}].`);
            return;
        }
    }

    const before = toInstallmentModel(beforeData, installmentId);
    const after = toInstallmentModel(afterData, installmentId);

    const idempotencyService = container.idempotencyService;

    // Atualizar sumários mensais por categoria
    await idempotencyService.runIdempotency(eventId, "processSummaryChange", async () => {
        logger.debug(`[onInstallmentWritten] Executando processSummaryChange: ${installmentId}`);
        await container.summaryService.processInstallmentChange(workspaceId, before, after);
    });

    // Atualiza o balance das accounts relacionadas ao Installment
    await idempotencyService.runIdempotency(eventId, "updateAccountBalance", async () => {
        logger.debug(`[onInstallmentWritten] Executando updateAccountBalance: ${installmentId}`);
        await container.financeService.updateAccountBalanceOnInstallmentChange(workspaceId, before, after);
    });

    // Atualizar metas baseadas no Installment.
    //
    // ORDEM IMPORTA: depois do saldo e do sumário. A meta `payDebt` é calculada
    // a partir dos saldos diários da conta e a `reduceExpense` a partir do
    // `period_summaries` do mês — rodando antes, as duas leriam o estado
    // anterior a esta parcela e ficariam sempre um evento atrasadas.
    await idempotencyService.runIdempotency(eventId, "processGoalChange", async () => {
        logger.debug(`[onInstallmentWritten] Executando processGoalChange: ${installmentId}`);
        await container.goalService.processInstallmentChange(workspaceId, before, after);
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
}

export const onInstallmentWritten = onDocumentWritten(
    "workspaces/{workspaceId}/installments/{installmentId}",
    async (event) => {
        const beforeData = event.data?.before.exists ? event.data.before.data()! : null;
        const afterData = event.data?.after.exists ? event.data.after.data()! : null;

        await handleInstallmentWritten(beforeData, afterData, {
            workspaceId: event.params.workspaceId,
            installmentId: event.params.installmentId,
            eventId: event.id,
        });
    });
