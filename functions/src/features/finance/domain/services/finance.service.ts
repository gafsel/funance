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
import { CategoryType } from "../../../workspace/domain/models/category.model";

export class FinanceService {
    constructor(private financeRepository: IFinanceRepository) {
    }

    async syncInstallments(workspaceId: string, orderId: string, before: OrderModel | null, after: OrderModel | null): Promise<void> {
        // 1. Buscar installments existentes
        const existingInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, orderId);

        // 2. Se a order foi excluída ou está cancelada, deletamos tudo
        if (!after || after.status === OrderStatus.cancelled) {
            for (const inst of existingInstallments) {
                await this.financeRepository.deleteInstallment(workspaceId, inst.id);
            }
            return;
        }

        // 3. Detectar o que mudou na Order
        const hasAmountChanged = !before || before.amount !== after.amount;
        const hasDescriptionChanged = !before || before.description !== after.description;
        const hasCategoryChanged = !before || before.category?.id !== after.category?.id;
        const hasAccountsChanged = !before || JSON.stringify(before.accounts) !== JSON.stringify(after.accounts);
        const hasTypeChanged = !before || before.type !== after.type;
        const hasDueDayChanged = !before || before.dueDay !== after.dueDay;
        const hasStartMonthChanged = !before || before.startMonth !== after.startMonth;
        const hasInstallmentTypeChanged = !before || before.installmentType !== after.installmentType;
        const hasInstallmentCountChanged = !before || before.installmentCount !== after.installmentCount;

        // Se mudou algo estrutural que afete a quantidade ou datas base de todas as parcelas, 
        // talvez precisemos de uma sincronização mais profunda.
        const isStructuralChange = !before || hasDueDayChanged || hasStartMonthChanged || hasInstallmentTypeChanged || hasInstallmentCountChanged;

        // 4. Gerar o que deveria existir (usado para criar novas ou mergear mudanças estruturais)
        const expectedInstallments: Omit<InstallmentModel, "id">[] = [];
        let installmentsToGenerate = 0;

        if (after.installmentType === InstallmentType.single) {
            installmentsToGenerate = 1;
        }
        else if (after.installmentType === InstallmentType.installment) {
            installmentsToGenerate = after.installmentCount || 1;
        }
        else if (after.installmentType === InstallmentType.recurring) {
            // Inicialmente gera 12 parcelas
            installmentsToGenerate = 12;
        }

        const [startYear, startMonth] = after.startMonth.split("-").map(Number);

        let shouldAllBePaid = false;
        if (after.installmentType === InstallmentType.installment &&
            (after.installmentCreationStatus === InstallmentStatus.paid || after.installmentCreationStatus === InstallmentStatus.settled)) {
            // Verificar se é conta de cartão de crédito
            const accountIds = Object.keys(after.accounts || {});
            if (accountIds.length > 0) {
                const account = await this.financeRepository.getAccountById(workspaceId, accountIds[0]);
                if (account?.type === AccountType.credit_card) {
                    shouldAllBePaid = true;
                }
            }
        }

        for (let i = 0; i < installmentsToGenerate; i++) {
            const date = new Date(startYear, startMonth - 1 + i, 1);
            const year = date.getFullYear();
            const month = date.getMonth(); // 0-indexed

            const lastDayOfMonth = new Date(year, month + 1, 0).getDate();
            const day = Math.min(after.dueDay, lastDayOfMonth);
            const dueDate = new Date(year, month, day);

            const isFirst = i === 0;
            const status = (shouldAllBePaid || (isFirst && (after.installmentCreationStatus === InstallmentStatus.paid || after.installmentCreationStatus === InstallmentStatus.settled)))
                ? after.installmentCreationStatus!
                : InstallmentStatus.pending;

            expectedInstallments.push({
                orderId: orderId,
                amount: after.amount,
                dueDate: dueDate,
                description: after.description,
                referenceDate: dueDate,
                referenceAmount: after.amount,
                status: status,
                type: after.type,
                installmentType: after.installmentType,
                installmentNumber: after.installmentType === InstallmentType.installment ? i + 1 : undefined,
                installmentCount: after.installmentType === InstallmentType.installment ? after.installmentCount : undefined,
                accounts: after.accounts,
                accountIds: Object.keys(after.accounts || {}),
                category: after.category,
                paidAmount: (status === InstallmentStatus.paid || status === InstallmentStatus.settled) ? after.amount : undefined,
                paidDate: (status === InstallmentStatus.paid || status === InstallmentStatus.settled) ? dueDate : undefined,
            });
        }

