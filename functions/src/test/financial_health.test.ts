/**
 * F2.2 — Bússola da Liberdade: a regra de pontuação, os quatro perfis e — o
 * que o QA reprovou na primeira rodada — a VIRADA DO MÊS.
 *
 * Os cenários são PERFIS de usuário, não números soltos: endividado,
 * equilibrado, poupador e "sem dados". E há um bloco só para provar que o
 * placar não se mexe sozinho no dia 1: um índice que rebaixa a patente porque
 * o mês acabou não é um placar, é uma armadilha.
 */

import {
    ALIVIO_STABLE_EPSILON,
    FOLEGO_TARGET_MONTHS,
    FinancialHealthSnapshot,
    FinancialHealthTier,
    HEALTH_WEIGHTS,
    POUPANCA_TARGET_RATE,
    scoreAlivio,
    scoreDisciplina,
    scoreFolego,
    scoreFromComponents,
    scorePoupanca,
    tierForScore,
} from "../features/health/domain/models/financial_health.model";
import {
    FinancialHealthService,
    POUPANCA_MIN_INCOME_RATIO,
    endOfMonthInstant,
    sameSnapshot,
} from "../features/health/domain/services/financial_health.service";
import {
    AccountBalanceTotals,
    CategoryLimitOutcome,
    IHealthRepository,
    MonthlyTotals,
} from "../features/health/domain/repositories/health.repository";
import { toDateKey } from "../core/utils/date_key";

/** 10/09/2026, 12:00 em São Paulo — bem longe de qualquer borda de mês. */
const NOW = new Date("2026-09-10T15:00:00.000Z");
/** 30/09/2026, 12:00 em São Paulo — último dia do mês. */
const LAST_DAY = new Date("2026-09-30T15:00:00.000Z");
/** 01/10/2026, 12:00 em São Paulo — o dia seguinte. */
const FIRST_DAY = new Date("2026-10-01T15:00:00.000Z");

type BalanceSource =
    | Record<string, Partial<AccountBalanceTotals>>
    | ((dateKey: string) => Partial<AccountBalanceTotals>);

interface Fixture {
    /** Saldos por chave de dia (`toDateKey`); a chave "*" é o padrão. */
    balances: BalanceSource;
    months: Record<string, MonthlyTotals>;
    limits: Record<string, CategoryLimitOutcome[]>;
    /** Despesas realizadas, com a chave de dia do `paidDate`. */
    expenses: Array<{ date: string, amount: number }>;
}

function makeRepository(fixture: Partial<Fixture>) {
    const balances = fixture.balances ?? {};
    const months = fixture.months ?? {};
    const limits = fixture.limits ?? {};
    const expenses = fixture.expenses ?? [];

    const saved: FinancialHealthSnapshot[] = [];
    const history = new Map<string, FinancialHealthSnapshot>();
    let current: FinancialHealthSnapshot | null = null;

    const balanceAt = (dateKey: string): Partial<AccountBalanceTotals> => {
        if (typeof balances === "function") return balances(dateKey);
        return balances[dateKey] ?? balances["*"] ?? {};
    };

    const repository: IHealthRepository = {
        getAccountBalanceTotals: jest.fn(async (_w: string, dateKey: string) => {
            const raw = balanceAt(dateKey);
            return {
                liquid: raw.liquid ?? 0,
                debt: raw.debt ?? 0,
                hasDebtAccounts: raw.hasDebtAccounts ?? false,
                hasAnyAccount: raw.hasAnyAccount ?? true,
            };
        }),
        getMonthlyTotals: jest.fn(async (_w: string, monthKey: string) => {
            return months[monthKey] ?? { income: 0, expense: 0 };
        }),
        getRealizedExpensesBetween: jest.fn(async (_w: string, since: Date, until: Date) => {
            const from = toDateKey(since);
            const to = toDateKey(until);
            return expenses
                .filter((entry) => entry.date >= from && entry.date <= to)
                .reduce((sum, entry) => sum + entry.amount, 0);
        }),
        getCategoryLimitOutcomes: jest.fn(async (_w: string, monthKey: string) => {
            return limits[monthKey] ?? [];
        }),
        saveCurrent: jest.fn(async (_w: string, snapshot: FinancialHealthSnapshot) => {
            saved.push(snapshot);
            current = snapshot;
        }),
        saveHistory: jest.fn(async (_w: string, snapshot: FinancialHealthSnapshot) => {
            history.set(snapshot.monthKey, snapshot);
        }),
        getHistory: jest.fn(async (_w: string, monthKey: string) => history.get(monthKey) ?? null),
        getCurrent: jest.fn(async () => current),
        markDirty: jest.fn(async () => undefined),
        clearDirty: jest.fn(async () => undefined),
    };

    const setCurrent = (snapshot: FinancialHealthSnapshot | null) => {
        current = snapshot;
    };

    return { repository, saved, history, setCurrent };
}

