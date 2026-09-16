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
import { formatWeekId, getWeekRef } from "../../../../core/utils/week.utils";
import { toDateKey } from "../../../../core/utils/date_key";

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

/** Campos replicáveis que mudaram entre a versão anterior e a nova da parcela. */
export interface InstallmentCascadeChanges {
    amount: boolean;
    dueDate: boolean;
    description: boolean;
    category: boolean;
    accounts: boolean;
    type: boolean;
    /** A parcela passou a ter status `removed` nesta escrita. */
    removed: boolean;
    /** Verdadeiro quando ao menos um campo replicável mudou. */
    hasReplicableChange: boolean;
}

/**
 * Diferença entre duas versões de uma parcela, restrita ao que a cascata
 * replica. Campos derivados (xp, replicationCascade) e de pagamento
 * (status paid, paidAmount, paidDate) NÃO entram: pagar uma parcela não
 * altera as irmãs.
 */
export function diffInstallmentForCascade(
    before: InstallmentModel,
    after: InstallmentModel
): InstallmentCascadeChanges {
    const amount = after.amount !== before.amount;
    const dueDate = (after.dueDate?.getTime() ?? null) !== (before.dueDate?.getTime() ?? null);
    const description = after.description !== before.description;
    const category = after.category?.id !== before.category?.id;
    const accounts = JSON.stringify(after.accounts || {}) !== JSON.stringify(before.accounts || {});
    const type = after.type !== before.type;
    const removed = before.status !== InstallmentStatus.removed && after.status === InstallmentStatus.removed;

    return {
        amount,
        dueDate,
        description,
        category,
        accounts,
        type,
        removed,
        hasReplicableChange: amount || dueDate || description || category || accounts || type || removed,
    };
}

/**
 * Desloca o vencimento de uma parcela irmã segundo a mudança de vencimento da
 * parcela de origem — em DIA DO MÊS, nunca em milissegundos.
 *
 * Somar o delta em ms quebra o calendário: 31/01 -> 28/02 são 28 dias, e somar
 * 28 dias a uma parcela de 31/03 daria 28/04 em vez de 28/04... e a de 31/05
 * cairia em 28/06 apenas por coincidência; com meses de 30 dias o erro se
 * acumula e as parcelas escorregam de mês.
 *
 * Regra:
 *  - o delta de MESES entre o vencimento antigo e o novo é aplicado ao mês da
 *    irmã (normalmente zero: o usuário só troca o dia);
 *  - o DIA passa a ser o dia do novo vencimento, com clamp no último dia do
 *    mês de destino (31 em fevereiro vira 28/29).
 */
export function shiftDueDateByMonthDay(
    siblingDueDate: Date,
    beforeDueDate: Date,
    afterDueDate: Date
): Date {
    const monthDelta = (afterDueDate.getFullYear() - beforeDueDate.getFullYear()) * 12
        + (afterDueDate.getMonth() - beforeDueDate.getMonth());

    const targetDay = afterDueDate.getDate();
    const year = siblingDueDate.getFullYear();
    const month = siblingDueDate.getMonth() + monthDelta;

    // O dia 0 do mês seguinte é o último dia do mês de destino (e o construtor
    // normaliza overflow/underflow de mês sozinho).
    const lastDayOfTargetMonth = new Date(year, month + 1, 0).getDate();
    const day = Math.min(targetDay, lastDayOfTargetMonth);

    return new Date(year, month, day, 12, 0, 0, 0);
}

/**
 * Valor de uma parcela para o total da order.
 *
 * `order.amount` significa REALIZADO + PLANEJADO EM ABERTO: parcela paga entra
 * pelo que de fato custou, parcela em aberto pelo que ainda se espera gastar, e
 * parcela removida não entra (ver `buildOrderUpdateFromCascade`).
 *
 * Na parcela paga o realizado é o `referenceAmount`, que o cliente calcula como
 * `paidAmount ?? amount` (installment_model.dart) e grava junto do pagamento.
 * Atenção: pagar pelo app NÃO zera o `amount` — ele continua com o planejado
 * original, que é justamente o que não queremos no realizado. O `amount` zerado
 * só acontece nas parcelas que NASCEM pagas (saldo inicial, compra já liquidada
 * no cartão), onde `syncInstallments` zera o planejado de propósito; somar
 * `amount` levaria o total dessas orders a zero.
 *
 * Na parcela em aberto o valor é o próprio `amount`: o `referenceAmount`
 * acompanha o planejado, mas pode chegar defasado na escrita que o cliente
 * acabou de fazer.
 */
