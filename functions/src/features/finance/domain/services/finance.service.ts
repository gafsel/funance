import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderModel,
    OrderStatus,
    OrderType,
    ReplicationCascade
} from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";
import { CategoryType, INITIAL_BALANCE_CATEGORY } from "../../../workspace/domain/models/category.model";
import { DEFAULT_FINANCE_CONFIG } from "../../../../core/config/finance.config";
import { InvoiceService } from "./invoice.service";
import { container } from "../../../../core/container";

/**
 * Divide um valor total em `count` parcelas usando aritmética de centavos inteiros,
 * evitando erros de ponto flutuante (ex.: 502.40 / 10 deve gerar 10x 50.24).
 * O resto da divisão é distribuído 1 centavo por parcela nas primeiras `resto` parcelas.
 */
export function splitAmountIntoInstallments(totalAmount: number, count: number): number[] {
    if (!Number.isFinite(totalAmount) || !Number.isInteger(count) || count <= 0) {
        return [];
    }

    const totalCents = Math.round(totalAmount * 100);
    const baseCents = Math.floor(totalCents / count);
    const remainderCents = totalCents - (baseCents * count);

    return Array.from({ length: count }, (_, i) => (baseCents + (i < remainderCents ? 1 : 0)) / 100);
}

export class FinanceService {
    constructor(private financeRepository: IFinanceRepository) {
    }

    async syncInstallments(workspaceId: string, orderId: string, before: OrderModel | null, after: OrderModel | null): Promise<void> {
        // 1. Buscar installments existentes
        const existingInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, orderId);

        // 2. Se a order foi excluída ou está cancelada, deletamos tudo.
        // Em lotes, não uma escrita sequencial por parcela: uma order parcelada
        // pode ter centenas de parcelas.
        if (!after) {
            if (existingInstallments.length > 0) {
                await this.financeRepository.deleteInstallmentsByOrderId(workspaceId, orderId);
            }
            return;
        }

        // 2.1 Se a order já existia, não fazemos cascateamento de edição para as installments.
        // A criação da order cria as installments, mas uma alteração na order não deve mexer nas installments.
        if (before && !before.isInvoice) {
            console.log(`SyncInstallments: Order ${orderId} atualizada. Pulando cascateamento para installments conforme regra de negócio.`);
            return;
        }

        // 3. Gerar o que deveria existir
        const expectedInstallments: Omit<InstallmentModel, "id">[] = [];
        let installmentsToGenerate = 0;

        if (after.installmentType === InstallmentType.single) {
            installmentsToGenerate = 1;
        }
        else if (after.installmentType === InstallmentType.installment) {
            installmentsToGenerate = after.installmentCount || 1;
        }
        else if (after.installmentType === InstallmentType.recurring) {
            // Inicialmente gera conforme configurado
            installmentsToGenerate = DEFAULT_FINANCE_CONFIG.recurrence.predictabilityMonths;
        }

        const [startYear, startMonth] = after.startMonth.split("-").map(Number);

        let shouldAllBePaid = false;
        if (after.installmentType === InstallmentType.installment &&
            (after.installmentCreationStatus === InstallmentStatus.paid || after.installmentCreationStatus === InstallmentStatus.settled)) {
            // Verificar se é conta de cartão de crédito
            const accountIds = Object.keys(after.accounts || {});
            if (accountIds.length > 0) {
                const account = await this.financeRepository.getAccountById(workspaceId, accountIds[0]);
                if (account?.runtimeType === AccountType.creditCard) {
                    shouldAllBePaid = true;
                }
            }
        }

        let lastDueDate: Date | undefined;

        // Divisão de parcelas em centavos inteiros (evita erros de ponto flutuante)
        const installmentAmounts = after.installmentType === InstallmentType.installment
            ? splitAmountIntoInstallments(after.amount, after.installmentCount || 1)
            : null;

