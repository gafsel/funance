/**
 * F2.2 — Bússola da Liberdade: a regra de pontuação e os quatro perfis.
 *
 * Os cenários são PERFIS de usuário, não números soltos: endividado,
 * equilibrado, poupador e "sem dados". É o que garante que o índice conta a
 * história certa — um endividado não pode aparecer como Mestre porque o saldo
 * da poupança está alto, e um workspace novo não pode explodir por falta de
 * histórico.
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
    endOfMonthInstant,
} from "../features/health/domain/services/financial_health.service";
import {
    AccountBalanceTotals,
    CategoryLimitOutcome,
    IHealthRepository,
    MonthlyTotals,
} from "../features/health/domain/repositories/health.repository";

/** 10/09/2026, 12:00 em São Paulo — bem longe de qualquer borda de mês. */
const NOW = new Date("2026-09-10T15:00:00.000Z");

interface Fixture {
    /** Saldos por chave de dia (`toDateKey`). A chave "*" é o padrão. */
    balances: Record<string, Partial<AccountBalanceTotals>>;
    months: Record<string, MonthlyTotals>;
    limits: Record<string, CategoryLimitOutcome[]>;
}

function makeRepository(fixture: Partial<Fixture>) {
    const balances = fixture.balances ?? {};
    const months = fixture.months ?? {};
    const limits = fixture.limits ?? {};

    const saved: FinancialHealthSnapshot[] = [];
    const history: FinancialHealthSnapshot[] = [];
    let current: FinancialHealthSnapshot | null = null;

    const repository: IHealthRepository = {
        getAccountBalanceTotals: jest.fn(async (_w: string, dateKey: string) => {
            const raw = balances[dateKey] ?? balances["*"] ?? {};
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
        getCategoryLimitOutcomes: jest.fn(async (_w: string, monthKey: string) => {
            return limits[monthKey] ?? [];
        }),
        saveCurrent: jest.fn(async (_w: string, snapshot: FinancialHealthSnapshot) => {
            saved.push(snapshot);
            current = snapshot;
        }),
        saveHistory: jest.fn(async (_w: string, snapshot: FinancialHealthSnapshot) => {
            history.push(snapshot);
        }),
        getCurrent: jest.fn(async () => current),
        markDirty: jest.fn(async () => undefined),
        clearDirty: jest.fn(async () => undefined),
    };

    const setCurrent = (snapshot: FinancialHealthSnapshot | null) => {
        current = snapshot;
    };

    return { repository, saved, history, setCurrent };
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
                // Fim de agosto: devia R$ 10.000 — a dívida CRESCEU.
                "2026-08-31": { liquid: 0, debt: -10000, hasDebtAccounts: true, hasAnyAccount: true },
            },
            months: {
                "2026-09": { income: 5000, expense: 6000 },
                "2026-08": { income: 5000, expense: 6000 },
                "2026-07": { income: 5000, expense: 6000 },
                "2026-06": { income: 5000, expense: 6000 },
            },
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
        expect(snapshot.components.alivio.score).toBe(0);
        expect(snapshot.score).toBe(0);
        expect(snapshot.tier).toBe(FinancialHealthTier.aprendiz);
        expect(snapshot.monthKey).toBe("2026-09");
    });

    it("EQUILIBRADO: três meses de reserva, poupando 15%, metade dos limites em dia — Estrategista", async () => {
        const { repository } = makeRepository({
            balances: {
                "2026-09-10": { liquid: 12000, debt: -2000, hasDebtAccounts: true, hasAnyAccount: true },
                // Dívida estável (dentro da faixa morta): componente vale 50.
                "2026-08-31": { liquid: 11000, debt: -2000, hasDebtAccounts: true, hasAnyAccount: true },
            },
            months: {
                "2026-09": { income: 8000, expense: 6800 },
                "2026-08": { income: 8000, expense: 4000 },
                "2026-07": { income: 8000, expense: 4000 },
                "2026-06": { income: 8000, expense: 4000 },
            },
            limits: {
                "2026-08": [
                    { categoryId: "mercado", limit: 1200, actual: 1100 },
                    { categoryId: "lazer", limit: 400, actual: 700 },
                ],
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        // 12.000 / 4.000 = 3 meses => 50.
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
            balances: {
                "*": { liquid: 60000, debt: 0, hasDebtAccounts: false, hasAnyAccount: true },
            },
            months: {
                "2026-09": { income: 10000, expense: 6000 },
                "2026-08": { income: 10000, expense: 5000 },
                "2026-07": { income: 10000, expense: 5000 },
                "2026-06": { income: 10000, expense: 5000 },
            },
            limits: {
                "2026-08": [
                    { categoryId: "mercado", limit: 1500, actual: 1200 },
                    { categoryId: "lazer", limit: 600, actual: 600 },
                ],
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        // 60.000 / 5.000 = 12 meses, acima do alvo de 6 => 100.
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
    });
});

describe("Bússola da Liberdade — janelas de tempo", () => {
    it("a Poupança recua para o mês anterior quando o corrente ainda não tem receita", async () => {
        // Todo dia 1 o mês corrente está vazio. Sem o recuo, a virada de mês
        // derrubaria o placar de todo mundo sozinha.
        const { repository } = makeRepository({
            balances: { "*": { liquid: 1000, hasAnyAccount: true } },
            months: {
                "2026-09": { income: 0, expense: 0 },
                "2026-08": { income: 10000, expense: 7000 },
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(snapshot.components.poupanca.rate).toBeCloseTo(0.3, 6);
        expect(snapshot.components.poupanca.score).toBe(100);
    });

    it("o Fôlego ignora o mês corrente (senão a reserva pareceria infinita todo dia 1)", async () => {
        const { repository } = makeRepository({
            balances: { "*": { liquid: 9000, hasAnyAccount: true } },
            months: {
                // Mês corrente com gasto ABSURDO: não pode entrar na média.
                "2026-09": { income: 1, expense: 999999 },
                "2026-08": { income: 0, expense: 3000 },
                "2026-07": { income: 0, expense: 3000 },
                "2026-06": { income: 0, expense: 3000 },
            },
        });

        const snapshot = await new FinancialHealthService(repository).computeHealth("w", NOW);

        expect(snapshot.components.folego.months).toBeCloseTo(3, 6);
    });

    it("a Disciplina julga o mês ANTERIOR, nunca o corrente", async () => {
        const { repository } = makeRepository({
            balances: { "*": { hasAnyAccount: true } },
        });

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

describe("Bússola da Liberdade — persistência e debounce", () => {
    const fixture = {
        balances: { "*": { liquid: 6000, hasAnyAccount: true } },
        months: {
            "2026-08": { income: 5000, expense: 1000 },
            "2026-07": { income: 5000, expense: 1000 },
            "2026-06": { income: 5000, expense: 1000 },
        },
    };

    it("grava o retrato corrente E o histórico do mês", async () => {
        const { repository, saved, history } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        const snapshot = await service.refreshHealth("w", NOW);

        expect(saved).toHaveLength(1);
        expect(history).toHaveLength(1);
        expect(history[0].monthKey).toBe("2026-09");
        expect(history[0]).toEqual(snapshot);
    });

    it("o recálculo é determinístico: duas passadas com o mesmo `now` dão o mesmo número", async () => {
        const { repository } = makeRepository(fixture);
        const service = new FinancialHealthService(repository);

        const first = await service.computeHealth("w", NOW);
        const second = await service.computeHealth("w", NOW);

        expect(second).toEqual(first);
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

        // 01/09/2026 03:30 em São Paulo — o horário do cron mensal.
        const dayOne = new Date("2026-09-01T06:30:00.000Z");
        await service.closeMonth("w", dayOne);

        expect(history.map((h) => h.monthKey)).toEqual(["2026-08", "2026-09"]);
        // O retrato CORRENTE nunca fica apontando para o mês que acabou.
        expect(saved).toHaveLength(1);
        expect(saved[0].monthKey).toBe("2026-09");
    });

    it("marcar como sujo nunca lança para quem chama", async () => {
        const { repository } = makeRepository(fixture);
        (repository.markDirty as jest.Mock).mockRejectedValue(new Error("firestore fora do ar"));

        // O carimbo vive dentro do gatilho de parcela: se ele derrubasse o
        // handler, uma falha da Bússola desfaria um pagamento.
        await expect(new FinancialHealthService(repository).markHealthDirty("w")).resolves.toBeUndefined();
    });
});
