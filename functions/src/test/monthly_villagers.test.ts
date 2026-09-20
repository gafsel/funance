/**
 * HUD MENSAL — O XP DOS ALDEÕES.
 *
 * Cada categoria com orçamento no mês é um aldeão cujo HP é o orçamento que
 * sobra. Testado aqui:
 *
 *  1. a REGRA pura (`evaluateVillagers`): quem vive, quem morre, o teto de 10
 *     categorias e o mínimo de 3 aldeões da vila;
 *  2. a PENEIRA do sumário mensal: sistema, receita e "sem orçamento" não são
 *     aldeões;
 *  3. o FECHAMENTO: XP único por mês, retrato gravado, barra semanal creditada
 *     na semana do mês que acabou;
 *  4. o CATÁLOGO publicado, que é a tela "como ganhar XP" do app.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança
// via ai.service, mas nada aqui exercita IA.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    VILLAGER_ALIVE_XP,
    VILLAGER_XP_CATEGORY_CAP,
    VILLAGE_ALIVE_XP,
    VILLAGE_MIN_VILLAGERS,
    evaluateVillagers,
} from "../features/goal/domain/services/villagers";
import {
    GamificationService,
    XP_SOURCES,
    XP_VALUES,
} from "../features/goal/domain/services/gamification.service";
import { buildBadgeCatalog } from "../features/goal/domain/services/badge_catalog.service";

/** Dia 1º de setembro de 2026, 03:00 em São Paulo — o horário do cron mensal. */
const MONTHLY_CRON = new Date("2026-09-01T06:00:00.000Z");
/** O mês AVALIADO é o anterior: agosto de 2026. */
const EVALUATED_MONTH = "2026-08";

function villager(categoryId: string, plannedCents: number, actualCents: number) {
    return { categoryId, plannedCents, actualCents };
}

/** Linha do sumário mensal como o repositório a devolve. */
function row(
    categoryId: string,
    plannedCents: number,
    actualCents: number,
    extra: Record<string, any> = {}
) {
    return {
        categoryId,
        type: "expense",
        isSystem: false,
        actualAmount: actualCents / 100,
        generalPlannedAmount: plannedCents / 100,
        specificPlannedAmount: 0,
        actualAmountCents: actualCents,
        generalPlannedAmountCents: plannedCents,
        specificPlannedAmountCents: 0,
        ...extra,
    };
}

function makeRepository(rows: any[] = [], overrides: Record<string, any> = {}) {
    return {
        getWorkspaceById: jest.fn().mockResolvedValue({ xp: 0, level: 1 }),
        addXp: jest.fn().mockResolvedValue(undefined),
        unlockBadge: jest.fn().mockResolvedValue(true),
        getPeriodSummaries: jest.fn().mockResolvedValue(rows),
        awardXpOnce: jest.fn().mockResolvedValue(true),
        saveMonthlyReport: jest.fn().mockResolvedValue(undefined),
        getMonthlyReport: jest.fn().mockResolvedValue(null),
        ...overrides,
    } as any;
}

