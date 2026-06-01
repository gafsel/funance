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
import {IFinanceRepository} from "../repositories/finance.repository";
import {CategoryType} from "../../../workspace/domain/models/category.model";

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

        // 2.1 Se a order já existia, não fazemos cascateamento de edição para as installments.
        // A criação da order cria as installments, mas uma alteração na order não deve mexer nas installments.
        if (before) {
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
            const dueDate = new Date(year, month, day, 12);

            const isFirst = i === 0;
            const status = (shouldAllBePaid || (isFirst && (after.installmentCreationStatus === InstallmentStatus.paid || after.installmentCreationStatus === InstallmentStatus.settled)))
                ? after.installmentCreationStatus!
                : InstallmentStatus.pending;

            let installmentAmount = after.amount;
            if (after.installmentType === InstallmentType.installment) {
                const totalAmount = after.amount;
                const count = after.installmentCount || 1;
                const baseValue = Math.floor((totalAmount / count) * 100) / 100;
                const remainder = Math.round((totalAmount - (baseValue * count)) * 100) / 100;

                installmentAmount = baseValue;
                if (i === (after.installmentCount || 1) - 1) {
                    installmentAmount = Math.round((baseValue + remainder) * 100) / 100;
                }
            }

            expectedInstallments.push({
                orderId: orderId,
                amount: installmentAmount,
                dueDate: dueDate,
                description: after.description,
                referenceDate: dueDate,
                referenceAmount: installmentAmount,
                status: status,
                type: after.type,
                installmentType: after.installmentType,
                installmentNumber: after.installmentType === InstallmentType.installment ? i + 1 : undefined,
                installmentCount: after.installmentType === InstallmentType.installment ? after.installmentCount : undefined,
                accounts: after.accounts,
                accountIds: Object.keys(after.accounts || {}),
                category: after.category,
                paidAmount: (status === InstallmentStatus.paid || status === InstallmentStatus.settled) ? installmentAmount : undefined,
                paidDate: (status === InstallmentStatus.paid || status === InstallmentStatus.settled) ? new Date(dueDate) : undefined,
            });
        }

        // 4. Criar as installments
        await this.financeRepository.createInstallments(workspaceId, expectedInstallments);
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
        // Se houver cascade, a lógica de saldo será tratada individualmente para cada installment alterada
        // mas o gatilho da function de trigger (se existir) chamaria este método para cada uma.
        // Se estivermos chamando manualmente no updateInstallment do service, precisamos tomar cuidado.

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
            accountIds: [accountId],
            installmentCreationStatus: InstallmentStatus.settled
        };

        await this.financeRepository.createOrder(workspaceId, order, initialBalanceOrderId);
    }

    async deleteOrdersByAccountId(workspaceId: string, accountId: string) {
        await this.financeRepository.deleteOrdersByAccountId(workspaceId, accountId);
    }

    async createOrderHistory(workspaceId: string, orderId: string, snapshot: any): Promise<void> {
        await this.financeRepository.createOrderHistory(workspaceId, orderId, snapshot);
    }

}
