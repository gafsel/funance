import { GoalServiceImpl, monthKeysBetween } from "../features/goal/domain/services/goal.service.impl";
import { isGoalActive, isGoalCompleted } from "../features/goal/domain/models/goal.model";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";

/**
 * Os documentos abaixo estão no formato REAL do Firestore: o discriminador da
 * union freezed vive em `runtimeType` e o campo `type` não é serializado pelo
 * cliente. Ler `goal.type` direto devolvia undefined — era por isso que o
 * progresso das metas nunca andava.
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

function makeRepository() {
    return {
        getGoals: jest.fn().mockResolvedValue([]),
        getActiveGoalsByAccount: jest.fn().mockResolvedValue([]),
        getActiveGoalsByCategory: jest.fn().mockResolvedValue([]),
        getGoal: jest.fn(),
        updateGoal: jest.fn(),
        updateGoalProgress: jest.fn().mockResolvedValue(undefined),
        getCategoryActualByMonths: jest.fn().mockResolvedValue(0),
        getBalancesForGoal: jest.fn().mockResolvedValue({ startBalance: null, currentBalance: null }),
        getPaidInstallmentsByAccountSince: jest.fn().mockResolvedValue([]),
    };
}

describe("GoalServiceImpl.processInstallmentChange — saveMoney e reduceCreditCard (delta)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any);
    });

    it("soma o crédito ao currentAmount de uma meta saveMoney (runtimeType)", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc()]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress).toHaveBeenCalledTimes(1);
        const [, goalId, amount] = repository.updateGoalProgress.mock.calls[0];
        expect(goalId).toBe("g1");
        expect(amount).toBe(500);
    });

    it("estorna a contribuição quando o pagamento é desfeito", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc({ currentAmount: 500 })]);

        await service.processInstallmentChange(
            "w1",
            installment(),
            installment({ status: InstallmentStatus.pending, paidAmount: undefined, paidDate: undefined })
        );

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(0);
    });

    it("em saveMoney, um débito na conta reduz o progresso", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc()]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            type: OrderType.expense,
        }));

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(-500);
    });

    it("em reduceCreditCard, só os débitos contam", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ runtimeType: "reduceCreditCard", averageSpending: 800 }),
        ]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            type: OrderType.expense,
            paidAmount: 300,
        }));

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(300);

        repository.updateGoalProgress.mockClear();
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc({ runtimeType: "reduceCreditCard" })]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });

    it("aceita o campo legado `type` como fallback", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ runtimeType: undefined, type: "saveMoney" }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(500);
    });

    it("ignora metas cujo tipo não é reconhecido", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc({ runtimeType: "algoDesconhecido" })]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });

    it("não altera metas quando a parcela é anterior ao início da meta", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ startDate: new Date("2026-06-01T00:00:00.000") }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });

    it("carimba completedAt na primeira vez que a meta alcança o alvo", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ targetAmount: 500 }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        const [, , amount, completedAt] = repository.updateGoalProgress.mock.calls[0];
        expect(amount).toBe(500);
        expect(completedAt).toBeInstanceOf(Date);
    });

    it("não reescreve completedAt de uma meta que já foi concluída", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ targetAmount: 500, completedAt: new Date("2026-02-01T00:00:00.000") }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress.mock.calls[0][3]).toBeUndefined();
    });
});

describe("GoalServiceImpl.processInstallmentChange — reduceExpense (categoria)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any);
    });

    const expenseGoal = () => goalDoc({
        id: "g-exp",
        runtimeType: "reduceExpense",
        accountId: undefined,
        category: { id: "cat1", name: "Mercado" },
        targetAmount: 1200,
        currentAmount: 0,
        startDate: new Date("2026-01-15T00:00:00.000"),
        deadline: new Date("2026-03-20T00:00:00.000"),
    });

    it("usa o realizado da categoria nos period_summaries do período da meta", async () => {
        repository.getActiveGoalsByCategory.mockResolvedValue([expenseGoal()]);
        repository.getCategoryActualByMonths.mockResolvedValue(430.5);

        await service.processInstallmentChange("w1", null, installment({
            accounts: undefined,
            accountIds: [],
            category: { id: "cat1", name: "Mercado" } as any,
            type: OrderType.expense,
        }));

        expect(repository.getActiveGoalsByCategory).toHaveBeenCalledWith("w1", "cat1");
        const [, categoryId, monthKeys] = repository.getCategoryActualByMonths.mock.calls[0];
        expect(categoryId).toBe("cat1");
        expect(monthKeys).toEqual(["2026-01", "2026-02", "2026-03"]);
        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(430.5);
    });

    it("recalcula também pela categoria ANTERIOR quando a parcela troca de categoria", async () => {
        repository.getActiveGoalsByCategory.mockResolvedValue([]);

        await service.processInstallmentChange(
            "w1",
            installment({ category: { id: "catA" } as any, accounts: undefined, accountIds: [] }),
            installment({ category: { id: "catB" } as any, accounts: undefined, accountIds: [] })
        );

        const consultadas = repository.getActiveGoalsByCategory.mock.calls.map((c) => c[1]);
        expect(consultadas.sort()).toEqual(["catA", "catB"]);
    });

    it("não grava quando o realizado não mudou", async () => {
        repository.getActiveGoalsByCategory.mockResolvedValue([expenseGoal()]);
        repository.getCategoryActualByMonths.mockResolvedValue(0);

        await service.processInstallmentChange("w1", null, installment({
            category: { id: "cat1" } as any,
            accounts: undefined,
            accountIds: [],
        }));

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });

    it("mantém o progresso de uma meta reduceExpense sem categoria", async () => {
        repository.getActiveGoalsByCategory.mockResolvedValue([
            { ...expenseGoal(), category: undefined },
        ]);

        await service.processInstallmentChange("w1", null, installment({
            category: { id: "cat1" } as any,
            accounts: undefined,
            accountIds: [],
        }));

        expect(repository.getCategoryActualByMonths).not.toHaveBeenCalled();
        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });
});

describe("GoalServiceImpl.processInstallmentChange — payDebt (saldo da conta)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any);
    });

    const debtGoal = () => goalDoc({
        id: "g-debt",
        runtimeType: "payDebt",
        accountId: "accDebt",
        targetAmount: 1000,
        currentAmount: 0,
    });

    it("mede quanto a dívida encolheu desde o startDate", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([debtGoal()]);
        // Saldo devedor é negativo: -1000 no início, -800 hoje => 200 amortizados.
        repository.getBalancesForGoal.mockResolvedValue({ startBalance: -1000, currentBalance: -800 });

        await service.processInstallmentChange("w1", null, installment({
            accounts: { accDebt: "credit" },
            accountIds: ["accDebt"],
        }));

        expect(repository.getBalancesForGoal).toHaveBeenCalledWith("w1", "accDebt", debtGoal().startDate);
        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(200);
    });

    it("dívida que cresceu não vira progresso negativo", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([{ ...debtGoal(), currentAmount: 100 }]);
        repository.getBalancesForGoal.mockResolvedValue({ startBalance: -1000, currentBalance: -1300 });

        await service.processInstallmentChange("w1", null, installment({
            accounts: { accDebt: "debt" },
            accountIds: ["accDebt"],
        }));

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(0);
    });

    it("conta sem saldo gravado mantém o progresso", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([debtGoal()]);
        repository.getBalancesForGoal.mockResolvedValue({ startBalance: -500, currentBalance: null });

        await service.processInstallmentChange("w1", null, installment({
            accounts: { accDebt: "credit" },
            accountIds: ["accDebt"],
        }));

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });

    it("sem saldo no startDate, a dívida do início conta como zero", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([debtGoal()]);
        repository.getBalancesForGoal.mockResolvedValue({ startBalance: null, currentBalance: 150 });

        await service.processInstallmentChange("w1", null, installment({
            accounts: { accDebt: "credit" },
            accountIds: ["accDebt"],
        }));

        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(150);
    });
});

describe("GoalServiceImpl.computeCurrentAmount — recálculo total", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any);
    });

    it("saveMoney soma créditos e subtrai débitos das parcelas pagas da conta", async () => {
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 500, paidAmount: 500, accounts: { acc1: "credit" } },
            { amount: 200, paidAmount: 120, accounts: { acc1: "debt" } },
            { amount: 900, paidAmount: 900, accounts: { outra: "credit" } },
        ]);

        const total = await service.computeCurrentAmount("w1", goalDoc() as any);

        expect(total).toBe(380);
    });

    it("reduceCreditCard soma só os débitos", async () => {
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 500, paidAmount: 500, accounts: { acc1: "credit" } },
            { amount: 200, paidAmount: 120, accounts: { acc1: "debt" } },
        ]);

        const total = await service.computeCurrentAmount(
            "w1",
            goalDoc({ runtimeType: "reduceCreditCard" }) as any
        );

        expect(total).toBe(120);
    });

    it("recomputeGoal devolve null quando o valor não mudou", async () => {
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([]);

        const result = await service.recomputeGoal("w1", goalDoc({ currentAmount: 0 }) as any);

        expect(result).toBeNull();
        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
    });
});

describe("monthKeysBetween", () => {
    it("cobre do mês do início ao mês do prazo, inclusive", () => {
        expect(monthKeysBetween(
            new Date("2026-11-20T00:00:00.000"),
            new Date("2027-02-03T00:00:00.000")
        )).toEqual(["2026-11", "2026-12", "2027-01", "2027-02"]);
    });

    it("um único mês quando início e prazo caem no mesmo mês", () => {
        expect(monthKeysBetween(
            new Date("2026-05-02T00:00:00.000"),
            new Date("2026-05-28T00:00:00.000")
        )).toEqual(["2026-05"]);
    });

    it("trunca períodos absurdos nos meses mais recentes", () => {
        const keys = monthKeysBetween(
            new Date("1990-01-01T00:00:00.000"),
            new Date("2030-01-01T00:00:00.000")
        );
        expect(keys).toHaveLength(120);
        expect(keys[keys.length - 1]).toBe("2030-01");
    });

    it("prazo anterior ao início não gera mês nenhum", () => {
        expect(monthKeysBetween(
            new Date("2026-05-01T00:00:00.000"),
            new Date("2026-01-01T00:00:00.000")
        )).toEqual([]);
    });
});

describe("isGoalActive / isGoalCompleted", () => {
    const hoje = new Date("2026-06-15T12:00:00.000");

    it("meta no prazo e com alvo a alcançar é ativa", () => {
        expect(isGoalActive(goalDoc({ currentAmount: 10 }), hoje)).toBe(true);
    });

    it("meta deletada não é ativa", () => {
        expect(isGoalActive(goalDoc({ isDeleted: true }), hoje)).toBe(false);
    });

    it("meta que alcançou o alvo não é ativa", () => {
        expect(isGoalActive(goalDoc({ currentAmount: 10000 }), hoje)).toBe(false);
    });

    it("meta com prazo vencido não é ativa", () => {
        expect(isGoalActive(goalDoc({ deadline: new Date("2026-01-31T00:00:00.000") }), hoje)).toBe(false);
    });

    it("meta que vence hoje ainda é ativa", () => {
        expect(isGoalActive(goalDoc({ deadline: new Date("2026-06-15T00:00:00.000") }), hoje)).toBe(true);
    });

    it("meta sem prazo é ativa enquanto não alcança o alvo", () => {
        expect(isGoalActive(goalDoc({ deadline: undefined }), hoje)).toBe(true);
    });

    it("conclusão é completedAt ou alvo alcançado", () => {
        expect(isGoalCompleted(goalDoc())).toBe(false);
        expect(isGoalCompleted(goalDoc({ currentAmount: 10000 }))).toBe(true);
        expect(isGoalCompleted(goalDoc({ completedAt: new Date() }))).toBe(true);
    });
});