describe("evaluateVillagers — a regra da aldeia", () => {
    it("o caso do pacote: 4 categorias, 3 dentro e 1 fora -> 45 XP", async () => {
        const outcome = evaluateVillagers([
            villager("mercado", 100_000, 90_000),
            villager("transporte", 30_000, 30_000),
            villager("lazer", 20_000, 5_000),
            villager("delivery", 10_000, 25_000),
        ]);

        expect(outcome.villagersPlanned).toBe(4);
        expect(outcome.villagersAlive).toBe(3);
        expect(outcome.deadCategoryIds).toEqual(["delivery"]);
        expect(outcome.villagersXp).toBe(3 * VILLAGER_ALIVE_XP);
        expect(outcome.villagersXp).toBe(45);

        // A VILA é uma conta separada: aqui o conjunto fechou dentro
        // (R$ 1.500 realizados de R$ 1.600 planejados), então os 45 dos
        // aldeões somam os 100 da vila.
        expect(outcome.plannedCents).toBe(160_000);
        expect(outcome.actualCents).toBe(150_000);
        expect(outcome.villageAlive).toBe(true);
        expect(outcome.xpAwarded).toBe(145);
    });

    it("gastar EXATAMENTE o orçamento mantém o aldeão vivo", () => {
        const outcome = evaluateVillagers([villager("transporte", 30_000, 30_000)]);

        expect(outcome.villagersAlive).toBe(1);
        expect(outcome.deadCategoryIds).toEqual([]);
    });

    it("um aldeão a mais de 10 não paga — o teto é 150 XP", () => {
        const rows = [];
        for (let i = 0; i < 14; i++) {
            rows.push(villager(`cat-${String(i).padStart(2, "0")}`, 10_000, 1_000));
        }

        const outcome = evaluateVillagers(rows);

        expect(outcome.villagersAlive).toBe(14);
        expect(outcome.villagersXp).toBe(VILLAGER_XP_CATEGORY_CAP * VILLAGER_ALIVE_XP);
        expect(outcome.villagersXp).toBe(150);
    });

    it("a VILA sobrevive quando a soma do realizado fica dentro da soma do planejado", () => {
        // Uma categoria estourou, mas o conjunto fechou dentro: os aldeões
        // vivos pagam e a vila também.
        const outcome = evaluateVillagers([
            villager("mercado", 100_000, 60_000),
            villager("transporte", 30_000, 30_000),
            villager("delivery", 10_000, 25_000),
        ]);

        expect(outcome.plannedCents).toBe(140_000);
        expect(outcome.actualCents).toBe(115_000);
        expect(outcome.villageAlive).toBe(true);
        expect(outcome.xpAwarded).toBe(2 * VILLAGER_ALIVE_XP + VILLAGE_ALIVE_XP);
    });

    it("a VILA morre quando a soma estoura, mesmo com aldeões vivos", () => {
        const outcome = evaluateVillagers([
            villager("mercado", 100_000, 90_000),
            villager("transporte", 30_000, 20_000),
            villager("delivery", 10_000, 80_000),
        ]);

        expect(outcome.villagersAlive).toBe(2);
        expect(outcome.villageAlive).toBe(false);
        expect(outcome.villageXp).toBe(0);
        expect(outcome.xpAwarded).toBe(30);
    });

    it("com menos de 3 aldeões a vila NÃO paga, por mais redondo que seja o mês", () => {
        const outcome = evaluateVillagers([
            villager("mercado", 100_000, 10),
            villager("lazer", 20_000, 10),
        ]);

        expect(VILLAGE_MIN_VILLAGERS).toBe(3);
        expect(outcome.villageAlive).toBe(false);
        expect(outcome.xpAwarded).toBe(2 * VILLAGER_ALIVE_XP);
    });

    it("com exatamente 3 aldeões a vila paga", () => {
        const outcome = evaluateVillagers([
            villager("mercado", 100_000, 10),
            villager("lazer", 20_000, 10),
            villager("transporte", 30_000, 10),
        ]);

        expect(outcome.villageAlive).toBe(true);
        expect(outcome.xpAwarded).toBe(3 * VILLAGER_ALIVE_XP + VILLAGE_ALIVE_XP);
    });

    it("aldeia vazia não rende nada e não quebra", () => {
        const outcome = evaluateVillagers([]);

        expect(outcome).toMatchObject({
            villagersPlanned: 0, villagersAlive: 0, villageAlive: false, xpAwarded: 0,
        });
    });

    it("a ordem dos ids é ESTÁVEL, não a ordem do mapa do Firestore", () => {
        const outcome = evaluateVillagers([
            villager("zelador", 10_000, 1),
            villager("agua", 10_000, 99_000),
            villager("mercado", 10_000, 1),
        ]);

        expect(outcome.aliveCategoryIds).toEqual(["mercado", "zelador"]);
        expect(outcome.deadCategoryIds).toEqual(["agua"]);
    });

    it("soma em CENTAVOS: doze categorias não matam a vila por ruído de double", () => {
        // 12 × R$ 0,10 = R$ 1,20 exatos. Em `double`, 0.1 somado doze vezes dá
        // 1.2000000000000002 — e a vila morreria por ruído de representação.
        const rows = [];
        for (let i = 0; i < 12; i++) {
            rows.push(villager(`cat-${i}`, 10, 10));
        }

        const outcome = evaluateVillagers(rows);

        expect(outcome.plannedCents).toBe(120);
        expect(outcome.actualCents).toBe(120);
        expect(outcome.villageAlive).toBe(true);
    });
});

