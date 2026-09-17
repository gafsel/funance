/**
 * F1.10 — a aritmética em centavos DENTRO das regras de negócio.
 *
 * `money.test.ts` prova o módulo; este arquivo prova que o dinheiro que passa
 * pelos cálculos do servidor (total da order, XP, impactos de planejamento,
 * progresso de meta) deixou de acumular erro de ponto flutuante — e que, fora
 * disso, nada mudou de semântica.
 */

// `ofx-js` é ESM puro e não é transformado pelo ts-jest; chega aqui pela cadeia
// finance.service -> container -> ai.service e não é usado nestes testes.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    buildOrderUpdateFromCascade,
    FinanceService,
    InstallmentCascadeChanges,
    splitAmountIntoInstallments,
} from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";
import {
    CategoryPlanningModel,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import { evaluateGoalOutcome } from "../features/goal/domain/models/goal.model";
import { sumMoney, toCents } from "../core/utils/money";

const CATEGORY = { id: "cat-1", name: "Mercado", type: "expense" } as any;

function installment(over: Partial<InstallmentModel> = {}): InstallmentModel {
    return {
        id: "i1",
        orderId: "o1",
        amount: 0,
        dueDate: new Date("2026-03-10T12:00:00.000Z"),
        description: "x",
        installmentType: InstallmentType.single,
        status: InstallmentStatus.pending,
        type: OrderType.expense,
        accountIds: [],
        referenceDate: new Date("2026-03-10T12:00:00.000Z"),
        referenceAmount: 0,
        ...over,
    } as InstallmentModel;
}

const ALL_CHANGED: InstallmentCascadeChanges = {
    amount: true,
    dueDate: false,
    description: false,
    category: false,
    accounts: false,
    type: false,
    removed: false,
    hasReplicableChange: true,
};

describe("F1.10 — total da order", () => {
    it("dez parcelas de R$ 50,24 somam exatamente R$ 502,40", () => {
        const parts = splitAmountIntoInstallments(502.4, 10);
        expect(parts).toEqual(new Array(10).fill(50.24));

        // O `reduce(+)` que existia aqui devolvia 502.4000000000001.
        expect(parts.reduce((a, b) => a + b, 0)).not.toBe(502.4);

        const installments = parts.map((amount, i) => installment({ id: `i${i}`, amount }));
        const update = buildOrderUpdateFromCascade(installments[0], installments, ALL_CHANGED);

        expect(update.amount).toBe(502.4);
    });

    it("0,10 + 0,20 no total da order dá 0,30", () => {
        const installments = [installment({ id: "a", amount: 0.1 }), installment({ id: "b", amount: 0.2 })];
        const update = buildOrderUpdateFromCascade(installments[0], installments, ALL_CHANGED);

        expect(update.amount).toBe(0.3);
    });

    it("parcela paga entra pelo referenceAmount, e a soma continua exata", () => {
        const installments = [
            installment({ id: "a", amount: 0, status: InstallmentStatus.paid, referenceAmount: 33.33, paidAmount: 33.33 }),
            installment({ id: "b", amount: 33.33 }),
            installment({ id: "c", amount: 33.34 }),
        ];
        const update = buildOrderUpdateFromCascade(installments[0], installments, ALL_CHANGED);

        expect(update.amount).toBe(100);
    });

    it("mil parcelas de R$ 0,07 somam exatamente R$ 70,00", () => {
        const installments = Array.from({ length: 1000 }, (_, i) => installment({ id: `i${i}`, amount: 0.07 }));
        const update = buildOrderUpdateFromCascade(installments[0], installments, ALL_CHANGED);

        expect(update.amount).toBe(70);
        expect(sumMoney(installments.map((i) => i.amount))).toBe(70);
    });
});

describe("F1.10 — XP por valor", () => {
    const service = new FinanceService({} as any);

    it("pagar exatamente o planejado rende o XP cheio", () => {
        expect(service.calculateXp(installment({ amount: 0.3, paidAmount: 0.3 }))).toBe(15);
    });

    it("pagar 0,10 + 0,20 contra um planejado de 0,30 NÃO é punido", () => {
        // O `double` diria que 0.30000000000000004 !== 0.3.
        expect(service.calculateXp(installment({ amount: 0.3, paidAmount: 0.1 + 0.2 }))).toBe(15);
    });

    it("a faixa morta de UM centavo é a mesma de antes — e agora é consistente", () => {
        // Antes: `Math.abs(0.02 - 0.01) > 0.01` era VERDADE (0.010000000000000002)
        // e `Math.abs(3.01 - 3.00) > 0.01` era FALSO (0.009999999999999787).
        // A mesma diferença de um centavo tinha dois vereditos.
        expect(service.calculateXp(installment({ amount: 0.01, paidAmount: 0.02 }))).toBe(15);
        expect(service.calculateXp(installment({ amount: 3, paidAmount: 3.01 }))).toBe(15);
    });

    it("dois centavos a mais numa despesa punem; dois a menos premiam", () => {
        expect(service.calculateXp(installment({ amount: 3, paidAmount: 3.02 }))).toBe(13.5);
        expect(service.calculateXp(installment({ amount: 3, paidAmount: 2.98 }))).toBe(16.5);
    });

    it("numa receita o sinal do prêmio se inverte", () => {
        const income = { type: OrderType.income };
        expect(service.calculateXp(installment({ ...income, amount: 100, paidAmount: 120 }))).toBe(16.5);
        expect(service.calculateXp(installment({ ...income, amount: 100, paidAmount: 80 }))).toBe(13.5);
    });

    it("planejado zero continua valendo ZERO XP (gasto não planejado)", () => {
        expect(service.calculateXp(installment({ amount: 0, paidAmount: 90 }))).toBe(0);
    });

    it("o espelho inteiro tem precedência sobre o double sujo", () => {
        const inst = installment({ amount: 100, amountCents: 10000, paidAmount: 100.0000000001, paidAmountCents: 10000 });
        expect(service.calculateXp(inst)).toBe(15);
    });
});

describe("F1.10 — impactos de planejamento", () => {
    const service = new SummaryService({} as any);

    function planning(over: Partial<CategoryPlanningModel> = {}): CategoryPlanningModel {
        return {
            id: "p1",
            category: CATEGORY,
            amount: 1000,
            startMonth: "2026-01",
            endMonth: "2026-01",
            ...over,
        } as CategoryPlanningModel;
    }

    it("todo impacto emitido é um decimal de DUAS CASAS exato", () => {
        // R$ 1.000,00 em janeiro (31 dias): a proporção semanal é 225,806451...
        const impacts = service.calculatePlanningImpacts(planning(), 1, { from: "2026-01", until: "2026-01" });

        expect(impacts.length).toBeGreaterThan(2);
        for (const impact of impacts) {
            const delta = impact.generalPlannedDelta!;
            expect(delta).toBe(Number(delta.toFixed(2)));
        }

        const weekly = impacts.filter((i) => i.week !== undefined);
        expect(weekly[0].generalPlannedDelta).toBe(225.81);
    });

    it("estorno e reaplicação do MESMO planejamento se anulam exatamente", () => {
        const window = { from: "2026-01", until: "2026-12" };
        const applied = service.calculatePlanningImpacts(planning({ endMonth: "2026-12" }), 1, window);
        const reverted = service.calculatePlanningImpacts(planning({ endMonth: "2026-12" }), -1, window);

        expect(applied).toHaveLength(reverted.length);

        let totalCents = 0;
        for (const impact of [...applied, ...reverted]) {
            totalCents += toCents(impact.generalPlannedDelta ?? 0);
        }
        // Era este resíduo — da ordem de 1e-13 — que obrigava o repositório a
        // carregar um `PLANNING_DELTA_EPSILON = 1e-9`.
        expect(totalCents).toBe(0);
    });

    it("o valor mensal e o anual saem do MESMO inteiro", () => {
        const impacts = service.calculatePlanningImpacts(
            planning({ amount: 1234.565 }),
            1,
            { from: "2026-01", until: "2026-01" }
        );

        const monthly = impacts.find((i) => i.month !== undefined)!;
        const yearly = impacts.find((i) => i.month === undefined && i.week === undefined)!;

        // 1234.565 -> 123457 centavos (half-away-from-zero).
        expect(monthly.generalPlannedDelta).toBe(1234.57);
        expect(yearly.generalPlannedDelta).toBe(1234.57);
    });
});

describe("F1.10 — desfecho de meta sem folga de meio centavo", () => {
    const hoje = new Date("2026-03-10T12:00:00.000Z");
    const prazo = new Date("2026-12-31T00:00:00.000Z");

    function goal(over: Record<string, unknown>) {
        return { runtimeType: "saveMoney", targetAmount: 1000, deadline: prazo, ...over };
    }

    it("alcançar o alvo ao centavo é sucesso", () => {
        expect(evaluateGoalOutcome(goal({ currentAmount: 1000 }), hoje)).toBe("success");
    });

    it("um centavo abaixo do alvo NÃO é sucesso", () => {
        expect(evaluateGoalOutcome(goal({ currentAmount: 999.99 }), hoje)).toBeNull();
    });

    it("0,1 + 0,2 contra um alvo de 0,3 é sucesso", () => {
        expect(evaluateGoalOutcome(goal({ targetAmount: 0.3, currentAmount: 0.1 + 0.2 }), hoje)).toBe("success");
    });

    it("meta de redução falha ao passar do teto, e não antes", () => {
        const reducao = { runtimeType: "reduceExpense", targetAmount: 1000, deadline: prazo };
        expect(evaluateGoalOutcome({ ...reducao, currentAmount: 1000 }, hoje)).toBeNull();
        expect(evaluateGoalOutcome({ ...reducao, currentAmount: 1000.01 }, hoje)).toBe("failed");
    });
});
