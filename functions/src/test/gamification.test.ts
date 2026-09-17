import { BADGES, calculateLevel, GamificationService } from "../features/goal/domain/services/gamification.service";
import {
    addCalendarDays,
    endOfWeekFromStart,
    getDayIndexInTz,
    getMonthKeyInTz,
    getMonthRangeInTz,
    getWeekId,
    startOfWeekInTz,
} from "../features/goal/domain/services/gamification_time.util";

const mockRepository = {
    getWorkspaceById: jest.fn(),
    addXp: jest.fn(),
    unlockBadge: jest.fn(),
    getAccountsCount: jest.fn(),
    hasPaidTransaction: jest.fn(),
    getCategoryPlannings: jest.fn(),
    getCompletedReconciliationsCount: jest.fn(),
    getGoals: jest.fn(),
    getPaidInstallmentsInPeriod: jest.fn(),
    getWeeklyMission: jest.fn(),
    createWeeklyMission: jest.fn(),
    updateWeeklyMission: jest.fn(),
    getWeeklyMissionsByWeek: jest.fn(),
    updateWorkspaceStreaks: jest.fn(),
    getPeriodSummaries: jest.fn(),
    getCategoriesCount: jest.fn(),
    getPaidInstallments: jest.fn(),
    getPaidInstallmentsSince: jest.fn(),
    completeMissionAndAwardXp: jest.fn(),
    getPaidInstallmentsCount: jest.fn(),
    getCompletedMissionsCount: jest.fn(),
    getCreditCardAccountIds: jest.fn(),
    hasPendingInstallmentsForAccounts: jest.fn(),
};

describe("Gamification Level Formula", () => {
    it("should calculate correct level for XP values", () => {
        expect(calculateLevel(0)).toBe(1);
        expect(calculateLevel(150)).toBe(1);
        expect(calculateLevel(300)).toBe(2);
        expect(calculateLevel(600)).toBe(2);
        expect(calculateLevel(900)).toBe(3);
        expect(calculateLevel(2100)).toBe(4);
        expect(calculateLevel(4500)).toBe(5);
        expect(calculateLevel(9300)).toBe(6);
    });
});