describe("computeMonthlyVillagers — a peneira do sumário mensal", () => {
    it("lê o sumário do mês pedido", async () => {
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);

        await new GamificationService(repository).computeMonthlyVillagers("w", EVALUATED_MONTH);

        expect(repository.getPeriodSummaries).toHaveBeenCalledWith("w", 2026, 8);
    });

    it("categoria SEM orçamento não é aldeão (e não morre)", async () => {
        const repository = makeRepository([
            row("mercado", 100_000, 10_000),
            // Gastou R$ 5.000 sem orçamento nenhum: fica "sem proteção", não
            // vira aldeão morto. O jogo não pune quem ainda não planejou.
            row("imprevistos", 0, 500_000),
        ]);

        const outcome = await new GamificationService(repository)
            .computeMonthlyVillagers("w", EVALUATED_MONTH);

        expect(outcome.villagersPlanned).toBe(1);
        expect(outcome.villagersAlive).toBe(1);
        expect(outcome.actualCents).toBe(10_000);
    });

    it("categoria de SISTEMA não é aldeão", async () => {
        const repository = makeRepository([
            row("mercado", 100_000, 10_000),
            row("initial-balance", 100_000, 900_000, { isSystem: true }),
        ]);

        const outcome = await new GamificationService(repository)
            .computeMonthlyVillagers("w", EVALUATED_MONTH);

        expect(outcome.villagersPlanned).toBe(1);
    });

    it("categoria de RECEITA não é aldeão", async () => {
        const repository = makeRepository([
            row("mercado", 100_000, 10_000),
            row("salario", 100_000, 900_000, { type: "income" }),
        ]);

        const outcome = await new GamificationService(repository)
            .computeMonthlyVillagers("w", EVALUATED_MONTH);

        expect(outcome.villagersPlanned).toBe(1);
    });

    it("recusa um monthKey que não é YYYY-MM", async () => {
        await expect(
            new GamificationService(makeRepository()).computeMonthlyVillagers("w", "2026-8")
        ).rejects.toThrow(/monthKey inválido/);
    });
});

