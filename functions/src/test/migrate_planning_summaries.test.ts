/**
 * Migração F1.5 (`migrate_planning_summaries.ts`): dry-run, idempotência,
 * cálculo dos marcadores, escopo por workspace e paginação.
 */

import { buildPlanningMarks, migratePlanningSummaries, parseArgs } from "../scripts/migrate_planning_summaries";
import { PLANNING_FULLY_SUMMARIZED } from "../features/finance/domain/services/summary.service";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";

const CATEGORY: CategoryModel = {
    id: "cat-moradia",
    name: "Moradia",
    icon: "home",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

const NOW = new Date("2026-09-15T15:00:00.000Z"); // mês corrente 2026-09, horizonte 2027-08

type Docs = Record<string, Record<string, any>>;

let committedBatchSizes: number[];

/** Firestore falso: collectionGroup/subcoleção paginados e batch. */
function buildFirestore(docsByWorkspace: Record<string, Docs>): any {
    const allDocs = (workspaceId?: string) => {
        const entries: Array<[string, string, Record<string, any>]> = [];
        for (const [wid, docs] of Object.entries(docsByWorkspace)) {
            if (workspaceId && wid !== workspaceId) continue;
            for (const [id, data] of Object.entries(docs)) entries.push([wid, id, data]);
        }
        return entries.sort(([, a], [, b]) => (a < b ? -1 : a > b ? 1 : 0));
    };

    const makeQuery = (workspaceId?: string) => {
        const query: any = {
            __pageSize: null as number | null,
            __startAfter: null as string | null,
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
                let entries = allDocs(workspaceId);
                if (query.__startAfter !== null) {
                    entries = entries.filter(([, id]) => id > query.__startAfter);
                }
                const page = query.__pageSize === null ? entries : entries.slice(0, query.__pageSize);
                return {
                    empty: page.length === 0,
                    size: page.length,
                    docs: page.map(([wid, id, data]) => ({
                        id,
                        data: () => ({ ...data }),
                        ref: {
                            id,
                            __workspaceId: wid,
                            parent: { parent: { id: wid } },
                        },
                    })),
                };
            },
        };
        return query;
    };

    return {
        collectionGroup: (name: string) => {
            if (name !== "category_planning") throw new Error(`grupo inesperado: ${name}`);
            return makeQuery();
        },
        collection: (name: string) => {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return {
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => {
                        if (sub !== "category_planning") throw new Error(`subcoleção inesperada: ${sub}`);
                        return makeQuery(workspaceId);
                    },
                }),
            };
        },
        batch: () => {
            const operations: Array<() => void> = [];
            return {
                set(ref: any, data: Record<string, any>) {
                    operations.push(() => {
                        const docs = docsByWorkspace[ref.__workspaceId];
                        docs[ref.id] = { ...docs[ref.id], ...data };
                    });
                },
                update: jest.fn(),
                delete: jest.fn(),
                async commit() {
                    committedBatchSizes.push(operations.length);
                    operations.forEach((operation) => operation());
                },
            };
        },
    };
}

const silent = () => undefined;

function planningDoc(overrides: Record<string, any> = {}): Record<string, any> {
    return {
        category: CATEGORY,
        amount: 1000,
        startMonth: "2026-01",
        endMonth: "2030-12",
        ...overrides,
    };
}

describe("buildPlanningMarks", () => {
    it("aplica a janela do horizonte rolante", () => {
        expect(buildPlanningMarks(planningDoc() as any, NOW)).toEqual({
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });
    });

    it("marca como concluído quem acaba dentro do horizonte", () => {
        const marks = buildPlanningMarks(planningDoc({ endMonth: "2026-12" }) as any, NOW);
        expect(marks).toMatchObject({ summarizedUntil: PLANNING_FULLY_SUMMARIZED, appliedUntil: "2026-12" });
    });

    it("planejamento no passado não tem nada aplicado", () => {
        expect(buildPlanningMarks(planningDoc({ startMonth: "2024-01", endMonth: "2025-06" }) as any, NOW)).toEqual({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedAmount: null,
            appliedAmountCents: null,
            appliedFrom: null,
            appliedUntil: null,
        });
    });

    it("devolve null para período fora do formato", () => {
        expect(buildPlanningMarks(planningDoc({ startMonth: "2026" }) as any, NOW)).toBeNull();
    });
});

