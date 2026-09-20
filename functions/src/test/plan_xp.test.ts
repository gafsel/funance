/**
 * F2.3 — O XP QUE PREMIA PLANEJAR.
 *
 * Três frentes, testadas aqui:
 *
 *  1. o cron semanal paga por categoria dentro do limite, dá bônus de semana
 *     redonda e mantém uma streak que ZERA quando o plano estoura;
 *  2. limite e recorrência rendem XP UMA VEZ por categoria — recriar não paga
 *     de novo;
 *  3. a parcela que nasce paga carimba `unplannedReason`, para o app poder
 *     explicar o zero em vez de deixá-lo mudo.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança
// via ai.service, mas nada aqui exercita IA.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    GamificationService,
    XP_SOURCES,
    XP_VALUES,
    BADGES,
} from "../features/goal/domain/services/gamification.service";
import { readWorkspaceStreaks } from "../features/goal/domain/repositories/gamification.repository";
import {
    UnplannedReason,
    resolveUnplannedReason,
} from "../features/finance/domain/models/finance.models";
import { buildBadgeCatalog } from "../features/goal/domain/services/badge_catalog.service";
import { getWeekId } from "../core/utils/week.utils";

/** Domingo, 06/09/2026 00:05 em São Paulo — o horário do cron semanal. */
const SUNDAY_CRON = new Date("2026-09-06T03:05:00.000Z");
/**
 * O horário ANTIGO do cron (segunda, 07/09/2026 03:00 em São Paulo). Continua
 * aqui para provar que a mudança de agendamento não mexeu na JANELA: os dois
 * instantes caem na mesma semana corrente e fecham a mesma semana anterior.
 */
const OLD_MONDAY_CRON = new Date("2026-09-07T06:00:00.000Z");
/** A semana AVALIADA é a anterior: domingo 30/08 a sábado 05/09. */
const EVALUATED_WEEK = "2026-W35";

/** Escritas na barra semanal (`weekly_xp`) capturadas pelo writer injetado. */
function makeWeeklyXp() {
    const calls: Array<{ workspaceId: string, date: Date, xp: number }> = [];
    const writer = jest.fn(async (workspaceId: string, date: Date, xp: number) => {
        calls.push({ workspaceId, date, xp });
    });
    return { calls, writer, total: () => calls.reduce((sum, c) => sum + c.xp, 0) };
}

function makeRepository(overrides: Record<string, any> = {}) {
    return {
        getWorkspaceById: jest.fn().mockResolvedValue({ weeklyStreaks: 0, streaks: { missions: 0, plan: 0 } }),
        addXp: jest.fn().mockResolvedValue(undefined),
        unlockBadge: jest.fn().mockResolvedValue(true),
        getWeeklySummaryRows: jest.fn().mockResolvedValue([]),
        updateWorkspaceStreaks: jest.fn().mockResolvedValue(undefined),
        awardXpOnce: jest.fn().mockResolvedValue(true),
        ...overrides,
    } as any;
}

function row(categoryId: string, planned: number, actual: number, extra: Record<string, any> = {}) {
    return {
        categoryId,
        type: "expense",
        isSystem: false,
        generalPlannedAmount: planned,
        actualAmount: actual,
        ...extra,
    };
}

/** XP total concedido em todas as chamadas de `addXp`. */
function totalXp(repository: any): number {
    return repository.addXp.mock.calls.reduce((sum: number, call: any[]) => sum + call[1], 0);
}

