/**
 * wp/missions-by-type — geração e progresso das missões semanais contra o
 * Firestore de verdade.
 *
 * Os unitários provam as REGRAS com repositório falso. Aqui provamos o que só
 * o banco prova:
 *
 *  - a geração grava o documento COMPLETO (`templateKey`, `workspaceType`,
 *    `actionPath`, `nameKey`, `params`) com `ignoreUndefinedProperties: false`
 *    ligado, igual à produção — um campo opcional mal montado derruba a
 *    escrita aqui, não em produção na segunda-feira;
 *  - um workspace `business` e um `personal` na mesma semana recebem missões
 *    DIFERENTES, do catálogo de cada um;
 *  - o progresso corporativo de conciliação conta documentos reais de
 *    `reconciliations` pela janela da semana, e não o que veio no evento;
 *  - a missão fecha concedendo XP na mesma transação.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { GamificationRepositoryImpl } from "../../features/goal/data/repositories/gamification.repository.impl";
import { GamificationService } from "../../features/goal/domain/services/gamification.service";
import {
    AUDIENCE_FORBIDDEN_TERMS,
    buildMissionName,
    findMissionTemplate,
    normalizeTerm,
    selectMissionTemplate,
} from "../../features/goal/domain/models/mission_catalog";
import { getWeekId, startOfWeekInTz } from "../../core/utils/week.utils";

/** Quinta 2026-09-10 12:00 em São Paulo. */
const THURSDAY = new Date("2026-09-10T15:00:00.000Z");
const WEEK_ID = getWeekId(startOfWeekInTz(THURSDAY));

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-missions-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function seedWorkspace(workspaceId: string, type: "personal" | "business"): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}`).set({
        name: type === "business" ? "Benav Labs" : "Casa",
        type,
        members: ["uid"],
        xp: 0,
        level: 1,
    });
}

async function seedPlanning(
    workspaceId: string,
    id: string,
    name: string,
    amount: number
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/category_planning/${id}`).set({
        amount,
        category: { id, name, icon: "label", color: "#000", type: "expense", isDeleted: false },
        startMonth: "2026-01",
        endMonth: "2026-12",
    });
}

async function readMissions(workspaceId: string): Promise<Record<string, any>> {
    const snapshot = await firestore.collection(`workspaces/${workspaceId}/weekly_missions`).get();
    const out: Record<string, any> = {};
    for (const doc of snapshot.docs) out[doc.id] = doc.data();
    return out;
}

