/**
 * F5.6 — cache de resposta de IA por hash da entrada.
 *
 * Duas camadas: o AiCacheServiceImpl (chave, TTL, tolerância a falha do
 * Firestore) e o uso nos dois serviços que ganharam cache — a regra que
 * amarra tudo é que **cache-hit não consome cota**.
 */

const mockFs = {
    /** documentos por caminho completo */
    docs: new Map<string, any>(),
    writes: [] as { path: string; data: any }[],
    getThrows: false,
    setThrows: false,
};

jest.mock("firebase-admin", () => {
    const makeDoc = (path: string[]): any => ({
        collection: (name: string) => makeCollection([...path, name]),
        get: async () => {
            if (mockFs.getThrows) throw new Error("firestore indisponível");
            const key = path.join("/");
            const data = mockFs.docs.get(key);
            return { exists: data !== undefined, data: () => data };
        },
        set: async (data: any) => {
            if (mockFs.setThrows) throw new Error("firestore indisponível");
            const key = path.join("/");
            mockFs.writes.push({ path: key, data });
            mockFs.docs.set(key, data);
        },
    });
    const makeCollection = (path: string[]): any => ({
        doc: (id: string) => makeDoc([...path, id]),
    });

    const firestore: any = () => ({ collection: (name: string) => makeCollection([name]) });
    firestore.FieldValue = { serverTimestamp: () => ({ __serverTimestamp: true }) };
    firestore.Timestamp = {
        fromDate: (d: Date) => ({ __millis: d.getTime(), toDate: () => d }),
    };
    return { firestore };
});

// ofx-js é ESM e entra na cadeia via ai.service.ts; nenhum teste aqui usa OFX.
jest.mock("ofx-js", () => ({ parse: async () => ({}) }));

// eslint-disable-next-line import/first
import {
    AI_CACHE_FUNCTIONS,
    AI_CACHE_TTL_DAYS,
    AiCacheServiceImpl,
    aiCacheKey,
    stableStringify,
} from "../core/services/ai_cache.service";
// eslint-disable-next-line import/first
import { QuotaGuard } from "../core/services/quota.service";
// eslint-disable-next-line import/first
import { GoalFeasibilityService } from "../features/goal/domain/services/goal_feasibility.service";
// eslint-disable-next-line import/first
import { OnboardingServiceImpl } from "../features/onboarding/domain/services/onboarding.service";

const DAY_MS = 24 * 60 * 60 * 1000;

beforeEach(() => {
    mockFs.docs = new Map();
    mockFs.writes = [];
    mockFs.getThrows = false;
    mockFs.setThrows = false;
    jest.spyOn(console, "log").mockImplementation(() => undefined);
    jest.spyOn(console, "error").mockImplementation(() => undefined);
});

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

/** Cache em memória, para testar os serviços sem o Firestore. */
function fakeCache() {
    const store = new Map<string, any>();
    const cache = {
        get: jest.fn(async (workspaceId: string, fn: string, input: unknown) => {
            return store.get(`${workspaceId}/${aiCacheKey(fn, input)}`) ?? null;
        }),
        set: jest.fn(async (workspaceId: string, fn: string, input: unknown, payload: any) => {
            store.set(`${workspaceId}/${aiCacheKey(fn, input)}`, payload);
        }),
    };
    return cache;
}

// ---------------------------------------------------------------------------
// Chave do cache
// ---------------------------------------------------------------------------

describe("stableStringify / aiCacheKey", () => {
    it("ignora a ordem das chaves do objeto", () => {
        expect(stableStringify({ b: 1, a: 2 })).toBe(stableStringify({ a: 2, b: 1 }));
    });

    it("respeita a ordem dos arrays (ordem de lançamento importa)", () => {
        expect(stableStringify([1, 2])).not.toBe(stableStringify([2, 1]));
    });

    it("normaliza Date e Timestamp para ISO", () => {
        const date = new Date("2026-03-01T12:00:00.000Z");
        const timestamp = { toDate: () => date };
        expect(stableStringify({ d: date })).toBe(stableStringify({ d: timestamp }));
        expect(stableStringify({ d: date })).toContain("2026-03-01T12:00:00.000Z");
    });

    it("gera a mesma chave para a mesma entrada e outra quando algo muda", () => {
        const input = { targetAmount: 1000, name: "Carro" };
        expect(aiCacheKey("f", input)).toBe(aiCacheKey("f", { name: "Carro", targetAmount: 1000 }));
        expect(aiCacheKey("f", input)).not.toBe(aiCacheKey("f", { ...input, targetAmount: 1001 }));
        expect(aiCacheKey("f", input)).not.toBe(aiCacheKey("g", input));
    });

    it("a chave é o nome da função mais um sha256", () => {
        expect(aiCacheKey("analysePlanning", { a: 1 })).toMatch(/^analysePlanning_[0-9a-f]{64}$/);
    });
});