describe("GamificationService", () => {
    let service: GamificationService;

    beforeEach(() => {
        service = new GamificationService(mockRepository as any);
        jest.clearAllMocks();
    });

    describe("addXp", () => {
        it("should delegate to repository addXp", async () => {
            await service.addXp("w1", 150, "Test");
            expect(mockRepository.addXp).toHaveBeenCalledWith("w1", 150, "Test");
        });
    });

    describe("unlockBadge", () => {
        it("should call repository unlockBadge with correct config and rewards", async () => {
            mockRepository.unlockBadge.mockResolvedValue(true);
            const result = await service.unlockBadge("w1", "first_step");

            expect(result).toBe(true);
            expect(mockRepository.unlockBadge).toHaveBeenCalledWith(
                "w1",
                "first_step",
                100,
                "Primeiro Passo"
            );
        });
    });

    describe("Badge Checking Rules", () => {
        it("should unlock first_step on onboarding completed", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            await service.checkFirstStep("w1", true);
            expect(spy).toHaveBeenCalledWith("w1", "first_step");
        });

        it("should unlock united_front when members >= 3", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            await service.checkUnitedFront("w1", 3);
            expect(spy).toHaveBeenCalledWith("w1", "united_front");
        });

        it("should unlock first_account if there are accounts", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockRepository.getAccountsCount.mockResolvedValue(1);

            await service.checkFirstAccount("w1");
            expect(spy).toHaveBeenCalledWith("w1", "first_account");
        });

        it("should unlock first_transaction if there are paid installments", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockRepository.hasPaidTransaction.mockResolvedValue(true);

            await service.checkFirstTransaction("w1");
            expect(spy).toHaveBeenCalledWith("w1", "first_transaction");
        });

        it("should unlock planner if 5 plannings with amount > 0", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            // Formato real dos documentos de workspaces/{w}/category_planning
            const mockPlannings = [
                { amount: 100, category: { id: "c1", name: "Moradia", type: "expense", allocation: "essential" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 200, category: { id: "c2", name: "Lazer", type: "expense", allocation: "comfort" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 50, category: { id: "c3", name: "Aportes", type: "expense", allocation: "investment" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 300, category: { id: "c4", name: "Alimentação", type: "expense", allocation: "essential" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 150, category: { id: "c5", name: "Transporte", type: "expense", allocation: "essential" }, startMonth: "2026-01", endMonth: "2026-12" },
            ];
            mockRepository.getCategoryPlannings.mockResolvedValue(mockPlannings);

            await service.checkPlanner("w1");
            expect(spy).toHaveBeenCalledWith("w1", "planner");
        });

        it("should unlock golden_rule when plannings cover all 3 pools", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const mockPlannings = [
                { amount: 100, category: { id: "c1", name: "Moradia", type: "expense", allocation: "essential" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 200, category: { id: "c2", name: "Lazer", type: "expense", allocation: "comfort" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 50, category: { id: "c3", name: "Aportes", type: "expense", allocation: "investment" }, startMonth: "2026-01", endMonth: "2026-12" },
            ];
            mockRepository.getCategoryPlannings.mockResolvedValue(mockPlannings);

            await service.checkGoldenRule("w1");
            expect(spy).toHaveBeenCalledWith("w1", "golden_rule");
        });

        it("should unlock reconciliation badges properly", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockRepository.getCompletedReconciliationsCount.mockResolvedValue(10);

            await service.checkReconciliationBadges("w1", 1, 10, 0);
            expect(spy).toHaveBeenCalledWith("w1", "reconcile_junior");
            expect(spy).toHaveBeenCalledWith("w1", "cash_detective");
            expect(spy).toHaveBeenCalledWith("w1", "zero_friction");
            expect(spy).toHaveBeenCalledWith("w1", "reconcile_master");
        });

        it("should unlock goal badges", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const concluida = {
                runtimeType: "saveMoney", currentAmount: 100, targetAmount: 100, outcome: "success",
            };
            mockRepository.getGoals.mockResolvedValue([concluida]);

            await service.checkGoalBadges("w1", concluida);
            expect(spy).toHaveBeenCalledWith("w1", "savings_seed");
        });

        it("não concede badge de conclusão para meta de redução com o teto ESTOURADO", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            // Valor acima do alvo — o que antes bastava para "concluir".
            const estourada = {
                runtimeType: "reduceExpense", currentAmount: 5000, targetAmount: 1000, outcome: "failed",
            };
            mockRepository.getGoals.mockResolvedValue([estourada]);

            await service.checkGoalBadges("w1", estourada);
            expect(spy).not.toHaveBeenCalled();
        });

        it("não concede badge de conclusão para meta sem desfecho, mesmo com o alvo alcançado", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const semDesfecho = { runtimeType: "saveMoney", currentAmount: 100, targetAmount: 100 };
            mockRepository.getGoals.mockResolvedValue([semDesfecho]);

            await service.checkGoalBadges("w1", semDesfecho);
            expect(spy).not.toHaveBeenCalled();
        });
    });

    describe("updateWeeklyMissionsProgress", () => {
        it("should generate weekly missions if they do not exist and evaluate planning progress", async () => {
            const mockWorkspaceDoc = {
                exists: true,
                type: "personal",
            };
            const mockCategoryPlannings = [
                { amount: 100, category: { id: "c1", name: "Alimentação", type: "expense", allocation: "essential" }, startMonth: "2026-01", endMonth: "2026-12" },
            ];
            const mockGoals: any[] = [];

            mockRepository.getWeeklyMission.mockResolvedValue(null);
            mockRepository.getWorkspaceById.mockResolvedValue(mockWorkspaceDoc);
            mockRepository.getCategoryPlannings.mockResolvedValue(mockCategoryPlannings);
            mockRepository.getGoals.mockResolvedValue(mockGoals);

            const mockAi = {
                analyzePlanningAndSuggestGoals: jest.fn(),
                analyzeAccountDocument: jest.fn(),
                analyzeReconciliationDocument: jest.fn(),
                generateCoachingSlides: jest.fn(),
                enrichAutomaticTransaction: jest.fn(),
                generateWeeklyMissions: jest.fn().mockResolvedValue({
                    consistency: { name: "AI Consistency Mission", target: 3 },
                    discipline: { name: "AI Discipline Mission", target: 5 },
                    organization: { name: "AI Organization Mission", target: 5 },
                }),
            };

            const aiService = new GamificationService(mockRepository as any, mockAi as any);

            await aiService.updateWeeklyMissionsProgress("w1", "planning", {});

            expect(mockAi.generateWeeklyMissions).toHaveBeenCalled();
            expect(mockRepository.createWeeklyMission).toHaveBeenCalledTimes(3);
        });
    });
});