        for (let i = 0; i < installmentsToGenerate; i++) {
            const date = new Date(startYear, startMonth - 1 + i, 1, 12);
            const year = date.getFullYear();
            const month = date.getMonth(); // 0-indexed

            const lastDayOfMonth = new Date(year, month + 1, 0).getDate();
            const day = Math.min(after.dueDay, lastDayOfMonth);
            const dueDate = new Date(year, month, day, 12);

            const isFirst = i === 0;
            const status = (shouldAllBePaid || (isFirst && (after.installmentCreationStatus === InstallmentStatus.paid || after.installmentCreationStatus === InstallmentStatus.settled)))
                ? after.installmentCreationStatus!
                : InstallmentStatus.pending;

            const isPaid = status === InstallmentStatus.paid || status === InstallmentStatus.settled;

            let installmentAmount = after.amount;
            if (installmentAmounts && installmentAmounts.length > i) {
                installmentAmount = installmentAmounts[i];
            }

            const paidDate = isPaid ? new Date(dueDate) : undefined;
            if (paidDate) paidDate.setHours(12, 0, 0, 0);

            // Regra: Se a parcela já nasce paga/liquidada, o amount planejado deve ser zero
            // para que o sistema compute isso como uma cobrança não planejada.
            const plannedAmount = isPaid ? 0 : installmentAmount;

            expectedInstallments.push({
                orderId: orderId,
                amount: plannedAmount,
                dueDate: dueDate,
                description: after.description,
                referenceDate: dueDate,
                referenceAmount: isPaid ? installmentAmount : plannedAmount,
                status: status,
                type: after.type,
                installmentType: after.installmentType,
                installmentNumber: after.installmentType === InstallmentType.installment ? i + 1 : undefined,
                installmentCount: after.installmentType === InstallmentType.installment ? after.installmentCount : undefined,
                accounts: after.accounts,
                accountIds: Object.keys(after.accounts || {}),
                category: after.category,
                paidAmount: isPaid ? installmentAmount : undefined,
                paidDate: paidDate,
                isInvoice: after.isInvoice,
            });

            lastDueDate = dueDate;
        }

        // 4. Criar as installments
        if (after.isInvoice && existingInstallments.length > 0) {
            const existingInvoice = existingInstallments[0];
            if (existingInvoice.amount !== expectedInstallments[0].amount) {
                const isInvoicePaid = existingInvoice.status === InstallmentStatus.paid
                    || existingInvoice.status === InstallmentStatus.settled;

                const invoiceUpdate: Partial<InstallmentModel> = {
                    amount: expectedInstallments[0].amount,
                    referenceAmount: expectedInstallments[0].referenceAmount,
                };

                // Se a fatura já foi paga/liquidada, atualiza apenas os valores,
                // SEM reverter o status para pending (o pagamento já impactou o saldo).
                if (!isInvoicePaid) {
                    invoiceUpdate.status = InstallmentStatus.pending;
                }

                await this.financeRepository.updateInstallment(workspaceId, existingInvoice.id, invoiceUpdate);
            }
        }
        else {
            await this.financeRepository.createInstallments(workspaceId, expectedInstallments);
        }