describe("migrate_planning_summaries", () => {
    beforeEach(() => {
        committedBatchSizes = [];
    });

    it("dry-run não escreve nada", async () => {
        const fixture = { w1: { p1: planningDoc() } };
        const firestore = buildFirestore(fixture);

        const summary = await migratePlanningSummaries(firestore, { dryRun: true, now: NOW }, silent);

        expect(summary).toMatchObject({ scanned: 1, marked: 1, failed: 0 });
        expect(fixture.w1.p1.summarizedUntil).toBeUndefined();
        expect(committedBatchSizes).toEqual([]);
    });

    it("grava os marcadores esperados", async () => {
        const fixture = { w1: { p1: planningDoc(), p2: planningDoc({ amount: 300, endMonth: "2026-10" }) } };
        const firestore = buildFirestore(fixture);

        await migratePlanningSummaries(firestore, { dryRun: false, now: NOW }, silent);

        expect(fixture.w1.p1).toMatchObject({
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });
        expect(fixture.w1.p2).toMatchObject({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedAmount: 300,
            appliedAmountCents: 30000,
            appliedUntil: "2026-10",
        });
    });

    it("é idempotente: a segunda execução pula quem já está marcado", async () => {
        const fixture = { w1: { p1: planningDoc() } };
        const firestore = buildFirestore(fixture);

        await migratePlanningSummaries(firestore, { dryRun: false, now: NOW }, silent);
        committedBatchSizes = [];

        const second = await migratePlanningSummaries(firestore, { dryRun: false, now: NOW }, silent);

        expect(second).toMatchObject({ scanned: 1, marked: 0, skippedAlreadyMarked: 1 });
        expect(committedBatchSizes).toEqual([]);
    });

    it("--force recalcula mesmo quem já está marcado", async () => {
        const fixture = { w1: { p1: planningDoc({ summarizedUntil: "2026-01", appliedFrom: "2025-01", appliedUntil: "2026-01" }) } };
        const firestore = buildFirestore(fixture);

        const summary = await migratePlanningSummaries(firestore, { dryRun: false, now: NOW, force: true }, silent);

        expect(summary).toMatchObject({ marked: 1, skippedAlreadyMarked: 0 });
        expect(fixture.w1.p1).toMatchObject({ summarizedUntil: "2027-08", appliedFrom: "2026-09" });
    });

    it("conta período inválido sem falhar", async () => {
        const fixture = { w1: { p1: planningDoc({ startMonth: "janeiro" }) } };
        const firestore = buildFirestore(fixture);

        const summary = await migratePlanningSummaries(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary).toMatchObject({ scanned: 1, marked: 0, skippedInvalid: 1, failed: 0 });
        expect(fixture.w1.p1.summarizedUntil).toBeUndefined();
    });

    it("limita o escopo a um workspace", async () => {
        const fixture = { w1: { p1: planningDoc() }, w2: { p2: planningDoc() } };
        const firestore = buildFirestore(fixture);

        const summary = await migratePlanningSummaries(firestore, { dryRun: false, now: NOW, workspaceId: "w2" }, silent);

        expect(summary).toMatchObject({ scanned: 1 });
        expect(fixture.w1.p1.summarizedUntil).toBeUndefined();
        expect(fixture.w2.p2.summarizedUntil).toBe("2027-08");
    });

    it("pagina a base inteira", async () => {
        const docs: Record<string, any> = {};
        for (let i = 0; i < 25; i++) {
            docs[`p${String(i).padStart(2, "0")}`] = planningDoc();
        }
        const fixture = { w1: docs };
        const firestore = buildFirestore(fixture);

        const summary = await migratePlanningSummaries(firestore, { dryRun: false, now: NOW, pageSize: 10 }, silent);

        expect(summary.scanned).toBe(25);
        expect(Object.values(docs).every((doc) => doc.summarizedUntil === "2027-08")).toBe(true);
    });

    it("parseArgs: dry-run por padrão e flags reconhecidas", () => {
        expect(parseArgs([])).toMatchObject({ dryRun: true, force: false });
        expect(parseArgs(["--apply", "--force", "--workspace=w1", "--project=p1", "--page-size=25"])).toMatchObject({
            dryRun: false,
            force: true,
            workspaceId: "w1",
            projectId: "p1",
            pageSize: 25,
        });
    });
});