describe("Gamification time utils (America/Sao_Paulo)", () => {
    it("startOfWeekInTz returns the local Sunday midnight as an instant", () => {
        // Terça 2026-08-11 12:00 em SP (15:00 UTC). Semana começa domingo 09/08 00:00 SP = 03:00 UTC.
        const now = new Date("2026-08-11T15:00:00Z");
        const start = startOfWeekInTz(now);
        expect(start.toISOString()).toBe("2026-08-09T03:00:00.000Z");
    });

    it("endOfWeekFromStart returns the last ms of Saturday (local)", () => {
        const start = new Date("2026-08-09T03:00:00Z");
        const end = endOfWeekFromStart(start);
        expect(end.toISOString()).toBe("2026-08-16T02:59:59.999Z");
    });

    it("getWeekId matches the legacy formula", () => {
        expect(getWeekId(new Date("2026-08-09T03:00:00Z"))).toBe("2026-W32");
        expect(getWeekId(new Date("2026-08-02T03:00:00Z"))).toBe("2026-W31");
    });

    it("getDayIndexInTz uses the local weekday (UTC evening can be another local day)", () => {
        // 2026-08-10 01:00 UTC ainda é domingo 22:00 em SP.
        expect(getDayIndexInTz(new Date("2026-08-10T01:00:00Z"))).toBe(0);
        expect(getDayIndexInTz(new Date("2026-08-10T15:00:00Z"))).toBe(1);
    });

    it("getMonthKeyInTz and getMonthRangeInTz respect the timezone and offsets", () => {
        // 2026-09-01 01:00 UTC ainda é 31/08 22:00 em SP.
        expect(getMonthKeyInTz(new Date("2026-09-01T01:00:00Z"))).toBe("2026-08");
        const lastMonth = getMonthRangeInTz(new Date("2026-08-11T15:00:00Z"), -1);
        expect(lastMonth.year).toBe(2026);
        expect(lastMonth.month).toBe(7);
        expect(lastMonth.start.toISOString()).toBe("2026-07-01T03:00:00.000Z");
        expect(lastMonth.end.toISOString()).toBe("2026-08-01T02:59:59.999Z");
    });

    it("addCalendarDays moves whole local days", () => {
        const start = new Date("2026-08-09T03:00:00Z");
        expect(addCalendarDays(start, -7).toISOString()).toBe("2026-08-02T03:00:00.000Z");
    });
});

describe("Weekly missions — discipline (elapsed days only)", () => {
    let service: GamificationService;

    const disciplineMission = { status: "pending", target: 5, rewardXp: 250 };

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        mockRepository.getWeeklyMission.mockImplementation(async (_w: string, _week: string, type: string) => {
            if (type === "discipline") return { ...disciplineMission };
            return { status: "completed" };
        });
        mockRepository.getCategoryPlannings.mockResolvedValue([
            { amount: 700, category: { name: "Alimentação" }, startMonth: "2026-01", endMonth: "2026-12" },
        ]);
        mockRepository.getPaidInstallmentsInPeriod.mockResolvedValue([]);
        mockRepository.completeMissionAndAwardXp.mockResolvedValue(true);
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("does not complete on Tuesday even with all days within budget (only 2 elapsed days)", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-11T15:00:00Z") }); // terça 12:00 SP

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(mockRepository.completeMissionAndAwardXp).not.toHaveBeenCalled();
        expect(mockRepository.updateWeeklyMission).toHaveBeenCalledWith(
            "w1",
            "2026-W32",
            "discipline",
            { progress: 2, status: "pending" }
        );
    });

    it("completes on Saturday when enough elapsed days are within budget", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-15T15:00:00Z") }); // sábado 12:00 SP

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(mockRepository.completeMissionAndAwardXp).toHaveBeenCalledWith(
            "w1",
            "2026-W32",
            "discipline",
            6,
            250,
            "Missão Semanal de Disciplina Concluída"
        );
    });

    it("queries paid installments by paidDate within the local week boundaries", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-15T15:00:00Z") });

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        const [, start, end] = mockRepository.getPaidInstallmentsInPeriod.mock.calls[0];
        expect(start.toISOString()).toBe("2026-08-09T03:00:00.000Z");
        expect(end.toISOString()).toBe("2026-08-16T02:59:59.999Z");
    });

    it("counts a day over budget as not within budget (grouped by paidDate)", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-15T15:00:00Z") }); // sábado, 6 dias decorridos
        // Limite diário = 700 / 7 = 100. Gasto de 1000 na segunda (10/08, 12:00 SP).
        mockRepository.getPaidInstallmentsInPeriod.mockResolvedValue([
            {
                status: "paid",
                type: "expense",
                category: { name: "Alimentação" },
                paidDate: new Date("2026-08-10T15:00:00Z"),
                paidAmount: 1000,
            },
        ]);
        mockRepository.getWeeklyMission.mockImplementation(async (_w: string, _week: string, type: string) => {
            if (type === "discipline") return { status: "pending", target: 6, rewardXp: 250 };
            return { status: "completed" };
        });

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // 5 dos 6 dias decorridos dentro do orçamento => não completa (target 6).
        expect(mockRepository.completeMissionAndAwardXp).not.toHaveBeenCalled();
        expect(mockRepository.updateWeeklyMission).toHaveBeenCalledWith(
            "w1",
            "2026-W32",
            "discipline",
            { progress: 5, status: "pending" }
        );
    });
});

