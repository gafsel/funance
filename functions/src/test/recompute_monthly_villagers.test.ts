/**
 * `recompute_monthly_villagers` — a primeira passada do HUD mensal.
 *
 * O que os testes fixam:
 *
 *  - DRY-RUN não escreve nada, mas relata exatamente o que gravaria (ele roda
 *    o MESMO cálculo do `--apply`);
 *  - `--apply` grava o retrato, concede o XP e publica a receita prevista;
 *  - o mês default é o ANTERIOR a hoje, e `--month` manda quando existe;
 *  - um workspace que lança não derruba os demais;
 *  - `--villagers-only` pula a publicação da receita.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este script.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import { recomputeMonthlyVillagers } from "../scripts/recompute_monthly_villagers";

/** 20/09/2026 12:00 em São Paulo — o mês anterior é agosto. */
const NOW = new Date("2026-09-20T15:00:00.000Z");
const LAST_MONTH = "2026-08";

const silent = () => undefined;

/**
 * Firestore de mentira: a varredura devolve `ids`, e `doc(id).get()` responde
 * `exists` conforme o id esteja na lista — é o que o script consulta quando
 * recebe `--workspace`.
 */
function firestoreWithWorkspaces(ids: string[]) {
    return {
        collection: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({ docs: ids.map((id) => ({ id })) }),
            }),
            doc: jest.fn((id: string) => ({
                get: jest.fn().mockResolvedValue({ id, exists: ids.includes(id) }),
            })),
        }),
    } as any;
}

