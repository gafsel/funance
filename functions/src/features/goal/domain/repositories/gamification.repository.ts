export interface IGamificationRepository {
    getWorkspaceById(workspaceId: string): Promise<any | null>;
    addXp(workspaceId: string, amount: number, reason: string): Promise<void>;
    unlockBadge(
        workspaceId: string,
        badgeId: string,
        xpReward: number,
        badgeName: string
    ): Promise<boolean>;
    getAccountsCount(workspaceId: string): Promise<number>;
    hasPaidTransaction(workspaceId: string): Promise<boolean>;
    getCategoryPlannings(workspaceId: string): Promise<any[]>;
    getCompletedReconciliationsCount(workspaceId: string, limit?: number): Promise<number>;
    getGoals(workspaceId: string): Promise<any[]>;
    getPaidInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<any[]>;
    getWeeklyMission(workspaceId: string, weekId: string, type: string): Promise<any | null>;
    createWeeklyMission(workspaceId: string, weekId: string, type: string, data: any): Promise<void>;
    updateWeeklyMission(workspaceId: string, weekId: string, type: string, data: any): Promise<void>;
    getInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<any[]>;
    getWeeklyMissionsByWeek(workspaceId: string, weekId: string): Promise<any[]>;
    updateWorkspaceStreaks(workspaceId: string, streaks: number): Promise<void>;
    getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<any[]>;
    getCategoriesCount(workspaceId: string): Promise<number>;
    getPaidInstallments(workspaceId: string): Promise<any[]>;
    getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<any[]>;
}