describe("Weekly missions — consistency (planning period filter)", () => {
    let service: GamificationService;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        mockRepository.getWeeklyMission.mockImplementation(async (_w: string, _week: string, type: string) => {
            if (type === "consistency") return { status: "pending", target: 3, rewardXp: 150 };
            return { status: "completed" };
        });
        mockRepository.completeMissionAndAwardXp.mockResolvedValue(true);
        jest.useFakeTimers({ now: new Date("2026-08-11T15:00:00Z") }); // agosto/2026
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("ignores plannings whose period does not cover the current month", async () => {
        mockRepository.getCategoryPlannings.mockResolvedValue([
            { amount: 100, category: { name: "A" }, startMonth: "2026-01", endMonth: "2026-05" },
            { amount: 200, category: { name: "B" }, startMonth: "2025-01", endMonth: "2025-12" },
            { amount: 300, category: { name: "C" }, startMonth: "2026-09", endMonth: "2026-12" },
            { amount: 400, category: { name: "D" }, startMonth: "2026-01", endMonth: "2026-12" },
        ]);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(mockRepository.completeMissionAndAwardXp).not.toHaveBeenCalled();
        expect(mockRepository.updateWeeklyMission).toHaveBeenCalledWith(
            "w1",
            "2026-W32",
            "consistency",
            { progress: 1, status: "pending" }
        );
    });

    it("completes atomically when enough plannings cover the current month", async () => {
        mockRepository.getCategoryPlannings.mockResolvedValue([
            { amount: 100, category: { name: "A" }, startMonth: "2026-01", endMonth: "2026-12" },
            { amount: 200, category: { name: "B" }, startMonth: "2026-08", endMonth: "2026-08" },
            { amount: 300, category: { name: "C" }, startMonth: "2026-07" },
        ]);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(mockRepository.completeMissionAndAwardXp).toHaveBeenCalledWith(
            "w1",
            "2026-W32",
            "consistency",
            3,
            150,
            "Missão Semanal de Consistência Concluída"
        );
        // O XP é concedido dentro da transação do repositório, nunca por fora.
        expect(mockRepository.addXp).not.toHaveBeenCalled();
    });
});

describe("Weekly cron — evaluates the PREVIOUS full week", () => {
    let service: GamificationService;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        // Segunda-feira 10/08/2026 03:00 SP (06:00 UTC) — momento do cron.
        jest.useFakeTimers({ now: new Date("2026-08-10T06:00:00Z") });
        mockRepository.getCompletedMissionsCount.mockResolvedValue(3);
        mockRepository.unlockBadge.mockResolvedValue(true);
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("increments the streak using the previous week's missions (not the new empty week)", async () => {
        mockRepository.getWeeklyMissionsByWeek.mockResolvedValue([
            { status: "completed" },
            { status: "completed" },
            { status: "completed" },
        ]);
        mockRepository.getWorkspaceById.mockResolvedValue({ weeklyStreaks: 2, members: [] });
        mockRepository.getPaidInstallmentsInPeriod.mockResolvedValue([]);

        await service.evaluateWeeklyMissionsCron("w1");

        // Semana anterior: 02/08 (domingo) a 08/08 => W31.
        expect(mockRepository.getWeeklyMissionsByWeek).toHaveBeenCalledWith("w1", "2026-W31");
        // F2.3: `weeklyStreaks` virou mapa; o cron semanal só toca `missions`.
        expect(mockRepository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 3 });

        // O badge financial_synapsis foi removido: o cron não precisa mais
        // varrer as parcelas pagas da semana.
        expect(mockRepository.getPaidInstallmentsInPeriod).not.toHaveBeenCalled();
    });

    it("resets the streak when the previous week is incomplete", async () => {
        mockRepository.getWeeklyMissionsByWeek.mockResolvedValue([
            { status: "completed" },
            { status: "pending" },
            { status: "completed" },
        ]);
        mockRepository.getWorkspaceById.mockResolvedValue({ weeklyStreaks: 2, members: [] });

        await service.evaluateWeeklyMissionsCron("w1");

        expect(mockRepository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 0 });
    });

    it("checks mission badges (previously dead code) after evaluating the week", async () => {
        const spy = jest.spyOn(service, "checkMissionBadges");
        mockRepository.getWeeklyMissionsByWeek.mockResolvedValue([
            { status: "completed" },
            { status: "completed" },
            { status: "completed" },
        ]);
        mockRepository.getWorkspaceById.mockResolvedValue({ weeklyStreaks: 0, members: [] });
        mockRepository.getPaidInstallmentsInPeriod.mockResolvedValue([]);

        await service.evaluateWeeklyMissionsCron("w1");

        expect(spy).toHaveBeenCalledWith("w1", 3, 1);
    });
});

