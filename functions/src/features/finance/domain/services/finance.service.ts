import { OrderModel, InstallmentModel, AccountModel, OrderStatus, InstallmentStatus, InstallmentType } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";

export class FinanceService {
    constructor(private financeRepository: IFinanceRepository) {}

    async syncInstallments(workspaceId: string, orderId: string, order: OrderModel | null): Promise<void> {
    // 1. Buscar installments existentes
        const existingInstallments = await this.financeRepository.getInstallmentsByOrderId(workspaceId, orderId);

        // 2. Se a order foi excluída ou está cancelada, deletamos tudo
        if (!order || order.status === OrderStatus.cancelled) {
            for (const inst of existingInstallments) {
                await this.financeRepository.deleteInstallment(workspaceId, inst.id);
            }
            return;
        }

        // 3. Gerar o que deveria existir
        const expectedInstallments: Omit<InstallmentModel, "id">[] = [];
        let installmentsToGenerate = 0;

        if (order.installmentType === InstallmentType.single) {
            installmentsToGenerate = 1;
        }
        else if (order.installmentType === InstallmentType.installment) {
            installmentsToGenerate = order.installmentCount || 1;
        }
        else if (order.installmentType === InstallmentType.recurring) {
            // Inicialmente gera 12 parcelas
            installmentsToGenerate = 12;
        }

        const [startYear, startMonth] = order.startMonth.split("-").map(Number);

        for (let i = 0; i < installmentsToGenerate; i++) {
            const date = new Date(startYear, startMonth - 1 + i, 1);
            const year = date.getFullYear();
            const month = date.getMonth(); // 0-indexed
      
            const lastDayOfMonth = new Date(year, month + 1, 0).getDate();
            const day = Math.min(order.dueDay, lastDayOfMonth);
            const dueDate = new Date(year, month, day);

            expectedInstallments.push({
                orderId: orderId,
                amount: order.amount,
                dueDate: dueDate,
                status: InstallmentStatus.pending,
                type: order.type,
                installmentType: order.installmentType,
                installmentNumber: order.installmentType === InstallmentType.installment ? i + 1 : undefined,
                installmentCount: order.installmentType === InstallmentType.installment ? order.installmentCount : undefined,
                accounts: order.accounts,
                category: order.category,
            });
        }

        // 4. Merge Inteligente
        // No novo modelo, se a Order mudar, podemos querer preservar Installments já pagos ou alterados.
        // Mas a especificação diz que a Order é a matriz.
        // Para simplificar o refactoring crítico, vamos seguir a lógica de sincronização:
    
        // Se mudou o número de parcelas, removemos as que sobraram (que não estejam pagas?)
        // A especificação de replicationCascade sugere que edições manuais em Installments são importantes.

        // Vamos implementar um merge básico por índice por enquanto:
        for (let i = 0; i < expectedInstallments.length; i++) {
            const expected = expectedInstallments[i];
            if (i < existingInstallments.length) {
                const existing = existingInstallments[i];
        
                // Se já está pago, não mexemos no valor/data/status a menos que a regra mude
                if (existing.status === InstallmentStatus.paid || existing.status === InstallmentStatus.settled) {
                    continue; 
                }

                const hasChanged =
          existing.amount !== expected.amount ||
          existing.dueDate.getTime() !== expected.dueDate.getTime() ||
          JSON.stringify(existing.accounts) !== JSON.stringify(expected.accounts) ||
          existing.category?.id !== expected.category?.id ||
          existing.type !== expected.type ||
          existing.installmentType !== expected.installmentType ||
          existing.installmentNumber !== expected.installmentNumber ||
          existing.installmentCount !== expected.installmentCount;

                if (hasChanged) {
                    await this.financeRepository.updateInstallment(workspaceId, existing.id, expected);
                }
            }
            else {
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

    async updateAccountBalanceOnInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
    // Só afeta saldo se status for 'paid'
    
        // Estorno do 'before' se era 'paid'
        if (before && before.status === InstallmentStatus.paid && before.accounts && before.paidAmount && before.paidDate) {
            for (const [accountId, role] of Object.entries(before.accounts)) {
                const delta = role === "credit" ? -before.paidAmount : before.paidAmount;
                await this.financeRepository.updateAccountBalance(workspaceId, accountId, before.paidDate, delta);
            }
        }

        // Aplicação do 'after' se é 'paid'
        if (after && after.status === InstallmentStatus.paid && after.accounts && after.paidAmount && after.paidDate) {
            for (const [accountId, role] of Object.entries(after.accounts)) {
                const delta = role === "credit" ? after.paidAmount : -after.paidAmount;
                await this.financeRepository.updateAccountBalance(workspaceId, accountId, after.paidDate, delta);
            }
        }
    }

    async syncInitialBalance(_workspaceId: string, _accountId: string, _account: AccountModel | null): Promise<void> {
    // TODO: Adaptar para Installment se necessário, ou manter LedgerEntry para saldo inicial?
    // O blueprint diz que tudo deve ser Installment. Saldo inicial pode ser uma Order do tipo 'income' ou um Installment avulso.
    // Por enquanto vou deixar como está, mas usando o repositório de Installment
    }
}
