// ofx-js é ESM e não passa pelo transform do ts-jest; entra na cadeia via
// ai.service.ts, mas nenhum teste aqui usa OFX.
jest.mock("ofx-js", () => ({ parse: async () => ({}) }));

// eslint-disable-next-line import/first
import { HttpsError } from "firebase-functions/v2/https";
import { QuotaGuard } from "../core/services/quota.service";
import { PlanningAnalysisService } from "../features/finance/domain/services/planning_analysis.service";
import { CoachingService } from "../features/coaching/domain/services/coaching.service";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";
import { CategoryGroup } from "../features/coaching/domain/models/category_group.model";

/**
 * Regra do WP (F0.8, achado do QA): a cota só pode ser consumida quando a IA é
 * REALMENTE chamada. Reabrir uma análise/insight servido pelo cache não gasta
 * nada, e uma falha de infraestrutura do Gemini é estornada.
 */

function makeQuota() {
    const calls = { check: 0, consume: 0, refund: 0 };
    const guard: QuotaGuard = {
        check: async () => {
            calls.check++;
        },
        consume: async () => {
            calls.consume++;
        },
        refund: async () => {
            calls.refund++;
        },
    };
    return { guard, calls };
}

function category(id: string, name: string, type: CategoryType, allocation = "essential"): CategoryModel {
    return { id, name, icon: "i", color: "#000000", type, isDeleted: false, allocation };
}

// ---------------------------------------------------------------------------
// PlanningAnalysisService (cache de 3 dias)
// ---------------------------------------------------------------------------

const INCOME_CATEGORY = category("inc-1", "Salário", CategoryType.income, "investment");
const EXPENSE_CATEGORY = category("exp-1", "Aluguel", CategoryType.expense, "essential");

function planningDeps(overrides: any = {}) {
    const aiRepository = {
        analyze503020Ideal: jest.fn().mockResolvedValue({
            summary: "ok",
            groups: [{ allocation: "essential", currentPct: 40, targetPct: 50, deltaBRL: -500 }],
            categories: [{
                categoryId: EXPENSE_CATEGORY.id,
                idealMonthlyAmount: 1500,
                idealPctOfIncome: 30,
                status: "ok",
                suggestedAllocation: "essential",
                shouldReclassify: false,
                reason: "dentro do ideal",
            }],
            insights: ["insight"],
        }),
        classifyCategoryGroups: jest.fn().mockResolvedValue({}),
        ...overrides.aiRepository,
    };

    const financeRepository = {
        getPlanningAnalysis: jest.fn().mockResolvedValue(null),
        getPeriodSummary: jest.fn().mockResolvedValue({
            categories: {
                [INCOME_CATEGORY.id]: { specificPlannedAmount: 5000, generalPlannedAmount: 0, actualAmount: 5000 },
                [EXPENSE_CATEGORY.id]: { specificPlannedAmount: 2000, generalPlannedAmount: 0, actualAmount: 1800 },
            },
        }),
        // Cache de grupos macro preenchido: evita chamada extra de IA.
        getCoachingCategoryGroups: jest.fn().mockResolvedValue({
            [EXPENSE_CATEGORY.id]: { name: EXPENSE_CATEGORY.name, group: CategoryGroup.housing },
        }),
        savePlanningAnalysis: jest.fn().mockResolvedValue(undefined),
        ...overrides.financeRepository,
    };

    const categoryRepository = {
        getCategories: jest.fn().mockResolvedValue([INCOME_CATEGORY, EXPENSE_CATEGORY]),
        ...overrides.categoryRepository,
    };

    const service = new PlanningAnalysisService(
        financeRepository as any,
        categoryRepository as any,
        aiRepository as any
    );

    return { service, aiRepository, financeRepository, categoryRepository };
}

