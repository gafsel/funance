import { GoalServiceImpl, monthKeysBetween } from "../features/goal/domain/services/goal.service.impl";
import {
    GoalOutcome,
    evaluateGoalOutcome,
    isGoalActive,
    isGoalCompleted,
    isGoalFailed,
} from "../features/goal/domain/models/goal.model";
import {
    AccountType,
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

/**
 * Relógio fixo para os testes: dentro do período padrão de `goalDoc`
 * (2026-01-01 a 2026-12-31). O desfecho de uma meta depende de o prazo ter
 * vencido, então nenhum teste pode depender do relógio real.
 */
const agora = () => new Date("2026-06-15T12:00:00.000");

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
        updateGoalOutcome: jest.fn().mockResolvedValue(undefined),
        getCategoryActualByMonths: jest.fn().mockResolvedValue(0),
        getBalancesForGoal: jest.fn().mockResolvedValue({ startBalance: null, currentBalance: null }),
        getCurrentBalance: jest.fn().mockResolvedValue(null),
        // Conta corrente por padrão: `saveMoney` segue no caminho dos aportes.
        getAccountType: jest.fn().mockResolvedValue(AccountType.checking),
        getPaidInstallmentsByAccountSince: jest.fn().mockResolvedValue([]),
    };
}

describe("GoalServiceImpl.processInstallmentChange — saveMoney e reduceCreditCard (delta)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any, agora);
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

    it("carimba outcome=success na primeira vez que a meta de acúmulo alcança o alvo", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ targetAmount: 500 }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        const [, , amount, stamp] = repository.updateGoalProgress.mock.calls[0];
        expect(amount).toBe(500);
        expect(stamp.outcome).toBe(GoalOutcome.success);
        expect(stamp.at).toBeInstanceOf(Date);
    });

    it("não reescreve o desfecho de uma meta que já desfechou", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({
                targetAmount: 500,
                outcome: "success",
                completedAt: new Date("2026-02-01T00:00:00.000"),
            }),
        ]);

        await service.processInstallmentChange("w1", null, installment());

        expect(repository.updateGoalProgress.mock.calls[0][3]).toBeNull();
    });
});

describe("GoalServiceImpl.processInstallmentChange — reduceExpense (categoria)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    // Relógio fixo DENTRO do período da meta: o desfecho depende de o prazo ter
    // vencido ou não, então um teste preso ao relógio real mudaria de resposta
    // com o passar dos meses.
    const dentroDoPrazo = () => new Date("2026-02-10T12:00:00.000");

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any, dentroDoPrazo);
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
        service = new GoalServiceImpl(repository as any, agora);
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
        service = new GoalServiceImpl(repository as any, agora);
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

/**
 * Decisão do produto: `saveMoney` numa conta de INVESTIMENTO (cofrinho) mede o
 * SALDO da conta, não os aportes desde o início. Caso real: meta "Disney 2030"
 * na conta "Cofrinho Disney", saldo 263,41 e `startDate` = hoje — a meta nascia
 * em ZERO porque nenhum aporte tinha sido feito DEPOIS da criação dela.
 */
