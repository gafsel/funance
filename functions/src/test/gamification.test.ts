import { calculateLevel, GamificationService } from "../features/goal/domain/services/gamification.service";
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
    getInstallmentsInPeriod: jest.fn(),
    getWeeklyMissionsByWeek: jest.fn(),
    updateWorkspaceStreaks: jest.fn(),
    getPeriodSummaries: jest.fn(),
    getCategoriesCount: jest.fn(),
    getPaidInstallments: jest.fn(),
    getPaidInstallmentsSince: jest.fn(),
    getAllWorkspaceIds: jest.fn(),
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
            const mockPlannings = [
                { amount: 100 },
                { amount: 200 },
                { amount: 50 },
                { amount: 300 },
                { amount: 150 },
            ];
            mockRepository.getCategoryPlannings.mockResolvedValue(mockPlannings);

            await service.checkPlanner("w1");
            expect(spy).toHaveBeenCalledWith("w1", "planner");
        });

        it("should unlock golden_rule when plannings cover all 3 pools", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const mockPlannings = [
                { amount: 100, category: { allocation: "essential" } },
                { amount: 200, category: { allocation: "comfort" } },
                { amount: 50, category: { allocation: "investment" } },
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
            mockRepository.getGoals.mockResolvedValue([
                { status: "completed" },
            ]);

            await service.checkGoalBadges("w1", { status: "completed", type: "emergency" });
            expect(spy).toHaveBeenCalledWith("w1", "savings_seed");
            expect(spy).toHaveBeenCalledWith("w1", "emergency_shield");
        });
    });

    describe("updateWeeklyMissionsProgress", () => {
        it("should generate weekly missions if they do not exist and evaluate planning progress", async () => {
            const mockWorkspaceDoc = {
                exists: true,
                type: "personal",
            };
            const mockCategoryPlannings = [
                { amount: 100, category: { name: "Alimentação" } },
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
        expect(mockRepository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", 3);

        const [, start, end] = mockRepository.getPaidInstallmentsInPeriod.mock.calls[0];
        expect(start.toISOString()).toBe("2026-08-02T03:00:00.000Z");
        expect(end.toISOString()).toBe("2026-08-09T02:59:59.999Z");
    });

    it("resets the streak when the previous week is incomplete", async () => {
        mockRepository.getWeeklyMissionsByWeek.mockResolvedValue([
            { status: "completed" },
            { status: "pending" },
            { status: "completed" },
        ]);
        mockRepository.getWorkspaceById.mockResolvedValue({ weeklyStreaks: 2, members: [] });

        await service.evaluateWeeklyMissionsCron("w1");

        expect(mockRepository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", 0);
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
