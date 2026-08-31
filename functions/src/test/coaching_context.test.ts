import {
    buildCategoryProfile,
    buildLifestyleDiagnosis,
    buildSavingsOpportunities,
    computeBenchmarkStatus,
    computeMonthlyIncome,
    computeOpportunityScore,
    CategoryProfileInput,
    ESSENTIAL_GROUPS,
} from "../features/coaching/domain/services/coaching_context.utils";
import { CategoryGroup } from "../features/coaching/domain/models/category_group.model";
import { CategoryGroupService } from "../features/coaching/domain/services/category_group.service";
import { CategoryType } from "../features/workspace/domain/models/category.model";

function profileInput(overrides: Partial<CategoryProfileInput>): CategoryProfileInput {
    return {
        categoryId: "cat-1",
        categoryName: "Categoria",
        group: CategoryGroup.other,
        sumLast3Months: 0,
        monthsWithData: 3,
        txCount: 0,
        installmentsTotal: 0,
        recurringAmount: 0,
        prevAvgMonthly: null,
        ...overrides,
    };
}

describe("computeMonthlyIncome", () => {
    it("usa a média dos meses completos com receita", () => {
        const result = computeMonthlyIncome([3000, 0, 6000], 1000);
        expect(result.monthlyIncome).toBe(4500);
        expect(result.source).toBe("avg3FullMonths");
    });

    it("cai para a receita do mês corrente quando não há meses completos com receita", () => {
        const result = computeMonthlyIncome([0, 0, 0], 2500);
        expect(result.monthlyIncome).toBe(2500);
        expect(result.source).toBe("currentMonth");
    });

    it("retorna null quando não há nenhuma receita registrada", () => {
        const result = computeMonthlyIncome([0, 0, 0], 0);
        expect(result.monthlyIncome).toBeNull();
        expect(result.source).toBeNull();
    });
});

describe("buildCategoryProfile — pctOfIncome / pctOfExpenses", () => {
    const inputs: CategoryProfileInput[] = [
        profileInput({
            categoryId: "mercado",
            categoryName: "Mercado",
            group: CategoryGroup.groceries,
            sumLast3Months: 3600, // avgMonthly 1200
            txCount: 12,
            installmentsTotal: 3600,
            recurringAmount: 0,
        }),
        profileInput({
            categoryId: "streaming",
            categoryName: "Streaming",
            group: CategoryGroup.subscriptions_services,
            sumLast3Months: 2400, // avgMonthly 800
            txCount: 6,
            installmentsTotal: 2400,
            recurringAmount: 2400,
        }),
    ];

    it("calcula pctOfIncome e pctOfExpenses sobre a renda e o total de despesas", () => {
        const profile = buildCategoryProfile(inputs, 8000);
        const mercado = profile.find(p => p.categoryId === "mercado")!;
        const streaming = profile.find(p => p.categoryId === "streaming")!;

        expect(mercado.avgMonthly).toBe(1200);
        expect(mercado.pctOfIncome).toBe(15); // 1200 / 8000
        expect(mercado.pctOfExpenses).toBe(60); // 1200 / 2000
        expect(mercado.avgTicket).toBe(300); // 3600 / 12
        expect(mercado.recurringShare).toBe(0);

        expect(streaming.pctOfIncome).toBe(10);
        expect(streaming.pctOfExpenses).toBe(40);
        expect(streaming.recurringShare).toBe(1);
    });

    it("com renda null, pctOfIncome fica null mas pctOfExpenses continua", () => {
        const profile = buildCategoryProfile(inputs, null);
        const mercado = profile.find(p => p.categoryId === "mercado")!;
        expect(mercado.pctOfIncome).toBeNull();
        expect(mercado.pctOfExpenses).toBe(60);
    });

    it("calcula trendPct vs a média dos 3 meses anteriores (null sem histórico)", () => {
        const profile = buildCategoryProfile([
            profileInput({ categoryId: "a", sumLast3Months: 3600, prevAvgMonthly: 1000 }), // 1200 vs 1000
            profileInput({ categoryId: "b", sumLast3Months: 3600, prevAvgMonthly: null }),
        ], 8000);

        expect(profile.find(p => p.categoryId === "a")!.trendPct).toBe(20);
        expect(profile.find(p => p.categoryId === "b")!.trendPct).toBeNull();
    });

    it("ordena por avgMonthly decrescente e descarta categorias sem movimento", () => {
        const profile = buildCategoryProfile([
            profileInput({ categoryId: "zerada", sumLast3Months: 0, txCount: 0 }),
            profileInput({ categoryId: "menor", sumLast3Months: 300 }),
            profileInput({ categoryId: "maior", sumLast3Months: 3000 }),
        ], null);

        expect(profile.map(p => p.categoryId)).toEqual(["maior", "menor"]);
    });
});