function installmentValueForOrderTotal(installment: InstallmentModel): number {
    const isPaid = installment.status === InstallmentStatus.paid
        || installment.status === InstallmentStatus.settled;

    if (isPaid) {
        return installment.referenceAmount ?? installment.paidAmount ?? 0;
    }

    return installment.amount ?? 0;
}

/**
 * Monta o patch da order a partir do estado final das parcelas.
 *
 * Só inclui o que de fato mudou — cada `updateOrder` dispara onOrderWritten,
 * que grava um documento em `orders/{id}/history`.
 */
export function buildOrderUpdateFromCascade(
    after: InstallmentModel,
    updatedInstallments: InstallmentModel[],
    changes: InstallmentCascadeChanges
): Partial<OrderModel> {
    const orderUpdate: Partial<OrderModel> = {};

    // Parcelas removidas são exclusões lógicas e não entram no total.
    const activeInstallments = updatedInstallments.filter((i) => i.status !== InstallmentStatus.removed);

    if (changes.amount || changes.removed) {
        const totalAmount = activeInstallments.reduce(
            (sum, i) => sum + installmentValueForOrderTotal(i),
            0
        );
        orderUpdate.amount = Math.round(totalAmount * 100) / 100;
    }

    if (changes.description) orderUpdate.description = after.description;
    if (changes.category) orderUpdate.category = after.category;
    if (changes.accounts) {
        orderUpdate.accounts = after.accounts;
        orderUpdate.accountIds = after.accountIds;
    }

    // `dueDay` só acompanha uma mudança de VENCIMENTO. Antes era reescrito em
    // toda cascata, inclusive quando o evento era um pagamento — e o dia do
    // pagamento acabava virando o dia de vencimento da order.
    if (changes.dueDate) orderUpdate.dueDay = after.dueDate.getDate();

    if (updatedInstallments.length > 0 && activeInstallments.length === 0) {
        orderUpdate.status = OrderStatus.cancelled;
    }

    return orderUpdate;
}

export class FinanceService {
    constructor(private financeRepository: IFinanceRepository) {
    }

    async syncInstallments(workspaceId: string, orderId: string, before: OrderModel | null, after: OrderModel | null): Promise<void> {
        // 1. Se a order foi excluída ou está cancelada, deletamos tudo.
        // Em lotes, não uma escrita sequencial por parcela: uma order parcelada
        // pode ter centenas de parcelas. O repositório já resolve a query, então
        // não há leitura prévia aqui.
        if (!after) {
            await this.financeRepository.deleteInstallmentsByOrderId(workspaceId, orderId);
            return;
        }

        // 2. Se a order já existia, não fazemos cascateamento de edição para as installments.
        // A criação da order cria as installments, mas uma alteração na order não deve mexer nas installments.
        if (before && !before.isInvoice) {
            console.log(`SyncInstallments: Order ${orderId} atualizada. Pulando cascateamento para installments conforme regra de negócio.`);
            return;
        }

        // 2.1 Installments existentes: só interessam ao fluxo de fatura (passo 4).
        const existingInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, orderId);

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

