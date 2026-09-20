/**
 * HUD MENSAL — A RECEITA PREVISTA DO MÊS.
 *
 * O denominador das razões de poção (investimentos), ovo (cartões) e gota
 * (dívidas) precisa ser o MESMO no app e no servidor. Estes testes fixam a
 * regra que o torna único:
 *
 *  1. o PLANEJADO manda — `specificPlannedAmount` das categorias de receita;
 *  2. na falta dele, a MÉDIA do realizado dos últimos três meses;
 *  3. mês sem sumário fica fora do divisor da média;
 *  4. a publicação em `workspaces/{w}.expectedIncome` só escreve quando o
 *     valor muda — o documento do workspace é observado por um gatilho.
 */

import { ExpectedIncomeService } from "../features/finance/domain/services/expected_income.service";
import {
    EXPECTED_INCOME_FALLBACK_MONTHS,
    sameExpectedIncome,
} from "../features/finance/domain/models/expected_income.model";
import { MonthlyIncomeTotals } from "../features/finance/domain/repositories/expected_income.repository";

/** 20/09/2026 12:00 em São Paulo — um instante qualquer dentro do mês. */
const NOW = new Date("2026-09-20T15:00:00.000Z");
const MONTH = "2026-09";

type Totals = Partial<MonthlyIncomeTotals> & { monthKey: string };

/**
 * Repositório de mentira: devolve os totais declarados e guarda o que foi
 * publicado. Mês não declarado responde "não existe", que é o caso do
 * workspace novo.
 */
function makeRepository(months: Totals[], published: any = null) {
    const byMonth = new Map(months.map((m) => [m.monthKey, m]));
    return {
        getMonthlyIncomeTotals: jest.fn(async (_workspaceId: string, monthKeys: string[]) =>
            monthKeys.map((monthKey) => ({
                monthKey,
                exists: byMonth.get(monthKey)?.exists ?? false,
                plannedCents: byMonth.get(monthKey)?.plannedCents ?? 0,
                actualCents: byMonth.get(monthKey)?.actualCents ?? 0,
            }))
        ),
        getPublishedExpectedIncome: jest.fn(async () => published),
        publishExpectedIncome: jest.fn(async () => undefined),
    };
}

describe("expectedMonthlyIncomeCents — o planejado manda", () => {
    it("usa o specificPlannedAmount de receita do mês quando ele existe", async () => {
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 850_000, actualCents: 120_000 },
            { monthKey: "2026-08", exists: true, actualCents: 300_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result).toMatchObject({ monthKey: MONTH, cents: 850_000, source: "planned" });
        // O realizado do mês NÃO entra: a previsão é o que foi agendado, não o
        // que já caiu na conta.
        expect(result.cents).not.toBe(120_000);
    });

    it("lê o mês pedido e os três anteriores numa chamada só", async () => {
        const repository = makeRepository([{ monthKey: MONTH, exists: true, plannedCents: 1 }]);

        await new ExpectedIncomeService(repository as any).expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(repository.getMonthlyIncomeTotals).toHaveBeenCalledTimes(1);
        expect(repository.getMonthlyIncomeTotals).toHaveBeenCalledWith(
            "w",
            [MONTH, "2026-08", "2026-07", "2026-06"]
        );
        expect(EXPECTED_INCOME_FALLBACK_MONTHS).toBe(3);
    });

    it("carimba updatedAt com o instante do cálculo", async () => {
        const repository = makeRepository([{ monthKey: MONTH, exists: true, plannedCents: 100 }]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result.updatedAt).toBe(NOW.toISOString());
    });

    it("recusa um monthKey que não é YYYY-MM", async () => {
        const repository = makeRepository([]);

        await expect(
            new ExpectedIncomeService(repository as any).expectedMonthlyIncomeCents("w", "setembro", NOW)
        ).rejects.toThrow(/monthKey inválido/);
    });
});

describe("expectedMonthlyIncomeCents — a média do realizado", () => {
    it("cai na média dos três meses quando não há receita agendada", async () => {
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 0, actualCents: 50_000 },
            { monthKey: "2026-08", exists: true, actualCents: 600_000 },
            { monthKey: "2026-07", exists: true, actualCents: 500_000 },
            { monthKey: "2026-06", exists: true, actualCents: 700_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result).toMatchObject({ cents: 600_000, source: "average" });
    });

    it("divide apenas pelos meses que TÊM sumário", async () => {
        // Workspace com dois meses de vida: o terceiro mês não existiu, e
        // contá-lo como zero cortaria a previsão em um terço.
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 0 },
            { monthKey: "2026-08", exists: true, actualCents: 600_000 },
            { monthKey: "2026-07", exists: true, actualCents: 400_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result).toMatchObject({ cents: 500_000, source: "average" });
    });

    it("um mês que EXISTE e não teve receita entra como zero", async () => {
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 0 },
            { monthKey: "2026-08", exists: true, actualCents: 600_000 },
            { monthKey: "2026-07", exists: true, actualCents: 0 },
            { monthKey: "2026-06", exists: true, actualCents: 600_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result.cents).toBe(400_000);
    });

    it("workspace sem histórico nenhum devolve zero (e não quebra)", async () => {
        const repository = makeRepository([{ monthKey: MONTH, exists: true, plannedCents: 0 }]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result).toMatchObject({ cents: 0, source: "average" });
    });

    it("a média é um INTEIRO de centavos", async () => {
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 0 },
            { monthKey: "2026-08", exists: true, actualCents: 100 },
            { monthKey: "2026-07", exists: true, actualCents: 100 },
            { monthKey: "2026-06", exists: true, actualCents: 101 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(Number.isInteger(result.cents)).toBe(true);
        expect(result.cents).toBe(100);
    });

    it("um mês de estornos não produz previsão NEGATIVA", async () => {
        // Denominador negativo inverteria o sinal das três razões do HUD.
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: 0 },
            { monthKey: "2026-08", exists: true, actualCents: -300_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result.cents).toBe(0);
    });

    it("planejado negativo também cai no fallback (não é previsão)", async () => {
        const repository = makeRepository([
            { monthKey: MONTH, exists: true, plannedCents: -1_000, actualCents: 0 },
            { monthKey: "2026-08", exists: true, actualCents: 900_000 },
        ]);

        const result = await new ExpectedIncomeService(repository as any)
            .expectedMonthlyIncomeCents("w", MONTH, NOW);

        expect(result).toMatchObject({ cents: 900_000, source: "average" });
    });
});

