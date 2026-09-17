/**
 * Migração leve `retag_weekly_missions.ts`: dry-run, carimbo, substituição das
 * missões ABERTAS de empresa, preservação das concluídas e idempotência.
 */

import { parseArgs, retagWeeklyMissions } from "../scripts/retag_weekly_missions";
import { buildMissionName, selectMissionTemplate } from "../features/goal/domain/models/mission_catalog";

/** Terça 2026-08-11 12:00 em São Paulo — semana 2026-W32. */
const NOW = new Date("2026-08-11T15:00:00Z");
const WEEK_ID = "2026-W32";

interface WorkspaceFixture {
    type?: string;
    missions: Record<string, Record<string, any>>;
    plannings?: Record<string, Record<string, any>>;
}

let written: Array<{ id: string; data: Record<string, any> }>;

/** Firestore falso: workspaces paginados + subcoleções por workspace. */
function buildFirestore(workspaces: Record<string, WorkspaceFixture>): any {
    const subcollection = (docs: Record<string, Record<string, any>>, workspaceId: string) => ({
        where() {
            return this;
        },
        async get() {
            const entries = Object.entries(docs);
            return {
                empty: entries.length === 0,
                size: entries.length,
                docs: entries.map(([id, data]) => ({
                    id,
                    data: () => ({ ...data }),
                    ref: { id, __workspaceId: workspaceId },
                })),
            };
        },
    });

    const workspaceDoc = (id: string) => {
        const fixture = workspaces[id];
        return {
            id,
            data: () => ({ type: fixture.type }),
            ref: {
                id,
                collection: (name: string) => {
                    if (name === "weekly_missions") return subcollection(fixture.missions, id);
                    if (name === "category_planning") return subcollection(fixture.plannings ?? {}, id);
                    throw new Error(`subcoleção inesperada: ${name}`);
                },
            },
        };
    };

    const makeQuery = () => {
        const query: any = {
            __only: null as string | null,
            __pageSize: null as number | null,
            __startAfter: null as string | null,
            where(_field: unknown, _op: string, value: string) {
                query.__only = value;
                return query;
            },
            orderBy() {
                return query;
            },
            limit(size: number) {
                query.__pageSize = size;
                return query;
            },
            startAfter(doc: any) {
                query.__startAfter = doc.id;
                return query;
            },
            async get() {
                let ids = Object.keys(workspaces).sort();
                if (query.__only) ids = ids.filter((id) => id === query.__only);
                if (query.__startAfter !== null) ids = ids.filter((id) => id > query.__startAfter);
                const page = query.__pageSize === null ? ids : ids.slice(0, query.__pageSize);
                return {
                    empty: page.length === 0,
                    size: page.length,
                    docs: page.map(workspaceDoc),
                };
            },
        };
        return query;
    };

    return {
        collection: (name: string) => {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return makeQuery();
        },
        batch: () => ({
            __ops: 0,
            set(ref: any, data: Record<string, any>) {
                written.push({ id: `${ref.__workspaceId}/${ref.id}`, data });
                this.__ops++;
            },
            update() {
                throw new Error("o script só usa set(merge)");
            },
            delete() {
                throw new Error("o script não apaga nada");
            },
            async commit() {
                return [];
            },
        }),
    };
}

const silent = () => undefined;

beforeEach(() => {
    written = [];
});

function legacyMission(type: string, status = "pending") {
    return {
        id: type,
        type,
        name: "Equipe planeja limites para pelo menos 3 categorias para organizar a semana.",
        status,
        progress: status === "completed" ? 3 : 1,
        target: 3,
        rewardXp: 150,
        weekId: WEEK_ID,
    };
}