describe("closeMonthlyVillagers — concessão e retrato", () => {
    const rows = [
        row("mercado", 100_000, 90_000),
        row("transporte", 30_000, 30_000),
        row("lazer", 20_000, 5_000),
        row("delivery", 10_000, 25_000),
    ];

    it("concede o XP UMA vez, pelo marcador durável do mês", async () => {
        const repository = makeRepository(rows);

        await new GamificationService(repository)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, new Date("2026-08-31T23:59:59.999Z"));

        expect(repository.awardXpOnce).toHaveBeenCalledTimes(1);
        const [workspaceId, group, key, xp] = repository.awardXpOnce.mock.calls[0];
        expect(workspaceId).toBe("w");
        expect(group).toBe("monthlyVillagers");
        // A chave é o MÊS: recalcular agosto amanhã não paga de novo.
        expect(key).toBe(EVALUATED_MONTH);
        // 3 aldeões vivos (45) + a vila, que fechou em 150.000 de 160.000 (100).
        expect(xp).toBe(145);
    });

    it("grava o retrato com o que o MÊS rendeu", async () => {
        const repository = makeRepository(rows);
        const now = new Date("2026-09-01T06:00:00.000Z");

        const report = await new GamificationService(repository)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, now, now);

        expect(repository.saveMonthlyReport).toHaveBeenCalledWith("w", {
            monthKey: EVALUATED_MONTH,
            villagersPlanned: 4,
            villagersAlive: 3,
            villageAlive: true,
            xpAwarded: 145,
            computedAt: now.toISOString(),
        });
        expect(report?.xpAwarded).toBe(145);
    });

    it("o retrato de um REcálculo guarda o valor do mês, não o zero concedido", async () => {
        // Segunda passada: o marcador já existe e `awardXpOnce` devolve false.
        const repository = makeRepository(rows, {
            awardXpOnce: jest.fn().mockResolvedValue(false),
        });

        const report = await new GamificationService(repository)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, MONTHLY_CRON);

        expect(report?.xpAwarded).toBe(145);
        expect(repository.saveMonthlyReport).toHaveBeenCalled();
    });

    it("grava o retrato mesmo quando TODOS os aldeões morreram", async () => {
        const repository = makeRepository([
            row("mercado", 100_000, 900_000),
            row("lazer", 20_000, 90_000),
        ]);

        const report = await new GamificationService(repository)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, MONTHLY_CRON);

        expect(report).toMatchObject({ villagersPlanned: 2, villagersAlive: 0, xpAwarded: 0 });
        expect(repository.saveMonthlyReport).toHaveBeenCalled();
        // Sem XP, sem marcador: nada foi concedido.
        expect(repository.awardXpOnce).not.toHaveBeenCalled();
    });

    it("mês SEM aldeia nenhuma não grava retrato nem concede XP", async () => {
        const repository = makeRepository([row("imprevistos", 0, 500_000)]);

        const report = await new GamificationService(repository)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, MONTHLY_CRON);

        expect(report).toBeNull();
        expect(repository.saveMonthlyReport).not.toHaveBeenCalled();
        expect(repository.awardXpOnce).not.toHaveBeenCalled();
    });

    it("credita a BARRA da semana do mês que acabou, não a da semana corrente", async () => {
        const repository = makeRepository(rows);
        const calls: Array<{ date: Date, xp: number }> = [];
        const writer = jest.fn(async (_w: string, date: Date, xp: number) => {
            calls.push({ date, xp });
        });
        // Último instante de agosto no fuso do produto.
        const monthEnd = new Date("2026-09-01T02:59:59.999Z");

        await new GamificationService(repository, undefined, undefined, writer)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, monthEnd);

        expect(calls).toHaveLength(1);
        expect(calls[0].date).toBe(monthEnd);
        expect(calls[0].xp).toBe(145);
    });

    it("não credita a barra quando o XP não saiu", async () => {
        const repository = makeRepository(rows, {
            awardXpOnce: jest.fn().mockResolvedValue(false),
        });
        const writer = jest.fn();

        await new GamificationService(repository, undefined, undefined, writer)
            .closeMonthlyVillagers("w", EVALUATED_MONTH, MONTHLY_CRON);

        expect(writer).not.toHaveBeenCalled();
    });
});

