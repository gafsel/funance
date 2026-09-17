/**
 * F2.3 — o XP que premia planejar, contra o Firestore de verdade.
 *
 * Os unitários provam as REGRAS; aqui provamos o que só o banco prova:
 *
 *  - o cron semanal lê o `period_summaries/{YYYY-Www}` de verdade e concede o
 *    XP certo, com a streak subindo e zerando;
 *  - a concessão única por categoria é ATÔMICA — duas chamadas concorrentes
 *    pagam uma vez só, porque o marcador e o XP vão na mesma transação;
 *  - `weeklyStreaks` migra de número para mapa sem perder a sequência antiga;
 *  - `unplannedReason` é de fato GRAVADO na parcela que nasce paga.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { GamificationRepositoryImpl } from "../../features/goal/data/repositories/gamification.repository.impl";
import {
    GamificationService,
    XP_VALUES,
} from "../../features/goal/domain/services/gamification.service";
import { readWorkspaceStreaks } from "../../features/goal/domain/repositories/gamification.repository";
import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../../features/finance/domain/models/finance.models";

/** Segunda-feira, 07/09/2026 03:00 em São Paulo — o horário do cron semanal. */
const MONDAY_CRON = new Date("2026-09-07T06:00:00.000Z");
/** A semana AVALIADA é a anterior: domingo 30/08 a sábado 05/09. */
const EVALUATED_WEEK = "2026-W35";

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-planxp-${label}-${Date.now()}`;
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

async function seedWeeklySummary(
    workspaceId: string,
    weekId: string,
    categories: Record<string, { generalPlannedAmount: number, actualAmount: number }>
): Promise<void> {
    const [year, week] = weekId.split("-W").map(Number);
    const payload: Record<string, any> = {};
    for (const [categoryId, values] of Object.entries(categories)) {
        payload[categoryId] = { ...values, specificPlannedAmount: 0 };
    }
    await firestore.doc(`workspaces/${workspaceId}/period_summaries/${weekId}`).set({
        year, month: null, week, runtimeType: "week", categories: payload,
    });
}

async function readWorkspace(workspaceId: string): Promise<Record<string, any>> {
    return (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!;
}

describe("XP que premia planejar (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("cron semanal: paga por categoria em dia, bônus de semana redonda e streak", async () => {
        const workspaceId = newWorkspace("semana");
        await seedWorkspace(workspaceId, { weeklyStreaks: { missions: 1, plan: 2 } });
        await seedCategory(workspaceId, "mercado", "expense");
        await seedCategory(workspaceId, "lazer", "expense");
        await seedCategory(workspaceId, "salario", "income");
        await seedCategory(workspaceId, "initial-balance", "income", { isSystem: true });

        await seedWeeklySummary(workspaceId, EVALUATED_WEEK, {
            mercado: { generalPlannedAmount: 700, actualAmount: 650 },
            lazer: { generalPlannedAmount: 200, actualAmount: 200 },
            // Receita e categoria de sistema não entram na conta.
            salario: { generalPlannedAmount: 2000, actualAmount: 2000 },
            "initial-balance": { generalPlannedAmount: 100, actualAmount: 5000 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateWeeklyPlanXp(workspaceId, MONDAY_CRON);

        const workspace = await readWorkspace(workspaceId);
        // 2×20 (duas dentro) + 50 (todas) + 10×3 (a streak vai de 2 para 3).
        expect(workspace.xp).toBe(2 * XP_VALUES.weeklyCategoryWithinLimit + XP_VALUES.weeklyAllWithinLimit + 30);
        expect(readWorkspaceStreaks(workspace.weeklyStreaks)).toEqual({ missions: 1, plan: 3 });
    });

    it("cron semanal: estourar um limite zera a streak e paga só o que ficou em dia", async () => {
        const workspaceId = newWorkspace("estouro");
        await seedWorkspace(workspaceId, { weeklyStreaks: { missions: 4, plan: 9 } });
        await seedCategory(workspaceId, "mercado", "expense");
        await seedCategory(workspaceId, "lazer", "expense");

        await seedWeeklySummary(workspaceId, EVALUATED_WEEK, {
            mercado: { generalPlannedAmount: 700, actualAmount: 650 },
            lazer: { generalPlannedAmount: 200, actualAmount: 450 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateWeeklyPlanXp(workspaceId, MONDAY_CRON);

        const workspace = await readWorkspace(workspaceId);
        expect(workspace.xp).toBe(XP_VALUES.weeklyCategoryWithinLimit);
        // A streak de PLANO zera; a de MISSÕES, que é outra coisa, sobrevive.
        expect(readWorkspaceStreaks(workspace.weeklyStreaks)).toEqual({ missions: 4, plan: 0 });
    });

    it("cron semanal: sem sumário da semana, nada acontece", async () => {
        const workspaceId = newWorkspace("semsumario");
        await seedWorkspace(workspaceId);

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateWeeklyPlanXp(workspaceId, MONDAY_CRON);

        expect((await readWorkspace(workspaceId)).xp).toBe(0);
    });

    it("weeklyStreaks LEGADO (número) vira mapa sem perder a sequência de missões", async () => {
        const workspaceId = newWorkspace("legado");
        // Formato antigo: um número solto.
        await seedWorkspace(workspaceId, { weeklyStreaks: 5 });
        await seedCategory(workspaceId, "mercado", "expense");
        await seedWeeklySummary(workspaceId, EVALUATED_WEEK, {
            mercado: { generalPlannedAmount: 700, actualAmount: 650 },
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.evaluateWeeklyPlanXp(workspaceId, MONDAY_CRON);

        const workspace = await readWorkspace(workspaceId);
        // As 5 semanas de missões continuam lá; o plano começa em 1.
        expect(workspace.weeklyStreaks).toEqual({ missions: 5, plan: 1 });
    });

    it("XP único: a segunda criação do mesmo limite não paga nada", async () => {
        const workspaceId = newWorkspace("unico");
        await seedWorkspace(workspaceId);

        const service = new GamificationService(new GamificationRepositoryImpl());
        const planning = { amount: 800, category: { id: "mercado", name: "Mercado" } };

        expect(await service.awardPlanningCreationXp(workspaceId, planning)).toBe(true);
        expect((await readWorkspace(workspaceId)).xp).toBe(XP_VALUES.planningCreated);

        // Editar, apagar e recriar o mesmo limite não é planejar de novo.
        expect(await service.awardPlanningCreationXp(workspaceId, planning)).toBe(false);
        expect(await service.awardPlanningCreationXp(workspaceId, { ...planning, amount: 1200 })).toBe(false);
        expect((await readWorkspace(workspaceId)).xp).toBe(XP_VALUES.planningCreated);

        // Uma categoria DIFERENTE, sim, paga.
        expect(await service.awardPlanningCreationXp(workspaceId, {
            amount: 300, category: { id: "lazer", name: "Lazer" },
        })).toBe(true);

        const workspace = await readWorkspace(workspaceId);
        expect(workspace.xp).toBe(2 * XP_VALUES.planningCreated);
        expect(Object.keys(workspace.xpAwardedFor.planning).sort()).toEqual(["lazer", "mercado"]);
    });

    it("XP único: limite e recorrência são contadores independentes", async () => {
        const workspaceId = newWorkspace("familias");
        await seedWorkspace(workspaceId);

        const service = new GamificationService(new GamificationRepositoryImpl());
        const category = { id: "aluguel", name: "Aluguel" };

        expect(await service.awardPlanningCreationXp(workspaceId, { amount: 2000, category })).toBe(true);
        // A mesma categoria pode render pelo limite E pela recorrência: são
        // dois atos de planejamento diferentes.
        expect(await service.awardRecurringCreationXp(workspaceId, {
            installmentType: "recurring", status: "active", category,
        })).toBe(true);
        // Mas a segunda recorrência da mesma categoria, não.
        expect(await service.awardRecurringCreationXp(workspaceId, {
            installmentType: "recurring", status: "active", category,
        })).toBe(false);

        const workspace = await readWorkspace(workspaceId);
        expect(workspace.xp).toBe(XP_VALUES.planningCreated + XP_VALUES.recurringCreated);
        expect(workspace.xpAwardedFor.planning.aluguel).toBeDefined();
        expect(workspace.xpAwardedFor.recurring.aluguel).toBeDefined();
    });

    it("XP único: duas concessões CONCORRENTES pagam uma vez só", async () => {
        // O marcador e o XP vão na mesma transação; é o Firestore que serializa
        // a disputa. Sem isso, duas escritas paralelas do mesmo planejamento
        // (o app salvando duas vezes, a reentrega de um evento) dobrariam o XP.
        const workspaceId = newWorkspace("corrida");
        await seedWorkspace(workspaceId);

        const service = new GamificationService(new GamificationRepositoryImpl());
        const planning = { amount: 800, category: { id: "mercado", name: "Mercado" } };

        const results = await Promise.all([
            service.awardPlanningCreationXp(workspaceId, planning),
            service.awardPlanningCreationXp(workspaceId, planning),
            service.awardPlanningCreationXp(workspaceId, planning),
        ]);

        expect(results.filter(Boolean)).toHaveLength(1);
        expect((await readWorkspace(workspaceId)).xp).toBe(XP_VALUES.planningCreated);
    });

    it("unplannedReason é GRAVADO na parcela que nasce paga, junto do xp zero", async () => {
        const workspaceId = newWorkspace("unplanned");
        await seedWorkspace(workspaceId);

        // A parcela que nasce paga: planejado ZERO, valor efetivo em paidAmount
        // (é o que `syncInstallments` faz para a cobrança contar como não
        // planejada — ver o contrato de orders/installments).
        const installmentId = "inst-born-paid";
        await firestore.doc(`workspaces/${workspaceId}/installments/${installmentId}`).set({
            orderId: "o1",
            amount: 0,
            paidAmount: 250,
            referenceAmount: 250,
            description: "Compra já liquidada no cartão",
            status: "paid",
            type: "expense",
            installmentType: "single",
            dueDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            referenceDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            paidDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            accountIds: [],
            replicationCascade: "all",
        });

        const financeService = new FinanceService(new FinanceRepositoryImpl());
        const after = {
            id: installmentId,
            orderId: "o1",
            amount: 0,
            paidAmount: 250,
            referenceAmount: 250,
            description: "Compra já liquidada no cartão",
            status: InstallmentStatus.paid,
            type: OrderType.expense,
            installmentType: InstallmentType.single,
            dueDate: new Date("2026-09-03T15:00:00.000Z"),
            referenceDate: new Date("2026-09-03T15:00:00.000Z"),
            paidDate: new Date("2026-09-03T15:00:00.000Z"),
            accountIds: [],
        } as InstallmentModel;

        await financeService.updateXpOnInstallmentChange(workspaceId, null, after);

        const stored = (await firestore.doc(`workspaces/${workspaceId}/installments/${installmentId}`).get()).data()!;
        expect(stored.xp).toBe(0);
        expect(stored.unplannedReason).toBe("born_paid");
        // Uma escrita só: a cascata foi zerada no mesmo update.
        expect(stored.replicationCascade).toBe("none");
    });

    it("a parcela PLANEJADA rende XP e não recebe motivo nenhum", async () => {
        const workspaceId = newWorkspace("planejada");
        await seedWorkspace(workspaceId);

        const installmentId = "inst-planned";
        await firestore.doc(`workspaces/${workspaceId}/installments/${installmentId}`).set({
            orderId: "o1",
            amount: 250,
            paidAmount: 250,
            referenceAmount: 250,
            description: "Conta de luz",
            status: "paid",
            type: "expense",
            installmentType: "single",
            dueDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            referenceDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            paidDate: admin.firestore.Timestamp.fromDate(new Date("2026-09-03T15:00:00.000Z")),
            accountIds: [],
        });

        const financeService = new FinanceService(new FinanceRepositoryImpl());
        await financeService.updateXpOnInstallmentChange(workspaceId, null, {
            id: installmentId,
            orderId: "o1",
            amount: 250,
            paidAmount: 250,
            referenceAmount: 250,
            description: "Conta de luz",
            status: InstallmentStatus.paid,
            type: OrderType.expense,
            installmentType: InstallmentType.single,
            dueDate: new Date("2026-09-03T15:00:00.000Z"),
            referenceDate: new Date("2026-09-03T15:00:00.000Z"),
            paidDate: new Date("2026-09-03T15:00:00.000Z"),
            accountIds: [],
        } as InstallmentModel);

        const stored = (await firestore.doc(`workspaces/${workspaceId}/installments/${installmentId}`).get()).data()!;
        expect(stored.xp).toBe(15);
        expect(stored.unplannedReason).toBeUndefined();
    });
});