describe("retag_weekly_missions", () => {
    it("dry-run não escreve nada e conta o que faria", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: true, now: NOW }, silent);

        expect(written).toEqual([]);
        expect(summary.replaced).toBe(1);
        expect(summary.tagged).toBe(0);
    });

    it("substitui a missão ABERTA de empresa pelo template corporativo da semana", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "business",
                missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") },
                plannings: { p1: { amount: 900, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" } },
            },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        const template = selectMissionTemplate("business", "consistency", WEEK_ID)!;
        expect(written).toHaveLength(1);
        expect(written[0].id).toBe(`w1/${WEEK_ID}_consistency`);
        expect(written[0].data).toMatchObject({
            templateKey: template.key,
            workspaceType: "business",
            actionPath: template.actionPath,
            nameKey: template.nameKey,
            target: template.target,
            rewardXp: template.rewardXp,
            progress: 0,
            status: "pending",
        });
        // A régua mudou: o progresso da missão anterior não significa nada nela.
        expect(written[0].data.name).toBe(buildMissionName(template, "pt", { target: template.target }));
    });

    it("missão CONCLUÍDA é só carimbada — nome, XP e status ficam intocados", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency", "completed") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.replaced).toBe(0);
        expect(summary.tagged).toBe(1);
        const patch = written[0].data;
        expect(Object.keys(patch).sort()).toEqual(["actionPath", "nameKey", "params", "templateKey", "workspaceType"]);
        // O carimbo descreve o que a missão FOI: o objetivo antigo era pessoal,
        // mesmo num workspace de empresa.
        expect(patch.templateKey).toBe("personal_consistency_plan_limits");
        expect(patch.workspaceType).toBe("personal");
    });

    it("workspace pessoal aberto é só carimbado (sem churn de texto)", async () => {
        const firestore = buildFirestore({
            w1: { type: "personal", missions: { [`${WEEK_ID}_organization`]: legacyMission("organization") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.replaced).toBe(0);
        expect(written[0].data).not.toHaveProperty("name");
        expect(written[0].data.templateKey).toBe("personal_organization_reconcile_items");
    });

    it("é idempotente: missão já carimbada é pulada (e --force recarimba)", async () => {
        const tagged = { ...legacyMission("consistency"), templateKey: "personal_consistency_plan_limits" };
        const firestore = buildFirestore({
            w1: { type: "personal", missions: { [`${WEEK_ID}_consistency`]: tagged } },
        });

        const first = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);
        expect(first.skippedAlreadyTagged).toBe(1);
        expect(written).toEqual([]);

        const forced = await retagWeeklyMissions(firestore, { dryRun: false, force: true, now: NOW }, silent);
        expect(forced.skippedAlreadyTagged).toBe(0);
        expect(written).toHaveLength(1);
    });

    it("usa a categoria de maior limite do mês no {category} do template", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "business",
                missions: { [`${WEEK_ID}_discipline`]: legacyMission("discipline") },
                plannings: {
                    p1: { amount: 900, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" },
                    p2: { amount: 2500, category: { name: "Folha" }, startMonth: "2026-01", endMonth: "2026-12" },
                    // Fora do mês corrente: não pode vencer a disputa.
                    p3: { amount: 90000, category: { name: "Obra" }, startMonth: "2025-01", endMonth: "2025-12" },
                },
            },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        const template = selectMissionTemplate("business", "discipline", WEEK_ID)!;
        const patch = written[0].data;
        if (template.params.includes("category")) {
            expect(patch.params).toEqual({ target: template.target, category: "Folha" });
            expect(patch.name).toContain("Folha");
        }
        else {
            // O template da semana é o de margem, que não tem placeholder.
            expect(patch.params).toBeUndefined();
        }
    });

    it("ignora missão com type fora do catálogo em vez de derrubar a varredura", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "personal",
                missions: {
                    [`${WEEK_ID}_mystery`]: { ...legacyMission("consistency"), type: "mystery" },
                    [`${WEEK_ID}_consistency`]: legacyMission("consistency"),
                },
            },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.skippedUnknownType).toBe(1);
        expect(summary.tagged).toBe(1);
    });

    it("limita a um workspace quando pedido", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
            w2: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, workspaceId: "w2", now: NOW }, silent);

        expect(summary.workspaces).toBe(1);
        expect(written.map((w) => w.id)).toEqual([`w2/${WEEK_ID}_consistency`]);
    });
});

describe("retag_weekly_missions — parseArgs", () => {
    it("dry-run é o padrão e --apply é a única forma de escrever", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
    });

    it("lê workspace, semana, página e force", () => {
        const options = parseArgs(["--workspace=w9", "--week=2026-W05", "--page-size=50", "--force"]);
        expect(options.workspaceId).toBe("w9");
        expect(options.weekId).toBe("2026-W05");
        expect(options.pageSize).toBe(50);
        expect(options.force).toBe(true);
    });

    it("ignora --page-size inválido", () => {
        expect(parseArgs(["--page-size=zero"]).pageSize).toBeUndefined();
        expect(parseArgs(["--page-size=-3"]).pageSize).toBeUndefined();
    });
});
