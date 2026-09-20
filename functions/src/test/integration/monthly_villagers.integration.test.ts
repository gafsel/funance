/**
 * HUD MENSAL — os aldeões e a receita prevista, contra o Firestore de verdade.
 *
 * Os unitários provam as REGRAS; aqui provamos o que só o banco prova:
 *
 *  - o cron mensal lê o `period_summaries/{YYYY-MM}` de verdade, faz o join em
 *    `categories` e concede o XP certo;
 *  - o pagamento é único por MÊS, pelo marcador durável
 *    `xpAwardedFor.monthlyVillagers.<monthKey>` — inclusive quando duas
 *    execuções disputam o mesmo documento;
 *  - o retrato vai parar em `monthly_reports/{YYYY-MM}`;
 *  - a receita prevista sai do sumário real (planejado e, na falta dele, a
 *    média de três meses) e é PUBLICADA no documento do workspace.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { GamificationRepositoryImpl } from "../../features/goal/data/repositories/gamification.repository.impl";
import { GamificationService } from "../../features/goal/domain/services/gamification.service";
import { ExpectedIncomeRepositoryImpl } from "../../features/finance/data/repositories/expected_income.repository.impl";
import { ExpectedIncomeService } from "../../features/finance/domain/services/expected_income.service";
import { VILLAGER_ALIVE_XP, VILLAGE_ALIVE_XP } from "../../features/goal/domain/services/villagers";
import { getWeekId } from "../../core/utils/week.utils";

/** Dia 1º de setembro de 2026, 03:00 em São Paulo — o horário do cron mensal. */
const MONTHLY_CRON = new Date("2026-09-01T06:00:00.000Z");
/** O mês AVALIADO é o anterior. */
const EVALUATED_MONTH = "2026-08";

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-aldeoes-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function seedWorkspace(workspaceId: string, extra: Record<string, any> = {}): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}`).set({
        name: "Casa", type: "personal", members: ["uid"], xp: 0, level: 1, ...extra,
    });
}

async function seedCategory(
    workspaceId: string,
    categoryId: string,
    type: "income" | "expense",
    extra: Record<string, any> = {}
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/categories/${categoryId}`).set({
        name: categoryId, icon: "label", color: "#000", type, isDeleted: false, ...extra,
    });
}

/**
 * Sumário MENSAL com os totais em centavos — o formato pós-migração (F1.10),
 * em que o inteiro é a fonte da verdade.
 */
async function seedMonthlySummary(
    workspaceId: string,
    monthKey: string,
    categories: Record<string, { plannedCents?: number, specificCents?: number, actualCents?: number }>
): Promise<void> {
    const [year, month] = monthKey.split("-").map(Number);
    const payload: Record<string, any> = {};

    for (const [categoryId, values] of Object.entries(categories)) {
        const planned = values.plannedCents ?? 0;
        const specific = values.specificCents ?? 0;
        const actual = values.actualCents ?? 0;
        payload[categoryId] = {
            generalPlannedAmount: planned / 100,
            specificPlannedAmount: specific / 100,
            actualAmount: actual / 100,
            generalPlannedAmountCents: planned,
            specificPlannedAmountCents: specific,
            actualAmountCents: actual,
        };
    }

    await firestore.doc(`workspaces/${workspaceId}/period_summaries/${monthKey}`).set({
        year, month, week: null, runtimeType: "month", categories: payload,
    });
}