describe("GoalServiceImpl — saveMoney de cofrinho (conta de investimento)", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    /** Meta criada hoje sobre um cofrinho que já tem dinheiro. */
    const disney = (over: Partial<any> = {}) => goalDoc({
        id: "g-disney",
        name: "Disney 2030",
        targetAmount: 30000,
        currentAmount: 0,
        accountId: "acc-cofrinho",
        startDate: new Date("2026-06-15T00:00:00.000"),
        ...over,
    });

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any, agora);
        repository.getAccountType.mockResolvedValue(AccountType.investment);
        repository.getCurrentBalance.mockResolvedValue(263.41);
    });

    it("computeCurrentAmount devolve o SALDO da conta, não os aportes", async () => {
        // Nenhuma parcela paga desde o início: pela regra antiga daria zero.
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([]);

        const total = await service.computeCurrentAmount("w1", disney() as any);

        expect(total).toBe(263.41);
        expect(repository.getCurrentBalance).toHaveBeenCalledWith("w1", "acc-cofrinho");
        // O caminho dos aportes nem é tocado.
        expect(repository.getPaidInstallmentsByAccountSince).not.toHaveBeenCalled();
    });

    it("cofrinho no negativo não vira progresso negativo (piso zero)", async () => {
        repository.getCurrentBalance.mockResolvedValue(-50);

        expect(await service.computeCurrentAmount("w1", disney() as any)).toBe(0);
    });

    it("cofrinho sem nenhum saldo gravado mantém o progresso", async () => {
        repository.getCurrentBalance.mockResolvedValue(null);

        expect(await service.computeCurrentAmount("w1", disney() as any)).toBeNull();
    });

    it("meta sem conta não tenta ler saldo nenhum", async () => {
        expect(await service.computeCurrentAmount("w1", disney({ accountId: undefined }) as any)).toBeNull();
        expect(repository.getCurrentBalance).not.toHaveBeenCalled();
    });

    it("o gatilho de parcela faz RECÁLCULO TOTAL, não delta", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([disney()]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { "acc-cofrinho": "credit" },
            accountIds: ["acc-cofrinho"],
        }));

        // 263,41 é o saldo da conta — não 0 + 500 (o aporte deste evento).
        expect(repository.updateGoalProgress).toHaveBeenCalledTimes(1);
        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(263.41);
    });

    it("o tipo da conta é lido UMA vez por conta do evento", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            disney(),
            disney({ id: "g-disney-2", name: "Disney 2031" }),
        ]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { "acc-cofrinho": "credit" },
            accountIds: ["acc-cofrinho"],
        }));

        expect(repository.getAccountType).toHaveBeenCalledTimes(1);
        expect(repository.updateGoalProgress).toHaveBeenCalledTimes(2);
    });

    it("conta CORRENTE mantém a regra dos aportes desde o início", async () => {
        repository.getAccountType.mockResolvedValue(AccountType.checking);
        repository.getActiveGoalsByAccount.mockResolvedValue([goalDoc()]);

        await service.processInstallmentChange("w1", null, installment());

        // Delta do evento (+500), não o saldo da conta.
        expect(repository.updateGoalProgress.mock.calls[0][2]).toBe(500);
        expect(repository.getCurrentBalance).not.toHaveBeenCalled();
    });

    it("conta sem `runtimeType` conhecido também mantém a regra dos aportes", async () => {
        repository.getAccountType.mockResolvedValue(null);
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 500, paidAmount: 500, accounts: { "acc-cofrinho": "credit" } },
        ]);

        expect(await service.computeCurrentAmount("w1", disney() as any)).toBe(500);
    });

    it("reduceCreditCard não muda de regra numa conta de investimento", async () => {
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 200, paidAmount: 120, accounts: { "acc-cofrinho": "debt" } },
        ]);

        const total = await service.computeCurrentAmount(
            "w1",
            disney({ runtimeType: "reduceCreditCard" }) as any
        );

        expect(total).toBe(120);
        expect(repository.getCurrentBalance).not.toHaveBeenCalled();
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

describe("evaluateGoalOutcome — os quatro tipos", () => {
    const hoje = new Date("2026-06-15T12:00:00.000");
    const noPrazo = new Date("2026-12-31T00:00:00.000");
    const vencido = new Date("2026-05-31T00:00:00.000");

    const meta = (runtimeType: string, over: Partial<any> = {}) => goalDoc({
        runtimeType, targetAmount: 1000, currentAmount: 0, deadline: noPrazo, ...over,
    });

    // ── Acúmulo: alcançar o alvo é vitória ────────────────────────────────

    it.each(["saveMoney", "payDebt"])("%s no prazo e abaixo do alvo segue em andamento", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 999 }), hoje)).toBeNull();
    });

    it.each(["saveMoney", "payDebt"])("%s que alcança o alvo é sucesso na hora", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 1000 }), hoje))
            .toBe(GoalOutcome.success);
    });

    it.each(["saveMoney", "payDebt"])("%s que vence sem alcançar falha", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 999, deadline: vencido }), hoje))
            .toBe(GoalOutcome.failed);
    });

    // ── Redução: passar do teto é FRACASSO, nunca conclusão ───────────────

    it.each(["reduceExpense", "reduceCreditCard"])("%s dentro do teto e no prazo segue em andamento", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 1000 }), hoje)).toBeNull();
    });

    it.each(["reduceExpense", "reduceCreditCard"])("%s que estoura o teto FALHA (não conclui)", (tipo) => {
        const outcome = evaluateGoalOutcome(meta(tipo, { currentAmount: 1000.5 }), hoje);
        expect(outcome).toBe(GoalOutcome.failed);
        expect(outcome).not.toBe(GoalOutcome.success);
    });

    it.each(["reduceExpense", "reduceCreditCard"])("%s que vence dentro do teto é sucesso", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 800, deadline: vencido }), hoje))
            .toBe(GoalOutcome.success);
    });

    it.each(["reduceExpense", "reduceCreditCard"])("%s que vence com o teto estourado falha", (tipo) => {
        expect(evaluateGoalOutcome(meta(tipo, { currentAmount: 1200, deadline: vencido }), hoje))
            .toBe(GoalOutcome.failed);
    });

    it("meta sem prazo e sem alvo alcançado nunca desfecha sozinha", () => {
        expect(evaluateGoalOutcome(meta("saveMoney", { deadline: undefined }), hoje)).toBeNull();
    });

    it("meta que vence HOJE ainda não desfecha por prazo", () => {
        expect(evaluateGoalOutcome(
            meta("reduceExpense", { currentAmount: 10, deadline: new Date("2026-06-15T00:00:00.000") }),
            hoje
        )).toBeNull();
    });
});