/** Uma despesa por dia, de `from` até `to` (chaves de dia inclusivas). */
function dailyExpenses(from: string, to: string, amount: number): Array<{ date: string, amount: number }> {
    const entries: Array<{ date: string, amount: number }> = [];
    const cursor = new Date(`${from}T12:00:00.000Z`);
    const end = new Date(`${to}T12:00:00.000Z`);
    while (cursor <= end) {
        entries.push({ date: cursor.toISOString().slice(0, 10), amount });
        cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
    return entries;
}

describe("Bússola da Liberdade — componentes", () => {
    it("Fôlego: 6 meses de reserva valem 100; metade disso vale 50", () => {
        expect(scoreFolego(6000, 1000)).toMatchObject({ months: 6, score: 100 });
        expect(scoreFolego(3000, 1000)).toMatchObject({ months: 3, score: 50 });
        // Acima do alvo não pontua mais: 12 meses continua 100.
        expect(scoreFolego(12000, 1000).score).toBe(100);
        expect(FOLEGO_TARGET_MONTHS).toBe(6);
    });

    it("Fôlego: sem histórico de despesa vale ZERO, não infinito", () => {
        // O workspace recém-criado tem saldo e nenhuma despesa. Dividir por
        // zero daria Infinity e o app mostraria "reserva infinita" para quem
        // acabou de chegar.
        expect(scoreFolego(10000, 0)).toEqual({ value: 0, score: 0, months: 0 });
        // Saldo negativo não é reserva negativa: é ausência de reserva.
        expect(scoreFolego(-500, 1000)).toEqual({ value: 0, score: 0, months: 0 });
    });

    it("Poupança: 30% da receita vale 100 e taxa negativa vale 0", () => {
        expect(scorePoupanca(10000, 7000)).toMatchObject({ rate: 0.3, score: 100 });
        expect(scorePoupanca(10000, 8500)).toMatchObject({ rate: 0.15, score: 50 });
        // Gastou mais do que ganhou: piso zero, nunca negativo.
        expect(scorePoupanca(1000, 1500)).toMatchObject({ score: 0 });
        expect(scorePoupanca(1000, 1500).rate).toBeLessThan(0);
        expect(POUPANCA_TARGET_RATE).toBe(0.3);
    });

    it("Poupança: receita zero vale 0 (o mês vazio não é 100% de poupança)", () => {
        expect(scorePoupanca(0, 0)).toEqual({ value: 0, score: 0, rate: 0 });
        expect(scorePoupanca(0, 500)).toEqual({ value: 0, score: 0, rate: 0 });
    });

    it("Disciplina: percentual das categorias com limite que fecharam dentro", () => {
        expect(scoreDisciplina(3, 4)).toMatchObject({ score: 75, within: 3, total: 4 });
        expect(scoreDisciplina(4, 4).score).toBe(100);
        expect(scoreDisciplina(0, 4).score).toBe(0);
    });

    it("Disciplina: sem nenhuma categoria com limite, não há disciplina a medir", () => {
        expect(scoreDisciplina(0, 0)).toEqual({ value: 0, score: 0, within: 0, total: 0 });
    });

    it("Alívio: dívida encolhendo 100, crescendo 0, estável 50", () => {
        // Saldo de dívida é negativo: amortizar aproxima de zero, delta > 0.
        expect(scoreAlivio(500, true).score).toBe(100);
        expect(scoreAlivio(-500, true).score).toBe(0);
        expect(scoreAlivio(0, true).score).toBe(50);
        // A faixa morta evita que um centavo de juros derrube 50 para 0.
        expect(scoreAlivio(ALIVIO_STABLE_EPSILON, true).score).toBe(50);
        expect(scoreAlivio(-ALIVIO_STABLE_EPSILON, true).score).toBe(50);
    });

    it("Alívio: sem conta de dívida nenhuma, o componente é máximo", () => {
        // Quem não tem dívida não pode ser punido por não estar amortizando.
        expect(scoreAlivio(0, false).score).toBe(100);
    });

    it("os pesos somam 100 — sem isso o índice nunca chegaria a 100", () => {
        const sum = HEALTH_WEIGHTS.folego + HEALTH_WEIGHTS.poupanca +
            HEALTH_WEIGHTS.disciplina + HEALTH_WEIGHTS.alivio;
        expect(sum).toBe(100);
    });

    it("as patentes cobrem as faixas do contrato", () => {
        expect(tierForScore(0)).toBe(FinancialHealthTier.aprendiz);
        expect(tierForScore(19)).toBe(FinancialHealthTier.aprendiz);
        expect(tierForScore(20)).toBe(FinancialHealthTier.guardiao);
        expect(tierForScore(39)).toBe(FinancialHealthTier.guardiao);
        expect(tierForScore(40)).toBe(FinancialHealthTier.estrategista);
        expect(tierForScore(59)).toBe(FinancialHealthTier.estrategista);
        expect(tierForScore(60)).toBe(FinancialHealthTier.mestre);
        expect(tierForScore(79)).toBe(FinancialHealthTier.mestre);
        expect(tierForScore(80)).toBe(FinancialHealthTier.livre);
        expect(tierForScore(100)).toBe(FinancialHealthTier.livre);
    });

    it("nota máxima em tudo dá exatamente 100", () => {
        const score = scoreFromComponents({
            folego: { value: 6, score: 100, months: 6 },
            poupanca: { value: 0.3, score: 100, rate: 0.3 },
            disciplina: { value: 1, score: 100, within: 2, total: 2 },
            alivio: { value: 1, score: 100, delta: 1 },
        });
        expect(score).toBe(100);
    });
});

describe("Bússola da Liberdade — quatro cenários", () => {
    it("ENDIVIDADO: sem reserva, gastando mais do que ganha e devendo mais — Aprendiz", async () => {
        const { repository } = makeRepository({
            balances: {
                // Hoje: nenhuma reserva e R$ 12.000 de dívida.
                "2026-09-10": { liquid: 0, debt: -12000, hasDebtAccounts: true, hasAnyAccount: true },
                // Trinta dias atrás devia R$ 10.000 — a dívida CRESCEU.
                "2026-08-11": { liquid: 0, debt: -10000, hasDebtAccounts: true, hasAnyAccount: true },
            },
            months: {
                "2026-09": { income: 5000, expense: 6000 },
                "2026-08": { income: 5000, expense: 6000 },
            },
            expenses: [
                { date: "2026-07-10", amount: 6000 },
                { date: "2026-08-10", amount: 6000 },
                { date: "2026-09-05", amount: 6000 },
            ],
            limits: {
                "2026-08": [
                    { categoryId: "mercado", limit: 800, actual: 1400 },
                    { categoryId: "lazer", limit: 300, actual: 900 },
                ],
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(snapshot.components.folego.score).toBe(0);
        expect(snapshot.components.poupanca.score).toBe(0);
        expect(snapshot.components.disciplina).toMatchObject({ score: 0, within: 0, total: 2 });
        expect(snapshot.components.alivio).toMatchObject({ delta: -2000, score: 0 });
        expect(snapshot.score).toBe(0);
        expect(snapshot.tier).toBe(FinancialHealthTier.aprendiz);
        expect(snapshot.monthKey).toBe("2026-09");
    });

    it("EQUILIBRADO: três meses de reserva, poupando 15%, metade dos limites em dia — Estrategista", async () => {
        const { repository } = makeRepository({
            balances: {
                "2026-09-10": { liquid: 12000, debt: -2000, hasDebtAccounts: true, hasAnyAccount: true },
                // Dívida estável (dentro da faixa morta): componente vale 50.
                "2026-08-11": { liquid: 11000, debt: -2000, hasDebtAccounts: true, hasAnyAccount: true },
            },
            months: {
                "2026-09": { income: 8000, expense: 6800 },
                "2026-08": { income: 8000, expense: 4000 },
            },
            // 12.000 em 90 dias ÷ 3 = 4.000/mês => 12.000 / 4.000 = 3 meses.
            expenses: [
                { date: "2026-07-10", amount: 4000 },
                { date: "2026-08-10", amount: 4000 },
                { date: "2026-09-05", amount: 4000 },
            ],
            limits: {
                "2026-08": [
                    { categoryId: "mercado", limit: 1200, actual: 1100 },
                    { categoryId: "lazer", limit: 400, actual: 700 },
                ],
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(snapshot.components.folego).toMatchObject({ months: 3, score: 50 });
        // (8000 - 6800) / 8000 = 15% => metade de 30% => 50.
        expect(snapshot.components.poupanca.score).toBe(50);
        expect(snapshot.components.disciplina).toMatchObject({ score: 50, within: 1, total: 2 });
        expect(snapshot.components.alivio.score).toBe(50);
        expect(snapshot.score).toBe(50);
        expect(snapshot.tier).toBe(FinancialHealthTier.estrategista);
    });

    it("POUPADOR: reserva farta, 40% guardado, todos os limites em dia e sem dívida — Livre", async () => {
        const { repository } = makeRepository({
            balances: { "*": { liquid: 60000, debt: 0, hasDebtAccounts: false, hasAnyAccount: true } },
            months: {
                "2026-09": { income: 10000, expense: 6000 },
                "2026-08": { income: 10000, expense: 5000 },
            },
            // 15.000 em 90 dias ÷ 3 = 5.000/mês => 60.000 / 5.000 = 12 meses.
            expenses: [
                { date: "2026-07-10", amount: 5000 },
                { date: "2026-08-10", amount: 5000 },
                { date: "2026-09-05", amount: 5000 },
            ],
            limits: {
                "2026-08": [
                    { categoryId: "mercado", limit: 1500, actual: 1200 },
                    { categoryId: "lazer", limit: 600, actual: 600 },
                ],
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        // 12 meses de reserva, acima do alvo de 6 => 100.
        expect(snapshot.components.folego.score).toBe(100);
        expect(snapshot.components.poupanca.score).toBe(100);
        // Gastar EXATAMENTE o limite conta como dentro.
        expect(snapshot.components.disciplina).toMatchObject({ score: 100, within: 2, total: 2 });
        expect(snapshot.components.alivio.score).toBe(100);
        expect(snapshot.score).toBe(100);
        expect(snapshot.tier).toBe(FinancialHealthTier.livre);
    });

    it("SEM DADOS: workspace novo devolve score 0 e Aprendiz, sem erro", async () => {
        const { repository } = makeRepository({
            balances: { "*": { hasAnyAccount: false } },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(snapshot.score).toBe(0);
        expect(snapshot.tier).toBe(FinancialHealthTier.aprendiz);
        expect(snapshot.components.folego).toEqual({ value: 0, score: 0, months: 0 });
        expect(snapshot.components.poupanca).toEqual({ value: 0, score: 0, rate: 0 });
        expect(snapshot.components.disciplina).toEqual({ value: 0, score: 0, within: 0, total: 0 });
        expect(snapshot.components.alivio).toEqual({ value: 0, score: 0, delta: 0 });
        expect(snapshot.monthKey).toBe("2026-09");
        // Sem conta nenhuma, nem os sumários são lidos: é o caminho barato.
        expect(repository.getMonthlyTotals).not.toHaveBeenCalled();
        expect(repository.getRealizedExpensesBetween).not.toHaveBeenCalled();
    });
});

/**
 * O BLOCO QUE O QA PEDIU.
 *
 * A primeira versão media Fôlego em meses de calendário e Alívio "contra o fim
 * do mês anterior". As duas janelas SALTAVAM no dia 1: o usuário ia dormir
 * Mestre em 30/09 e acordava Estrategista em 01/10 sem ter feito nada. Um
 * placar que se mexe sozinho ensina o usuário a ignorá-lo.
 */
describe("Bússola da Liberdade — a virada do mês não mexe no placar", () => {
    it("ALÍVIO: 30/09 e 01/10 dão a mesma nota para quem vem amortizando", async () => {
        // Dívida encolhendo R$ 20/dia, sem nenhuma inflexão na virada.
        const debtAt = (dateKey: string) => {
            const days = Math.round(
                (new Date(`${dateKey}T12:00:00.000Z`).getTime() - new Date("2026-01-01T12:00:00.000Z").getTime())
                / 86400000
            );
            return { liquid: 5000, debt: -20000 + days * 20, hasDebtAccounts: true, hasAnyAccount: true };
        };

        const { repository } = makeRepository({ balances: debtAt });
        const service = new FinancialHealthService(repository);

        const before = await service.computeHealth("w", LAST_DAY);
        const after = await service.computeHealth("w", FIRST_DAY);

        // 30 dias × R$ 20 = R$ 600 amortizados, nos dois dias.
        expect(before.components.alivio.delta).toBeCloseTo(600, 6);
        expect(after.components.alivio.delta).toBeCloseTo(600, 6);
        expect(before.components.alivio.score).toBe(100);
        expect(after.components.alivio.score).toBe(100);
    });

    it("FÔLEGO: 30/09 e 01/10 veem a mesma janela de 90 dias", async () => {
        // Junho foi um mês ATÍPICO (R$ 9.000 num dia). Com meses de calendário,
        // ele saía da janela exatamente na virada e a média mensal despencava
        // de 5.000 para 3.000 — trinta dias de despesa trocados de uma vez.
        // Com a janela móvel ele já está fora nos dois dias.
        const { repository } = makeRepository({
            balances: { "*": { liquid: 18000, hasAnyAccount: true } },
            expenses: [
                { date: "2026-06-10", amount: 9000 },
                { date: "2026-07-10", amount: 3000 },
                { date: "2026-08-10", amount: 3000 },
                { date: "2026-09-10", amount: 3000 },
            ],
        });
        const service = new FinancialHealthService(repository);

        const before = await service.computeHealth("w", LAST_DAY);
        const after = await service.computeHealth("w", FIRST_DAY);

        // 9.000 em 90 dias ÷ 3 = 3.000/mês => 18.000 / 3.000 = 6 meses.
        expect(before.components.folego.months).toBeCloseTo(6, 6);
        expect(after.components.folego.months).toBeCloseTo(6, 6);
        expect(before.components.folego.score).toBe(100);
        expect(after.components.folego.score).toBe(100);
    });

    it("o SCORE INTEIRO é o mesmo em 30/09 e em 01/10", async () => {
        const { repository } = makeRepository({
            balances: { "*": { liquid: 18000, debt: -1000, hasDebtAccounts: true, hasAnyAccount: true } },
            expenses: dailyExpenses("2026-05-01", "2026-10-31", 100),
            months: {
                "2026-09": { income: 9000, expense: 6300 },
                "2026-08": { income: 9000, expense: 6300 },
            },
            // Agosto e setembro fecharam iguais: a Disciplina, que é a única
            // que TROCA de mês de propósito, dá a mesma nota nos dois dias.
            limits: {
                "2026-08": [{ categoryId: "mercado", limit: 3000, actual: 2000 }],
                "2026-09": [{ categoryId: "mercado", limit: 3000, actual: 2000 }],
            },
        });
        const service = new FinancialHealthService(repository);

        const before = await service.computeHealth("w", LAST_DAY);
        const after = await service.computeHealth("w", FIRST_DAY);

        expect(after.score).toBe(before.score);
        expect(after.tier).toBe(before.tier);
        // E o mês de referência, esse, avançou: é o único que deve mudar.
        expect(before.monthKey).toBe("2026-09");
        expect(after.monthKey).toBe("2026-10");
    });
});

describe("Bússola da Liberdade — Poupança e a primeira receita do mês", () => {
    const base = {
        balances: { "*": { liquid: 1000, hasAnyAccount: true } as Partial<AccountBalanceTotals> },
        expenses: [{ date: "2026-08-10", amount: 3000 }],
    };

    it("um reembolso de R$ 100 no dia 2 NÃO derruba a nota do mês anterior", async () => {
        // Sem o piso, R$ 100 viravam o denominador inteiro da taxa: com R$ 300
        // de despesa no mesmo dia, a taxa ia a −200% e o componente a ZERO.
        const { repository } = makeRepository({
            ...base,
            months: {
                "2026-10": { income: 100, expense: 300 },
                "2026-09": { income: 9000, expense: 3000 },
            },
        });

        const dayTwo = new Date("2026-10-02T15:00:00.000Z");
        const snapshot = await new FinancialHealthService(repository).computeHealth("w", dayTwo);

        // Setembro: (9000 − 3000) / 9000 = 66,7% => acima do alvo => 100.
        expect(snapshot.components.poupanca.rate).toBeCloseTo(2 / 3, 6);
        expect(snapshot.components.poupanca.score).toBe(100);
    });

    it("o salário no dia 5 troca a nota para o mês corrente", async () => {
        const { repository } = makeRepository({
            ...base,
            months: {
                // 9.000 >= 50% de 9.000: o mês novo já é comparável.
                "2026-10": { income: 9000, expense: 7650 },
                "2026-09": { income: 9000, expense: 3000 },
            },
        });

        const dayFive = new Date("2026-10-05T15:00:00.000Z");
        const snapshot = await new FinancialHealthService(repository).computeHealth("w", dayFive);

        // Outubro: (9000 − 7650) / 9000 = 15% => 50.
        expect(snapshot.components.poupanca.rate).toBeCloseTo(0.15, 6);
        expect(snapshot.components.poupanca.score).toBe(50);
    });

    it("o piso é exatamente metade da receita do mês anterior", async () => {
        expect(POUPANCA_MIN_INCOME_RATIO).toBe(0.5);

        const onTheLine = makeRepository({
            ...base,
            months: {
                "2026-10": { income: 5000, expense: 5000 },
                "2026-09": { income: 10000, expense: 1000 },
            },
        });
        const dayFive = new Date("2026-10-05T15:00:00.000Z");
        // 5.000 == 50% de 10.000: já vale o mês corrente (taxa zero).
        const snapshot = await new FinancialHealthService(onTheLine.repository).computeHealth("w", dayFive);
        expect(snapshot.components.poupanca.rate).toBe(0);

        const justBelow = makeRepository({
            ...base,
            months: {
                "2026-10": { income: 4999, expense: 4999 },
                "2026-09": { income: 10000, expense: 1000 },
            },
        });
        // Um real abaixo: ainda vale o mês anterior (90% de poupança).
        const fallback = await new FinancialHealthService(justBelow.repository).computeHealth("w", dayFive);
        expect(fallback.components.poupanca.rate).toBeCloseTo(0.9, 6);
    });

    it("no primeiro mês do workspace não há a quem recuar: vale o corrente", async () => {
        const { repository } = makeRepository({
            ...base,
            months: { "2026-10": { income: 4000, expense: 2800 } },
        });

        const dayFive = new Date("2026-10-05T15:00:00.000Z");
        const snapshot = await new FinancialHealthService(repository).computeHealth("w", dayFive);

        expect(snapshot.components.poupanca.rate).toBeCloseTo(0.3, 6);
        expect(snapshot.components.poupanca.score).toBe(100);
    });
});

describe("Bússola da Liberdade — a Disciplina julga o mês fechado", () => {
    it("usa o mês ANTERIOR, nunca o corrente", async () => {
        const { repository } = makeRepository({ balances: { "*": { hasAnyAccount: true } } });

        await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(repository.getCategoryLimitOutcomes).toHaveBeenCalledWith("w", "2026-08");
        expect(repository.getCategoryLimitOutcomes).not.toHaveBeenCalledWith("w", "2026-09");
    });

    it("endOfMonthInstant devolve o último milissegundo do mês no fuso do produto", () => {
        // 31/08/2026 23:59:59.999 em São Paulo = 01/09 02:59:59.999 UTC.
        expect(endOfMonthInstant("2026-08").toISOString()).toBe("2026-09-01T02:59:59.999Z");
        // Fevereiro de ano bissexto: 29/02/2028 23:59:59.999 em São Paulo.
        expect(endOfMonthInstant("2028-02").toISOString()).toBe("2028-03-01T02:59:59.999Z");
        // Virada de ano.
        expect(endOfMonthInstant("2026-12").toISOString()).toBe("2027-01-01T02:59:59.999Z");
    });
});

describe("Bússola da Liberdade — persistência, debounce e escrita mínima", () => {
    const fixture = {
        balances: { "*": { liquid: 6000, hasAnyAccount: true } as Partial<AccountBalanceTotals> },
        expenses: [{ date: "2026-08-10", amount: 3000 }],
        months: { "2026-08": { income: 5000, expense: 1000 } },
    };

    it("grava o retrato corrente E o histórico do mês", async () => {
        const { repository, saved, history } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        const snapshot = await service.refreshHealth("w", NOW);

        expect(saved).toHaveLength(1);
        expect(history.get("2026-09")).toEqual(snapshot);
    });

    it("o recálculo é determinístico: duas passadas com o mesmo `now` dão o mesmo número", async () => {
        const { repository } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        const first = await service.computeHealth("w", NOW);
        const second = await service.computeHealth("w", NOW);

        expect(second).toEqual(first);
    });

    it("NÃO reescreve o histórico quando o retrato não mudou", async () => {
        // O histórico é um ponto de tendência. Reescrevê-lo a cada 15 minutos
        // com o mesmo score é uma escrita por workspace por ciclo que não conta
        // nada a ninguém.
        const { repository } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        await service.refreshHealth("w", NOW);
        expect(repository.saveHistory).toHaveBeenCalledTimes(1);

        await service.refreshHealth("w", new Date(NOW.getTime() + 20 * 60 * 1000));
        expect(repository.saveHistory).toHaveBeenCalledTimes(1);

        // O retrato CORRENTE, esse, é reescrito sempre: é dele que sai o
        // `computedAt` que ancora o debounce, e é ele que carrega os valores
        // exatos que o app mostra.
        expect(repository.saveCurrent).toHaveBeenCalledTimes(2);
    });

    it("volta a gravar o histórico quando o score muda", () => {
        const snapshot = (score: number): FinancialHealthSnapshot => ({
            score,
            tier: tierForScore(score),
            components: {
                folego: { value: 1, score: 10, months: 1 },
                poupanca: { value: 0.1, score: 20, rate: 0.1 },
                disciplina: { value: 1, score: 100, within: 2, total: 2 },
                alivio: { value: 0, score: 50, delta: 0 },
            },
            computedAt: NOW,
            monthKey: "2026-09",
        });

        expect(sameSnapshot(snapshot(40), snapshot(40))).toBe(true);
        expect(sameSnapshot(snapshot(40), snapshot(41))).toBe(false);
        expect(sameSnapshot(null, snapshot(40))).toBe(false);

        // Um centavo a mais de saldo mexe no valor BRUTO e não na nota: isso
        // não é motivo para reescrever o ponto de tendência.
        const a = snapshot(40);
        const b = snapshot(40);
        b.components.folego.months = 1.0001;
        b.components.folego.value = 1.0001;
        expect(sameSnapshot(a, b)).toBe(true);
    });

    it("o debounce adia o recálculo de quem foi calculado há menos de 10 minutos", async () => {
        const { repository, setCurrent } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        setCurrent({
            score: 42,
            tier: FinancialHealthTier.estrategista,
            components: {} as any,
            computedAt: new Date(NOW.getTime() - 5 * 60 * 1000),
            monthKey: "2026-09",
        });

        const result = await service.refreshIfDue("w", NOW);

        expect(result).toMatchObject({ computed: false, debounced: true, snapshot: null });
        // O marcador NÃO é limpo: o workspace continua sujo e entra no ciclo
        // seguinte. Limpá-lo aqui perderia a mudança para sempre.
        expect(repository.clearDirty).not.toHaveBeenCalled();
        expect(repository.saveCurrent).not.toHaveBeenCalled();
    });

    it("passados 10 minutos, recalcula e limpa o marcador de sujo", async () => {
        const { repository, setCurrent } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        setCurrent({
            score: 42,
            tier: FinancialHealthTier.estrategista,
            components: {} as any,
            computedAt: new Date(NOW.getTime() - 11 * 60 * 1000),
            monthKey: "2026-09",
        });

        const result = await service.refreshIfDue("w", NOW);

        expect(result.computed).toBe(true);
        expect(repository.clearDirty).toHaveBeenCalledWith("w");
        expect(repository.saveCurrent).toHaveBeenCalled();
    });

    it("a virada de mês fecha o histórico do mês anterior e reabre o corrente", async () => {
        const { repository, history, saved } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        // 01/09/2026 04:30 em São Paulo — o horário do cron mensal.
        const dayOne = new Date("2026-09-01T07:30:00.000Z");
        await service.closeMonth("w", dayOne);

        expect([...history.keys()].sort()).toEqual(["2026-08", "2026-09"]);
        // O retrato CORRENTE nunca fica apontando para o mês que acabou.
        expect(saved).toHaveLength(1);
        expect(saved[0].monthKey).toBe("2026-09");
        // O carimbo do mês fechado é o último instante DAQUELE mês.
        expect(history.get("2026-08")!.computedAt.toISOString()).toBe("2026-09-01T02:59:59.999Z");
    });

    it("closeMonth é IDEMPOTENTE: um mês já fechado não é reescrito", async () => {
        // Sem esta guarda, uma segunda execução do cron recalcularia o mês
        // fechado com os dados de HOJE — a Disciplina passaria a julgar outro
        // mês e o retrato congelado mudaria depois de congelado.
        const { repository, history } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);
        const dayOne = new Date("2026-09-01T07:30:00.000Z");

        await service.closeMonth("w", dayOne);
        const closed = history.get("2026-08")!;

        (repository.saveHistory as jest.Mock).mockClear();
        await service.closeMonth("w", dayOne);

        // Nenhuma escrita em 2026-08 na segunda passada.
        const rewrittenMonths = (repository.saveHistory as jest.Mock).mock.calls
            .map((call) => call[1].monthKey);
        expect(rewrittenMonths).not.toContain("2026-08");
        expect(history.get("2026-08")).toEqual(closed);
    });

    it("marcar como sujo nunca lança para quem chama", async () => {
        const { repository } = makeRepository(fixture);
        (repository.markDirty as jest.Mock).mockRejectedValue(new Error("firestore fora do ar"));

        // O carimbo vive dentro do gatilho de parcela: se ele derrubasse o
        // handler, uma falha da Bússola desfaria um pagamento.
        await expect(new FinancialHealthService(repository).markHealthDirty("w")).resolves.toBeUndefined();
    });
});