// ---------------------------------------------------------------------------
// AiCacheServiceImpl
// ---------------------------------------------------------------------------

describe("AiCacheServiceImpl", () => {
    const service = new AiCacheServiceImpl();
    const input = { goal: "carro" };

    it("grava em workspaces/{id}/ai_cache/{functionName}_{sha256} com TTL de 7 dias", async () => {
        const before = Date.now();
        await service.set("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input, { status: "feasible" });

        expect(mockFs.writes).toHaveLength(1);
        expect(mockFs.writes[0].path).toBe(
            `workspaces/w1/ai_cache/${aiCacheKey(AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input)}`
        );
        const expires = mockFs.writes[0].data.expiresAt.__millis;
        expect(expires - before).toBeGreaterThanOrEqual(AI_CACHE_TTL_DAYS * DAY_MS - 5000);
        expect(expires - before).toBeLessThanOrEqual(AI_CACHE_TTL_DAYS * DAY_MS + 5000);
    });

    it("devolve o payload gravado para a mesma entrada", async () => {
        await service.set("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input, { status: "feasible" });
        const hit = await service.get("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input);
        expect(hit).toEqual({ status: "feasible" });
    });

    it("entrada diferente é cache-miss", async () => {
        await service.set("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input, { status: "feasible" });
        const miss = await service.get("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, { goal: "moto" });
        expect(miss).toBeNull();
    });

    it("não vaza entre workspaces", async () => {
        await service.set("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input, { status: "feasible" });
        expect(await service.get("w2", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input)).toBeNull();
    });

    it("documento vencido é cache-miss mesmo antes do TTL do Firestore agir", async () => {
        const key = aiCacheKey(AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input);
        const expired = new Date(Date.now() - DAY_MS);
        mockFs.docs.set(`workspaces/w1/ai_cache/${key}`, {
            payload: { status: "feasible" },
            expiresAt: { toDate: () => expired },
        });

        expect(await service.get("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input)).toBeNull();
    });

    it("falha do Firestore vira cache-miss, nunca erro", async () => {
        mockFs.getThrows = true;
        expect(await service.get("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input)).toBeNull();

        mockFs.setThrows = true;
        await expect(
            service.set("w1", AI_CACHE_FUNCTIONS.analyzeGoalFeasibility, input, { status: "ok" })
        ).resolves.toBeUndefined();
    });
});

// ---------------------------------------------------------------------------
// GoalFeasibilityService
// ---------------------------------------------------------------------------

describe("GoalFeasibilityService com cache", () => {
    const goalPayload = {
        name: "Carro", targetAmount: 40000, deadlineDays: 365, monthlyRequired: 3300, type: "saveMoney",
    };

    function deps(overrides: any = {}) {
        const aiRepository = {
            analyzeGoalFeasibility: jest.fn().mockResolvedValue({
                status: "feasible", reason: "sobra R$ 4.000/mês", suggestion: "mantenha",
            }),
            ...overrides.aiRepository,
        };
        const financeRepository = {
            getPeriodSummary: jest.fn().mockResolvedValue(null),
            ...overrides.financeRepository,
        };
        const categoryRepository = {
            getCategories: jest.fn().mockResolvedValue([]),
            ...overrides.categoryRepository,
        };
        return { aiRepository, financeRepository, categoryRepository };
    }

    it("cache-miss chama a IA, consome cota e grava o cache", async () => {
        const { aiRepository, financeRepository, categoryRepository } = deps();
        const cache = fakeCache();
        const { guard, calls } = makeQuota();
        const service = new GoalFeasibilityService(
            financeRepository as any, categoryRepository as any, aiRepository as any, cache as any
        );

        const result = await service.analyze("w1", goalPayload as any, guard);

        expect(aiRepository.analyzeGoalFeasibility).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
        expect(cache.set).toHaveBeenCalledTimes(1);
        expect(result.status).toBe("feasible");
    });

    it("cache-hit NÃO chama a IA e NÃO consome cota", async () => {
        const { aiRepository, financeRepository, categoryRepository } = deps();
        const cache = fakeCache();
        const { guard, calls } = makeQuota();
        const service = new GoalFeasibilityService(
            financeRepository as any, categoryRepository as any, aiRepository as any, cache as any
        );

        await service.analyze("w1", goalPayload as any, guard);
        const second = await service.analyze("w1", goalPayload as any, guard);

        expect(aiRepository.analyzeGoalFeasibility).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
        expect(second.status).toBe("feasible");
    });

    it("entrada diferente refaz a análise e consome cota de novo", async () => {
        const { aiRepository, financeRepository, categoryRepository } = deps();
        const cache = fakeCache();
        const { guard, calls } = makeQuota();
        const service = new GoalFeasibilityService(
            financeRepository as any, categoryRepository as any, aiRepository as any, cache as any
        );

        await service.analyze("w1", goalPayload as any, guard);
        await service.analyze("w1", { ...goalPayload, targetAmount: 50000 } as any, guard);

        expect(aiRepository.analyzeGoalFeasibility).toHaveBeenCalledTimes(2);
        expect(calls.consume).toBe(2);
    });

    it("falha de infraestrutura do Gemini estorna a cota e não grava cache", async () => {
        const { financeRepository, categoryRepository } = deps();
        const aiRepository = {
            analyzeGoalFeasibility: jest.fn().mockRejectedValue(
                Object.assign(new Error("indisponível"), { status: 503 })
            ),
        };
        const cache = fakeCache();
        const { guard, calls } = makeQuota();
        const service = new GoalFeasibilityService(
            financeRepository as any, categoryRepository as any, aiRepository as any, cache as any
        );

        await expect(service.analyze("w1", goalPayload as any, guard)).rejects.toThrow("indisponível");
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(1);
        expect(cache.set).not.toHaveBeenCalled();
    });

    it("resposta inválida NÃO estorna a cota", async () => {
        const { financeRepository, categoryRepository } = deps();
        const aiRepository = {
            analyzeGoalFeasibility: jest.fn().mockRejectedValue(
                new Error("A resposta da IA não contém JSON válido.")
            ),
        };
        const { guard, calls } = makeQuota();
        const service = new GoalFeasibilityService(
            financeRepository as any, categoryRepository as any, aiRepository as any, fakeCache() as any
        );

        await expect(service.analyze("w1", goalPayload as any, guard)).rejects.toThrow();
        expect(calls.refund).toBe(0);
    });
});

// ---------------------------------------------------------------------------
// OnboardingService.analyzePlanning
// ---------------------------------------------------------------------------

describe("OnboardingService.analyzePlanning com cache", () => {
    function build(overrides: any = {}) {
        const aiRepository = {
            analyzePlanningAndSuggestGoals: jest.fn().mockResolvedValue({
                goals: [{ name: "Reserva" }], plannings: [],
            }),
            ...overrides.aiRepository,
        };
        const categoryRepository = { getCategories: jest.fn().mockResolvedValue([{ id: "c1", name: "Mercado" }]) };
        const financeRepository = { getOrders: jest.fn().mockResolvedValue([{ id: "o1", amount: 10 }]) };
        const workspaceRepository = { getWorkspaceById: jest.fn().mockResolvedValue({ id: "w1", type: "personal" }) };
        const cache = fakeCache();
        const service = new OnboardingServiceImpl(
            aiRepository as any, categoryRepository as any, financeRepository as any,
            workspaceRepository as any, cache as any
        );
        return { service, aiRepository, cache, financeRepository };
    }

    it("cache-miss chama a IA, consome cota e grava o cache", async () => {
        const { service, aiRepository, cache } = build();
        const { guard, calls } = makeQuota();

        const result = await service.analyzePlanning("w1", guard);

        expect(aiRepository.analyzePlanningAndSuggestGoals).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
        expect(cache.set).toHaveBeenCalledTimes(1);
        expect(result.goals).toHaveLength(1);
    });

    it("cache-hit NÃO chama a IA e NÃO consome cota", async () => {
        const { service, aiRepository } = build();
        const { guard, calls } = makeQuota();

        await service.analyzePlanning("w1", guard);
        await service.analyzePlanning("w1", guard);

        expect(aiRepository.analyzePlanningAndSuggestGoals).toHaveBeenCalledTimes(1);
        expect(calls.consume).toBe(1);
    });

    it("lançamento novo muda a entrada e refaz a análise", async () => {
        const { service, aiRepository, financeRepository } = build();
        const { guard, calls } = makeQuota();

        await service.analyzePlanning("w1", guard);
        financeRepository.getOrders.mockResolvedValue([{ id: "o1", amount: 10 }, { id: "o2", amount: 20 }]);
        await service.analyzePlanning("w1", guard);

        expect(aiRepository.analyzePlanningAndSuggestGoals).toHaveBeenCalledTimes(2);
        expect(calls.consume).toBe(2);
    });

    it("falha de infraestrutura estorna a cota e não grava cache", async () => {
        const { service, aiRepository, cache } = build();
        aiRepository.analyzePlanningAndSuggestGoals.mockRejectedValue(
            Object.assign(new Error("503"), { status: 503 })
        );
        const { guard, calls } = makeQuota();

        await expect(service.analyzePlanning("w1", guard)).rejects.toThrow("503");
        expect(calls.consume).toBe(1);
        expect(calls.refund).toBe(1);
        expect(cache.set).not.toHaveBeenCalled();
    });
});
