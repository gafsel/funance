/**
 * Testes do GamificationRepositoryImpl com o FORMATO REAL dos documentos.
 *
 * Cobrem dois dos bugs da F2.1:
 *  1. a coleção de planejamentos é `category_planning` (singular) — o plural
 *     fazia planner/golden_rule/first_planning/planning_month nunca dispararem;
 *  2. `period_summaries` tem UM documento por mês, com um mapa `categories`;
 *     devolver o documento inteiro deixava `actualAmount`/`category.type`
 *     sempre undefined no serviço.
 */
const mockFirestoreState: any = { collections: {} };

jest.mock("firebase-admin", () => {
    const firestore: any = () => ({
        collection: (path: string) => {
            const docs = mockFirestoreState.collections[path] || [];
            const query: any = {
                where: () => query,
                limit: () => query,
                select: () => query,
                count: () => ({ get: async () => ({ data: () => ({ count: docs.length }) }) }),
                async get() {
                    mockFirestoreState.queried.push(path);
                    return { docs, empty: docs.length === 0, size: docs.length };
                },
            };
            return query;
        },
    });
    firestore.Timestamp = { fromDate: (date: Date) => date };
    firestore.FieldValue = { serverTimestamp: () => "ts", increment: (n: number) => n };
    return { firestore };
});

import { GamificationRepositoryImpl } from "../features/goal/data/repositories/gamification.repository.impl";

const doc = (id: string, data: any) => ({ id, data: () => data });

describe("GamificationRepositoryImpl.getCategoryPlannings", () => {
    beforeEach(() => {
        mockFirestoreState.collections = {};
        mockFirestoreState.queried = [];
    });

    it("lê a coleção `category_planning` (singular), não `category_plannings`", async () => {
        mockFirestoreState.collections["workspaces/w1/category_planning"] = [
            doc("p1", { amount: 300, category: { id: "c1", name: "Alimentação", allocation: "essential" } }),
        ];
        mockFirestoreState.collections["workspaces/w1/category_plannings"] = [
            doc("x", { amount: 999 }),
        ];

        const result = await new GamificationRepositoryImpl().getCategoryPlannings("w1");

        expect(mockFirestoreState.queried).toEqual(["workspaces/w1/category_planning"]);
        // O `id` vem do DOCUMENTO (a coleção não o guarda como campo) e é o
        // repositório que o acrescenta desde F1.11, para que a leitura caiba
        // em `CategoryPlanningModel` em vez de `any[]`.
        expect(result).toEqual([
            { id: "p1", amount: 300, category: { id: "c1", name: "Alimentação", allocation: "essential" } },
        ]);
    });
});