describe("evaluateMonthlyVillagersXp — a janela e a idempotência do cron", () => {
    it("avalia o mês ANTERIOR ao instante do cron", async () => {
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);

        await new GamificationService(repository).evaluateMonthlyVillagersXp("w", MONTHLY_CRON);

        expect(repository.getPeriodSummaries).toHaveBeenCalledWith("w", 2026, 8);
    });

    it("dia 1º às 00:30 de Brasília ainda fecha o mês anterior", async () => {
        // 01/09/2026 00:30 local = 03:30Z. A janela sai do fuso do PRODUTO.
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);

        await new GamificationService(repository)
            .evaluateMonthlyVillagersXp("w", new Date("2026-09-01T03:30:00.000Z"));

        expect(repository.getPeriodSummaries).toHaveBeenCalledWith("w", 2026, 8);
    });

    it("vira o ANO corretamente (janeiro fecha dezembro)", async () => {
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);

        await new GamificationService(repository)
            .evaluateMonthlyVillagersXp("w", new Date("2027-01-01T06:00:00.000Z"));

        expect(repository.getPeriodSummaries).toHaveBeenCalledWith("w", 2026, 12);
    });

    it("usa a chave de idempotência workspace_mês com a ação monthlyVillagersXp", async () => {
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);
        const runIdempotency = jest.fn(async (_key: string, _action: string, fn: () => Promise<void>) => {
            await fn();
        });

        await new GamificationService(repository, undefined, { runIdempotency } as any)
            .evaluateMonthlyVillagersXp("w", MONTHLY_CRON);

        expect(runIdempotency).toHaveBeenCalledWith(
            `w_${EVALUATED_MONTH}`,
            "monthlyVillagersXp",
            expect.any(Function)
        );
    });

    it("uma reexecução barrada pela idempotência não toca em nada", async () => {
        const repository = makeRepository([row("mercado", 100_000, 10_000)]);
        // Marcador já gravado: a ação nem roda.
        const runIdempotency = jest.fn(async () => undefined);

        await new GamificationService(repository, undefined, { runIdempotency } as any)
            .evaluateMonthlyVillagersXp("w", MONTHLY_CRON);

        expect(repository.getPeriodSummaries).not.toHaveBeenCalled();
        expect(repository.awardXpOnce).not.toHaveBeenCalled();
        expect(repository.saveMonthlyReport).not.toHaveBeenCalled();
    });
});

describe("catálogo publicado (config/badges.xpSources)", () => {
    const catalog = buildBadgeCatalog();
    const byId = new Map(catalog.xpSources.map((s) => [s.id, s]));

    it("publica Aldeão protegido e Vila protegida, em pt e en", () => {
        expect(byId.get("villager_alive")).toMatchObject({
            name: { pt: "Aldeão protegido", en: "Villager protected" },
            xp: VILLAGER_ALIVE_XP,
            audience: "both",
        });
        expect(byId.get("village_alive")).toMatchObject({
            name: { pt: "Vila protegida", en: "Village protected" },
            xp: VILLAGE_ALIVE_XP,
            audience: "both",
        });
    });

    it("a descrição revela os tetos que o número sozinho esconde", () => {
        expect(byId.get("villager_alive")!.description.pt).toContain(String(VILLAGER_XP_CATEGORY_CAP));
        expect(byId.get("villager_alive")!.description.en).toContain(String(VILLAGER_XP_CATEGORY_CAP));
        expect(byId.get("village_alive")!.description.pt).toContain(String(VILLAGE_MIN_VILLAGERS));
        expect(byId.get("village_alive")!.description.en).toContain(String(VILLAGE_MIN_VILLAGERS));
    });

    it("toda fonte de XP tem os dois idiomas e uma audiência", () => {
        for (const source of catalog.xpSources) {
            expect(source.name.pt).toBeTruthy();
            expect(source.name.en).toBeTruthy();
            expect(source.description.pt).toBeTruthy();
            expect(source.description.en).toBeTruthy();
            expect(source.audience).toBeTruthy();
        }
    });

    it("os valores publicados são os mesmos que o cron concede", () => {
        expect(XP_VALUES.villagerAlive).toBe(VILLAGER_ALIVE_XP);
        expect(XP_VALUES.villageAlive).toBe(VILLAGE_ALIVE_XP);
        expect(XP_SOURCES.find((s) => s.id === "villager_alive")?.xp).toBe(XP_VALUES.villagerAlive);
        expect(XP_SOURCES.find((s) => s.id === "village_alive")?.xp).toBe(XP_VALUES.villageAlive);
    });

    it("ids de fonte de XP não se repetem", () => {
        expect(byId.size).toBe(catalog.xpSources.length);
    });
});