async function readWorkspace(workspaceId: string): Promise<Record<string, any>> {
    return (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!;
}

async function readReport(workspaceId: string, monthKey: string): Promise<Record<string, any> | undefined> {
    return (await firestore.doc(`workspaces/${workspaceId}/monthly_reports/${monthKey}`).get()).data();
}

describe("HUD mensal (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("cron mensal: 4 categorias, 3 dentro e 1 fora -> 45 XP de aldeões + 100 da vila", async () => {
        const workspaceId = newWorkspace("quatro");
        await seedWorkspace(workspaceId);
        for (const id of ["mercado", "transporte", "lazer", "delivery"]) {
            await seedCategory(workspaceId, id, "expense");
        }
        // Receita e categoria de sistema: nenhuma das duas é aldeão.
        await seedCategory(workspaceId, "salario", "income");
        await seedCategory(workspaceId, "initial-balance", "income", { isSystem: true });

        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            mercado: { plannedCents: 100_000, actualCents: 90_000 },
            transporte: { plannedCents: 30_000, actualCents: 30_000 },
            lazer: { plannedCents: 20_000, actualCents: 5_000 },
            delivery: { plannedCents: 10_000, actualCents: 25_000 },
            salario: { plannedCents: 500_000, actualCents: 900_000 },
            "initial-balance": { plannedCents: 100_000, actualCents: 900_000 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        const workspace = await readWorkspace(workspaceId);
        // 3 × 15 = 45; a soma fechou em R$ 1.500 de R$ 1.600, então +100.
        expect(workspace.xp).toBe(3 * VILLAGER_ALIVE_XP + VILLAGE_ALIVE_XP);
        expect(workspace.xpAwardedFor?.monthlyVillagers?.[EVALUATED_MONTH]).toBeTruthy();

        expect(await readReport(workspaceId, EVALUATED_MONTH)).toMatchObject({
            monthKey: EVALUATED_MONTH,
            villagersPlanned: 4,
            villagersAlive: 3,
            villageAlive: true,
            xpAwarded: 145,
        });
    });

    it("a segunda execução do cron NÃO paga de novo", async () => {
        const workspaceId = newWorkspace("idempotente");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "mercado", "expense");
        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            mercado: { plannedCents: 100_000, actualCents: 10_000 },
        });

        // Sem o serviço de idempotência: quem barra o segundo pagamento é o
        // marcador DURÁVEL no documento do workspace, que é o que o script
        // retroativo também encontra 30 dias depois (o marcador de
        // `_idempotency` já teria expirado).
        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        expect((await readWorkspace(workspaceId)).xp).toBe(VILLAGER_ALIVE_XP);
    });

    it("duas execuções CONCORRENTES pagam uma vez só", async () => {
        const workspaceId = newWorkspace("concorrente");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "mercado", "expense");
        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            mercado: { plannedCents: 100_000, actualCents: 10_000 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await Promise.all([
            service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON),
            service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON),
            service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON),
        ]);

        expect((await readWorkspace(workspaceId)).xp).toBe(VILLAGER_ALIVE_XP);
    });

    it("o teto de 10 categorias segura o XP em 150", async () => {
        const workspaceId = newWorkspace("teto");
        await seedWorkspace(workspaceId);

        const categories: Record<string, { plannedCents: number, actualCents: number }> = {};
        for (let i = 0; i < 14; i++) {
            const id = `cat-${String(i).padStart(2, "0")}`;
            await seedCategory(workspaceId, id, "expense");
            categories[id] = { plannedCents: 10_000, actualCents: 1_000 };
        }
        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, categories);

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        // 150 do teto + 100 da vila (14 aldeões, soma bem dentro).
        expect((await readWorkspace(workspaceId)).xp).toBe(150 + VILLAGE_ALIVE_XP);
        expect((await readReport(workspaceId, EVALUATED_MONTH))?.villagersAlive).toBe(14);
    });

    it("mês sem categoria orçada: nenhum XP e NENHUM retrato", async () => {
        const workspaceId = newWorkspace("semaldeia");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "imprevistos", "expense");
        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            imprevistos: { plannedCents: 0, actualCents: 500_000 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        expect((await readWorkspace(workspaceId)).xp).toBe(0);
        expect(await readReport(workspaceId, EVALUATED_MONTH)).toBeUndefined();
    });

    it("o XP do mês entra na BARRA da semana em que o mês terminou", async () => {
        const workspaceId = newWorkspace("barra");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "mercado", "expense");
        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            mercado: { plannedCents: 100_000, actualCents: 10_000 },
        });

        const written: Array<{ date: Date, xp: number }> = [];
        const service = new GamificationService(
            new GamificationRepositoryImpl(),
            undefined,
            undefined,
            async (_w, date, xp) => {
                written.push({ date, xp });
            }
        );
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        expect(written).toHaveLength(1);
        expect(written[0].xp).toBe(VILLAGER_ALIVE_XP);
        // O último instante de agosto cai na semana que começou no domingo
        // 30/08 — e é a barra DELA que recebe o mérito do mês.
        expect(getWeekId(written[0].date)).toBe("2026-W35");
    });

    it("sumário LEGADO (sem os campos *Cents) ainda decide pelo double", async () => {
        const workspaceId = newWorkspace("legado");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "mercado", "expense");
        await firestore.doc(`workspaces/${workspaceId}/period_summaries/${EVALUATED_MONTH}`).set({
            year: 2026, month: 8, week: null, runtimeType: "month",
            categories: {
                mercado: { generalPlannedAmount: 1000, specificPlannedAmount: 0, actualAmount: 100 },
            },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        expect((await readWorkspace(workspaceId)).xp).toBe(VILLAGER_ALIVE_XP);
    });

    it("allocation INVESTMENT vem do documento da categoria e inverte a regra", async () => {
        // O join com `categories` é o que traz a `allocation`: aqui ela está
        // no documento de verdade, no emulador, e não num mock.
        const workspaceId = newWorkspace("investimento");
        await seedWorkspace(workspaceId);
        await seedCategory(workspaceId, "mercado", "expense", { allocation: "essential" });
        await seedCategory(workspaceId, "transporte", "expense", { allocation: "comfort" });
        await seedCategory(workspaceId, "aportes", "expense", { allocation: "investment" });
        await seedCategory(workspaceId, "previdencia", "expense", { allocation: "investment" });
        // APAGADA, e de investimento: com alvo de R$ 900 e nada aportado, ela
        // seria o pior aldeão do mês se o join a deixasse passar. Documento de
        // verdade, `isDeleted: true` de verdade.
        await seedCategory(workspaceId, "tesouro-antigo", "expense", {
            allocation: "investment", isDeleted: true,
        });

        await seedMonthlySummary(workspaceId, EVALUATED_MONTH, {
            mercado: { plannedCents: 100_000, actualCents: 90_000 },
            transporte: { plannedCents: 30_000, actualCents: 30_000 },
            // Aportou o DOBRO do alvo: vivo pela regra invertida.
            aportes: { plannedCents: 20_000, actualCents: 40_000 },
            // Não alcançou o alvo: cai, embora tenha "gastado menos".
            previdencia: { plannedCents: 50_000, actualCents: 10_000 },
            "tesouro-antigo": { plannedCents: 90_000, actualCents: 0 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateMonthlyVillagersXp(workspaceId, MONTHLY_CRON);

        // 3 vivos (mercado, transporte, aportes) = 45. A vila cai: o envelope
        // de investimento pediu R$ 700 e recebeu R$ 500. E são QUATRO aldeões,
        // não cinco: a categoria apagada ficou de fora do join.
        expect((await readWorkspace(workspaceId)).xp).toBe(3 * VILLAGER_ALIVE_XP);
        expect(await readReport(workspaceId, EVALUATED_MONTH)).toMatchObject({
            villagersPlanned: 4,
            villagersAlive: 3,
            villageAlive: false,
            xpAwarded: 45,
        });
    });

    describe("receita prevista do mês", () => {
        const service = () => new ExpectedIncomeService(new ExpectedIncomeRepositoryImpl());

        it("usa o planejado de receita do mês e o publica no workspace", async () => {
            const workspaceId = newWorkspace("receita-planejada");
            await seedWorkspace(workspaceId);
            await seedCategory(workspaceId, "salario", "income");
            await seedCategory(workspaceId, "servicos", "income");
            await seedCategory(workspaceId, "mercado", "expense");
            await seedCategory(workspaceId, "initial-balance", "income", { isSystem: true });

            await seedMonthlySummary(workspaceId, "2026-09", {
                salario: { specificCents: 800_000, actualCents: 100_000 },
                servicos: { specificCents: 250_000 },
                // Despesa agendada e saldo inicial NÃO entram na previsão.
                mercado: { specificCents: 400_000, actualCents: 90_000 },
                "initial-balance": { specificCents: 2_000_000, actualCents: 2_000_000 },
            });

            const result = await service().publishExpectedIncome(workspaceId, "2026-09", MONTHLY_CRON);

            expect(result.value).toMatchObject({
                monthKey: "2026-09", cents: 1_050_000, source: "planned",
            });
            expect(result.published).toBe(true);
            expect((await readWorkspace(workspaceId)).expectedIncome).toEqual({
                monthKey: "2026-09",
                cents: 1_050_000,
                source: "planned",
                updatedAt: MONTHLY_CRON.toISOString(),
            });
        });

        it("sem receita agendada, cai na média do realizado dos três meses", async () => {
            const workspaceId = newWorkspace("receita-media");
            await seedWorkspace(workspaceId);
            await seedCategory(workspaceId, "salario", "income");

            // O mês corrente existe, mas nada foi agendado.
            await seedMonthlySummary(workspaceId, "2026-09", { salario: { actualCents: 10_000 } });
            await seedMonthlySummary(workspaceId, "2026-08", { salario: { actualCents: 600_000 } });
            await seedMonthlySummary(workspaceId, "2026-07", { salario: { actualCents: 500_000 } });
            await seedMonthlySummary(workspaceId, "2026-06", { salario: { actualCents: 700_000 } });

            const result = await service().publishExpectedIncome(workspaceId, "2026-09", MONTHLY_CRON);

            expect(result.value).toMatchObject({ cents: 600_000, source: "average" });
        });

        it("workspace novo: meses inexistentes não entram no divisor", async () => {
            const workspaceId = newWorkspace("receita-novo");
            await seedWorkspace(workspaceId);
            await seedCategory(workspaceId, "salario", "income");

            await seedMonthlySummary(workspaceId, "2026-09", { salario: { actualCents: 0 } });
            await seedMonthlySummary(workspaceId, "2026-08", { salario: { actualCents: 600_000 } });

            const result = await service().publishExpectedIncome(workspaceId, "2026-09", MONTHLY_CRON);

            // Um mês de histórico: a média é ele mesmo, e não 600.000/3.
            expect(result.value).toMatchObject({ cents: 600_000, source: "average" });
        });

        it("republicar o mesmo valor NÃO escreve de novo", async () => {
            const workspaceId = newWorkspace("receita-estavel");
            await seedWorkspace(workspaceId);
            await seedCategory(workspaceId, "salario", "income");
            await seedMonthlySummary(workspaceId, "2026-09", { salario: { specificCents: 800_000 } });

            const first = await service().publishExpectedIncome(workspaceId, "2026-09", MONTHLY_CRON);
            const second = await service().publishExpectedIncome(
                workspaceId,
                "2026-09",
                new Date("2026-09-20T12:00:00.000Z")
            );

            expect(first.published).toBe(true);
            expect(second.published).toBe(false);
            // O `updatedAt` gravado continua sendo o da PRIMEIRA publicação:
            // nada foi escrito na segunda.
            expect((await readWorkspace(workspaceId)).expectedIncome.updatedAt)
                .toBe(MONTHLY_CRON.toISOString());
        });

        it("workspace inexistente não é RESSUSCITADO pela publicação", async () => {
            await expect(
                service().publishExpectedIncome("ws-que-nunca-existiu", "2026-09", MONTHLY_CRON)
            ).resolves.toBeDefined();

            expect((await firestore.doc("workspaces/ws-que-nunca-existiu").get()).exists).toBe(false);
        });
    });
});
