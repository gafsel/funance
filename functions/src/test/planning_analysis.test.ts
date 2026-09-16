import {
    ALLOCATION_TARGETS,
    MAX_CONTEXT_CATEGORIES,
    PlanningAllocation,
    PlanningCategoryInput,
    buildAllocationTotals,
    buildPlanningCategoryContext,
    computeProjectedIncome,
    isValidPlanningAllocation,
    resolveBenchmarksBRL,
    validatePlanningAnalysis,
} from "../features/finance/domain/services/planning_analysis.utils";
import { CategoryGroup } from "../features/coaching/domain/models/category_group.model";

function categoryInput(overrides: Partial<PlanningCategoryInput>): PlanningCategoryInput {
    return {
        categoryId: "cat-1",
        categoryName: "Categoria",
        allocation: "comfort",
        group: CategoryGroup.other,
        plannedAmount: 0,
        actualAmount: 0,
        avgActual3Months: 0,
        ...overrides,
    };
}

describe("computeProjectedIncome", () => {
    it("usa a receita planejada do mês corrente quando existe", () => {
        const result = computeProjectedIncome(5000, [3000, 4000, 0]);
        expect(result.projectedIncome).toBe(5000);
        expect(result.source).toBe("plannedCurrentMonth");
    });

    it("cai para a média realizada dos meses completos COM receita", () => {
        const result = computeProjectedIncome(0, [3000, 0, 6000]);
        expect(result.projectedIncome).toBe(4500);
        expect(result.source).toBe("avgActual3Months");
    });

    it("retorna null quando não há planejado nem realizado", () => {
        const result = computeProjectedIncome(0, [0, 0, 0]);
        expect(result.projectedIncome).toBeNull();
        expect(result.source).toBeNull();
    });
});

describe("buildPlanningCategoryContext", () => {
    it("calcula percentuais sobre a renda prevista e marca grupos essenciais", () => {
        const entries = buildPlanningCategoryContext(
            [
                categoryInput({
                    categoryId: "mercado",
                    allocation: "essential",
                    group: CategoryGroup.groceries,
                    plannedAmount: 1200,
                    actualAmount: 600,
                    avgActual3Months: 1000,
                }),
            ],
            8000
        );

        expect(entries).toHaveLength(1);
        expect(entries[0].plannedPctOfIncome).toBe(15); // 1200 / 8000
        expect(entries[0].actualPctOfIncome).toBe(7.5); // 600 / 8000
        expect(entries[0].avgActualPctOfIncome).toBe(12.5); // 1000 / 8000
        expect(entries[0].isEssentialGroup).toBe(true);
    });

    it("descarta categorias sem sinal quando existem categorias com sinal", () => {
        const entries = buildPlanningCategoryContext(
            [
                categoryInput({ categoryId: "com-gasto", plannedAmount: 500 }),
                categoryInput({ categoryId: "sem-gasto" }),
            ],
            5000
        );

        expect(entries.map(e => e.categoryId)).toEqual(["com-gasto"]);
    });

    it("mantém todas as categorias quando NENHUMA tem sinal (workspace novo)", () => {
        const entries = buildPlanningCategoryContext(
            [categoryInput({ categoryId: "a" }), categoryInput({ categoryId: "b" })],
            5000
        );

        expect(entries).toHaveLength(2);
    });

    it("ordena por compromisso mensal decrescente e respeita o limite de categorias", () => {
        const inputs = Array.from({ length: MAX_CONTEXT_CATEGORIES + 5 }, (_, i) =>
            categoryInput({ categoryId: `cat-${i}`, plannedAmount: i + 1 })
        );

        const entries = buildPlanningCategoryContext(inputs, 10000);
        expect(entries).toHaveLength(MAX_CONTEXT_CATEGORIES);
        expect(entries[0].categoryId).toBe(`cat-${MAX_CONTEXT_CATEGORIES + 4}`);
    });
});

describe("buildAllocationTotals", () => {
    it("soma planejado/realizado por alocação e compara com os alvos 50/30/20", () => {
        const entries = buildPlanningCategoryContext(
            [
                categoryInput({ categoryId: "aluguel", allocation: "essential", plannedAmount: 3000, actualAmount: 3000 }),
                categoryInput({ categoryId: "mercado", allocation: "essential", plannedAmount: 1500, actualAmount: 1000 }),
                categoryInput({ categoryId: "lazer", allocation: "comfort", plannedAmount: 1000, actualAmount: 500 }),
            ],
            10000
        );

        const totals = buildAllocationTotals(entries, 10000);
        expect(totals.map(t => t.allocation)).toEqual(["essential", "comfort", "investment"]);

        const essential = totals[0];
        expect(essential.targetPct).toBe(ALLOCATION_TARGETS.essential);
        expect(essential.targetBRL).toBe(5000);
        expect(essential.plannedBRL).toBe(4500);
        expect(essential.plannedPct).toBe(45);
        expect(essential.actualBRL).toBe(4000);
        expect(essential.plannedDeltaBRL).toBe(-500);

        const investment = totals[2];
        expect(investment.plannedBRL).toBe(0);
        expect(investment.targetBRL).toBe(2000);
        expect(investment.plannedDeltaBRL).toBe(-2000);
    });
});

