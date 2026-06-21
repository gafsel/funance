import { calculateLevel, GamificationService } from "../features/goal/domain/services/gamification.service";

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