describe("PlanningAnalysisService + cota", () => {
    it("não consome cota quando devolve a análise em cache", async () => {
        const { guard, calls } = makeQuota();
        const { service, aiRepository } = planningDeps({
            financeRepository: {
                getPlanningAnalysis: jest.fn().mockResolvedValue({
                    month: "2026-09",
                    summary: "cacheada",
                    groups: [],
                    categories: [],
                    insights: [],
                    createdAt: new Date(),
                }),
            },
        });

        const result = await service.analyze("w1", guard);

        expect(result.summary).toBe("cacheada");
        expect(calls.consume).toBe(0);
        expect(calls.refund).toBe(0);
        expect(aiRepository.analyze503020Ideal).not.toHaveBeenCalled();
    });

    it("consome cota exatamente uma vez quando chama a IA de fato", async () => {
        const { guard, calls } = makeQuota();
        const { service, aiRepository } = planningDeps();

        await service.analyze("w1", guard);

        expect(aiRepository.analyze503020Ideal).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(0);
    });

    it("consome a cota ANTES de chamar a IA", async () => {
        const order: string[] = [];
        const guard: QuotaGuard = {
            check: async () => {
                order.push("check");
            },
            consume: async () => {
                order.push("consume");
            },
            refund: async () => {
                order.push("refund");
            },
        };
        const { service } = planningDeps({
            aiRepository: {
                analyze503020Ideal: jest.fn().mockImplementation(async () => {
                    order.push("ia");
                    throw Object.assign(new Error("indisponível"), { status: 503 });
                }),
            },
        });

        await expect(service.analyze("w1", guard)).rejects.toThrow("indisponível");
        expect(order).toEqual(["consume", "ia", "refund"]);
    });

    it("estorna a cota quando o Gemini falha por infraestrutura (503)", async () => {
        const { guard, calls } = makeQuota();
        const { service } = planningDeps({
            aiRepository: {
                analyze503020Ideal: jest.fn().mockRejectedValue(
                    Object.assign(new Error("service unavailable"), { status: 503 })
                ),
            },
        });

        await expect(service.analyze("w1", guard)).rejects.toThrow("service unavailable");
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(1);
    });

    it("NÃO estorna quando a IA responde algo inválido (erro de payload)", async () => {
        const { guard, calls } = makeQuota();
        const { service } = planningDeps({
            aiRepository: {
                // Resposta sem categorias válidas: o serviço lança HttpsError "internal".
                analyze503020Ideal: jest.fn().mockResolvedValue({ groups: [], categories: [], insights: [] }),
            },
        });

        await expect(service.analyze("w1", guard)).rejects.toBeInstanceOf(HttpsError);
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(0);
    });

    it("NÃO consome cota quando falha antes da IA (sem receita prevista)", async () => {
        const { guard, calls } = makeQuota();
        const { service, aiRepository } = planningDeps({
            financeRepository: {
                getPlanningAnalysis: jest.fn().mockResolvedValue(null),
                getPeriodSummary: jest.fn().mockResolvedValue({ categories: {} }),
            },
        });

        await expect(service.analyze("w1", guard)).rejects.toBeInstanceOf(HttpsError);
        expect(calls.consume).toBe(0);
        expect(aiRepository.analyze503020Ideal).not.toHaveBeenCalled();
    });

    it("funciona sem guard (chamada server-side sem cota)", async () => {
        const { service, aiRepository } = planningDeps();

        await expect(service.analyze("w1")).resolves.toBeDefined();
        expect(aiRepository.analyze503020Ideal).toHaveBeenCalledTimes(1);
    });
});

// ---------------------------------------------------------------------------
// CoachingService (cache de 5 dias)
// ---------------------------------------------------------------------------

const COACHING_AI_RESPONSE = {
    message: "Vamos organizar o mês",
    summary: "Resumo do diagnóstico",
    type: "insight",
    slides: [{
        title: "Diagnóstico",
        message: "Sua renda cobre as despesas.",
        icon: "insights",
        icons: ["insights"],
        color: "#4A8C9C",
        secondaryColor: "#2E5B66",
        animationType: "fade",
        actionLabel: null,
        actionPath: null,
    }],
};