describe("GoalServiceImpl.writeProgress — desfecho por tipo", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any, agora);
    });

    it("meta reduceCreditCard que estoura o teto é gravada como FALHA", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ runtimeType: "reduceCreditCard", targetAmount: 400, currentAmount: 0 }),
        ]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            paidAmount: 500,
            amount: 500,
        }));

        const [, , amount, stamp] = repository.updateGoalProgress.mock.calls[0];
        expect(amount).toBe(500);
        expect(stamp.outcome).toBe(GoalOutcome.failed);
    });

    it("meta reduceCreditCard dentro do teto não desfecha", async () => {
        repository.getActiveGoalsByAccount.mockResolvedValue([
            goalDoc({ runtimeType: "reduceCreditCard", targetAmount: 400, currentAmount: 0 }),
        ]);

        await service.processInstallmentChange("w1", null, installment({
            accounts: { acc1: "debt" },
            paidAmount: 100,
            amount: 100,
        }));

        expect(repository.updateGoalProgress.mock.calls[0][3]).toBeNull();
    });
});

describe("GoalServiceImpl.closeExpiredGoals", () => {
    let repository: ReturnType<typeof makeRepository>;
    let service: GoalServiceImpl;
    const hoje = new Date("2026-06-15T12:00:00.000");
    const vencido = new Date("2026-05-31T00:00:00.000");

    beforeEach(() => {
        repository = makeRepository();
        service = new GoalServiceImpl(repository as any, agora);
    });

    const meta = (over: Partial<any> = {}) => goalDoc({
        targetAmount: 1000, currentAmount: 0, deadline: vencido, ...over,
    });

    it("fecha em sucesso a meta de redução que venceu dentro do teto", async () => {
        repository.getGoals.mockResolvedValue([
            meta({ id: "g-red", runtimeType: "reduceExpense", currentAmount: 800 }),
        ]);

        const closed = await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome).toHaveBeenCalledWith(
            "w1", "g-red", { outcome: GoalOutcome.success, at: hoje }
        );
        expect(closed).toHaveLength(1);
        expect(isGoalCompleted(closed[0])).toBe(true);
        expect(closed[0].completedAt).toEqual(hoje);
    });

    it("fecha em falha a meta de redução que venceu com o teto estourado", async () => {
        repository.getGoals.mockResolvedValue([
            meta({ id: "g-red2", runtimeType: "reduceExpense", currentAmount: 1500 }),
        ]);

        const closed = await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome.mock.calls[0][2].outcome).toBe(GoalOutcome.failed);
        expect(isGoalFailed(closed[0])).toBe(true);
        expect(closed[0].failedAt).toEqual(hoje);
        expect(closed[0].completedAt).toBeUndefined();
    });

    it("fecha em falha a meta de acúmulo que venceu sem alcançar o alvo", async () => {
        repository.getGoals.mockResolvedValue([
            meta({ id: "g-save", runtimeType: "saveMoney", currentAmount: 999 }),
        ]);

        const closed = await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome.mock.calls[0][2].outcome).toBe(GoalOutcome.failed);
        expect(isGoalFailed(closed[0])).toBe(true);
    });

    it("fecha em sucesso a meta de acúmulo que venceu com o alvo alcançado", async () => {
        repository.getGoals.mockResolvedValue([
            meta({ id: "g-save2", runtimeType: "payDebt", currentAmount: 1000 }),
        ]);

        await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome.mock.calls[0][2].outcome).toBe(GoalOutcome.success);
    });

    it("não toca em meta no prazo, deletada, ou que já desfechou", async () => {
        repository.getGoals.mockResolvedValue([
            meta({ id: "g-prazo", deadline: new Date("2026-12-31T00:00:00.000") }),
            meta({ id: "g-del", isDeleted: true }),
            meta({ id: "g-pronta", outcome: "failed" }),
        ]);

        const closed = await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome).not.toHaveBeenCalled();
        expect(closed).toHaveLength(0);
    });

    it("é idempotente: a segunda passada não reescreve nada", async () => {
        const goal = meta({ id: "g-idem", runtimeType: "reduceExpense", currentAmount: 10 });
        repository.getGoals.mockResolvedValue([goal]);

        await service.closeExpiredGoals("w1", hoje);
        repository.getGoals.mockResolvedValue([{ ...goal, outcome: "success" }]);
        const second = await service.closeExpiredGoals("w1", hoje);

        expect(repository.updateGoalOutcome).toHaveBeenCalledTimes(1);
        expect(second).toHaveLength(0);
    });
});