describe("publicação em workspaces/{w}.expectedIncome", () => {
    it("publica quando ainda não havia previsão", async () => {
        const repository = makeRepository([{ monthKey: MONTH, exists: true, plannedCents: 700_000 }]);

        const result = await new ExpectedIncomeService(repository as any)
            .publishExpectedIncome("w", MONTH, NOW);

        expect(result.published).toBe(true);
        expect(repository.publishExpectedIncome).toHaveBeenCalledWith("w", {
            monthKey: MONTH,
            cents: 700_000,
            source: "planned",
            updatedAt: NOW.toISOString(),
        });
    });

    it("NÃO escreve quando o valor publicado já é o mesmo", async () => {
        // O documento do workspace é observado por `onWorkspaceUpdated`:
        // republicar o mesmo número a cada parcela de receita acordaria o
        // gatilho de gamificação de graça.
        const repository = makeRepository(
            [{ monthKey: MONTH, exists: true, plannedCents: 700_000 }],
            { monthKey: MONTH, cents: 700_000, source: "planned", updatedAt: "2026-09-01T00:00:00.000Z" }
        );

        const result = await new ExpectedIncomeService(repository as any)
            .publishExpectedIncome("w", MONTH, NOW);

        expect(result.published).toBe(false);
        expect(repository.publishExpectedIncome).not.toHaveBeenCalled();
    });

    it("escreve quando só a ORIGEM mudou, com o mesmo valor", async () => {
        // Mesmo número vindo do planejado em vez da média é informação nova: o
        // app mostra a origem ao usuário.
        const repository = makeRepository(
            [{ monthKey: MONTH, exists: true, plannedCents: 700_000 }],
            { monthKey: MONTH, cents: 700_000, source: "average", updatedAt: "2026-09-01T00:00:00.000Z" }
        );

        const result = await new ExpectedIncomeService(repository as any)
            .publishExpectedIncome("w", MONTH, NOW);

        expect(result.published).toBe(true);
    });

    it("escreve quando o MÊS virou, mesmo com o valor igual", async () => {
        const repository = makeRepository(
            [{ monthKey: MONTH, exists: true, plannedCents: 700_000 }],
            { monthKey: "2026-08", cents: 700_000, source: "planned", updatedAt: "2026-08-01T00:00:00.000Z" }
        );

        const result = await new ExpectedIncomeService(repository as any)
            .publishExpectedIncome("w", MONTH, NOW);

        expect(result.published).toBe(true);
    });

    it("publishCurrentMonth usa o mês do fuso do produto", async () => {
        const repository = makeRepository([{ monthKey: MONTH, exists: true, plannedCents: 1 }]);

        // 01/09/2026 00:30 em São Paulo = 03:30Z. Em UTC ainda seria setembro,
        // mas a borda que importa é a LOCAL.
        await new ExpectedIncomeService(repository as any)
            .publishCurrentMonth("w", new Date("2026-09-01T03:30:00.000Z"));

        expect(repository.getMonthlyIncomeTotals).toHaveBeenCalledWith(
            "w",
            [MONTH, "2026-08", "2026-07", "2026-06"]
        );
    });

    it("01/09 às 00:30 em Brasília ainda é agosto? não — mas 31/08 às 23:30 é", async () => {
        const repository = makeRepository([{ monthKey: "2026-08", exists: true, plannedCents: 1 }]);

        // 31/08/2026 23:30 em São Paulo = 01/09 02:30Z: em UTC já virou o mês,
        // no fuso do produto não.
        await new ExpectedIncomeService(repository as any)
            .publishCurrentMonth("w", new Date("2026-09-01T02:30:00.000Z"));

        expect(repository.getMonthlyIncomeTotals.mock.calls[0][1][0]).toBe("2026-08");
    });
});

describe("sameExpectedIncome", () => {
    const value = { monthKey: MONTH, cents: 100, source: "planned" as const, updatedAt: "a" };

    it("ignora o updatedAt", () => {
        expect(sameExpectedIncome(value, { ...value, updatedAt: "b" })).toBe(true);
    });

    it("um lado ausente nunca é igual", () => {
        expect(sameExpectedIncome(null, value)).toBe(false);
        expect(sameExpectedIncome(value, null)).toBe(false);
    });

    it("diferença em qualquer dos três campos do contrato quebra a igualdade", () => {
        expect(sameExpectedIncome(value, { ...value, cents: 101 })).toBe(false);
        expect(sameExpectedIncome(value, { ...value, monthKey: "2026-08" })).toBe(false);
        expect(sameExpectedIncome(value, { ...value, source: "average" })).toBe(false);
    });
});