    /**
     * Cascata de uma parcela para as irmãs e para a order.
     *
     * Só roda quando algum campo REPLICÁVEL mudou: uma escrita que apenas
     * recalculou `xp` ou zerou a cascata não tem o que replicar.
     */
    async processInstallmentCascade(
        workspaceId: string,
        before: InstallmentModel,
        after: InstallmentModel
    ): Promise<void> {
        const cascade = after.replicationCascade || ReplicationCascade.none;
        const changes = diffInstallmentForCascade(before, after);

        if (cascade === ReplicationCascade.none) {
            // Sem cascata sobra uma única consequência possível na order: esta
            // pode ter sido a ÚLTIMA parcela viva. Remoções uma a uma (cada
            // uma com cascade 'none') precisam cancelar a order no fim.
            if (changes.removed) {
                await this.cancelOrderIfFullyRemoved(workspaceId, after);
            }
            return;
        }

        if (!changes.hasReplicableChange) {
            logger.debug(`[processInstallmentCascade] ${after.id}: nenhum campo replicável mudou; cascata ignorada.`);
            return;
        }

        const allInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, after.orderId);
        const sorted = [...allInstallments].sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());

        const siblings = sorted.filter((i) => i.id !== after.id);

        // 'future' é por DATA, não por índice: irmãs que vencem a partir do
        // (novo) vencimento desta parcela. Por índice, uma parcela fora de
        // ordem — ou uma order recorrente com parcelas geradas depois —
        // selecionava o conjunto errado.
        const afterDueMs = after.dueDate.getTime();
        const targets = (cascade === ReplicationCascade.all
            ? siblings
            : siblings.filter((i) => i.dueDate.getTime() >= afterDueMs)
        // Parcelas já removidas são exclusões lógicas: não recebem replicação.
        ).filter((i) => i.status !== InstallmentStatus.removed);

        const appliedUpdates = new Map<string, Partial<InstallmentModel>>();

        for (const inst of targets) {
            const installmentUpdate: Partial<InstallmentModel> = {};
            const isTargetPaid = inst.status === InstallmentStatus.paid || inst.status === InstallmentStatus.settled;

            if (changes.description) installmentUpdate.description = after.description;

            // Parcela paga tem `amount` zerado por regra de negócio (o valor
            // efetivo vive em paidAmount/referenceAmount): replicar o novo
            // planejado para ela reintroduziria um planejado já realizado.
            if (changes.amount && !isTargetPaid) {
                installmentUpdate.amount = after.amount;
                installmentUpdate.referenceAmount = after.amount;
            }

            if (changes.category) installmentUpdate.category = after.category;
            if (changes.accounts) {
                installmentUpdate.accounts = after.accounts;
                installmentUpdate.accountIds = after.accountIds;
            }
            if (changes.type) installmentUpdate.type = after.type;
            if (changes.removed) installmentUpdate.status = InstallmentStatus.removed;

            if (changes.dueDate) {
                const newDueDate = shiftDueDateByMonthDay(inst.dueDate, before.dueDate, after.dueDate);
                installmentUpdate.dueDate = newDueDate;

                // Se não estiver paga, o referenceDate segue a dueDate
                if (!isTargetPaid) {
                    installmentUpdate.referenceDate = newDueDate;
                }
            }

            if (Object.keys(installmentUpdate).length > 0) {
                // Importante: marcar a cascata como none para evitar recursão
                // infinita se o trigger disparar novamente.
                installmentUpdate.replicationCascade = ReplicationCascade.none;

                appliedUpdates.set(inst.id, installmentUpdate);
                await this.financeRepository.updateInstallment(workspaceId, inst.id, installmentUpdate);
            }
        }

        // Estado final das parcelas depois da cascata, sem reler o Firestore.
        const updatedInstallments = sorted.map((inst) => {
            if (inst.id === after.id) return after;
            const update = appliedUpdates.get(inst.id);
            return update ? { ...inst, ...update } : inst;
        });

        const orderUpdate = buildOrderUpdateFromCascade(after, updatedInstallments, changes);

        if (Object.keys(orderUpdate).length > 0) {
            logger.info(`[processInstallmentCascade] Cascateando alteração de Installment para Order ${after.orderId}: ${JSON.stringify(Object.keys(orderUpdate))}.`);
            await this.financeRepository.updateOrder(workspaceId, after.orderId, orderUpdate);
        }
        else {
            logger.debug(`[processInstallmentCascade] Order ${after.orderId} sem mudanças relevantes; updateOrder ignorado.`);
        }

        // A cascata já foi consumida: zerar no documento de ORIGEM, senão ela
        // fica grudada e a próxima escrita qualquer na parcela replica tudo de
        // novo. Num pagamento a escrita de xp já faz isso (xp + cascata juntos);
        // numa cascata sem pagamento — trocar a categoria com `all`, por
        // exemplo — não há escrita de xp, e é esta que fecha o ciclo. O evento
        // resultante só mexe num campo derivado, então o handler o ignora pela
        // guarda por conteúdo.
        await this.financeRepository.updateInstallment(workspaceId, after.id, {
            replicationCascade: ReplicationCascade.none,
        });
    }

    /**
     * Cancela a order quando TODAS as suas parcelas estão removidas.
     *
     * Usado no caminho sem cascata: o usuário pode remover parcela a parcela,
     * e só a última remoção encerra a order.
     *
     * Grava `amount: 0` junto do cancelamento, igual ao caminho com cascata:
     * sem nenhuma parcela viva, o total realizado + planejado da order é zero.
     */
    private async cancelOrderIfFullyRemoved(workspaceId: string, after: InstallmentModel): Promise<void> {
        const allInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, after.orderId);
        const merged = allInstallments.map((inst) => (inst.id === after.id ? after : inst));

        if (merged.length === 0) return;
        if (!merged.every((inst) => inst.status === InstallmentStatus.removed)) return;

        logger.info(`[processInstallmentCascade] Todas as parcelas da order ${after.orderId} estão removidas: cancelando a order.`);
        await this.financeRepository.updateOrder(workspaceId, after.orderId, {
            amount: 0,
            status: OrderStatus.cancelled,
        });
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
            // Uma ÚNICA escrita com xp + cascata zerada: a cascata já foi
            // consumida por este evento e não pode ficar grudada no documento
            // de origem (senão a próxima escrita qualquer a reexecuta). Como
            // ambos são campos derivados, o evento resultante desta escrita cai
            // na guarda por conteúdo do handler e sai cedo.
            await this.financeRepository.updateInstallment(workspaceId, after.id, {
                xp,
                replicationCascade: ReplicationCascade.none,
            });
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
                    // Idem ao caso 2: xp e cascata na mesma escrita.
                    await this.financeRepository.updateInstallment(workspaceId, after.id, {
                        xp: newXp,
                        replicationCascade: ReplicationCascade.none,
                    });
                    
                    // Estorna o XP antigo da data antiga e aplica o novo na nova data
                    await this.updateWeeklyTotalXp(workspaceId, before.paidDate || before.dueDate, -oldXp);
                    await this.updateWeeklyTotalXp(workspaceId, after.paidDate || after.dueDate, newXp);
                    await container.gamificationService.addXp(workspaceId, newXp - oldXp, "Alteração de transação paga");
                }
            }
        }
    }

    /**
     * XP de uma parcela paga.
     *
     * PÚBLICO apenas para que o job de reconstrução (rebuild.service.ts) some
     * exatamente o mesmo XP que o gatilho — a semântica não mudou.
     */
    calculateXp(inst: InstallmentModel): number {
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

    /**
     * XP semanal em `weekly_xp/{YYYY-Www}`.
     *
     * F1.9: o id vem da ÚNICA definição de semana do projeto
     * (`core/utils/week.utils.ts`, fuso do produto). Antes havia aqui uma cópia
     * privada da aritmética, em UTC, que divergia das missões semanais no
     * sábado à noite.
     */
    private async updateWeeklyTotalXp(workspaceId: string, date: Date, deltaXp: number): Promise<void> {
        if (deltaXp === 0) return;

        const { year, week } = getWeekRef(date);
        const weeklyXpId = formatWeekId({ year, week });

        const docRef = admin.firestore().collection(`workspaces/${workspaceId}/weekly_xp`).doc(weeklyXpId);
        await docRef.set({
            year,
            week,
            xp: admin.firestore.FieldValue.increment(deltaXp),
            lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // O cliente lê a semana corrente do workspace em vez de calculá-la:
        // qualquer handler que mexa em dados semanais reafirma o marcador.
        await container.weekSyncService.ensureCurrentWeek(workspaceId);
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
        // Cartões cuja próxima fatura precisa ser recalculada ao fim deste
        // evento (F1.8). Só entram aqui contas que o evento de fato afetou —
        // uma parcela pendente de cartão não mexe em fatura nenhuma.
        const cardsToSync = new Set<string>();
        const invoiceCard = (inst: InstallmentModel | null): string | undefined => {
            if (!inst?.isInvoice || !inst.accounts) return undefined;
            return Object.entries(inst.accounts).find(([, role]) => role === "credit")?.[0];
        };

        // A própria parcela de fatura mudou (valor, status ou deixou de
        // existir): o resumo da conta muda junto, paga ou não.
        for (const candidate of [invoiceCard(before), invoiceCard(after)]) {
            if (candidate) cardsToSync.add(candidate);
        }

        // Excluir faturas com valor zero
        if (after && after.isInvoice && after.amount === 0) {
            logger.info(`[processInvoiceUpdate] Excluindo fatura com valor zero: ${after.id}`);
            await this.financeRepository.deleteInstallment(workspaceId, after.id);
            if (after.orderId) {
                await this.financeRepository.deleteOrder(workspaceId, after.orderId);
            }
            await this.syncNextInvoices(workspaceId, cardsToSync);
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
                            logger.info(`[processInvoiceUpdate] Atualizando próxima fatura: accountId=${accountId}, dueDate=${toDateKey(nextInvoiceDueDate)}, delta=${delta}`);
                            await this.financeRepository.updateInvoiceWithDelta(workspaceId, account, nextInvoiceDueDate, delta);
                            cardsToSync.add(accountId);
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
                    logger.info(`[processInvoiceUpdate] Impactando fatura de cartão: accountId=${accountId}, role=${role}, invoiceDueDate=${toDateKey(invoiceDueDate)}, delta=${-delta}, isReversal=${isReversal}`);
                    await this.financeRepository.updateInvoiceWithDelta(workspaceId, account, invoiceDueDate, -delta);
                    cardsToSync.add(accountId);
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

        await this.syncNextInvoices(workspaceId, cardsToSync);
    }

    /**
     * Recalcula `accounts/{id}.nextInvoice` dos cartões afetados (F1.8).
     *
     * **Por que isto converge mesmo lendo um valor momentaneamente velho.**
     * `updateInvoiceWithDelta` escreve a ORDER; a parcela da fatura só ganha o
     * novo valor quando `onOrderWritten` roda. A sincronização feita aqui
     * enxerga a parcela anterior — mas a escrita da parcela dispara
     * `onInstallmentWritten` -> `processInvoiceUpdate` de novo, e é essa última
     * passagem que grava o valor certo. O cron diário é a terceira rede.
     *
     * Falhar aqui NÃO pode derrubar o pagamento que disparou o gatilho: o
     * resumo é uma conveniência para o cliente, e o cron o reconstrói.
     */
    private async syncNextInvoices(workspaceId: string, accountIds: Set<string>): Promise<void> {
        for (const accountId of accountIds) {
            try {
                await container.invoiceSyncService.syncNextInvoice(workspaceId, accountId);
            }
            catch (error) {
                logger.warn(`[processInvoiceUpdate] Falha ao sincronizar nextInvoice de ${accountId}: ${error}`);
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

    /**
     * Parcelas que faltam gerar para uma order recorrente, do mês seguinte ao
     * último vencimento já gerado até o horizonte de previsibilidade.
     *
     * NÃO muta `order`: o `setHours` antigo escrevia dentro de
     * `order.lastGeneratedDueDate`, e o mesmo objeto é reaproveitado pelo
     * repositório na hora de gravar o novo `lastGeneratedDueDate`.
     */
    private createInstallmentsForOrder(
        order: OrderModel,
        thresholdDate: Date
    ): Omit<InstallmentModel, "id" | "referenceDate" | "referenceAmount">[] {
        // Sem `lastGeneratedDueDate` não há como saber onde a série parou:
        // assumir "hoje" (o fallback antigo) inventava parcelas a partir do mês
        // corrente, duplicando ou furando a série. A query do repositório já
        // exclui estas orders (o Firestore não casa documentos sem o campo);
        // esta guarda cobre qualquer outro caminho de chamada.
        // Use scripts/backfill_last_generated_due_date.ts para preencher a base
        // legada.
        if (!order.lastGeneratedDueDate) {
            logger.warn(`[generateRecurringInstallments] Order ${order.id} é recorrente e não tem lastGeneratedDueDate: nada será gerado.`);
            return [];
        }

        const lastGenerated = new Date(order.lastGeneratedDueDate);
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

            // Mesmos campos que `syncInstallments` monta para a criação normal
            // — as parcelas do cron não podem ter um schema próprio.
            expectedInstallments.push({
                orderId: order.id,
                amount: order.amount,
                dueDate: dueDate,
                description: order.description,
                status: InstallmentStatus.pending,
                type: order.type,
                installmentType: order.installmentType,
                accounts: order.accounts,
                accountIds: Object.keys(order.accounts || {}),
                category: order.category,
                isInvoice: order.isInvoice,
            });
        }

        return expectedInstallments;
    }


}