describe("missões semanais por tipo (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        jest.useRealTimers();
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("gera missões DIFERENTES para empresa e para pessoa na mesma semana", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const business = newWorkspace("business");
        const personal = newWorkspace("personal");
        await seedWorkspace(business, "business");
        await seedWorkspace(personal, "personal");
        await seedPlanning(business, "marketing", "Marketing", 9000);
        await seedPlanning(personal, "mercado", "Mercado", 900);

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.updateWeeklyMissionsProgress(business, "planning", {});
        await service.updateWeeklyMissionsProgress(personal, "planning", {});

        const businessMissions = await readMissions(business);
        const personalMissions = await readMissions(personal);

        expect(Object.keys(businessMissions).sort()).toEqual([
            `${WEEK_ID}_consistency`, `${WEEK_ID}_discipline`, `${WEEK_ID}_organization`,
        ]);

        for (const [id, mission] of Object.entries(businessMissions)) {
            const type = id.split("_")[1] as "consistency" | "discipline" | "organization";
            const template = selectMissionTemplate("business", type, WEEK_ID)!;
            expect(mission.templateKey).toBe(template.key);
            expect(mission.workspaceType).toBe("business");
            expect(mission.actionPath).toBe(template.actionPath);
            expect(mission.nameKey).toBe(template.nameKey);
            // A regressão que o pacote existe para impedir.
            for (const term of AUDIENCE_FORBIDDEN_TERMS.business) {
                expect(normalizeTerm(mission.name)).not.toContain(term);
            }
        }

        for (const mission of Object.values(personalMissions)) {
            expect(mission.workspaceType).toBe("personal");
            expect(mission.templateKey).toMatch(/^personal_/);
        }

        // Os dois catálogos não podem coincidir: se coincidissem, o tipo do
        // workspace não estaria mudando nada.
        const businessKeys = Object.values(businessMissions).map((m) => m.templateKey).sort();
        const personalKeys = Object.values(personalMissions).map((m) => m.templateKey).sort();
        expect(businessKeys).not.toEqual(personalKeys);
    });

    it("grava `params` e não deixa placeholder no nome (ignoreUndefinedProperties desligado)", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("params");
        await seedWorkspace(workspaceId, "personal");
        await seedPlanning(workspaceId, "moradia", "Moradia", 2100);
        await seedPlanning(workspaceId, "mercado", "Mercado", 900);

        const service = new GamificationService(new GamificationRepositoryImpl());
        await service.updateWeeklyMissionsProgress(workspaceId, "planning", {});

        const missions = await readMissions(workspaceId);
        const discipline = missions[`${WEEK_ID}_discipline`];
        const template = findMissionTemplate(discipline.templateKey)!;

        expect(discipline.params).toEqual({ target: template.target, category: "Moradia" });
        expect(discipline.name).toBe(buildMissionName(template, "pt", discipline.params));
        expect(discipline.name).not.toContain("{");
    });

    it("progresso corporativo: conta os extratos conciliados NA SEMANA e paga o XP", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("reconcile");
        await seedWorkspace(workspaceId, "business");

        const template = findMissionTemplate("business_organization_reconcile_statements")!;
        await firestore.doc(`workspaces/${workspaceId}/weekly_missions/${WEEK_ID}_organization`).set({
            id: "organization",
            type: "organization",
            name: buildMissionName(template, "pt", { target: template.target }),
            status: "pending",
            progress: 0,
            target: template.target,
            rewardXp: template.rewardXp,
            weekId: WEEK_ID,
            templateKey: template.key,
            workspaceType: "business",
            actionPath: template.actionPath,
            nameKey: template.nameKey,
        });
        // As outras duas já concluídas, para isolar a regra sob teste.
        for (const type of ["consistency", "discipline"]) {
            await firestore.doc(`workspaces/${workspaceId}/weekly_missions/${WEEK_ID}_${type}`).set({
                id: type, type, name: "x", status: "completed", progress: 1, target: 1,
                rewardXp: 0, weekId: WEEK_ID, templateKey: "x", workspaceType: "business",
                actionPath: "/planning", nameKey: "x",
            });
        }

        const weekStart = startOfWeekInTz(THURSDAY);
        await firestore.collection(`workspaces/${workspaceId}/reconciliations`).add({
            status: "completed",
            totalTransactionsProcessed: 3,
            createdAt: admin.firestore.Timestamp.fromDate(new Date(weekStart.getTime() + 36 * 3600 * 1000)),
        });
        await firestore.collection(`workspaces/${workspaceId}/reconciliations`).add({
            status: "completed",
            totalTransactionsProcessed: 7,
            createdAt: admin.firestore.Timestamp.fromDate(new Date(weekStart.getTime() + 60 * 3600 * 1000)),
        });
        // Fora da janela: de duas semanas atrás.
        await firestore.collection(`workspaces/${workspaceId}/reconciliations`).add({
            status: "completed",
            totalTransactionsProcessed: 99,
            createdAt: admin.firestore.Timestamp.fromDate(new Date(weekStart.getTime() - 14 * 24 * 3600 * 1000)),
        });

        const service = new GamificationService(new GamificationRepositoryImpl());
        // O evento traz UM extrato; a regra corporativa conta os DOIS da semana.
        await service.updateWeeklyMissionsProgress(workspaceId, "reconciliation", {
            status: "completed",
            totalTransactionsProcessed: 7,
        });

        const missions = await readMissions(workspaceId);
        expect(missions[`${WEEK_ID}_organization`].status).toBe("completed");
        expect(missions[`${WEEK_ID}_organization`].progress).toBe(2);

        const workspace = (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!;
        expect(workspace.xp).toBe(template.rewardXp);
    });
});