describe("computeBenchmarkStatus", () => {
    it("classifica below/within/above e calcula o delta em R$ acima do teto", () => {
        // groceries: 10–15% da renda
        expect(computeBenchmarkStatus(CategoryGroup.groceries, 8, 10000).status).toBe("below");
        expect(computeBenchmarkStatus(CategoryGroup.groceries, 12, 10000).status).toBe("within");

        const above = computeBenchmarkStatus(CategoryGroup.groceries, 20, 10000);
        expect(above.status).toBe("above");
        expect(above.deltaMonthlyBRL).toBe(500); // (20 - 15)% de R$ 10.000
    });

    it("nos limites exatos da faixa o status é within (e delta 0)", () => {
        expect(computeBenchmarkStatus(CategoryGroup.groceries, 10, 10000).status).toBe("within");
        const atMax = computeBenchmarkStatus(CategoryGroup.groceries, 15, 10000);
        expect(atMax.status).toBe("within");
        expect(atMax.deltaMonthlyBRL).toBe(0);
    });

    it("savings_investments é meta mínima: nunca above, below apenas sob o mínimo", () => {
        expect(computeBenchmarkStatus(CategoryGroup.savings_investments, 5, 10000).status).toBe("below");
        expect(computeBenchmarkStatus(CategoryGroup.savings_investments, 30, 10000).status).toBe("within");
        expect(computeBenchmarkStatus(CategoryGroup.savings_investments, 30, 10000).deltaMonthlyBRL).toBe(0);
    });

    it("sem renda ou sem benchmark o status fica null", () => {
        expect(computeBenchmarkStatus(CategoryGroup.groceries, null, null).status).toBeNull();
        expect(computeBenchmarkStatus(CategoryGroup.other, 50, 10000).status).toBeNull();
    });
});

describe("buildLifestyleDiagnosis", () => {
    it("agrega por grupo e aplica o benchmark", () => {
        const profile = buildCategoryProfile([
            profileInput({ categoryId: "aluguel", group: CategoryGroup.housing, sumLast3Months: 12000 }), // 4000/mês
            profileInput({ categoryId: "condominio", group: CategoryGroup.housing, sumLast3Months: 3000 }), // 1000/mês
            profileInput({ categoryId: "mercado", group: CategoryGroup.groceries, sumLast3Months: 3000 }), // 1000/mês
        ], 10000);

        const lifestyle = buildLifestyleDiagnosis(profile, 10000);
        const housing = lifestyle.find(l => l.group === CategoryGroup.housing)!;
        const groceries = lifestyle.find(l => l.group === CategoryGroup.groceries)!;

        expect(housing.avgMonthly).toBe(5000);
        expect(housing.actualPctOfIncome).toBe(50);
        expect(housing.status).toBe("above"); // teto 35%
        expect(housing.deltaMonthlyBRL).toBe(1500); // (50 - 35)% de R$ 10.000

        expect(groceries.actualPctOfIncome).toBe(10);
        expect(groceries.status).toBe("within");
    });

    it("com monthlyIncome null limita o diagnóstico a % das despesas", () => {
        const profile = buildCategoryProfile([
            profileInput({ categoryId: "aluguel", group: CategoryGroup.housing, sumLast3Months: 9000 }),
            profileInput({ categoryId: "mercado", group: CategoryGroup.groceries, sumLast3Months: 3000 }),
        ], null);

        const lifestyle = buildLifestyleDiagnosis(profile, null);
        const housing = lifestyle.find(l => l.group === CategoryGroup.housing)!;

        expect(housing.actualPctOfIncome).toBeNull();
        expect(housing.status).toBeNull();
        expect(housing.deltaMonthlyBRL).toBe(0);
        expect(housing.pctOfExpenses).toBe(75);
    });
});