describe("isGoalActive / isGoalCompleted — o desfecho manda", () => {
    const hoje = new Date("2026-06-15T12:00:00.000");

    it("meta no prazo e sem desfecho é ativa", () => {
        expect(isGoalActive(goalDoc({ currentAmount: 10 }), hoje)).toBe(true);
    });

    it("meta deletada não é ativa", () => {
        expect(isGoalActive(goalDoc({ isDeleted: true }), hoje)).toBe(false);
    });

    it("meta de acúmulo com desfecho de sucesso não é mais ativa", () => {
        expect(isGoalActive(goalDoc({ currentAmount: 10000, outcome: "success" }), hoje)).toBe(false);
    });

    it("meta de REDUÇÃO no prazo continua ativa mesmo com valor acima do alvo, enquanto o desfecho não é gravado", () => {
        // O valor sozinho não decide nada: quem tira do pool é o `outcome`, que
        // o serviço grava na mesma escrita que passou do teto.
        const estourada = goalDoc({ runtimeType: "reduceExpense", currentAmount: 99999 });
        expect(isGoalActive(estourada, hoje)).toBe(true);
        expect(isGoalActive({ ...estourada, outcome: "failed" }, hoje)).toBe(false);
    });

    it("meta com prazo vencido não é ativa", () => {
        expect(isGoalActive(goalDoc({ deadline: new Date("2026-01-31T00:00:00.000") }), hoje)).toBe(false);
    });

    it("meta que vence hoje ainda é ativa", () => {
        expect(isGoalActive(goalDoc({ deadline: new Date("2026-06-15T00:00:00.000") }), hoje)).toBe(true);
    });

    it("meta sem prazo é ativa enquanto não desfecha", () => {
        expect(isGoalActive(goalDoc({ deadline: undefined }), hoje)).toBe(true);
    });

    it("concluída é SÓ outcome=success — alvo alcançado sozinho não basta", () => {
        expect(isGoalCompleted(goalDoc())).toBe(false);
        expect(isGoalCompleted(goalDoc({ currentAmount: 10000 }))).toBe(false);
        expect(isGoalCompleted(goalDoc({ completedAt: new Date() }))).toBe(false);
        expect(isGoalCompleted(goalDoc({ outcome: "success" }))).toBe(true);
    });

    it("meta de redução com o teto estourado NUNCA conta como concluída", () => {
        const estourada = goalDoc({
            runtimeType: "reduceExpense",
            targetAmount: 1000,
            currentAmount: 5000,
            outcome: "failed",
            failedAt: new Date("2026-06-10T00:00:00.000"),
        });
        expect(isGoalCompleted(estourada)).toBe(false);
        expect(isGoalFailed(estourada)).toBe(true);
    });
});