describe("GamificationRepositoryImpl.getPeriodSummaries", () => {
    beforeEach(() => {
        mockFirestoreState.collections = {};
        mockFirestoreState.queried = [];
    });

    /** Forma real do documento: um por mês, com mapa `categories`. */
    const summaryDoc = doc("2026-07", {
        year: 2026,
        month: 7,
        week: null,
        runtimeType: "month",
        categories: {
            salario: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 8000 },
            lazer: { generalPlannedAmount: 500, specificPlannedAmount: 400, actualAmount: 620 },
            aportes: { generalPlannedAmount: 1000, specificPlannedAmount: 1000, actualAmount: 1000 },
        },
    });

    it("achata o mapa `categories` em uma linha por categoria, com join em categories", async () => {
        mockFirestoreState.collections["workspaces/w1/period_summaries"] = [summaryDoc];
        mockFirestoreState.collections["workspaces/w1/categories"] = [
            doc("salario", { name: "Salário", type: "income", isDeleted: false }),
            doc("lazer", { name: "Lazer", type: "expense", allocation: "comfort", isDeleted: false }),
            doc("aportes", { name: "Aportes", type: "expense", allocation: "investment", isDeleted: false }),
        ];

        const rows = await new GamificationRepositoryImpl().getPeriodSummaries("w1", 2026, 7);

        expect(rows).toEqual([
            {
                categoryId: "salario", type: "income", allocation: undefined, isSystem: false,
                actualAmount: 8000, generalPlannedAmount: 0, specificPlannedAmount: 0,
            },
            {
                categoryId: "lazer", type: "expense", allocation: "comfort", isSystem: false,
                actualAmount: 620, generalPlannedAmount: 500, specificPlannedAmount: 400,
            },
            {
                categoryId: "aportes", type: "expense", allocation: "investment", isSystem: false,
                actualAmount: 1000, generalPlannedAmount: 1000, specificPlannedAmount: 1000,
            },
        ]);
    });

    it("ignora categorias isDeleted e categorias sem documento correspondente", async () => {
        mockFirestoreState.collections["workspaces/w1/period_summaries"] = [summaryDoc];
        mockFirestoreState.collections["workspaces/w1/categories"] = [
            doc("salario", { type: "income", isDeleted: false }),
            doc("lazer", { type: "expense", allocation: "comfort", isDeleted: true }),
            // 'aportes' não existe na coleção de categorias
        ];

        const rows = await new GamificationRepositoryImpl().getPeriodSummaries("w1", 2026, 7);

        expect(rows.map((r) => r.categoryId)).toEqual(["salario"]);
    });

    it("devolve lista vazia quando não há summary do mês", async () => {
        mockFirestoreState.collections["workspaces/w1/period_summaries"] = [];
        mockFirestoreState.collections["workspaces/w1/categories"] = [
            doc("salario", { type: "income", isDeleted: false }),
        ];

        const rows = await new GamificationRepositoryImpl().getPeriodSummaries("w1", 2026, 7);

        expect(rows).toEqual([]);
    });
});

describe("GamificationRepositoryImpl.getPeriodSummaries — marcação isSystem", () => {
    beforeEach(() => {
        mockFirestoreState.collections = {};
        mockFirestoreState.queried = [];
    });

    it("marca como isSystem o saldo inicial e as virtuais, mesmo sem a flag no documento", async () => {
        mockFirestoreState.collections["workspaces/w1/period_summaries"] = [
            doc("2026-07", {
                year: 2026,
                month: 7,
                categories: {
                    "initial-balance": { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 5000 },
                    virtual_debt_expense: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 900 },
                    virtual_investment_expense: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 400 },
                    lazer: { generalPlannedAmount: 300, specificPlannedAmount: 300, actualAmount: 250 },
                },
            }),
        ];
        mockFirestoreState.collections["workspaces/w1/categories"] = [
            // Workspace legado: os documentos ainda não têm a flag isSystem.
            doc("initial-balance", { type: "income", isDeleted: false }),
            doc("virtual_debt_expense", { type: "expense", isDeleted: false }),
            doc("virtual_investment_expense", { type: "expense", allocation: "investment", isDeleted: false }),
            doc("lazer", { type: "expense", allocation: "comfort", isDeleted: false }),
        ];

        const rows = await new GamificationRepositoryImpl().getPeriodSummaries("w1", 2026, 7);

        const byId = Object.fromEntries(rows.map((r) => [r.categoryId, r.isSystem]));
        expect(byId).toEqual({
            "initial-balance": true,
            virtual_debt_expense: true,
            virtual_investment_expense: true,
            lazer: false,
        });
    });

    it("respeita a flag isSystem quando ela existe no documento", async () => {
        mockFirestoreState.collections["workspaces/w1/period_summaries"] = [
            doc("2026-07", {
                year: 2026, month: 7,
                categories: { minha: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 10 } },
            }),
        ];
        mockFirestoreState.collections["workspaces/w1/categories"] = [
            doc("minha", { type: "expense", isDeleted: false, isSystem: true }),
        ];

        const rows = await new GamificationRepositoryImpl().getPeriodSummaries("w1", 2026, 7);

        expect(rows[0].isSystem).toBe(true);
    });
});