describe("computeOpportunityScore / buildSavingsOpportunities", () => {
    it("aplica os fatores de recorrência, benchmark e tendência", () => {
        expect(computeOpportunityScore(1000, 0, false, null)).toBe(1000);
        expect(computeOpportunityScore(1000, 1, false, null)).toBe(500); // 100% recorrente = metade
        expect(computeOpportunityScore(1000, 0, true, null)).toBe(1500); // grupo acima da faixa
        expect(computeOpportunityScore(1000, 0, false, 30)).toBe(1300); // tendência de alta
        expect(computeOpportunityScore(1000, 0, false, -30)).toBe(1000); // queda não reduz o score
        expect(computeOpportunityScore(1000, 0.5, true, 20)).toBe(1350); // 1000×0.75×1.5×1.2
    });

    it("ordena por score: recurringShare alto rebaixa, tendência de alta promove", () => {
        // Mesmo gasto médio; a categoria variável e em alta deve vir primeiro.
        const profile = buildCategoryProfile([
            profileInput({
                categoryId: "assinaturas",
                categoryName: "Assinaturas",
                group: CategoryGroup.subscriptions_services,
                sumLast3Months: 3000,
                installmentsTotal: 3000,
                recurringAmount: 3000,
                txCount: 9,
            }),
            profileInput({
                categoryId: "delivery",
                categoryName: "Delivery",
                group: CategoryGroup.dining_out,
                sumLast3Months: 3000,
                installmentsTotal: 3000,
                recurringAmount: 0,
                txCount: 30,
                prevAvgMonthly: 800, // 1000 vs 800 => +25%
            }),
        ], null);

        const opportunities = buildSavingsOpportunities(profile, buildLifestyleDiagnosis(profile, null));

        expect(opportunities.map(o => o.categoryName)).toEqual(["Delivery", "Assinaturas"]);
        expect(opportunities[0].score).toBe(1250); // 1000 × 1 × 1 × 1.25
        expect(opportunities[1].score).toBe(500); // 1000 × 0.5
    });

    it("multiplica por 1.5 quando o grupo está acima da faixa e marca isEssential", () => {
        // Renda 10.000; farmácia 1.500/mês => 15% (teto 10%) => above
        const profile = buildCategoryProfile([
            profileInput({
                categoryId: "farmacia",
                categoryName: "Farmácia",
                group: CategoryGroup.health_pharmacy,
                sumLast3Months: 4500,
            }),
            profileInput({
                categoryId: "lazer",
                categoryName: "Lazer",
                group: CategoryGroup.leisure,
                sumLast3Months: 3000, // 1000/mês => 10% => within
            }),
        ], 10000);

        const lifestyle = buildLifestyleDiagnosis(profile, 10000);
        const opportunities = buildSavingsOpportunities(profile, lifestyle);

        const farmacia = opportunities.find(o => o.categoryName === "Farmácia")!;
        const lazer = opportunities.find(o => o.categoryName === "Lazer")!;

        expect(farmacia.groupStatus).toBe("above");
        expect(farmacia.score).toBe(2250); // 1500 × 1.5
        expect(farmacia.isEssential).toBe(true);
        expect(lazer.score).toBe(1000);
        expect(lazer.isEssential).toBe(false);
    });

    it("limita a 5 oportunidades e exclui savings_investments", () => {
        const inputs = Array.from({ length: 7 }, (_, i) => profileInput({
            categoryId: `cat-${i}`,
            categoryName: `Categoria ${i}`,
            group: CategoryGroup.leisure,
            sumLast3Months: 300 * (i + 1),
        }));
        inputs.push(profileInput({
            categoryId: "aportes",
            categoryName: "Aportes",
            group: CategoryGroup.savings_investments,
            sumLast3Months: 90000,
        }));

        const profile = buildCategoryProfile(inputs, null);
        const opportunities = buildSavingsOpportunities(profile, buildLifestyleDiagnosis(profile, null));

        expect(opportunities).toHaveLength(5);
        expect(opportunities.some(o => o.group === CategoryGroup.savings_investments)).toBe(false);
    });

    it("ESSENTIAL_GROUPS cobre os grupos de consumo necessário", () => {
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.groceries)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.health_pharmacy)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.transport)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.housing)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.pets)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.education)).toBe(true);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.dining_out)).toBe(false);
        expect(ESSENTIAL_GROUPS.has(CategoryGroup.subscriptions_services)).toBe(false);
    });
});

