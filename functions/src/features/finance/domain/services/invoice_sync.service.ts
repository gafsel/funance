/**
 * F1.8 — mantém `accounts/{accountId}.nextInvoice` em dia.
 *
 * O app calculava vencimento, fechamento e janela de fatura por conta própria,
 * com uma cópia Dart das regras que já divergia da versão TypeScript. Como o id
 * da order de fatura deriva da data (`invoice-{accountId}-{YYYY-MM-DD}`), as
 * duas implementações podiam apontar para faturas DIFERENTES — e o valor
 * mostrado na lista de contas era o da fatura errada.
 *
 * Agora o SERVIDOR resolve e denormaliza o resumo na conta; o cliente só lê.
 * A consulta é a mesma que o app fazia (`isInvoice` + `accountIds` + `pending`,
 * ordenada por `dueDate`), só que de um lado só.
 *
 * Três caminhos de atualização, todos idempotentes:
 *
 *  1. `processInvoiceUpdate` — pagamento/estorno que mexe numa fatura ou num
 *     cartão (`FinanceService`);
 *  2. `onAccountCreated`/`onAccountUpdated` — cartão novo, ou mudança do dia de
 *     fechamento/vencimento;
 *  3. o cron diário `syncNextInvoices` — avança a fatura quando o vencimento
 *     passa sem que nada tenha sido escrito.
 *
 * > **Escrever só quando MUDA é obrigatório, não otimização.** A escrita
 * > acontece no documento da conta, que é exatamente o que dispara
 * > `onAccountUpdated`. Sem a comparação, o gatilho se realimentaria em laço.
 */

import * as logger from "firebase-functions/logger";
import {
    AccountModel,
    AccountType,
    InstallmentStatus,
    NextInvoiceModel,
} from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";
import { InvoiceService } from "./invoice.service";
import { forEachWorkspacePaged, WorkspaceScanResult } from "../../../../core/utils/cron_runner";
import {
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
    CRON_WORKSPACE_CONCURRENCY,
} from "../../../../core/config/functions.config";
import { startOfDayInTz } from "../../../../core/utils/timezone.utils";

/** Chave ESTÁVEL do checkpoint do cron: mudá-la recomeça a varredura uma vez. */
export const NEXT_INVOICE_CHECKPOINT_KEY = "next_invoice_sync";

export interface IInvoiceSyncService {
    /**
     * Recalcula o resumo da conta. Devolve `true` quando algo foi escrito.
     * `account` evita uma leitura quando o chamador já tem o documento.
     */
    syncNextInvoice(
        workspaceId: string,
        accountId: string,
        account?: AccountModel | null,
        now?: Date
    ): Promise<boolean>;

    /**
     * Ressincroniza os cartões do workspace cujo resumo está AUSENTE ou cujo
     * vencimento já passou. Usado pelo cron e pelo script de backfill.
     */
    syncWorkspace(workspaceId: string, now?: Date): Promise<{ scanned: number; updated: number }>;

    /** Varre todos os workspaces, com checkpoint e parada por deadline. */
    syncAllWorkspaces(now?: Date): Promise<WorkspaceScanResult>;
}

export class InvoiceSyncServiceImpl implements IInvoiceSyncService {
    constructor(private readonly financeRepository: IFinanceRepository) { }

    async syncNextInvoice(
        workspaceId: string,
        accountId: string,
        account?: AccountModel | null,
        now: Date = new Date()
    ): Promise<boolean> {
        const resolved = account ?? await this.financeRepository.getAccountById(workspaceId, accountId);
        if (!resolved) return false;

        // Conta que deixou de ser cartão (ou foi apagada logicamente) não pode
        // ficar com um resumo velho pendurado: o app mostraria uma fatura de
        // algo que não cobra mais.
        if (resolved.runtimeType !== AccountType.creditCard || resolved.isDeleted) {
            if (!resolved.nextInvoice) return false;
            await this.financeRepository.setAccountNextInvoice(workspaceId, accountId, null);
            return true;
        }

        const next = await this.resolveNextInvoice(workspaceId, accountId, resolved, now);

        if (isSameNextInvoice(resolved.nextInvoice, next)) {
            return false;
        }

        await this.financeRepository.setAccountNextInvoice(workspaceId, accountId, next);
        logger.debug(
            `[InvoiceSync] ${workspaceId}/${accountId}: fatura ${next.orderId}, ` +
            `valor ${next.amount}, status ${next.status}.`
        );
        return true;
    }