        // 5. Atualizar a data da última parcela gerada na Order
        if (lastDueDate && after.installmentType === InstallmentType.recurring) {
            await this.financeRepository.updateOrder(workspaceId, orderId, {
                lastGeneratedDueDate: lastDueDate,
            });
        }
    }

    async processInstallmentCascade(
        workspaceId: string,
        before: InstallmentModel,
        after: InstallmentModel
    ): Promise<void> {
        const cascade = after.replicationCascade || ReplicationCascade.none;
        if (cascade === ReplicationCascade.none) return;

        const allInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, after.orderId);
        const sorted = allInstallments.sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());

        const currentIndex = sorted.findIndex(i => i.id === after.id);
        const targetInstallments = cascade === ReplicationCascade.all
            ? sorted.filter(i => i.id !== after.id)
            : sorted.slice(currentIndex + 1);

        if (targetInstallments.length === 0) return;

        let dateDeltaMs = 0;
        if (after.dueDate && before.dueDate) {
            dateDeltaMs = after.dueDate.getTime() - before.dueDate.getTime();
        }

        const hasAmountChanged = after.amount !== before.amount;
        const hasDescriptionChanged = after.description !== before.description;
        const hasCategoryChanged = after.category?.id !== before.category?.id;
        const hasAccountsChanged = JSON.stringify(after.accounts) !== JSON.stringify(before.accounts);
        const hasTypeChanged = after.type !== before.type;
        const wasRemoved = before.status !== InstallmentStatus.removed && after.status === InstallmentStatus.removed;

        for (const inst of targetInstallments) {
            const installmentUpdate: Partial<InstallmentModel> = {};

            if (hasDescriptionChanged) installmentUpdate.description = after.description;
            if (hasAmountChanged) {
                installmentUpdate.amount = after.amount;

                // Se não estiver paga, o referenceAmount segue o amount
                if (inst.status !== InstallmentStatus.paid && inst.status !== InstallmentStatus.settled) {
                    installmentUpdate.referenceAmount = after.amount;
                }
            }
            if (hasCategoryChanged) installmentUpdate.category = after.category;
            if (hasAccountsChanged) {
                installmentUpdate.accounts = after.accounts;
                installmentUpdate.accountIds = after.accountIds;
            }
            if (hasTypeChanged) installmentUpdate.type = after.type;
            if (wasRemoved) installmentUpdate.status = InstallmentStatus.removed;

            // 1. Aplicamos o delta na data se houver
            if (dateDeltaMs !== 0) {
                const currentDueDate = new Date(inst.dueDate);
                const newDueDate = new Date(currentDueDate.getTime() + dateDeltaMs);
                installmentUpdate.dueDate = newDueDate;

                // Se não estiver paga, o referenceDate segue a dueDate
                if (inst.status !== InstallmentStatus.paid && inst.status !== InstallmentStatus.settled) {
                    installmentUpdate.referenceDate = newDueDate;
                }
            }

            if (Object.keys(installmentUpdate).length > 0) {
                // Importante: Marcar a cascata como none para evitar recursão infinita se o trigger disparar novamente
                installmentUpdate.replicationCascade = ReplicationCascade.none;

                await this.financeRepository.updateInstallment(workspaceId, inst.id, installmentUpdate);
            }
        }

        // 3. Cascatear alteração de Installment para Order
        // O cascateamento deve ser feito na order também, definindo na order o valor mais acurado das installments.
        // O valor acurado para uma Order que possui parcelas é a soma das parcelas.
        // Se a parcela atual mudou (after), ela já está refletida em allInstallments se buscarmos novamente ou se mergearmos manualmente.
        const updatedInstallments = allInstallments.map(i => i.id === after.id ? after : i);

        // Se houver cascade 'all' ou 'next', as outras parcelas também foram atualizadas no loop acima,
        // mas aqui no JS 'targetInstallments' e 'after' contêm os novos valores para essas parcelas.
        // Precisamos garantir que updatedInstallments tenha os valores que acabamos de salvar.
        for (const inst of updatedInstallments) {
            if (inst.id === after.id) continue;
            const isTarget = targetInstallments.some(t => t.id === inst.id);
            if (isTarget) {
                // Merge manual para o cálculo do total
                if (hasAmountChanged) inst.amount = after.amount;
                if (hasDescriptionChanged) inst.description = after.description;
                if (hasCategoryChanged) inst.category = after.category;
                if (hasAccountsChanged) {
                    inst.accounts = after.accounts;
                    inst.accountIds = after.accountIds;
                }
                if (wasRemoved) inst.status = after.status;
                // ... data delta não afeta o total
            }
        }

        const totalAmount = updatedInstallments.reduce((sum, i) => sum + i.amount, 0);
        const orderUpdate: Partial<OrderModel> = {
            amount: Math.round(totalAmount * 100) / 100,
            dueDay: after.dueDate.getDate(),
            description: after.description,
            category: after.category,
            accounts: after.accounts,
            accountIds: after.accountIds,
        };

        // Se a installment foi alterada para removed, inativar a order
        if (wasRemoved) {
            orderUpdate.status = OrderStatus.cancelled;
        }

        console.log(`Cascateando alteração de Installment para Order ${after.orderId}. Novo total: ${orderUpdate.amount}`);
        await this.financeRepository.updateOrder(workspaceId, after.orderId, orderUpdate);
    }

    async updateAccountBalanceOnInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        const isPaidStatus = (s: InstallmentStatus | undefined) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        const isBeforePaid = isPaidStatus(before?.status);
        const isAfterPaid = isPaidStatus(after?.status);

        // Caso 1: Estorno (Era pago e deixou de ser, ou foi deletado)
        if (isBeforePaid && (!after || !isAfterPaid)) {
            await this.applyInstallmentBalance(workspaceId, before!, true);
        }
        // Caso 2: Novo pagamento (Não era pago e passou a ser)
        else if (!isBeforePaid && after && isAfterPaid) {
            await this.applyInstallmentBalance(workspaceId, after, false);
        }
        // Caso 3: Alteração em pagamento existente (Era pago e continua pago)
        else if (isBeforePaid && isAfterPaid && before && after) {
            const hasChangedAccount = JSON.stringify(before.accounts) !== JSON.stringify(after.accounts);
            const hasChangedAmount = before.paidAmount !== after.paidAmount;
            const hasChangedDate = before.paidDate?.getTime() !== after.paidDate?.getTime();

            if (hasChangedAccount || hasChangedAmount || hasChangedDate) {
                // Estorna o anterior e aplica o novo
                await this.applyInstallmentBalance(workspaceId, before, true);
                await this.applyInstallmentBalance(workspaceId, after, false);
            }
        }
    }

    async updateXpOnInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        const isPaidStatus = (s: InstallmentStatus | undefined) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        const isBeforePaid = isPaidStatus(before?.status);
        const isAfterPaid = isPaidStatus(after?.status);

        // Caso 1: Estorno (Era pago e deixou de ser, ou foi deletado)
        if (isBeforePaid && (!after || !isAfterPaid)) {
            const oldXp = before!.xp || this.calculateXp(before!);
            await this.updateWeeklyTotalXp(workspaceId, before!.paidDate || before!.dueDate, -oldXp);
            await container.gamificationService.addXp(workspaceId, -oldXp, "Estorno de transação paga");
        }
        // Caso 2: Novo pagamento (Não era pago e passou a ser)
        else if (!isBeforePaid && after && isAfterPaid) {
            const xp = this.calculateXp(after);
            await this.financeRepository.updateInstallment(workspaceId, after.id, { xp });
            await this.updateWeeklyTotalXp(workspaceId, after.paidDate || after.dueDate, xp);
            await container.gamificationService.addXp(workspaceId, xp, "Transação paga");
        }
        // Caso 3: Alteração em pagamento existente (Era pago e continua pago)
        else if (isBeforePaid && isAfterPaid && before && after) {
            const hasChangedAmount = before.paidAmount !== after.paidAmount;
            const hasChangedDate = before.paidDate?.getTime() !== after.paidDate?.getTime();

            if (hasChangedAmount || hasChangedDate) {
                const oldXp = before.xp || this.calculateXp(before);
                const newXp = this.calculateXp(after);
                
                if (oldXp !== newXp || hasChangedDate) {
                    await this.financeRepository.updateInstallment(workspaceId, after.id, { xp: newXp });
                    
                    // Estorna o XP antigo da data antiga e aplica o novo na nova data
                    await this.updateWeeklyTotalXp(workspaceId, before.paidDate || before.dueDate, -oldXp);
                    await this.updateWeeklyTotalXp(workspaceId, after.paidDate || after.dueDate, newXp);
                    await container.gamificationService.addXp(workspaceId, newXp - oldXp, "Alteração de transação paga");
                }
            }
        }
    }

    private calculateXp(inst: InstallmentModel): number {
        const baseXP = 15;
        const predictedAmount = inst.amount;
        const actualAmount = inst.paidAmount ?? inst.amount;

        if (predictedAmount === 0) return 0;

        const diff = actualAmount - predictedAmount;
        const isExpense = inst.type === OrderType.expense;

        // Se o valor for diferente, há uma inflação ou deflação de 10% dos XP (1.5 XP)
        if (Math.abs(diff) > 0.01) {
            // Para despesa: se gastou MAIS (diff > 0), pune (-10%). Se gastou MENOS (diff < 0), premia (+10%).
            // Para ganho: se ganhou MAIS (diff > 0), premia (+10%). Se ganhou MENOS (diff < 0), pune (-10%).
            const shouldReward = isExpense ? diff < 0 : diff > 0;
            return baseXP + (shouldReward ? 1.5 : -1.5);
        }

        return baseXP;
    }

    private async updateWeeklyTotalXp(workspaceId: string, date: Date, deltaXp: number): Promise<void> {
        if (deltaXp === 0) return;
        
        const week = this.getWeekNumber(date);
        const year = this.getWeekYear(date);
        const weeklyXpId = `${year}-W${String(week).padStart(2, "0")}`;
        
        const docRef = admin.firestore().collection(`workspaces/${workspaceId}/weekly_xp`).doc(weeklyXpId);
        await docRef.set({
            year,
            week,
            xp: admin.firestore.FieldValue.increment(deltaXp),
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }

    private getWeekNumber(d: Date): number {
        const date = new Date(d.getTime());
        date.setHours(0, 0, 0, 0);
        // Ajusta para o domingo mais próximo (início da semana)
        date.setDate(date.getDate() - date.getDay());
        const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
        const days = Math.floor((date.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
        return Math.floor(days / 7) + 1;
    }

    private getWeekYear(d: Date): number {
        const date = new Date(d.getTime());
        date.setHours(0, 0, 0, 0);
        // Ajusta para o domingo mais próximo
        date.setDate(date.getDate() - date.getDay());
        return date.getFullYear();
    }


    private async applyInstallmentBalance(
        workspaceId: string,
        installment: InstallmentModel,
        isReversal: boolean
    ): Promise<void> {
        if (!installment.accounts || !installment.paidAmount || !installment.paidDate) {
            return;
        }

        for (const [accountId, role] of Object.entries(installment.accounts)) {
            // Se for expense/transfer (debt): -amount. Se for income (credit): +amount.
            // Se for estorno (isReversal), inverte o sinal.

            let delta = 0;
            if (role === "credit") {
                delta = installment.paidAmount;
            }
            else {
                delta = -installment.paidAmount;
            }

            if (isReversal) {
                delta = -delta;
            }

            await this.financeRepository.updateAccountBalance(workspaceId, accountId, installment.paidDate, delta);
        }
    }

    async processInvoiceUpdate(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        // Excluir faturas com valor zero
        if (after && after.isInvoice && after.amount === 0) {
            logger.info(`[processInvoiceUpdate] Excluindo fatura com valor zero: ${after.id}`);
            await this.financeRepository.deleteInstallment(workspaceId, after.id);
            if (after.orderId) {
                await this.financeRepository.deleteOrder(workspaceId, after.orderId);
            }
            return;
        }

        const isPaidStatus = (s: InstallmentStatus | undefined) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        const isBeforePaid = isPaidStatus(before?.status);
        const isAfterPaid = isPaidStatus(after?.status);

        const handleInvoice = async (inst: InstallmentModel, isReversal: boolean) => {
            if (!inst.accounts || !inst.paidAmount || !inst.paidDate) {
                logger.debug(`[processInvoiceUpdate] Instalação ignorada por falta de dados (accounts, paidAmount ou paidDate): ${inst.id}`);
                return;
            }

            // Se for o pagamento de uma fatura, precisamos checar a diferença e impactar a próxima
            if (inst.isInvoice) {
                const diff = (inst.paidAmount || 0) - (inst.amount || 0);
                logger.info(`[processInvoiceUpdate] Processando pagamento de fatura: id=${inst.id}, diff=${diff}, isReversal=${isReversal}`);

                if (diff !== 0) {
                    // Para faturas (isInvoice), identificamos a conta de crédito (que recebeu o pagamento)
                    let accountId: string | undefined;

                    if (inst.accounts) {
                        accountId = Object.entries(inst.accounts).find(([, role]) => role === "credit")?.[0];
                    }

                    if (accountId) {
                        const account = await this.financeRepository.getAccountById(workspaceId, accountId);
                        if (account) {
                            const nextInvoiceDueDate = InvoiceService.calculateInvoiceDueDate(inst.paidDate, account);
                            // Se pago a mais (diff > 0), decrementa a próxima (delta negativo)
                            // Se pago a menos (diff < 0), incrementa a próxima (delta positivo)
                            let delta = -diff;
                            if (isReversal) {
                                delta = -delta;
                            }
                            logger.info(`[processInvoiceUpdate] Atualizando próxima fatura: accountId=${accountId}, dueDate=${nextInvoiceDueDate.toISOString()}, delta=${delta}`);
                            await this.financeRepository.updateInvoiceWithDelta(workspaceId, account, nextInvoiceDueDate, delta);
                        }
                        else {
                            logger.warn(`[processInvoiceUpdate] Conta não encontrada para fatura: ${accountId}`);
                        }
                    }
                    else {
                        logger.warn(`[processInvoiceUpdate] Não foi possível identificar a conta de crédito na fatura: ${inst.id}`);
                    }
                }
                return;
            }

            for (const [accountId, role] of Object.entries(inst.accounts)) {
                let delta = 0;
                if (role === "credit") {
                    delta = inst.paidAmount;
                }
                else {
                    delta = -inst.paidAmount;
                }

                if (isReversal) {
                    delta = -delta;
                }

                const account = await this.financeRepository.getAccountById(workspaceId, accountId);
                if (account?.runtimeType === AccountType.creditCard) {
                    const invoiceDueDate = InvoiceService.calculateInvoiceDueDate(inst.paidDate, account);
                    logger.info(`[processInvoiceUpdate] Impactando fatura de cartão: accountId=${accountId}, role=${role}, invoiceDueDate=${invoiceDueDate.toISOString()}, delta=${-delta}, isReversal=${isReversal}`);
                    await this.financeRepository.updateInvoiceWithDelta(workspaceId, account, invoiceDueDate, -delta);
                }
            }
        };

        // Caso 1: Estorno
        if (isBeforePaid && (!after || !isAfterPaid)) {
            logger.info(`[processInvoiceUpdate] Detectado estorno/cancelamento: ${before?.id}`);
            await handleInvoice(before!, true);
        }
        // Caso 2: Novo pagamento
        else if (!isBeforePaid && after && isAfterPaid) {
            logger.info(`[processInvoiceUpdate] Detectado novo pagamento: ${after.id}`);
            await handleInvoice(after, false);
        }
        // Caso 3: Alteração em pagamento existente
        else if (isBeforePaid && isAfterPaid && before && after) {
            const hasChangedAccount = JSON.stringify(before.accounts) !== JSON.stringify(after.accounts);
            const hasChangedAmount = before.paidAmount !== after.paidAmount;
            const hasChangedDate = before.paidDate?.getTime() !== after.paidDate?.getTime();

            if (hasChangedAccount || hasChangedAmount || hasChangedDate) {
                logger.info(`[processInvoiceUpdate] Detectada alteração em pagamento: ${after.id}, hasChangedAccount=${hasChangedAccount}, hasChangedAmount=${hasChangedAmount}, hasChangedDate=${hasChangedDate}`);
                await handleInvoice(before, true);
                await handleInvoice(after, false);
            }
        }
    }

    /**
     * Normaliza a data do saldo inicial: o cliente grava uma string ISO, mas
     * documentos antigos podem ter Timestamp. Sempre retorna meio-dia local
     * para evitar viradas de dia por fuso horário.
     */
    private resolveInitialBalanceDate(raw: any): Date {
        let date: Date;
        if (raw && typeof raw.toDate === "function") {
            date = raw.toDate();
        }
        else if (raw) {
            date = new Date(raw);
        }
        else {
            date = new Date();
        }

        if (Number.isNaN(date.getTime())) {
            date = new Date();
        }

        date.setHours(12, 0, 0, 0);
        return date;
    }

    /** Monta a order sintética de saldo inicial a partir da conta. */
    private buildInitialBalanceOrder(accountId: string, account: AccountModel, date: Date): Omit<OrderModel, "id"> {
        const year = date.getFullYear();
        const month = date.getMonth() + 1;
        const startMonth = `${year}-${month.toString().padStart(2, "0")}`;

        let type: OrderType;
        let impact: "debt" | "credit";

        if (account.runtimeType === AccountType.creditCard || account.runtimeType === AccountType.debt) {
            // Para cartões e dívidas, um saldo "positivo" (limit usado ou valor da dívida) é um débito (reduz patrimônio líquido)
            type = OrderType.expense;
            impact = "debt";
        }
        else {
            // Para conta corrente e investimentos, saldo positivo é crédito
            type = account.initialBalance >= 0 ? OrderType.income : OrderType.expense;
            impact = account.initialBalance >= 0 ? "credit" : "debt";
        }

        // Categoria de sistema `initial-balance`, criada em
        // workspaces/{wid}/categories por createDefaultCategories. O `type`
        // acompanha o sinal do saldo (a categoria persistida é única).
        const category = {
            ...INITIAL_BALANCE_CATEGORY,
            type: type === OrderType.income ? CategoryType.income : CategoryType.expense,
        };

        return {
            amount: Math.abs(account.initialBalance),
            description: "Saldo Inicial",
            category: category,
            status: OrderStatus.settled,
            type: type,
            installmentType: InstallmentType.single,
            dueDay: date.getDate(),
            startMonth: startMonth,
            accounts: {
                [accountId]: impact
            },
            accountIds: [accountId],
            installmentCreationStatus: InstallmentStatus.settled
        };
    }

    /**
     * Cria, atualiza ou remove a order de saldo inicial da conta.
     *
     * Chamada na criação da conta e sempre que `initialBalance`/
     * `initialBalanceDate` mudarem. Como `syncInstallments` não cascateia
     * edições de order para as parcelas, a parcela correspondente é ajustada
     * explicitamente aqui.
     */
    async syncInitialBalance(workspaceId: string, accountId: string, account: AccountModel | null): Promise<void> {
        const initialBalanceOrderId = `initial-balance-${accountId}`;
        const existingOrder = await this.financeRepository.getOrderById(workspaceId, initialBalanceOrderId);

        if (!account || !account.initialBalance) {
            // Saldo inicial zerado (ou conta removida): a order sintética não
            // deve existir. Apagar a order faz onOrderWritten remover as parcelas.
            if (existingOrder) {
                logger.info(`[syncInitialBalance] Saldo inicial zerado: removendo ${initialBalanceOrderId} do workspace ${workspaceId}.`);
                await this.financeRepository.deleteOrder(workspaceId, initialBalanceOrderId);
            }
            return;
        }

        const date = this.resolveInitialBalanceDate(account.initialBalanceDate);
        const order = this.buildInitialBalanceOrder(accountId, account, date);

        if (!existingOrder) {
            await this.financeRepository.createOrder(workspaceId, order, initialBalanceOrderId);
            return;
        }

        const hasChanged = existingOrder.amount !== order.amount
            || existingOrder.dueDay !== order.dueDay
            || existingOrder.startMonth !== order.startMonth
            || existingOrder.type !== order.type
            || JSON.stringify(existingOrder.accounts || {}) !== JSON.stringify(order.accounts || {});

        if (!hasChanged) {
            return;
        }

        logger.info(`[syncInitialBalance] Ressincronizando ${initialBalanceOrderId} do workspace ${workspaceId} (amount ${existingOrder.amount} -> ${order.amount}).`);

        await this.financeRepository.updateOrder(workspaceId, initialBalanceOrderId, {
            amount: order.amount,
            dueDay: order.dueDay,
            startMonth: order.startMonth,
            type: order.type,
            accounts: order.accounts,
            accountIds: order.accountIds,
            category: order.category,
            status: order.status,
        });

        // A parcela do saldo inicial nasce liquidada: o planejado (`amount`) é
        // zero e o valor efetivo vive em `paidAmount`/`referenceAmount`.
        const installments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, initialBalanceOrderId);
        for (const installment of installments) {
            await this.financeRepository.updateInstallment(workspaceId, installment.id, {
                amount: 0,
                paidAmount: order.amount,
                dueDate: date,
                paidDate: date,
                description: order.description,
                type: order.type,
                accounts: order.accounts,
                category: order.category,
                status: InstallmentStatus.settled,
                replicationCascade: ReplicationCascade.none,
            });
        }
    }

    async deleteOrdersByAccountId(workspaceId: string, accountId: string) {
        await this.financeRepository.deleteOrdersByAccountId(workspaceId, accountId);
    }

    async createOrderHistory(workspaceId: string, orderId: string, snapshot: any): Promise<void> {
        await this.financeRepository.createOrderHistory(workspaceId, orderId, snapshot);
    }

    async generateRecurringInstallments(): Promise<void> {
        const predictabilityMonths = DEFAULT_FINANCE_CONFIG.recurrence.predictabilityMonths;
        const GLOBAL_LIMIT = 500;
        const CHUNK_SIZE = 50;

        // Limite de data: hoje + previsibilidade
        const now = new Date();
        now.setHours(12, 0, 0, 0);
        const thresholdDate = new Date(now.getFullYear(), now.getMonth() + predictabilityMonths, 1, 12);

        console.log(`Buscando até ${GLOBAL_LIMIT} ordens recorrentes para processar em chunks de ${CHUNK_SIZE}...`);
        const ordersToProcess = await this.financeRepository.getOrdersByRecurringNextGenerationGroup(thresholdDate, GLOBAL_LIMIT);

        if (ordersToProcess.length === 0) {
            console.log("Nenhuma ordem recorrente pendente de geração.");
            return;
        }

        console.log(`Processando ${ordersToProcess.length} ordens...`);

        // Processa em chunks para usar transações
        for (let i = 0; i < ordersToProcess.length; i += CHUNK_SIZE) {
            const chunk = ordersToProcess.slice(i, i + CHUNK_SIZE);
            console.log(`Processando chunk de ${chunk.length} ordens (índice ${i} a ${i + chunk.length - 1})...`);

            await this.financeRepository.processRecurringInstallmentsChunk(chunk, (order) => {
                return this.createInstallmentsForOrder(order, thresholdDate);
            });
        }
    }

    private createInstallmentsForOrder(
        order: OrderModel,
        thresholdDate: Date
    ): Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[] {
        const lastGenerated = order.lastGeneratedDueDate || new Date(); // Fallback de segurança
        lastGenerated.setHours(12, 0, 0, 0);

        let currentYear = lastGenerated.getFullYear();
        let currentMonth = lastGenerated.getMonth(); // 0-indexed

        const expectedInstallments: Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[] = [];

        // Gera enquanto a próxima data for menor ou igual ao threshold
        let finished = false;
        while (!finished) {
            // Avança para o próximo mês
            currentMonth++;
            if (currentMonth > 11) {
                currentMonth = 0;
                currentYear++;
            }

            const nextMonthFirstDay = new Date(currentYear, currentMonth, 1, 12);

            finished = (nextMonthFirstDay > thresholdDate)

            if (finished) {
                break;
            }

            const lastDayOfMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
            const day = Math.min(order.dueDay, lastDayOfMonth);
            const dueDate = new Date(currentYear, currentMonth, day, 12);

            expectedInstallments.push({
                orderId: order.id,
                amount: order.amount,
                dueDate: dueDate,
                description: order.description,
                status: InstallmentStatus.pending,
                type: order.type,
                installmentType: order.installmentType,
                accounts: order.accounts,
                accountIds: order.accountIds,
                category: order.category,
            });
        }

        return expectedInstallments;
    }


}
