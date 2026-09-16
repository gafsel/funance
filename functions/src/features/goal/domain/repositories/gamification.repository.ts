/**
 * Linha achatada de um period_summary: uma entrada do mapa `categories` do
 * documento mensal, já com o join em `workspaces/{wid}/categories` feito
 * (categorias `isDeleted` são omitidas). Há um único documento por mês.
 */
export interface PeriodSummaryRow {
    categoryId: string;
    type: string;
    allocation?: string;
    /**
     * Categoria de sistema (saldo inicial, virtuais de transferência). Não
     * representa uma escolha de consumo do usuário e é ignorada pelas
     * avaliações de badge.
     */
    isSystem: boolean;
    actualAmount: number;
    generalPlannedAmount: number;
    specificPlannedAmount: number;
}

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
    getWeeklyMissionsByWeek(workspaceId: string, weekId: string): Promise<any[]>;
    updateWorkspaceStreaks(workspaceId: string, streaks: number): Promise<void>;
    /** Linhas (categoria x mês) do period_summary, já achatadas e com join em categories. */
    getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<PeriodSummaryRow[]>;
    getCategoriesCount(workspaceId: string): Promise<number>;
    getPaidInstallments(workspaceId: string): Promise<any[]>;
    getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<any[]>;
    /** Lista os IDs de todos os workspaces (para os crons agendados). */
    getAllWorkspaceIds(): Promise<string[]>;
    /**
     * Marca a missão como concluída e concede o XP na MESMA transação.
     * Retorna false (sem conceder nada) se a missão já estava concluída.
     */
    completeMissionAndAwardXp(
        workspaceId: string,
        weekId: string,
        type: string,
        progress: number,
        rewardXp: number,
        reason: string
    ): Promise<boolean>;
    /** Contagem (aggregate count) de installments pagas/settled do workspace. */
    getPaidInstallmentsCount(workspaceId: string): Promise<number>;
    /** Contagem (aggregate count) de missões semanais concluídas do workspace. */
    getCompletedMissionsCount(workspaceId: string): Promise<number>;
    /** IDs das contas do tipo cartão de crédito (não deletadas). */
    getCreditCardAccountIds(workspaceId: string): Promise<string[]>;
    /** Existe installment pendente no período vinculada a alguma das contas? */
    hasPendingInstallmentsForAccounts(
        workspaceId: string,
        accountIds: string[],
        start: Date,
        end: Date
    ): Promise<boolean>;
}
