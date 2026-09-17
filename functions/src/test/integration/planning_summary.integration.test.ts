// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { RebuildRepositoryImpl } from "../../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { RebuildService } from "../../features/finance/domain/services/rebuild.service";
import {
    PLANNING_FULLY_SUMMARIZED,
    SummaryService,
    planningHorizon,
} from "../../features/finance/domain/services/summary.service";
import { CategoryPlanningModel } from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { monthKeyRange, shiftMonthKey, toMonthKey } from "../../core/utils/month_key";

/**
 * F1.5 — horizonte rolante do planejamento, contra o emulador do Firestore.
 *
 * O que se verifica aqui é o encadeamento completo: gatilho -> impactos
 * agrupados -> documentos de `period_summaries` -> marcadores no planejamento,
 * e o cron mensal empurrando o horizonte um mês por vez.
 */

const CATEGORY: CategoryModel = {
    id: "cat-moradia",
    name: "Moradia",
    icon: "home",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

/** Base de tempo fixa: 15 de setembro de 2026, meio-dia em São Paulo. */
const NOW = new Date("2026-09-15T15:00:00.000Z");
const CURRENT_MONTH = toMonthKey(NOW);
const HORIZON = planningHorizon(NOW);

let firestore: admin.firestore.Firestore;
let financeRepository: FinanceRepositoryImpl;
let summaryService: SummaryService;
let rebuildService: RebuildService;

const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-planning-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function writePlanning(
    workspaceId: string,
    planning: CategoryPlanningModel
): Promise<void> {
    const { id, ...data } = planning;
    await firestore.doc(`workspaces/${workspaceId}/category_planning/${id}`).set(data, { merge: true });
}

async function readPlanning(workspaceId: string, planningId: string): Promise<Record<string, any>> {
    const doc = await firestore.doc(`workspaces/${workspaceId}/category_planning/${planningId}`).get();
    return doc.data() ?? {};
}

/** `generalPlannedAmount` da categoria em cada documento de `period_summaries`. */
async function readGeneralPlanned(workspaceId: string): Promise<Record<string, number>> {
    const snapshot = await firestore.collection(`workspaces/${workspaceId}/period_summaries`).get();
    const result: Record<string, number> = {};

    for (const doc of snapshot.docs) {
        const value = doc.data()?.categories?.[CATEGORY.id]?.generalPlannedAmount;
        if (typeof value === "number") result[doc.id] = value;
    }
    return result;
}

const monthIds = (planned: Record<string, number>) =>
    Object.keys(planned).filter((id) => /^\d{4}-\d{2}$/.test(id)).sort();
const weekIds = (planned: Record<string, number>) =>
    Object.keys(planned).filter((id) => /^\d{4}-W\d{2}$/.test(id)).sort();

describe("Planejamento por categoria (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }

        firestore = admin.firestore();
        financeRepository = new FinanceRepositoryImpl();
        summaryService = new SummaryService(financeRepository);
        rebuildService = new RebuildService(
            new RebuildRepositoryImpl(),
            summaryService,
            new FinanceService(financeRepository)
        );
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("criar um planejamento gera os sumários dos 12 meses do horizonte", async () => {
        const workspaceId = newWorkspace("criacao");
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 1200,
            startMonth: "2026-01",
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        const planned = await readGeneralPlanned(workspaceId);

        // Doze meses, do mês corrente ao horizonte.
        expect(monthIds(planned)).toEqual(monthKeyRange(CURRENT_MONTH, HORIZON));
        for (const monthKey of monthKeyRange(CURRENT_MONTH, HORIZON)) {
            expect({ monthKey, value: planned[monthKey] }).toEqual({ monthKey, value: expect.closeTo(1200, 2) });
        }

        // Ano: a soma dos meses aplicados (4 em 2026, 8 em 2027).
        expect(planned["2026"]).toBeCloseTo(4 * 1200, 2);
        expect(planned["2027"]).toBeCloseTo(8 * 1200, 2);

        // Semanas: nenhuma repetida e a soma de cada mês ≈ o valor do mês.
        const weeks = weekIds(planned);
        expect(new Set(weeks).size).toBe(weeks.length);
        const weeklyTotal = weeks.reduce((total, id) => total + planned[id], 0);
        expect(weeklyTotal).toBeGreaterThan(12 * 1200 * 0.9);
        expect(weeklyTotal).toBeLessThan(12 * 1200 * 1.2);

        // Marcadores no próprio planejamento.
        expect(await readPlanning(workspaceId, planning.id)).toMatchObject({
            summarizedUntil: HORIZON,
            appliedAmount: 1200,
            appliedFrom: CURRENT_MONTH,
            appliedUntil: HORIZON,
        });
    }, 60000);

    it("alterar o valor estorna o que estava aplicado e reaplica o novo", async () => {
        const workspaceId = newWorkspace("alteracao");
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 1000,
            startMonth: "2026-01",
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        // O `before` do segundo evento é o documento COM os marcadores.
        const before = { id: planning.id, ...(await readPlanning(workspaceId, planning.id)) } as CategoryPlanningModel;
        const after: CategoryPlanningModel = { ...before, amount: 1500 };

        await writePlanning(workspaceId, after);
        await summaryService.processCategoryPlanningChange(workspaceId, before, after, NOW);

        const planned = await readGeneralPlanned(workspaceId);

        // Sem estorno, o regime antigo deixaria 2500 aqui.
        for (const monthKey of monthKeyRange(CURRENT_MONTH, HORIZON)) {
            expect({ monthKey, value: planned[monthKey] }).toEqual({ monthKey, value: expect.closeTo(1500, 2) });
        }
        expect(planned["2026"]).toBeCloseTo(4 * 1500, 2);
        expect(planned["2027"]).toBeCloseTo(8 * 1500, 2);

        expect(await readPlanning(workspaceId, planning.id)).toMatchObject({ appliedAmount: 1500 });
    }, 60000);

    it("encurtar o período zera os meses que saíram", async () => {
        const workspaceId = newWorkspace("encurtar");
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 900,
            startMonth: "2026-01",
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        const before = { id: planning.id, ...(await readPlanning(workspaceId, planning.id)) } as CategoryPlanningModel;
        const after: CategoryPlanningModel = { ...before, endMonth: "2026-12" };

        await writePlanning(workspaceId, after);
        await summaryService.processCategoryPlanningChange(workspaceId, before, after, NOW);

        const planned = await readGeneralPlanned(workspaceId);

        for (const monthKey of monthKeyRange(CURRENT_MONTH, "2026-12")) {
            expect({ monthKey, value: planned[monthKey] }).toEqual({ monthKey, value: expect.closeTo(900, 2) });
        }
        for (const monthKey of monthKeyRange("2027-01", HORIZON)) {
            expect({ monthKey, value: planned[monthKey] }).toEqual({ monthKey, value: expect.closeTo(0, 2) });
        }

        expect(await readPlanning(workspaceId, planning.id)).toMatchObject({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedUntil: "2026-12",
        });
    }, 60000);

    it("apagar o planejamento estorna tudo o que estava aplicado", async () => {
        const workspaceId = newWorkspace("exclusao");
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 800,
            startMonth: "2026-09",
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        const before = { id: planning.id, ...(await readPlanning(workspaceId, planning.id)) } as CategoryPlanningModel;
        await firestore.doc(`workspaces/${workspaceId}/category_planning/${planning.id}`).delete();
        await summaryService.processCategoryPlanningChange(workspaceId, before, null, NOW);

        const planned = await readGeneralPlanned(workspaceId);
        for (const [docId, value] of Object.entries(planned)) {
            expect({ docId, value }).toEqual({ docId, value: expect.closeTo(0, 2) });
        }
    }, 60000);

    it("a virada de mês pelo cron aplica exatamente UM mês novo", async () => {
        const workspaceId = newWorkspace("cron");
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 600,
            startMonth: "2026-01",
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        const antes = await readGeneralPlanned(workspaceId);

        // Dia 1 do mês seguinte, 00h de Brasília.
        const proximoMes = new Date("2026-10-01T03:30:00.000Z");
        const novoHorizonte = planningHorizon(proximoMes);
        expect(novoHorizonte).toBe(shiftMonthKey(HORIZON, 1));

        await summaryService.generateCategoryPlanningSummaries(proximoMes);

        const depois = await readGeneralPlanned(workspaceId);

        // Só o mês da ponta entrou; nenhum mês anterior foi somado de novo.
        expect(monthIds(depois)).toEqual([...monthIds(antes), novoHorizonte]);
        for (const monthKey of monthIds(antes)) {
            expect({ monthKey, value: depois[monthKey] }).toEqual({ monthKey, value: expect.closeTo(antes[monthKey], 2) });
        }
        expect(depois[novoHorizonte]).toBeCloseTo(600, 2);

        expect(await readPlanning(workspaceId, planning.id)).toMatchObject({
            summarizedUntil: novoHorizonte,
            appliedUntil: novoHorizonte,
        });

        // Rodar o cron de novo no mesmo mês não muda nada (a consulta não casa).
        await summaryService.generateCategoryPlanningSummaries(proximoMes);
        const terceira = await readGeneralPlanned(workspaceId);
        for (const [docId, value] of Object.entries(terceira)) {
            expect({ docId, value }).toEqual({ docId, value: expect.closeTo(depois[docId], 2) });
        }
    }, 60000);

    it("o cron ADOTA o planejamento legado sem reaplicar impacto", async () => {
        const workspaceId = newWorkspace("legado");

        // Planejamento do regime antigo: sem `summarizedUntil`, com o
        // `lastSummaryMonth` que ninguém mais usa.
        await firestore.doc(`workspaces/${workspaceId}/category_planning/plan-legado`).set({
            category: CATEGORY,
            amount: 700,
            startMonth: "2026-01",
            endMonth: "2030-12",
            lastSummaryMonth: "2026-08",
        });

        await summaryService.generateCategoryPlanningSummaries(NOW);

        // Nenhum sumário criado: reaplicar aqui dobraria o planejado legado.
        expect(await readGeneralPlanned(workspaceId)).toEqual({});
        expect(await readPlanning(workspaceId, "plan-legado")).toMatchObject({
            summarizedUntil: HORIZON,
            appliedAmount: 700,
            appliedFrom: CURRENT_MONTH,
            appliedUntil: HORIZON,
        });
    }, 60000);

    it("rebuild --rebuild-planning reproduz exatamente o incremental", async () => {
        const workspaceId = newWorkspace("rebuild");
        await firestore.doc(`workspaces/${workspaceId}`).set({
            name: "Planejamento",
            type: "personal",
            members: ["uid-dono"],
        });

        // O planejamento começa no mês corrente: incremental e rebuild cobrem
        // exatamente a mesma janela (ver a divergência documentada em
        // rebuild.service.ts para planejamentos que começam no passado).
        const planning: CategoryPlanningModel = {
            id: "plan-moradia",
            category: CATEGORY,
            amount: 1234.56,
            startMonth: CURRENT_MONTH,
            endMonth: "2030-12",
        };

        await writePlanning(workspaceId, planning);
        await summaryService.processCategoryPlanningChange(workspaceId, null, planning, NOW);

        const report = await rebuildService.rebuildWorkspace(workspaceId, { now: NOW, rebuildPlanning: true });

        expect(report.rebuildPlanning).toBe(true);
        expect(report.diff.periodSummaries).toMatchObject({ toCreate: 0, toUpdate: 0, toDelete: 0 });
        expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);
        expect(report.totalChanges).toBe(0);
    }, 60000);
});
