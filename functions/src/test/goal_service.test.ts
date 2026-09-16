import { GoalServiceImpl } from "../features/goal/domain/services/goal.service.impl";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";

/**
 * Regressão: `processInstallmentChange` lia `goal.type`, mas o cliente Flutter
 * grava o discriminador da union freezed em `runtimeType` e NÃO serializa
 * `type`. A contribuição era sempre zero e o `currentAmount` das metas nunca
 * mudava. Os documentos abaixo estão no formato real do Firestore.
 */
function goalDoc(over: Partial<any> = {}) {
    return {
        id: "g1",
        name: "Reserva",
        runtimeType: "saveMoney",
        targetAmount: 10000,
        currentAmount: 0,
        accountId: "acc1",
        startDate: new Date("2026-01-01T00:00:00.000"),
        deadline: new Date("2026-12-31T00:00:00.000"),
        isDeleted: false,
        ...over,
    };
}

function installment(over: Partial<InstallmentModel> = {}): InstallmentModel {
    return {
        id: "i1",
        orderId: "o1",
        amount: 500,
        dueDate: new Date("2026-03-10T12:00:00.000"),
        description: "Aporte",
        paidAmount: 500,
        paidDate: new Date("2026-03-10T12:00:00.000"),
        installmentType: InstallmentType.single,
        status: InstallmentStatus.paid,
        type: OrderType.income,
        accounts: { acc1: "credit" },
        accountIds: ["acc1"],
        referenceDate: new Date("2026-03-10T12:00:00.000"),
        referenceAmount: 500,
        ...over,
    } as InstallmentModel;
}

describe("GoalServiceImpl.processInstallmentChange", () => {
    let repository: any;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = {
            getActiveGoalsByAccount: jest.fn(),
            updateGoal: jest.fn(),
        };
        service = new GoalServiceImpl(repository);
    });

    it("soma o crédito ao currentAmount de uma meta saveMoney (runtimeType)", async () => {
        const goal = goalDoc();
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoal).toHaveBeenCalledTimes(1);
        const [, updated] = repository.updateGoal.mock.calls[0];
        expect(updated.currentAmount).toBe(500);
    });

    it("estorna a contribuição quando o pagamento é desfeito", async () => {
        const goal = goalDoc({ currentAmount: 500 });
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange(
            "w1",
            installment(),
            installment({ status: InstallmentStatus.pending, paidAmount: undefined, paidDate: undefined })
        );

        const [, updated] = repository.updateGoal.mock.calls[0];
        expect(updated.currentAmount).toBe(0);
    });

    it("em saveMoney, um débito na conta reduz o progresso", async () => {
        const goal = goalDoc();
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            type: OrderType.expense,
        }));

        const [, updated] = repository.updateGoal.mock.calls[0];
        expect(updated.currentAmount).toBe(-500);
    });

    it("em reduceCreditCard, só os débitos contam", async () => {
        const goal = goalDoc({ runtimeType: "reduceCreditCard", averageSpending: 800 });
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            type: OrderType.expense,
            paidAmount: 300,
        }));

        expect(repository.updateGoal.mock.calls[0][1].currentAmount).toBe(300);

        repository.updateGoal.mockClear();
        const creditGoal = goalDoc({ runtimeType: "reduceCreditCard" });
        repository.getActiveGoalsByAccount.mockResolvedValue([creditGoal]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoal).not.toHaveBeenCalled();
    });

    it("aceita o campo legado `type` como fallback", async () => {
        const goal = goalDoc({ runtimeType: undefined, type: "saveMoney" });
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoal.mock.calls[0][1].currentAmount).toBe(500);
    });

    it("ignora metas cujo tipo não é reconhecido", async () => {
        const goal = goalDoc({ runtimeType: "algoDesconhecido" });
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoal).not.toHaveBeenCalled();
    });

    it("não altera metas quando a parcela é anterior ao início da meta", async () => {
        const goal = goalDoc({ startDate: new Date("2026-06-01T00:00:00.000") });
        repository.getActiveGoalsByAccount.mockResolvedValue([goal]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoal).not.toHaveBeenCalled();
    });
});