describe("XP semanal — categorias dentro do limite", () => {
    it("paga 20 XP por categoria dentro do limite e não paga pelas estouradas", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([
                row("mercado", 300, 250),
                row("lazer", 100, 180),
                row("transporte", 200, 200),
            ]),
        });
        const service = new GamificationService(repository);

        await service.evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(repository.getWeeklySummaryRows).toHaveBeenCalledWith("w", EVALUATED_WEEK);
        // Duas dentro (mercado e transporte, esta gastando EXATAMENTE o limite).
        expect(totalXp(repository)).toBe(2 * XP_VALUES.weeklyCategoryWithinLimit);
        // Uma estourou: sem bônus de semana redonda e a streak zera.
        expect(repository.updateWorkspaceStreaks).not.toHaveBeenCalled();
    });

    it("fecha a MESMA semana no domingo 00:05 e no antigo horário de segunda 03:00", async () => {
        // A janela sai de `startOfWeekInTz(now) - 7 dias`, não do relógio: o
        // cron mudou de dia/hora sem mudar a semana que ele encerra.
        const domingo = makeRepository();
        const segunda = makeRepository();

        await new GamificationService(domingo).evaluateWeeklyPlanXp("w", SUNDAY_CRON);
        await new GamificationService(segunda).evaluateWeeklyPlanXp("w", OLD_MONDAY_CRON);

        expect(domingo.getWeeklySummaryRows).toHaveBeenCalledWith("w", EVALUATED_WEEK);
        expect(segunda.getWeeklySummaryRows).toHaveBeenCalledWith("w", EVALUATED_WEEK);
    });

    it("gastar EXATAMENTE o planejado conta como dentro do limite", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([row("mercado", 300, 300)]),
        });

        await new GamificationService(repository).evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        // 20 (dentro) + 50 (todas) + 10 (streak 1).
        expect(totalXp(repository)).toBe(
            XP_VALUES.weeklyCategoryWithinLimit +
            XP_VALUES.weeklyAllWithinLimit +
            XP_VALUES.weeklyPlanStreakStep
        );
    });

    it("dá o bônus de semana redonda quando TODAS fecham dentro", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([
                row("mercado", 300, 250),
                row("lazer", 100, 80),
            ]),
            getWorkspaceById: jest.fn().mockResolvedValue({ weeklyStreaks: 2, streaks: { missions: 2, plan: 3 } }),
        });
        const weekly = makeWeeklyXp();

        await new GamificationService(repository, undefined, undefined, weekly.writer)
            .evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        // 2×20 + 50 + 10×4 (a streak sobe de 3 para 4).
        expect(totalXp(repository)).toBe(40 + 50 + 40);
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w", { plan: 4 });

        // O MESMO XP entra na barra da semana AVALIADA, não na corrente: o
        // mérito é daquela semana e é nela que a barra histórica o mostra.
        expect(weekly.total()).toBe(130);
        expect(getWeekId(weekly.calls[0].date)).toBe(EVALUATED_WEEK);
    });

    it("o bônus de streak tem teto de 100 XP", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([row("mercado", 300, 250)]),
            // Streak alta: 10×30 seria 300, mas o teto é 100.
            getWorkspaceById: jest.fn().mockResolvedValue({ weeklyStreaks: 0, streaks: { missions: 0, plan: 29 } }),
        });

        const weekly = makeWeeklyXp();
        await new GamificationService(repository, undefined, undefined, weekly.writer)
            .evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(totalXp(repository)).toBe(20 + 50 + XP_VALUES.weeklyPlanStreakCap);
        expect(weekly.total()).toBe(20 + 50 + XP_VALUES.weeklyPlanStreakCap);
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w", { plan: 30 });
    });

    it("estourar UM limite zera a streak de plano", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([
                row("mercado", 300, 250),
                row("lazer", 100, 400),
            ]),
            getWorkspaceById: jest.fn().mockResolvedValue({ weeklyStreaks: 5, streaks: { missions: 5, plan: 7 } }),
        });

        await new GamificationService(repository).evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w", { plan: 0 });
        // O XP da categoria que se manteve continua sendo pago: a semana não
        // foi redonda, mas a categoria em dia foi mérito.
        expect(totalXp(repository)).toBe(XP_VALUES.weeklyCategoryWithinLimit);
    });

    it("sem nenhuma categoria com limite: nada de XP e a streak zera", async () => {
        // "Semanas dentro do plano" pressupõe um plano. Apagar os limites não
        // pode ser uma forma de congelar a sequência.
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([row("mercado", 0, 250)]),
            getWorkspaceById: jest.fn().mockResolvedValue({ weeklyStreaks: 0, streaks: { missions: 0, plan: 6 } }),
        });

        await new GamificationService(repository).evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(repository.addXp).not.toHaveBeenCalled();
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w", { plan: 0 });
    });

    it("ignora categorias de sistema e de receita", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([
                row("initial-balance", 500, 100, { isSystem: true }),
                row("salario", 5000, 100, { type: "income" }),
                row("mercado", 300, 250),
            ]),
        });

        await new GamificationService(repository).evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        // Só `mercado` conta: 20 + 50 (todas) + 10 (streak 1).
        expect(totalXp(repository)).toBe(80);
    });

    it("é idempotente: a segunda execução do cron não paga de novo", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([row("mercado", 300, 250)]),
        });

        // Idempotência real: o primeiro `runIdempotency` roda a ação, o
        // segundo (mesma chave) sai sem executar nada.
        const claimed = new Set<string>();
        const idempotency = {
            runIdempotency: jest.fn(async (eventId: string, action: string, fn: () => Promise<any>) => {
                const key = `${eventId}_${action}`;
                if (claimed.has(key)) return;
                claimed.add(key);
                return fn();
            }),
        };

        const service = new GamificationService(repository, undefined, idempotency as any);
        await service.evaluateWeeklyPlanXp("w", SUNDAY_CRON);
        await service.evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(repository.addXp).toHaveBeenCalledTimes(1);
        expect(idempotency.runIdempotency)
            .toHaveBeenCalledWith(`w_${EVALUATED_WEEK}`, "weeklyPlanXp", expect.any(Function));
    });

    it("um workspace inexistente não gera XP nem escrita de streak", async () => {
        const repository = makeRepository({
            getWeeklySummaryRows: jest.fn().mockResolvedValue([row("mercado", 300, 250)]),
            getWorkspaceById: jest.fn().mockResolvedValue(null),
        });

        await new GamificationService(repository).evaluateWeeklyPlanXp("w", SUNDAY_CRON);

        expect(repository.addXp).not.toHaveBeenCalled();
        expect(repository.updateWorkspaceStreaks).not.toHaveBeenCalled();
    });
});