function row(categoryId: string, plannedCents: number, actualCents: number, extra: Record<string, any> = {}) {
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

/** Aldeia do pacote: 4 categorias, 3 dentro e 1 fora; a soma fecha dentro. */
const ALDEIA = [
    row("mercado", 100_000, 90_000),
    row("transporte", 30_000, 30_000),
    row("lazer", 20_000, 5_000),
    row("delivery", 10_000, 25_000),
];

function makeGamificationRepository(rowsByWorkspace: Record<string, any[]>, overrides: Record<string, any> = {}) {
    return {
        getWorkspaceById: jest.fn().mockResolvedValue({ xp: 0, level: 1 }),
        addXp: jest.fn().mockResolvedValue(undefined),
        getPeriodSummaries: jest.fn(async (workspaceId: string) => rowsByWorkspace[workspaceId] ?? []),
        awardXpOnce: jest.fn().mockResolvedValue(true),
        saveMonthlyReport: jest.fn().mockResolvedValue(undefined),
        getMonthlyReport: jest.fn().mockResolvedValue(null),
        ...overrides,
    } as any;
}

function makeIncomeRepository(plannedCents = 0, published: any = null) {
    return {
        getMonthlyIncomeTotals: jest.fn(async (_w: string, monthKeys: string[]) =>
            monthKeys.map((monthKey, index) => ({
                monthKey,
                exists: true,
                plannedCents: index === 0 ? plannedCents : 0,
                actualCents: 0,
            }))
        ),
        getPublishedExpectedIncome: jest.fn().mockResolvedValue(published),
        publishExpectedIncome: jest.fn().mockResolvedValue(undefined),
        clearExpectedIncome: jest.fn().mockResolvedValue(undefined),
    } as any;
}

describe("recompute_monthly_villagers (script)", () => {
    it("dry-run CALCULA e não escreve nada", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA });
        const income = makeIncomeRepository(900_000);

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            income,
            { dryRun: true, now: NOW },
            silent
        );

        expect(gamification.saveMonthlyReport).not.toHaveBeenCalled();
        expect(gamification.awardXpOnce).not.toHaveBeenCalled();
        expect(income.publishExpectedIncome).not.toHaveBeenCalled();
        // Mas o relatório já diz o que aconteceria: 45 + 100.
        expect(summary).toMatchObject({
            monthKey: LAST_MONTH,
            scanned: 1,
            withVillagers: 1,
            withoutVillagers: 0,
            xpTotal: 145,
            incomePublished: 1,
            failed: 0,
        });
    });

    it("com --apply grava o retrato, concede o XP e publica a receita", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA });
        const income = makeIncomeRepository(900_000);

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            income,
            { dryRun: false, now: NOW },
            silent
        );

        expect(gamification.saveMonthlyReport).toHaveBeenCalledWith("w1", expect.objectContaining({
            monthKey: LAST_MONTH, villagersPlanned: 4, villagersAlive: 3, villageAlive: true, xpAwarded: 145,
        }));
        expect(gamification.awardXpOnce).toHaveBeenCalledWith(
            "w1", "monthlyVillagers", LAST_MONTH, 145, expect.any(String)
        );
        expect(income.publishExpectedIncome).toHaveBeenCalledWith("w1", expect.objectContaining({
            monthKey: "2026-09", cents: 900_000, source: "planned",
        }));
        expect(summary.failed).toBe(0);
    });

    it("recalcular um mês já pago NÃO paga de novo, mas reescreve o retrato", async () => {
        // `awardXpOnce` devolve false: o marcador durável do mês já existia.
        const gamification = makeGamificationRepository({ w1: ALDEIA }, {
            awardXpOnce: jest.fn().mockResolvedValue(false),
            getMonthlyReport: jest.fn().mockResolvedValue({
                monthKey: LAST_MONTH, villagersPlanned: 4, villagersAlive: 3, villageAlive: true,
                xpAwarded: 145, computedAt: "2026-09-01T06:00:00.000Z",
            }),
        });

        await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            makeIncomeRepository(),
            { dryRun: false, now: NOW, villagersOnly: true },
            silent
        );

        expect(gamification.saveMonthlyReport).toHaveBeenCalled();
        // O retrato continua contando o que o MÊS rendeu, não o zero desta
        // execução.
        expect(gamification.saveMonthlyReport.mock.calls[0][1].xpAwarded).toBe(145);
    });

    it("o mês default é o ANTERIOR a hoje", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA });

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            makeIncomeRepository(),
            { dryRun: true, now: NOW, villagersOnly: true },
            silent
        );

        expect(summary.monthKey).toBe(LAST_MONTH);
        expect(gamification.getPeriodSummaries).toHaveBeenCalledWith("w1", 2026, 8);
    });

    it("--month manda sobre o default", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA });

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            makeIncomeRepository(),
            { dryRun: true, now: NOW, monthKey: "2026-06", villagersOnly: true },
            silent
        );

        expect(summary.monthKey).toBe("2026-06");
        expect(gamification.getPeriodSummaries).toHaveBeenCalledWith("w1", 2026, 6);
    });

    it("recusa um --month que não é YYYY-MM, antes de tocar em qualquer workspace", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA });

        await expect(
            recomputeMonthlyVillagers(
                firestoreWithWorkspaces(["w1"]),
                gamification,
                makeIncomeRepository(),
                { dryRun: true, now: NOW, monthKey: "agosto" },
                silent
            )
        ).rejects.toThrow(/--month inválido/);

        expect(gamification.getPeriodSummaries).not.toHaveBeenCalled();
    });

    it("--workspace limita a execução a um workspace (sem varrer a coleção)", async () => {
        const firestore = firestoreWithWorkspaces(["w1", "w2", "w3"]);
        const gamification = makeGamificationRepository({ w2: ALDEIA });

        const summary = await recomputeMonthlyVillagers(
            firestore,
            gamification,
            makeIncomeRepository(),
            { dryRun: true, now: NOW, workspaceId: "w2", villagersOnly: true },
            silent
        );

        // A coleção é tocada UMA vez, e só para confirmar que o workspace
        // existe — `select().get()` (a varredura) não roda.
        expect(firestore.collection().select).not.toHaveBeenCalled();
        expect(summary.scanned).toBe(1);
        expect(summary.withVillagers).toBe(1);
    });

    it("--workspace inexistente PARA com erro claro, em vez de relatar 'sem aldeia'", async () => {
        // Um dígito trocado no id produziria "nenhuma categoria orçada — sem
        // aldeia", que é um relatório plausível e uma conclusão errada.
        const gamification = makeGamificationRepository({ w1: ALDEIA });

        await expect(
            recomputeMonthlyVillagers(
                firestoreWithWorkspaces(["w1"]),
                gamification,
                makeIncomeRepository(),
                { dryRun: true, now: NOW, workspaceId: "w7", villagersOnly: true },
                silent
            )
        ).rejects.toThrow(/workspace w7 não existe/);

        expect(gamification.getPeriodSummaries).not.toHaveBeenCalled();
        expect(gamification.saveMonthlyReport).not.toHaveBeenCalled();
    });

    it("workspace sem aldeia é contado e não gera retrato", async () => {
        const gamification = makeGamificationRepository({
            w1: [row("imprevistos", 0, 500_000)],
        });

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            gamification,
            makeIncomeRepository(),
            { dryRun: false, now: NOW, villagersOnly: true },
            silent
        );

        expect(summary).toMatchObject({ withVillagers: 0, withoutVillagers: 1, xpTotal: 0 });
        expect(gamification.saveMonthlyReport).not.toHaveBeenCalled();
    });

    it("um workspace que lança não derruba os demais", async () => {
        const gamification = makeGamificationRepository({ w1: ALDEIA, w3: ALDEIA }, {
            getPeriodSummaries: jest.fn(async (workspaceId: string) => {
                if (workspaceId === "w2") throw new Error("documento corrompido");
                return ALDEIA;
            }),
        });

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1", "w2", "w3"]),
            gamification,
            makeIncomeRepository(),
            { dryRun: false, now: NOW, villagersOnly: true },
            silent
        );

        expect(summary).toMatchObject({ scanned: 3, withVillagers: 2, failed: 1 });
        expect(gamification.saveMonthlyReport).toHaveBeenCalledTimes(2);
    });

    it("--villagers-only pula a publicação da receita prevista", async () => {
        const income = makeIncomeRepository(900_000);

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            income,
            { dryRun: false, now: NOW, villagersOnly: true },
            silent
        );

        expect(income.getMonthlyIncomeTotals).not.toHaveBeenCalled();
        expect(income.publishExpectedIncome).not.toHaveBeenCalled();
        expect(summary.incomePublished).toBe(0);
    });

    it("não republica a receita quando o valor não mudou", async () => {
        const income = makeIncomeRepository(900_000, {
            monthKey: "2026-09", cents: 900_000, source: "planned", updatedAt: "2026-09-01T00:00:00.000Z",
        });

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            income,
            { dryRun: false, now: NOW },
            silent
        );

        expect(income.publishExpectedIncome).not.toHaveBeenCalled();
        expect(summary.incomePublished).toBe(0);
    });

    it("sem planejado nem histórico, não publica um zero", async () => {
        // Campo ausente é como o servidor diz "não sei quanto este workspace
        // ganha"; um zero publicado viraria poção vazia na tela.
        const income = makeIncomeRepository(0);

        const summary = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            income,
            { dryRun: false, now: NOW },
            silent
        );

        expect(income.publishExpectedIncome).not.toHaveBeenCalled();
        expect(income.clearExpectedIncome).not.toHaveBeenCalled();
        expect(summary.incomePublished).toBe(0);
    });

    it("REMOVE a previsão antiga que deixou de valer, e o dry-run avisa", async () => {
        const stale = {
            monthKey: "2026-08", cents: 500_000, source: "average", updatedAt: "2026-08-01T00:00:00.000Z",
        };
        const lines: string[] = [];

        const dry = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            makeIncomeRepository(0, stale),
            { dryRun: true, now: NOW },
            (message) => {
                lines.push(message);
            }
        );

        expect(dry.incomePublished).toBe(1);
        expect(lines.join("\n")).toContain("REMOVERIA");

        const income = makeIncomeRepository(0, stale);
        const applied = await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            income,
            { dryRun: false, now: NOW },
            silent
        );

        expect(income.clearExpectedIncome).toHaveBeenCalledWith("w1");
        expect(income.publishExpectedIncome).not.toHaveBeenCalled();
        expect(applied.incomePublished).toBe(1);
    });

    it("a receita publicada é a do mês CORRENTE, não a do mês recalculado", async () => {
        const income = makeIncomeRepository(900_000);

        await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            income,
            { dryRun: true, now: NOW, monthKey: "2026-06" },
            silent
        );

        // O HUD fala do mês em curso: recalcular junho não muda o denominador
        // de hoje.
        expect(income.getMonthlyIncomeTotals.mock.calls[0][1][0]).toBe("2026-09");
    });

    it("credita a barra semanal pelo writer injetado, e só no --apply", async () => {
        const dry = jest.fn();
        const applied = jest.fn();

        await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            makeIncomeRepository(),
            { dryRun: true, now: NOW, villagersOnly: true, weeklyXpWriter: dry },
            silent
        );
        await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            makeIncomeRepository(),
            { dryRun: false, now: NOW, villagersOnly: true, weeklyXpWriter: applied },
            silent
        );

        expect(dry).not.toHaveBeenCalled();
        // A semana creditada sai do MÊS recalculado, não do relógio de hoje.
        expect(applied).toHaveBeenCalledWith("w1", new Date("2026-09-01T02:59:59.999Z"), 145);
    });

    it("o log do dry-run diz DRY-RUN e o do apply diz APPLY", async () => {
        const lines: string[] = [];
        const log = (message: string) => {
            lines.push(message);
        };

        await recomputeMonthlyVillagers(
            firestoreWithWorkspaces(["w1"]),
            makeGamificationRepository({ w1: ALDEIA }),
            makeIncomeRepository(),
            { dryRun: true, now: NOW, villagersOnly: true },
            log
        );

        expect(lines[0]).toContain("DRY-RUN");
        expect(lines[0]).toContain(LAST_MONTH);
        expect(lines.join("\n")).toContain("GRAVARIA");
        expect(lines.join("\n")).toContain("3/4 aldeões vivos");
    });
});