describe("CategoryGroupService", () => {
    const financeRepository = {
        getCoachingCategoryGroups: jest.fn(),
        saveCoachingCategoryGroups: jest.fn(),
    };
    const aiRepository = {
        classifyCategoryGroups: jest.fn(),
    };

    const category = (id: string, name: string, type: CategoryType = CategoryType.expense) => ({
        id, name, type, icon: "icon", color: "#000000", isDeleted: false,
    });

    let service: CategoryGroupService;

    beforeEach(() => {
        service = new CategoryGroupService(financeRepository as any, aiRepository as any);
    });

    it("usa o cache e não chama a IA quando todas as categorias já estão mapeadas", async () => {
        financeRepository.getCoachingCategoryGroups.mockResolvedValue({
            "c1": { group: "groceries", name: "Mercado" },
        });

        const result = await service.resolveCategoryGroups("w1", [category("c1", "Mercado")]);

        expect(result["c1"]).toBe(CategoryGroup.groceries);
        expect(aiRepository.classifyCategoryGroups).not.toHaveBeenCalled();
        expect(financeRepository.saveCoachingCategoryGroups).not.toHaveBeenCalled();
    });

    it("classifica via IA apenas as categorias novas ou renomeadas e faz merge no cache", async () => {
        financeRepository.getCoachingCategoryGroups.mockResolvedValue({
            "c1": { group: "groceries", name: "Mercado" },
            "c2": { group: "leisure", name: "Nome Antigo" }, // renomeada => reclassificar
        });
        aiRepository.classifyCategoryGroups.mockResolvedValue({
            "c2": "pets",
            "c3": "dining_out",
        });

        const result = await service.resolveCategoryGroups("w1", [
            category("c1", "Mercado"),
            category("c2", "Pet Shop"),
            category("c3", "iFood"),
        ]);

        expect(aiRepository.classifyCategoryGroups).toHaveBeenCalledWith("w1", [
            { id: "c2", name: "Pet Shop", type: "expense" },
            { id: "c3", name: "iFood", type: "expense" },
        ]);
        expect(result).toEqual({
            "c1": CategoryGroup.groceries,
            "c2": CategoryGroup.pets,
            "c3": CategoryGroup.dining_out,
        });
        expect(financeRepository.saveCoachingCategoryGroups).toHaveBeenCalledWith("w1", {
            "c2": { group: "pets", name: "Pet Shop" },
            "c3": { group: "dining_out", name: "iFood" },
        });
    });

    it("mapeia receitas e categorias virtuais sem IA", async () => {
        financeRepository.getCoachingCategoryGroups.mockResolvedValue(null);

        const result = await service.resolveCategoryGroups("w1", [
            category("salario", "Salário", CategoryType.income),
            category("virtual_debt_expense", "Empréstimo/Dívidas"),
            category("virtual_investment_expense", "Investimentos"),
        ]);

        expect(result).toEqual({
            "salario": CategoryGroup.income,
            "virtual_debt_expense": CategoryGroup.debt_financial,
            "virtual_investment_expense": CategoryGroup.savings_investments,
        });
        expect(aiRepository.classifyCategoryGroups).not.toHaveBeenCalled();
    });

    it("usa 'other' e não grava cache quando a IA falha", async () => {
        financeRepository.getCoachingCategoryGroups.mockResolvedValue(null);
        aiRepository.classifyCategoryGroups.mockRejectedValue(new Error("boom"));

        const result = await service.resolveCategoryGroups("w1", [category("c1", "Mercado")]);

        expect(result["c1"]).toBe(CategoryGroup.other);
        expect(financeRepository.saveCoachingCategoryGroups).not.toHaveBeenCalled();
    });

    it("substitui grupos inválidos retornados pela IA por 'other'", async () => {
        financeRepository.getCoachingCategoryGroups.mockResolvedValue(null);
        aiRepository.classifyCategoryGroups.mockResolvedValue({ "c1": "grupo_inexistente" });

        const result = await service.resolveCategoryGroups("w1", [category("c1", "Mercado")]);

        expect(result["c1"]).toBe(CategoryGroup.other);
        expect(financeRepository.saveCoachingCategoryGroups).toHaveBeenCalledWith("w1", {
            "c1": { group: "other", name: "Mercado" },
        });
    });
});