describe("streaks — campo novo, `weeklyStreaks` continua NÚMERO", () => {
    it("lê o `weeklyStreaks` legado como sequência de missões, sem perder nada", () => {
        expect(readWorkspaceStreaks({ weeklyStreaks: 4 })).toEqual({ missions: 4, plan: 0 });
    });

    it("prefere o mapa `streaks` quando ele existe", () => {
        expect(readWorkspaceStreaks({ streaks: { missions: 3, plan: 2 }, weeklyStreaks: 3 }))
            .toEqual({ missions: 3, plan: 2 });
    });

    it("tolera chaves ausentes, tipos errados e workspace vazio", () => {
        expect(readWorkspaceStreaks({ streaks: { plan: 2 } })).toEqual({ missions: 0, plan: 2 });
        expect(readWorkspaceStreaks({ streaks: { missions: "x", plan: null } })).toEqual({ missions: 0, plan: 0 });
        expect(readWorkspaceStreaks({})).toEqual({ missions: 0, plan: 0 });
        expect(readWorkspaceStreaks(undefined)).toEqual({ missions: 0, plan: 0 });
        expect(readWorkspaceStreaks({ weeklyStreaks: -7 })).toEqual({ missions: 0, plan: 0 });
    });
});

describe("XP único por categoria", () => {
    it("concede 30 XP ao criar o limite de uma categoria, com marcador", async () => {
        const repository = makeRepository();
        const weekly = makeWeeklyXp();
        const service = new GamificationService(repository, undefined, undefined, weekly.writer);

        await service.awardPlanningCreationXp("w", { amount: 500, category: { id: "mercado" } }, SUNDAY_CRON);

        expect(repository.awardXpOnce).toHaveBeenCalledWith(
            "w", "planning", "mercado", XP_VALUES.planningCreated, expect.any(String)
        );
        // Também na barra da semana CORRENTE — o limite foi criado agora.
        expect(weekly.total()).toBe(XP_VALUES.planningCreated);
        expect(getWeekId(weekly.calls[0].date)).toBe(getWeekId(SUNDAY_CRON));
    });

    it("a barra semanal NÃO é creditada quando o XP único não saiu", async () => {
        // Quem decide é a transação do repositório. Creditar a semana mesmo
        // assim faria a segunda criação do mesmo limite inflar a barra sem
        // inflar o total do workspace.
        const repository = makeRepository({ awardXpOnce: jest.fn().mockResolvedValue(false) });
        const weekly = makeWeeklyXp();
        const service = new GamificationService(repository, undefined, undefined, weekly.writer);

        expect(await service.awardPlanningCreationXp("w", { amount: 500, category: { id: "mercado" } })).toBe(false);
        expect(weekly.writer).not.toHaveBeenCalled();
    });

    it("uma falha na barra semanal não desfaz o XP já concedido", async () => {
        // O total do workspace é a fonte da verdade (é ele que move o nível);
        // a barra é apresentação.
        const repository = makeRepository();
        const writer = jest.fn().mockRejectedValue(new Error("weekly_xp fora do ar"));
        const service = new GamificationService(repository, undefined, undefined, writer);

        await expect(
            service.awardPlanningCreationXp("w", { amount: 500, category: { id: "mercado" } })
        ).resolves.toBe(true);
    });

    it("a segunda criação do mesmo limite não paga de novo", async () => {
        // A unicidade vive no repositório (marcador + XP na mesma transação);
        // aqui provamos que o serviço respeita o veredito dele.
        const repository = makeRepository({
            awardXpOnce: jest.fn()
                .mockResolvedValueOnce(true)
                .mockResolvedValueOnce(false),
        });
        const service = new GamificationService(repository);
        const planning = { amount: 500, category: { id: "mercado" } };

        expect(await service.awardPlanningCreationXp("w", planning)).toBe(true);
        expect(await service.awardPlanningCreationXp("w", planning)).toBe(false);
    });

    it("limite zerado, categoria sem id e categoria de sistema não pagam nada", async () => {
        const repository = makeRepository();
        const service = new GamificationService(repository);

        // Zerar o limite é DESLIGAR o planejamento, não criar um.
        expect(await service.awardPlanningCreationXp("w", { amount: 0, category: { id: "mercado" } })).toBe(false);
        expect(await service.awardPlanningCreationXp("w", { amount: 500, category: { id: "" } })).toBe(false);
        expect(await service.awardPlanningCreationXp("w", { amount: 500 })).toBe(false);
        expect(await service.awardPlanningCreationXp("w", { amount: 500, category: { id: "initial-balance" } })).toBe(false);
        expect(await service.awardPlanningCreationXp("w", null)).toBe(false);

        expect(repository.awardXpOnce).not.toHaveBeenCalled();
    });

    it("concede 30 XP na primeira recorrência de uma categoria", async () => {
        const repository = makeRepository();
        const service = new GamificationService(repository);

        await service.awardRecurringCreationXp("w", {
            installmentType: "recurring",
            status: "active",
            category: { id: "aluguel" },
        });

        expect(repository.awardXpOnce).toHaveBeenCalledWith(
            "w", "recurring", "aluguel", XP_VALUES.recurringCreated, expect.any(String)
        );
    });

    it("order avulsa, parcelada, fatura, cancelada ou de sistema não paga recorrência", async () => {
        const repository = makeRepository();
        const service = new GamificationService(repository);
        const base = { installmentType: "recurring", status: "active", category: { id: "aluguel" } };

        expect(await service.awardRecurringCreationXp("w", { ...base, installmentType: "single" })).toBe(false);
        expect(await service.awardRecurringCreationXp("w", { ...base, installmentType: "installment" })).toBe(false);
        // Fatura de cartão é criada pelo SERVIDOR: premiar seria dar XP por ter cartão.
        expect(await service.awardRecurringCreationXp("w", { ...base, isInvoice: true })).toBe(false);
        expect(await service.awardRecurringCreationXp("w", { ...base, status: "cancelled" })).toBe(false);
        expect(await service.awardRecurringCreationXp("w", {
            ...base, category: { id: "virtual_debt_expense" },
        })).toBe(false);

        expect(repository.awardXpOnce).not.toHaveBeenCalled();
    });
});