describe("no_credit_debt badge (monthly cron)", () => {
    let service: GamificationService;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        jest.useFakeTimers({ now: new Date("2026-08-01T06:00:00Z") });
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("unlocks when there is a credit card and no pending card installments last month", async () => {
        const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: {} });
        mockRepository.getCreditCardAccountIds.mockResolvedValue(["card1"]);
        mockRepository.hasPendingInstallmentsForAccounts.mockResolvedValue(false);

        await service.checkNoCreditDebtBadge("w1");

        expect(spy).toHaveBeenCalledWith("w1", "no_credit_debt");
    });

    it("does not unlock without credit card accounts, with pending debt, or when already unlocked", async () => {
        const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);

        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: {} });
        mockRepository.getCreditCardAccountIds.mockResolvedValue([]);
        await service.checkNoCreditDebtBadge("w1");
        expect(spy).not.toHaveBeenCalled();

        mockRepository.getCreditCardAccountIds.mockResolvedValue(["card1"]);
        mockRepository.hasPendingInstallmentsForAccounts.mockResolvedValue(true);
        await service.checkNoCreditDebtBadge("w1");
        expect(spy).not.toHaveBeenCalled();

        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: { no_credit_debt: "2026-01-01" } });
        await service.checkNoCreditDebtBadge("w1");
        expect(spy).not.toHaveBeenCalled();
        expect(mockRepository.getCreditCardAccountIds).toHaveBeenCalledTimes(2);
    });
});

describe("checkSimpleTransactionBadges — early return and count()", () => {
    let service: GamificationService;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
    });

    it("returns early without any installment query when all relevant badges are unlocked", async () => {
        const allUnlocked: Record<string, string> = {};
        for (const id of [
            "first_income", "first_expense", "first_transfer", "round_number",
            "big_transaction", "income_registered", "five_transactions",
            "twenty_transactions", "fifty_transactions", "hundred_transactions",
            "small_transactions_ten", "first_month", "two_months_active",
        ]) {
            allUnlocked[id] = "2026-01-01";
        }
        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: allUnlocked });

        await service.checkSimpleTransactionBadges("w1", { type: "expense", amount: 50 });

        expect(mockRepository.getPaidInstallments).not.toHaveBeenCalled();
        expect(mockRepository.getPaidInstallmentsCount).not.toHaveBeenCalled();
        expect(mockRepository.unlockBadge).not.toHaveBeenCalled();
    });

    it("uses aggregate count() for count badges instead of downloading documents", async () => {
        const unlocked: Record<string, string> = {
            small_transactions_ten: "x",
            first_month: "x",
            two_months_active: "x",
            first_expense: "x",
            round_number: "x",
            big_transaction: "x",
        };
        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: unlocked });
        mockRepository.getPaidInstallmentsCount.mockResolvedValue(25);
        const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);

        await service.checkSimpleTransactionBadges("w1", { type: "expense", amount: 33.5 });

        expect(mockRepository.getPaidInstallmentsCount).toHaveBeenCalledWith("w1");
        expect(mockRepository.getPaidInstallments).not.toHaveBeenCalled();
        expect(spy).toHaveBeenCalledWith("w1", "five_transactions");
        expect(spy).toHaveBeenCalledWith("w1", "twenty_transactions");
        expect(spy).not.toHaveBeenCalledWith("w1", "fifty_transactions");
    });
});

/**
 * Regressões da F2.1 — cada bloco abaixo falharia antes das correções.
 */
describe("F2.1 — badges de dupla removidos", () => {
    it("o catálogo não expõe mais dynamic_duo, financial_synapsis nem emergency_shield", () => {
        // dynamic_duo/financial_synapsis dependiam de createdBy/paidBy, que não
        // existem em InstallmentModel; emergency_shield dependia do tipo de meta
        // "emergency", que não existe no enum GoalType.
        expect(BADGES.dynamic_duo).toBeUndefined();
        expect(BADGES.financial_synapsis).toBeUndefined();
        expect(BADGES.emergency_shield).toBeUndefined();
    });

    it("o serviço não expõe mais checkDynamicDuo", () => {
        const service = new GamificationService(mockRepository as any);
        expect((service as any).checkDynamicDuo).toBeUndefined();
    });

    it("checkGoalBadges não concede nenhum badge de dupla/emergência", async () => {
        const service = new GamificationService(mockRepository as any);
        const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getGoals.mockResolvedValue([
            { runtimeType: "payDebt", currentAmount: 10, targetAmount: 10 },
        ]);

        await service.checkGoalBadges("w1", { runtimeType: "payDebt", currentAmount: 10, targetAmount: 10 });

        const granted = spy.mock.calls.map((c) => c[1]);
        expect(granted).not.toContain("emergency_shield");
        expect(granted).not.toContain("dynamic_duo");
    });
});

