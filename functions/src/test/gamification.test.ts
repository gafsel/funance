import { calculateLevel, GamificationService } from "../features/goal/domain/services/gamification.service";

// Mock firebase-admin
const mockUpdate = jest.fn();
const mockGet = jest.fn();
const mockSet = jest.fn();

const mockDoc = {
    get: mockGet,
    update: mockUpdate,
    set: mockSet,
};

const mockCollection = jest.fn().mockReturnValue({
    doc: jest.fn().mockReturnValue(mockDoc),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
});

const mockRunTransaction = jest.fn();

jest.mock("firebase-admin", () => {
    return {
        firestore: Object.assign(() => ({
            collection: mockCollection,
            runTransaction: mockRunTransaction,
        }), {
            FieldValue: {
                serverTimestamp: () => "mock-timestamp",
                increment: (v: number) => `increment-${v}`,
            },
        }),
    };
});

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
        service = new GamificationService();
        jest.clearAllMocks();

        mockCollection.mockReset();
        mockCollection.mockReturnValue({
            doc: jest.fn().mockReturnValue(mockDoc),
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: jest.fn(),
        });
    });

    describe("addXp", () => {
        it("should increment XP and level up if needed", async () => {
            const mockWorkspaceRef = {};
            mockCollection.mockReturnValue({
                doc: jest.fn().mockReturnValue(mockWorkspaceRef),
            });

            mockRunTransaction.mockImplementation(async (callback) => {
                const mockTransaction = {
                    get: jest.fn().mockResolvedValue({
                        exists: true,
                        data: () => ({ xp: 150, level: 1 }),
                    }),
                    update: mockUpdate,
                };
                return callback(mockTransaction);
            });

            await service.addXp("w1", 150, "Test");

            expect(mockUpdate).toHaveBeenCalledWith(expect.anything(), {
                xp: 300,
                level: 2,
                lastLevelUpAt: "mock-timestamp",
            });
        });
    });

    describe("unlockBadge", () => {
        it("should unlock a locked badge and award XP", async () => {
            const mockWorkspaceRef = {};
            mockCollection.mockReturnValue({
                doc: jest.fn().mockReturnValue(mockWorkspaceRef),
            });

            // First call: unlockBadge transaction
            mockRunTransaction.mockImplementationOnce(async (callback) => {
                const mockTransaction = {
                    get: jest.fn().mockResolvedValue({
                        exists: true,
                        data: () => ({ unlockedBadges: {} }),
                    }),
                    update: mockUpdate,
                };
                return callback(mockTransaction);
            });

            // Second call (called from inside unlockBadge as addXp): addXp transaction
            mockRunTransaction.mockImplementationOnce(async (callback) => {
                const mockTransaction = {
                    get: jest.fn().mockResolvedValue({
                        exists: true,
                        data: () => ({ xp: 0, level: 1 }),
                    }),
                    update: mockUpdate,
                };
                return callback(mockTransaction);
            });

            const result = await service.unlockBadge("w1", "first_step");

            expect(result).toBe(true);
            expect(mockUpdate).toHaveBeenCalledWith(expect.anything(), {
                unlockedBadges: {
                    first_step: expect.any(String),
                },
            });
        });

        it("should not unlock an already unlocked badge", async () => {
            mockRunTransaction.mockImplementation(async (callback) => {
                const mockTransaction = {
                    get: jest.fn().mockResolvedValue({
                        exists: true,
                        data: () => ({
                            unlockedBadges: { first_step: "2026-06-20T22:00:00Z" },
                        }),
                    }),
                    update: mockUpdate,
                };
                return callback(mockTransaction);
            });

            const result = await service.unlockBadge("w1", "first_step");

            expect(result).toBe(false);
            expect(mockUpdate).not.toHaveBeenCalled();
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
            mockCollection.mockReturnValue({
                where: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ size: 1 }),
            });

            await service.checkFirstAccount("w1");
            expect(spy).toHaveBeenCalledWith("w1", "first_account");
        });

        it("should unlock first_transaction if there are paid installments", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockCollection.mockReturnValue({
                where: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ size: 1 }),
            });

            await service.checkFirstTransaction("w1");
            expect(spy).toHaveBeenCalledWith("w1", "first_transaction");
        });

        it("should unlock planner if 5 plannings with amount > 0", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const mockPlannings = [
                { data: () => ({ amount: 100 }) },
                { data: () => ({ amount: 200 }) },
                { data: () => ({ amount: 50 }) },
                { data: () => ({ amount: 300 }) },
                { data: () => ({ amount: 150 }) },
            ];
            mockCollection.mockReturnValue({
                get: jest.fn().mockResolvedValue(mockPlannings),
            });

            await service.checkPlanner("w1");
            expect(spy).toHaveBeenCalledWith("w1", "planner");
        });

        it("should unlock golden_rule when plannings cover all 3 pools", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            const mockPlannings = [
                { data: () => ({ amount: 100, category: { allocation: "essential" } }) },
                { data: () => ({ amount: 200, category: { allocation: "comfort" } }) },
                { data: () => ({ amount: 50, category: { allocation: "investment" } }) },
            ];
            mockCollection.mockReturnValue({
                get: jest.fn().mockResolvedValue(mockPlannings),
            });

            await service.checkGoldenRule("w1");
            expect(spy).toHaveBeenCalledWith("w1", "golden_rule");
        });

        it("should unlock reconciliation badges properly", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockCollection.mockReturnValue({
                where: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ size: 10 }),
            });

            await service.checkReconciliationBadges("w1", 1, 10, 0);
            expect(spy).toHaveBeenCalledWith("w1", "reconcile_junior");
            expect(spy).toHaveBeenCalledWith("w1", "cash_detective");
            expect(spy).toHaveBeenCalledWith("w1", "zero_friction");
            expect(spy).toHaveBeenCalledWith("w1", "reconcile_master");
        });

        it("should unlock goal badges", async () => {
            const spy = jest.spyOn(service, "unlockBadge").mockResolvedValue(true);
            mockCollection.mockReturnValue({
                get: jest.fn().mockResolvedValue([
                    { data: () => ({ status: "completed" }) },
                ]),
            });

            await service.checkGoalBadges("w1", { status: "completed", type: "emergency" });
            expect(spy).toHaveBeenCalledWith("w1", "savings_seed");
            expect(spy).toHaveBeenCalledWith("w1", "emergency_shield");
        });
    });

    describe("updateWeeklyMissionsProgress", () => {
        it("should generate weekly missions if they do not exist and evaluate planning progress", async () => {
            const mockWorkspaceDoc = {
                exists: true,
                data: () => ({ type: "personal" })
            };
            const mockCategoryPlannings = [
                { data: () => ({ amount: 100, category: { name: "Alimentação" } }) }
            ];
            const mockGoals: any[] = [];

            let getCallCount = 0;
            mockGet.mockImplementation(async () => {
                getCallCount++;
                if (getCallCount === 1) {
                    return { exists: false };
                }
                if (getCallCount === 2) {
                    return mockWorkspaceDoc;
                }
                return {
                    exists: true,
                    data: () => ({ status: "pending", target: 3, rewardXp: 150 })
                };
            });

            const prevCollection = mockCollection.getMockImplementation();

            mockCollection.mockImplementation((path: string) => {
                if (path.includes("category_plannings")) {
                    return { get: jest.fn().mockResolvedValue(mockCategoryPlannings) };
                }
                if (path.includes("goals")) {
                    return { get: jest.fn().mockResolvedValue(mockGoals) };
                }
                return { 
                    doc: jest.fn().mockReturnValue(mockDoc),
                    where: jest.fn().mockReturnThis(),
                    limit: jest.fn().mockReturnThis(),
                    get: jest.fn().mockResolvedValue(mockGoals)
                };
            });

            const mockAi = {
                analyzePlanningAndSuggestGoals: jest.fn(),
                analyzeAccountDocument: jest.fn(),
                analyzeReconciliationDocument: jest.fn(),
                generateCoachingSlides: jest.fn(),
                enrichAutomaticTransaction: jest.fn(),
                generateWeeklyMissions: jest.fn().mockResolvedValue({
                    consistency: { name: "AI Consistency Mission", target: 3 },
                    discipline: { name: "AI Discipline Mission", target: 5 },
                    organization: { name: "AI Organization Mission", target: 5 }
                })
            };

            const aiService = new GamificationService(mockAi as any);
            mockSet.mockResolvedValue(undefined);

            await aiService.updateWeeklyMissionsProgress("w1", "planning", {});

            expect(mockAi.generateWeeklyMissions).toHaveBeenCalled();
            expect(mockSet).toHaveBeenCalledTimes(3);

            // Restore mock implementation
            mockCollection.mockImplementation(prevCollection!);
        });
    });
});
