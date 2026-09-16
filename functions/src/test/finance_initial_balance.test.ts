// ofx-js é ESM puro e não é transformado pelo ts-jest; mockamos pois não é usado nestes testes
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import { FinanceService } from "../features/finance/domain/services/finance.service";
import {
    AccountType,
    InstallmentStatus,
    OrderStatus,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import { INITIAL_BALANCE_CATEGORY_ID } from "../features/workspace/domain/models/category.model";

function createMockRepository() {
    return {
        createOrder: jest.fn(),
        getOrderById: jest.fn(),
        updateOrder: jest.fn(),
        deleteOrder: jest.fn(),
        getInstallmentsByOrderId: jest.fn().mockResolvedValue([]),
        updateInstallment: jest.fn(),
    } as any;
}

const checkingAccount = {
    id: "acc1",
    name: "Conta Corrente",
    icon: "wallet",
    color: "#fff",
    runtimeType: AccountType.checking,
    isDeleted: false,
    initialBalance: 1000,
    initialBalanceDate: "2026-03-10T00:00:00.000",
} as any;

describe("FinanceService.syncInitialBalance", () => {
    let repository: any;
    let service: FinanceService;

    beforeEach(() => {
        repository = createMockRepository();
        service = new FinanceService(repository);
    });

    it("cria a order sintética quando ela ainda não existe", async () => {
        repository.getOrderById.mockResolvedValue(null);

        await service.syncInitialBalance("w1", "acc1", checkingAccount);

        expect(repository.createOrder).toHaveBeenCalledTimes(1);
        const [workspaceId, order, orderId] = repository.createOrder.mock.calls[0];
        expect(workspaceId).toBe("w1");
        expect(orderId).toBe("initial-balance-acc1");
        expect(order.amount).toBe(1000);
        expect(order.type).toBe(OrderType.income);
        expect(order.status).toBe(OrderStatus.settled);
        expect(order.accounts).toEqual({ acc1: "credit" });
        expect(order.accountIds).toEqual(["acc1"]);
        expect(order.category.id).toBe(INITIAL_BALANCE_CATEGORY_ID);
        expect(order.category.isSystem).toBe(true);
        expect(order.startMonth).toBe("2026-03");
        expect(order.dueDay).toBe(10);
    });

    it("atualiza a order e a parcela quando o initialBalance muda", async () => {
        repository.getOrderById.mockResolvedValue({
            id: "initial-balance-acc1",
            amount: 1000,
            dueDay: 10,
            startMonth: "2026-03",
            type: OrderType.income,
            accounts: { acc1: "credit" },
        });
        repository.getInstallmentsByOrderId.mockResolvedValue([{ id: "inst1" }]);

        await service.syncInitialBalance("w1", "acc1", { ...checkingAccount, initialBalance: 2500 });

        expect(repository.createOrder).not.toHaveBeenCalled();
        expect(repository.updateOrder).toHaveBeenCalledWith(
            "w1",
            "initial-balance-acc1",
            expect.objectContaining({ amount: 2500, type: OrderType.income, status: OrderStatus.settled })
        );

        // A parcela do saldo inicial nasce liquidada: planejado zero, valor em paidAmount.
        expect(repository.updateInstallment).toHaveBeenCalledTimes(1);
        const [, installmentId, update] = repository.updateInstallment.mock.calls[0];
        expect(installmentId).toBe("inst1");
        expect(update.amount).toBe(0);
        expect(update.paidAmount).toBe(2500);
        expect(update.status).toBe(InstallmentStatus.settled);
        expect(update.paidDate).toEqual(update.dueDate);
    });

    it("atualiza a data da order e da parcela quando o initialBalanceDate muda", async () => {
        repository.getOrderById.mockResolvedValue({
            id: "initial-balance-acc1",
            amount: 1000,
            dueDay: 10,
            startMonth: "2026-03",
            type: OrderType.income,
            accounts: { acc1: "credit" },
        });
        repository.getInstallmentsByOrderId.mockResolvedValue([{ id: "inst1" }]);

        await service.syncInitialBalance("w1", "acc1", {
            ...checkingAccount,
            initialBalanceDate: "2026-05-22T00:00:00.000",
        });

        expect(repository.updateOrder).toHaveBeenCalledWith(
            "w1",
            "initial-balance-acc1",
            expect.objectContaining({ startMonth: "2026-05", dueDay: 22 })
        );
        const [, , update] = repository.updateInstallment.mock.calls[0];
        expect(update.dueDate.getFullYear()).toBe(2026);
        expect(update.dueDate.getMonth()).toBe(4);
        expect(update.dueDate.getDate()).toBe(22);
    });

    it("não escreve nada quando nada relevante mudou", async () => {
        repository.getOrderById.mockResolvedValue({
            id: "initial-balance-acc1",
            amount: 1000,
            dueDay: 10,
            startMonth: "2026-03",
            type: OrderType.income,
            accounts: { acc1: "credit" },
        });

        await service.syncInitialBalance("w1", "acc1", checkingAccount);

        expect(repository.updateOrder).not.toHaveBeenCalled();
        expect(repository.updateInstallment).not.toHaveBeenCalled();
        expect(repository.createOrder).not.toHaveBeenCalled();
    });

    it("remove a order quando o saldo inicial passa a ser zero", async () => {
        repository.getOrderById.mockResolvedValue({ id: "initial-balance-acc1", amount: 1000 });

        await service.syncInitialBalance("w1", "acc1", { ...checkingAccount, initialBalance: 0 });

        expect(repository.deleteOrder).toHaveBeenCalledWith("w1", "initial-balance-acc1");
        expect(repository.updateOrder).not.toHaveBeenCalled();
    });

    it("não cria nada quando o saldo inicial é zero e a order não existe", async () => {
        repository.getOrderById.mockResolvedValue(null);

        await service.syncInitialBalance("w1", "acc1", { ...checkingAccount, initialBalance: 0 });

        expect(repository.createOrder).not.toHaveBeenCalled();
        expect(repository.deleteOrder).not.toHaveBeenCalled();
    });

    it("trata cartão de crédito como débito, independentemente do sinal", async () => {
        repository.getOrderById.mockResolvedValue(null);

        await service.syncInitialBalance("w1", "acc1", {
            ...checkingAccount,
            runtimeType: AccountType.creditCard,
            initialBalance: 800,
        });

        const [, order] = repository.createOrder.mock.calls[0];
        expect(order.type).toBe(OrderType.expense);
        expect(order.accounts).toEqual({ acc1: "debt" });
    });
});