describe("F2.1 — evaluateMonthlyMissionsCron lê linhas achatadas de period_summaries", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    const row = (over: Partial<any>) => ({
        categoryId: "c",
        type: "expense",
        allocation: undefined,
        isSystem: false,
        actualAmount: 0,
        generalPlannedAmount: 0,
        specificPlannedAmount: 0,
        ...over,
    });

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        jest.useFakeTimers({ now: new Date("2026-08-01T06:00:00Z") });
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    const granted = () => spy.mock.calls.map((c) => c[1]);

    it("concede under_control quando o realizado fica dentro do planejado", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "moradia", generalPlannedAmount: 2000, actualAmount: 1800 }),
                row({ categoryId: "salario", type: "income", actualAmount: 8000 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).toContain("under_control");
    });

    it("NÃO concede under_control quando não houve planejamento de despesa (bug antigo)", async () => {
        // Antes, qualquer workspace com um period_summary ganhava o badge,
        // porque summary.actualAmount/summary.category eram sempre undefined.
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", generalPlannedAmount: 0, actualAmount: 900 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).not.toContain("under_control");
    });

    it("NÃO concede under_control quando estourou o planejado", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", allocation: "comfort", generalPlannedAmount: 500, actualAmount: 900 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).not.toContain("under_control");
    });

    it("concede future_focus quando o investido é >= 20% da receita", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "salario", type: "income", actualAmount: 5000 }),
                row({ categoryId: "aportes", allocation: "investment", generalPlannedAmount: 1000, actualAmount: 1200 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).toContain("future_focus");
    });

    it("concede cost_cutter quando o conforto cai para <= 80% do mês anterior", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", allocation: "comfort", generalPlannedAmount: 1000, actualAmount: 700 }),
            ])
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", allocation: "comfort", generalPlannedAmount: 1000, actualAmount: 1000 }),
            ]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).toContain("cost_cutter");
    });
});

describe("F2.1 — checkFinancialHealthBadges lê linhas achatadas de period_summaries", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getPaidInstallmentsSince.mockResolvedValue([]);
    });

    it("concede os badges de saúde financeira a partir do realizado por categoria", async () => {
        mockRepository.getPeriodSummaries.mockResolvedValue([
            { categoryId: "salario", type: "income", actualAmount: 6000, generalPlannedAmount: 0, specificPlannedAmount: 0 },
            { categoryId: "moradia", type: "expense", actualAmount: 2000, generalPlannedAmount: 2000, specificPlannedAmount: 0 },
            { categoryId: "alimentacao", type: "expense", actualAmount: 900, generalPlannedAmount: 1000, specificPlannedAmount: 0 },
            { categoryId: "transporte", type: "expense", actualAmount: 400, generalPlannedAmount: 400, specificPlannedAmount: 0 },
            { categoryId: "lazer", type: "expense", actualAmount: 300, generalPlannedAmount: 300, specificPlannedAmount: 0 },
            { categoryId: "saude", type: "expense", actualAmount: 200, generalPlannedAmount: 200, specificPlannedAmount: 0 },
        ]);

        await service.checkFinancialHealthBadges("w1");

        const granted = spy.mock.calls.map((c) => c[1]);
        expect(granted).toContain("expense_under_income");
        expect(granted).toContain("three_categories_month");
        expect(granted).toContain("five_categories_month");
        // 6000 - 3800 = 2200 >= 10% de 6000
        expect(granted).toContain("savings_10pct");
    });

    it("não concede nada quando não há receita realizada no mês", async () => {
        mockRepository.getPeriodSummaries.mockResolvedValue([
            { categoryId: "moradia", type: "expense", actualAmount: 2000, generalPlannedAmount: 2000, specificPlannedAmount: 0 },
        ]);

        await service.checkFinancialHealthBadges("w1");

        const granted = spy.mock.calls.map((c) => c[1]);
        expect(granted).not.toContain("expense_under_income");
        expect(granted).not.toContain("savings_10pct");
    });

    it("ignora categorias de despesa sem movimento na contagem de categorias do mês", async () => {
        mockRepository.getPeriodSummaries.mockResolvedValue([
            { categoryId: "salario", type: "income", actualAmount: 6000, generalPlannedAmount: 0, specificPlannedAmount: 0 },
            { categoryId: "moradia", type: "expense", actualAmount: 2000, generalPlannedAmount: 2000, specificPlannedAmount: 0 },
            { categoryId: "lazer", type: "expense", actualAmount: 0, generalPlannedAmount: 300, specificPlannedAmount: 0 },
            { categoryId: "saude", type: "expense", actualAmount: 0, generalPlannedAmount: 200, specificPlannedAmount: 0 },
        ]);

        await service.checkFinancialHealthBadges("w1");

        const granted = spy.mock.calls.map((c) => c[1]);
        expect(granted).not.toContain("three_categories_month");
    });
});