describe("unplannedReason — a punição deixa de ser muda", () => {
    it("a parcela que nasce paga (planejado zero) recebe born_paid", () => {
        expect(resolveUnplannedReason({ amount: 0 })).toBe(UnplannedReason.bornPaid);
        expect(UnplannedReason.bornPaid).toBe("born_paid");
    });

    it("a parcela planejada não recebe motivo nenhum", () => {
        expect(resolveUnplannedReason({ amount: 150 })).toBeNull();
    });

    it("a FATURA fica de fora, mesmo com planejado zero", () => {
        // O valor da fatura é a soma das compras do ciclo, mantida pelo
        // servidor — não um planejamento que o usuário deixou de fazer.
        expect(resolveUnplannedReason({ amount: 0, isInvoice: true })).toBeNull();
    });
});

describe("Catálogo de XP publicado em config/badges", () => {
    it("publica a tabela de fontes de XP em pt e en", () => {
        const catalog = buildBadgeCatalog();

        expect(catalog.xpSources.length).toBe(XP_SOURCES.length);
        for (const source of catalog.xpSources) {
            expect(source.id.length).toBeGreaterThan(0);
            expect(source.name.pt.length).toBeGreaterThan(0);
            expect(source.name.en.length).toBeGreaterThan(0);
            expect(source.description.pt.length).toBeGreaterThan(0);
            expect(source.description.en.length).toBeGreaterThan(0);
            expect(source.xp).toBeGreaterThan(0);
        }
    });

    it("as fontes de XP entram no hash da versão", () => {
        // Sem isso, mudar quanto vale uma semana dentro do plano não
        // republicaria o catálogo e o app mostraria a tabela velha.
        const catalog = buildBadgeCatalog();
        expect(catalog.version).toHaveLength(16);

        const semFontes = JSON.stringify({
            badges: catalog.badges,
            levelThresholds: catalog.levelThresholds,
        });
        const comFontes = JSON.stringify({
            badges: catalog.badges,
            levelThresholds: catalog.levelThresholds,
            xpSources: catalog.xpSources,
        });
        expect(semFontes).not.toBe(comFontes);
    });

    it("os badges de CONTAGEM não pagam mais XP", () => {
        const zerados = [
            "five_accounts", "two_accounts", "three_accounts",
            "round_number", "workspace_one_year",
            "five_transactions", "twenty_transactions", "fifty_transactions", "hundred_transactions",
            "five_categories", "ten_categories", "three_categories_month", "five_categories_month",
            "first_category", "first_income", "first_expense", "first_transfer", "first_month",
            // Segunda rodada (QA): o que sobrou de contagem pura.
            "reconcile_five", "five_active_goals", "two_active_goals",
            "two_months_active", "small_transactions_ten", "big_transaction",
        ];

        for (const id of zerados) {
            expect(BADGES[id]).toBeDefined();
            expect(BADGES[id].xpReward).toBe(0);
        }
    });

    it("os badges de CONQUISTA continuam pagando XP", () => {
        // O corte foi na contagem, não no mérito: conciliar, fechar o mês sob
        // controle e concluir metas continuam valendo.
        for (const id of ["under_control", "golden_rule", "planner", "iron_consistency", "goal_bronze"]) {
            expect(BADGES[id].xpReward).toBeGreaterThan(0);
        }
    });
});