describe("resolveBenchmarksBRL", () => {
    it("converte as faixas de % da renda para R$", () => {
        const benchmarks = resolveBenchmarksBRL(10000);
        const housing = benchmarks.find(b => b.group === CategoryGroup.housing)!;

        expect(housing.minPct).toBe(25);
        expect(housing.maxPct).toBe(35);
        expect(housing.minBRL).toBe(2500);
        expect(housing.maxBRL).toBe(3500);
        expect(housing.isMinimumTarget).toBe(false);
    });

    it("mantém maxBRL null para metas mínimas (savings_investments)", () => {
        const benchmarks = resolveBenchmarksBRL(10000);
        const savings = benchmarks.find(b => b.group === CategoryGroup.savings_investments)!;

        expect(savings.maxPct).toBeNull();
        expect(savings.maxBRL).toBeNull();
        expect(savings.isMinimumTarget).toBe(true);
    });
});

describe("isValidPlanningAllocation", () => {
    it("aceita apenas o enum essential/comfort/investment", () => {
        expect(isValidPlanningAllocation("essential")).toBe(true);
        expect(isValidPlanningAllocation("comfort")).toBe(true);
        expect(isValidPlanningAllocation("investment")).toBe(true);
        expect(isValidPlanningAllocation("savings")).toBe(false);
        expect(isValidPlanningAllocation(null)).toBe(false);
    });
});

describe("validatePlanningAnalysis", () => {
    const allocations = new Map<string, PlanningAllocation>([
        ["mercado", "essential"],
        ["plano-saude", "comfort"],
    ]);

    it("descarta categorias com id desconhecido e números não finitos", () => {
        const result = validatePlanningAnalysis({
            summary: " Diagnóstico ",
            groups: [],
            categories: [
                {
                    categoryId: "mercado",
                    idealMonthlyAmount: 1200,
                    idealPctOfIncome: 12,
                    status: "ok",
                    suggestedAllocation: "essential",
                    shouldReclassify: false,
                    reason: "",
                },
                {
                    categoryId: "inventada",
                    idealMonthlyAmount: 100,
                    idealPctOfIncome: 1,
                    status: "ok",
                    suggestedAllocation: "comfort",
                    shouldReclassify: false,
                    reason: "",
                },
                {
                    categoryId: "plano-saude",
                    idealMonthlyAmount: Infinity,
                    idealPctOfIncome: 5,
                    status: "ok",
                    suggestedAllocation: "essential",
                    shouldReclassify: false,
                    reason: "",
                },
            ],
            insights: ["Insight válido", 42, "  "],
        }, allocations);

        expect(result.summary).toBe("Diagnóstico");
        expect(result.categories.map(c => c.categoryId)).toEqual(["mercado"]);
        expect(result.insights).toEqual(["Insight válido"]);
    });

    it("só mantém shouldReclassify com alocação válida, diferente da atual e com justificativa", () => {
        const result = validatePlanningAnalysis({
            summary: "s",
            groups: [],
            categories: [
                {
                    categoryId: "plano-saude",
                    idealMonthlyAmount: 500,
                    idealPctOfIncome: 5,
                    status: "above",
                    suggestedAllocation: "essential",
                    shouldReclassify: true,
                    reason: "Plano de saúde é gasto essencial, não conforto.",
                    savingTip: "Compare operadoras e reveja a coparticipação.",
                },
                {
                    categoryId: "mercado",
                    idealMonthlyAmount: 800,
                    idealPctOfIncome: 8,
                    status: "ok",
                    // mesma alocação atual — reclassificação deve ser neutralizada
                    suggestedAllocation: "essential",
                    shouldReclassify: true,
                    reason: "Já é essencial.",
                },
            ],
            insights: [],
        }, allocations);

        const planoSaude = result.categories.find(c => c.categoryId === "plano-saude")!;
        expect(planoSaude.shouldReclassify).toBe(true);
        expect(planoSaude.suggestedAllocation).toBe("essential");
        expect(planoSaude.savingTip).toBe("Compare operadoras e reveja a coparticipação.");

        const mercado = result.categories.find(c => c.categoryId === "mercado")!;
        expect(mercado.shouldReclassify).toBe(false);
        expect(mercado.suggestedAllocation).toBeNull();
    });

    it("neutraliza reclassificação sem justificativa e status fora do enum", () => {
        const result = validatePlanningAnalysis({
            summary: "s",
            groups: [
                { allocation: "essential", currentPct: 55, targetPct: 50, deltaBRL: 500 },
                { allocation: "poupanca", currentPct: 10, targetPct: 20, deltaBRL: -100 },
                { allocation: "comfort", currentPct: NaN, targetPct: 30, deltaBRL: 0 },
            ],
            categories: [
                {
                    categoryId: "plano-saude",
                    idealMonthlyAmount: 500,
                    idealPctOfIncome: 5,
                    status: "critical",
                    suggestedAllocation: "essential",
                    shouldReclassify: true,
                    reason: "   ",
                },
            ],
            insights: [],
        }, allocations);

        expect(result.groups).toHaveLength(1);
        expect(result.groups[0].allocation).toBe("essential");

        const category = result.categories[0];
        expect(category.status).toBe("ok");
        expect(category.shouldReclassify).toBe(false);
        expect(category.savingTip).toBeNull();
    });

    it("retorna estrutura vazia para payloads malformados", () => {
        const result = validatePlanningAnalysis(null, allocations);
        expect(result.summary).toBe("");
        expect(result.groups).toEqual([]);
        expect(result.categories).toEqual([]);
        expect(result.insights).toEqual([]);
    });
});