describe("F2.1 — tipo de meta lido do campo realmente persistido (runtimeType)", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        // Todos os outros badges já desbloqueados para isolar goal_debt_paid.
        mockRepository.getWorkspaceById.mockResolvedValue({
            unlockedBadges: {
                first_goal: "x", goal_linked_account: "x", long_term_goal: "x",
                two_active_goals: "x", five_active_goals: "x", goal_deposit: "x",
                savings_start: "x", goal_halfway: "x", goal_75pct: "x",
                short_term_goal: "x", goal_under_deadline: "x",
            },
        });
    });

    it("concede goal_debt_paid para uma meta payDebt concluída", async () => {
        await service.checkSimpleGoalBadges("w1", {
            runtimeType: "payDebt",
            currentAmount: 5000,
            targetAmount: 5000,
            outcome: "success",
        });

        expect(spy.mock.calls.map((c) => c[1])).toContain("goal_debt_paid");
    });

    it("aceita o campo legado `type` como fallback", async () => {
        await service.checkSimpleGoalBadges("w1", {
            type: "payDebt",
            currentAmount: 5000,
            targetAmount: 5000,
            outcome: "success",
        });

        expect(spy.mock.calls.map((c) => c[1])).toContain("goal_debt_paid");
    });

    it("não concede goal_debt_paid para outros tipos de meta", async () => {
        await service.checkSimpleGoalBadges("w1", {
            runtimeType: "saveMoney",
            currentAmount: 5000,
            targetAmount: 5000,
            outcome: "success",
        });

        expect(spy.mock.calls.map((c) => c[1])).not.toContain("goal_debt_paid");
    });
});

describe("QA — categorias de sistema ficam fora das avaliações de badge", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    const row = (over: Partial<any>) => ({
        categoryId: "c",
        type: "expense",
        allocation: undefined,
        isSystem: false,
        actualAmount: 0,
        generalPlannedAmount: 0,
        specificPlannedAmount: 0,
        ...over,
    });

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getPaidInstallmentsSince.mockResolvedValue([]);
        jest.useFakeTimers({ now: new Date("2026-08-01T06:00:00Z") });
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    const granted = () => spy.mock.calls.map((c) => c[1]);

    it("under_control continua alcançável para quem usa empréstimo/aporte (categorias virtuais)", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "moradia", generalPlannedAmount: 2000, actualAmount: 1800 }),
                // Virtuais nunca têm planejamento: antes derrubavam underControl.
                row({ categoryId: "virtual_debt_expense", isSystem: true, generalPlannedAmount: 0, actualAmount: 900 }),
                row({ categoryId: "virtual_investment_expense", isSystem: true, allocation: "investment", generalPlannedAmount: 0, actualAmount: 500 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        expect(granted()).toContain("under_control");
    });

    it("o saldo inicial de cartão/dívida não é somado como receita nem como aporte", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "initial-balance", isSystem: true, type: "income", actualAmount: 50000 }),
                row({ categoryId: "salario", type: "income", actualAmount: 1000 }),
                row({ categoryId: "aportes", allocation: "investment", generalPlannedAmount: 100, actualAmount: 100 }),
            ])
            .mockResolvedValueOnce([]);

        await service.evaluateMonthlyMissionsCron("w1");

        // 100 / 1000 = 10% < 20%. Se o saldo inicial entrasse na receita, ou se
        // uma virtual de investimento entrasse no aporte, o cálculo mudaria.
        expect(granted()).not.toContain("future_focus");
    });

    it("checkFinancialHealthBadges ignora categorias de sistema", async () => {
        mockRepository.getPeriodSummaries.mockResolvedValue([
            row({ categoryId: "initial-balance", isSystem: true, type: "income", actualAmount: 90000 }),
            row({ categoryId: "virtual_debt_expense", isSystem: true, actualAmount: 800 }),
            row({ categoryId: "virtual_investment_expense", isSystem: true, actualAmount: 800 }),
            row({ categoryId: "moradia", actualAmount: 2000 }),
        ]);

        await service.checkFinancialHealthBadges("w1");

        // Sem receita real no mês, nada é concedido — e as duas virtuais não
        // podem contar como "categorias do mês".
        expect(granted()).not.toContain("expense_under_income");
        expect(granted()).not.toContain("savings_10pct");
        expect(granted()).not.toContain("three_categories_month");
    });

    it("cost_cutter ignora o conforto vindo de categorias de sistema", async () => {
        mockRepository.getPeriodSummaries
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", allocation: "comfort", generalPlannedAmount: 1000, actualAmount: 700 }),
            ])
            .mockResolvedValueOnce([
                row({ categoryId: "lazer", allocation: "comfort", actualAmount: 800 }),
                row({ categoryId: "virtual_debt_expense", isSystem: true, allocation: "comfort", actualAmount: 5000 }),
            ]);

        await service.evaluateMonthlyMissionsCron("w1");

        // Base do mês anterior = 800 (não 5800): 700 > 0.8 * 800 = 640.
        expect(granted()).not.toContain("cost_cutter");
    });
});