        // 5. Merge Inteligente
        for (let i = 0; i < expectedInstallments.length; i++) {
            const expected = expectedInstallments[i];
            if (i < existingInstallments.length) {
                const existing = existingInstallments[i];

                // Se já está pago, não mexemos (regra de proteção)
                if (existing.status === InstallmentStatus.paid || existing.status === InstallmentStatus.settled) {
                    continue;
                }

                // Se não mudou nada relevante, pula
                if (!isStructuralChange && !hasAmountChanged && !hasDescriptionChanged && !hasCategoryChanged && !hasAccountsChanged && !hasTypeChanged) {
                    continue;
                }

                const installmentUpdate: Partial<InstallmentModel> = {};

                // Apenas o que mudou na Order deve ser replicado
                if (hasAmountChanged) {
                    installmentUpdate.amount = after.amount;
                    installmentUpdate.referenceAmount = after.amount;
                }
                if (hasDescriptionChanged) {
                    installmentUpdate.description = after.description;
                }
                if (hasCategoryChanged) {
                    installmentUpdate.category = after.category;
                }
                if (hasAccountsChanged) {
                    installmentUpdate.accounts = after.accounts;
                    installmentUpdate.accountIds = Object.keys(after.accounts || {});
                }
                if (hasTypeChanged) {
                    installmentUpdate.type = after.type;
                }

                // Se houve mudança estrutural, sincronizamos datas e metadados de parcelamento
                if (isStructuralChange) {
                    if (existing.dueDate.getTime() !== expected.dueDate.getTime()) {
                        installmentUpdate.dueDate = expected.dueDate;
                        installmentUpdate.referenceDate = expected.dueDate;
                    }
                    if (existing.installmentType !== expected.installmentType) {
                        installmentUpdate.installmentType = expected.installmentType;
                    }
                    if (existing.installmentNumber !== expected.installmentNumber) {
                        installmentUpdate.installmentNumber = expected.installmentNumber;
                    }
                    if (existing.installmentCount !== expected.installmentCount) {
                        installmentUpdate.installmentCount = expected.installmentCount;
                    }
                }

                if (Object.keys(installmentUpdate).length > 0) {
                    await this.financeRepository.updateInstallment(workspaceId, existing.id, installmentUpdate);
                }
            }
            else {
                // Nova parcela (ex: aumentou installmentCount)
                await this.financeRepository.createInstallments(workspaceId, [expected]);
            }
        }

        // Remover excedentes
        if (existingInstallments.length > expectedInstallments.length) {
            for (let i = expectedInstallments.length; i < existingInstallments.length; i++) {
                const existing = existingInstallments[i];
                if (existing.status !== InstallmentStatus.paid && existing.status !== InstallmentStatus.settled) {
                    await this.financeRepository.deleteInstallment(workspaceId, existing.id);
                }
            }
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
    }

    async updateAccountBalanceOnInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        // Se houver cascade, a lógica de saldo será tratada individualmente para cada installment alterada
        // mas o gatilho da function de trigger (se existir) chamaria este método para cada uma.
        // Se estivermos chamando manualmente no updateInstallment do service, precisamos tomar cuidado.

        const isBeforePaid = before?.status === InstallmentStatus.paid || before?.status === InstallmentStatus.settled;
        const isAfterPaid = after?.status === InstallmentStatus.paid || after?.status === InstallmentStatus.settled;

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

    async syncInitialBalance(workspaceId: string, accountId: string, account: AccountModel | null): Promise<void> {
        if (!account || account.initialBalance === 0) {
            return;
        }

        const initialBalanceOrderId = `initial-balance-${accountId}`;

        const existingOrder = await this.financeRepository.getOrderById(workspaceId, initialBalanceOrderId);
        if (existingOrder) {
            return;
        }

        const date = (account.initialBalanceDate as any)?.toDate?.() || new Date(account.initialBalanceDate) || new Date();
        const year = date.getFullYear();
        const month = date.getMonth() + 1;
        const startMonth = `${year}-${month.toString().padStart(2, "0")}`;

        const category = {
            id: "initial-balance",
            name: "Saldo Inicial",
            icon: "account_balance_wallet",
            color: "0xFF9E9E9E",
            type: account.initialBalance >= 0 ? CategoryType.income : CategoryType.expense,
            isDeleted: false,
        };

        const order: Omit<OrderModel, "id"> = {
            amount: Math.abs(account.initialBalance),
            description: "Saldo Inicial",
            category: category,
            status: OrderStatus.settled,
            type: account.initialBalance >= 0 ? OrderType.income : OrderType.expense,
            installmentType: InstallmentType.single,
            dueDay: date.getDate(),
            startMonth: startMonth,
            accounts: {
                [accountId]: account.initialBalance >= 0 ? "credit" : "debt"
            },
            installmentCreationStatus: InstallmentStatus.settled
        };

        await this.financeRepository.createOrder(workspaceId, order, initialBalanceOrderId);
    }

    async deleteOrdersByAccountId(workspaceId: string, accountId: string) {
        await this.financeRepository.deleteOrdersByAccountId(workspaceId, accountId);
    }

}