describe("CoachingService + cota", () => {
    /** Dependências mínimas para o fluxo completo (cache-miss até a IA). */
    function coachingService(lastAnalyses: any[], overrides: any = {}) {
        const aiRepository = {
            generateCoachingSlides: jest.fn().mockResolvedValue(COACHING_AI_RESPONSE),
            classifyCategoryGroups: jest.fn().mockResolvedValue({}),
            ...overrides.aiRepository,
        };
        const financeRepository = {
            getLastCoachingAnalyses: jest.fn().mockResolvedValue(lastAnalyses),
            getPeriodSummary: jest.fn().mockResolvedValue(null),
            getInstallments: jest.fn().mockResolvedValue([]),
            getAccountById: jest.fn().mockResolvedValue(null),
            getCategoryPlannings: jest.fn().mockResolvedValue([]),
            getCoachingCategoryGroups: jest.fn().mockResolvedValue({}),
            saveCoachingAnalysis: jest.fn().mockResolvedValue("coach-novo"),
            ...overrides.financeRepository,
        };
        const workspaceRepository = {
            getWorkspaceById: jest.fn().mockResolvedValue({ id: "w1", type: "personal", members: ["u1"] }),
        };
        const categoryRepository = {
            getCategories: jest.fn().mockResolvedValue([EXPENSE_CATEGORY, INCOME_CATEGORY]),
        };
        const goalRepository = {
            getGoals: jest.fn().mockResolvedValue([]),
        };

        const service = new CoachingService(
            financeRepository as any,
            goalRepository as any,
            categoryRepository as any,
            workspaceRepository as any,
            aiRepository as any
        );
        return { service, aiRepository, financeRepository };
    }

    it("não consome cota quando devolve o insight em cache", async () => {
        const { guard, calls } = makeQuota();
        const { service, aiRepository } = coachingService([
            { id: "c1", message: "oi", summary: "resumo", type: "insight", slides: [], date: new Date() },
        ]);

        const result = await service.generateCoaching("w1", guard);

        expect(result.id).toBe("c1");
        expect(calls.consume).toBe(0);
        expect(calls.refund).toBe(0);
        expect(aiRepository.generateCoachingSlides).not.toHaveBeenCalled();
    });

    it("consome cota exatamente uma vez no cache-miss (sem insight anterior)", async () => {
        const { guard, calls } = makeQuota();
        const { service, aiRepository, financeRepository } = coachingService([]);

        const result = await service.generateCoaching("w1", guard);

        expect(aiRepository.generateCoachingSlides).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(0);
        expect(result.id).toBe("coach-novo");
        expect(financeRepository.saveCoachingAnalysis).toHaveBeenCalledTimes(1);
    });

    it("insight antigo não conta como cache: consome cota e chama a IA", async () => {
        const old = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const { guard, calls } = makeQuota();
        const { service, aiRepository } = coachingService([
            { id: "c1", message: "oi", summary: "resumo", type: "insight", slides: [], date: old },
        ]);

        await service.generateCoaching("w1", guard);

        expect(aiRepository.generateCoachingSlides).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
    });

    it("consome a cota ANTES de chamar a IA e estorna em falha de infra", async () => {
        const order: string[] = [];
        const guard: QuotaGuard = {
            check: async () => {
                order.push("check");
            },
            consume: async () => {
                order.push("consume");
            },
            refund: async () => {
                order.push("refund");
            },
        };
        const { service } = coachingService([], {
            aiRepository: {
                generateCoachingSlides: jest.fn().mockImplementation(async () => {
                    order.push("ia");
                    throw Object.assign(new Error("service unavailable"), { status: 503 });
                }),
            },
        });

        await expect(service.generateCoaching("w1", guard)).rejects.toThrow("service unavailable");
        expect(order).toEqual(["consume", "ia", "refund"]);
    });

    it("NÃO estorna quando a IA responde algo inválido", async () => {
        const { guard, calls } = makeQuota();
        const { service } = coachingService([], {
            aiRepository: {
                generateCoachingSlides: jest.fn().mockResolvedValue({ slides: "não é lista" }),
            },
        });

        await expect(service.generateCoaching("w1", guard)).rejects.toBeDefined();
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(0);
    });

    it("funciona sem guard (cron de coaching proativo não gasta cota do usuário)", async () => {
        const { service, aiRepository } = coachingService([]);

        await expect(service.generateCoaching("w1")).resolves.toBeDefined();
        expect(aiRepository.generateCoachingSlides).toHaveBeenCalledTimes(1);
    });
});