describe("QA — badges de PROGRESSO não premiam gasto de meta de redução", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    const granted = () => spy.mock.calls.map((c) => c[1]);

    const goal = (over: Partial<any> = {}) => ({
        id: "g1",
        name: "Teto do mercado",
        runtimeType: "reduceExpense",
        targetAmount: 1000,
        currentAmount: 800,
        category: { id: "cat1" },
        startDate: new Date("2026-01-01T12:00:00.000"),
        deadline: new Date("2026-12-31T12:00:00.000"),
        isDeleted: false,
        ...over,
    });

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: {} });
        mockRepository.getGoals.mockResolvedValue([]);
    });

    it("meta de redução com 80% do teto consumido não ganha goal_halfway nem goal_75pct", async () => {
        await service.checkSimpleGoalBadges("w1", goal());

        expect(granted()).not.toContain("goal_halfway");
        expect(granted()).not.toContain("goal_75pct");
    });

    it("meta de redução com gasto > 0 não ganha goal_deposit nem savings_start", async () => {
        await service.checkSimpleGoalBadges("w1", goal({ currentAmount: 1 }));

        expect(granted()).not.toContain("goal_deposit");
        expect(granted()).not.toContain("savings_start");
    });

    it("a mesma progressão numa meta de ACÚMULO continua concedendo", async () => {
        await service.checkSimpleGoalBadges("w1", goal({
            runtimeType: "saveMoney",
            accountId: "acc1",
            category: undefined,
        }));

        const badges = granted();
        expect(badges).toContain("goal_halfway");
        expect(badges).toContain("goal_75pct");
        expect(badges).toContain("goal_deposit");
        expect(badges).toContain("savings_start");
    });
});

describe("QA — badges de meta usam os campos reais do documento (startDate/deadline)", () => {
    let service: GamificationService;
    let spy: jest.SpyInstance;

    /**
     * Documento de meta no formato real: sem createdAt/targetDate. Concluída
     * COM SUCESSO (`outcome`), que é o que libera os badges de conclusão — o
     * valor igual ao alvo, sozinho, não conclui nada.
     */
    const goal = (over: Partial<any> = {}) => ({
        id: "g1",
        name: "Meta",
        runtimeType: "saveMoney",
        targetAmount: 1000,
        currentAmount: 1000,
        outcome: "success",
        accountId: "acc1",
        startDate: new Date("2026-01-01T12:00:00.000"),
        deadline: new Date("2026-12-31T12:00:00.000"),
        isDeleted: false,
        ...over,
    });

    beforeEach(() => {
        jest.clearAllMocks();
        service = new GamificationService(mockRepository as any);
        spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
        mockRepository.getWorkspaceById.mockResolvedValue({ unlockedBadges: {} });
        mockRepository.getGoals.mockResolvedValue([]);
        jest.useFakeTimers({ now: new Date("2026-03-01T15:00:00Z") });
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    const granted = () => spy.mock.calls.map((c) => c[1]);

    it("NÃO concede short_term_goal para uma meta de um ano (bug antigo: concedia a todas)", async () => {
        await service.checkSimpleGoalBadges("w1", goal());

        expect(granted()).not.toContain("short_term_goal");
    });

    it("concede short_term_goal quando a janela planejada é menor que 30 dias", async () => {
        await service.checkSimpleGoalBadges("w1", goal({
            startDate: new Date("2026-02-10T12:00:00.000"),
            deadline: new Date("2026-03-05T12:00:00.000"),
        }));

        expect(granted()).toContain("short_term_goal");
    });

    it("concede goal_under_deadline usando `deadline` (o campo real)", async () => {
        await service.checkSimpleGoalBadges("w1", goal());

        // Hoje (01/03/2026) <= deadline (31/12/2026).
        expect(granted()).toContain("goal_under_deadline");
    });

    it("NÃO concede goal_under_deadline quando o prazo já passou", async () => {
        await service.checkSimpleGoalBadges("w1", goal({
            deadline: new Date("2026-02-01T12:00:00.000"),
        }));

        expect(granted()).not.toContain("goal_under_deadline");
    });

    it("concede long_term_goal a partir de startDate/deadline, não de targetDate/createdAt", async () => {
        await service.checkSimpleGoalBadges("w1", goal({
            startDate: new Date("2026-01-01T12:00:00.000"),
            deadline: new Date("2028-01-01T12:00:00.000"),
        }));

        expect(granted()).toContain("long_term_goal");
    });

    it("não quebra quando startDate/deadline vêm como Timestamp do Firestore", async () => {
        const timestamp = (iso: string) => ({ toDate: () => new Date(iso) });

        await service.checkSimpleGoalBadges("w1", goal({
            startDate: timestamp("2026-02-10T12:00:00.000"),
            deadline: timestamp("2026-03-05T12:00:00.000"),
        }));

        expect(granted()).toContain("short_term_goal");
    });

    it("ignora os badges de data quando os campos estão ausentes", async () => {
        await service.checkSimpleGoalBadges("w1", goal({ startDate: undefined, deadline: undefined }));

        const badges = granted();
        expect(badges).not.toContain("short_term_goal");
        expect(badges).not.toContain("goal_under_deadline");
        expect(badges).not.toContain("long_term_goal");
        // Os badges que não dependem de data continuam funcionando.
        expect(badges).toContain("first_goal");
        expect(badges).toContain("goal_halfway");
    });
});