    async syncWorkspace(workspaceId: string, now: Date = new Date()): Promise<{ scanned: number; updated: number }> {
        const accounts = await this.financeRepository.getAccounts(workspaceId);
        const cards = accounts.filter((account) => account.runtimeType === AccountType.creditCard);
        const today = startOfDayInTz(now);

        let updated = 0;
        for (const card of cards) {
            // O cron é leve de propósito: só mexe em quem está sem resumo ou
            // com o vencimento já vencido. Um cartão em dia não custa consulta.
            const current = card.nextInvoice;
            if (current && current.dueDate && current.dueDate.getTime() >= today.getTime()) {
                continue;
            }

            if (await this.syncNextInvoice(workspaceId, card.id, card, now)) {
                updated++;
            }
        }

        return { scanned: cards.length, updated };
    }

    async syncAllWorkspaces(now: Date = new Date()): Promise<WorkspaceScanResult> {
        let updated = 0;
        let scanned = 0;

        const result = await forEachWorkspacePaged(
            {
                checkpointKey: NEXT_INVOICE_CHECKPOINT_KEY,
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                const partial = await this.syncWorkspace(workspaceId, now);
                scanned += partial.scanned;
                updated += partial.updated;
            }
        );

        logger.info(
            `[InvoiceSync] cartões vistos: ${scanned}, atualizados: ${updated}, ` +
            `workspaces com falha: ${result.failed}.`
        );

        return result;
    }

    /**
     * O resumo que a conta DEVERIA ter agora.
     *
     * A fatura em aberto mais próxima é a fonte primária — inclusive quando já
     * está vencida e não paga, que é justamente a que o usuário precisa ver.
     * Sem nenhuma fatura em aberto (cartão novo, ou fatura zerada e apagada
     * por `processInvoiceUpdate`), o ciclo corrente é calculado e o valor vai
     * zero: o app mostra a janela e a data certas em vez de nada.
     */
    private async resolveNextInvoice(
        workspaceId: string,
        accountId: string,
        account: AccountModel,
        now: Date
    ): Promise<NextInvoiceModel> {
        const pending = await this.financeRepository.getNextPendingInvoice(workspaceId, accountId);

        const dueDate = pending?.dueDate ?? InvoiceService.resolveUpcomingDueDate(now, account);
        const cycle = InvoiceService.calculateInvoiceCycleRange(dueDate, account);

        return {
            dueDate,
            closingDate: cycle.closingDate,
            cycleStart: cycle.start,
            cycleEnd: cycle.end,
            amount: pending?.amount ?? 0,
            orderId: pending?.orderId ?? InvoiceService.invoiceOrderId(accountId, dueDate),
            installmentId: pending?.id ?? null,
            status: pending?.status ?? InstallmentStatus.pending,
        };
    }
}

/**
 * Compara o que está gravado com o que acabou de ser calculado, IGNORANDO
 * `updatedAt` — ele muda a cada execução e transformaria toda sincronização
 * numa escrita (e toda escrita num novo `onAccountUpdated`).
 */
export function isSameNextInvoice(
    current: NextInvoiceModel | null | undefined,
    next: NextInvoiceModel
): boolean {
    if (!current) return false;

    return sameInstant(current.dueDate, next.dueDate)
        && sameInstant(current.closingDate, next.closingDate)
        && sameInstant(current.cycleStart, next.cycleStart)
        && sameInstant(current.cycleEnd, next.cycleEnd)
        && current.amount === next.amount
        && current.orderId === next.orderId
        && (current.installmentId ?? null) === (next.installmentId ?? null)
        && current.status === next.status;
}

function sameInstant(a: Date | null | undefined, b: Date | null | undefined): boolean {
    if (!a || !b) return a === b;
    return a.getTime() === b.getTime();
}
