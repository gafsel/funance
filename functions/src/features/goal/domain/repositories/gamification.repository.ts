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

/**
 * Uma linha do `period_summaries` SEMANAL (`{YYYY-Www}`), já com o join em
 * `categories`. É a fonte do XP semanal de F2.3: `generalPlannedAmount` é a
 * proporção semanal do limite da categoria (ver F1.5) e `actualAmount` é o que
 * de fato foi gasto naquela semana.
 */
export interface WeeklySummaryRow {
    categoryId: string;
    type: string;
    isSystem: boolean;
    actualAmount: number;
    generalPlannedAmount: number;
}

/**
 * F2.3 — os streaks semanais do workspace.
 *
 * `weeklyStreaks` era (e CONTINUA SENDO) um número: a sequência de semanas com
 * todas as missões concluídas. Com o streak de PLANO (semanas seguidas
 * fechando dentro dos limites) passaram a ser dois, e o novo campo `streaks`
 * carrega os dois num mapa.
 *
 * **Por que não transformar `weeklyStreaks` num mapa.** O app instalado
 * desserializa esse campo como número (`workspace_model.g.dart`: `as num?`).
 * Trocar o tipo faria toda build em campo lançar `TypeError` ao ler o
 * workspace — e o cron semanal escreve nesse campo em TODOS os workspaces, de
 * modo que a quebra chegaria a todo mundo na segunda-feira seguinte ao deploy,
 * sem nenhuma ação do usuário. Um campo novo ao lado não quebra ninguém: o app
 * antigo o ignora.
 *
 * Os dois são escritos na MESMA transação e `weeklyStreaks === streaks.missions`
 * é invariante. O contrato novo para o app é `streaks.plan`.
 */
export interface WorkspaceStreaks {
    /** Semanas consecutivas com TODAS as missões semanais concluídas. */
    missions: number;
    /** Semanas consecutivas fechando TODAS as categorias com limite dentro do limite. */
    plan: number;
}

/**
 * Lê os streaks do documento do workspace, tolerando as duas gerações:
 * `streaks` (mapa, quando existe) e o `weeklyStreaks` numérico, que é a única
 * fonte de `missions` num workspace que ainda não passou pelo cron novo.
 */
export function readWorkspaceStreaks(workspaceData: any): WorkspaceStreaks {
    const pick = (value: any) =>
        typeof value === "number" && Number.isFinite(value) ? Math.max(0, Math.trunc(value)) : 0;

    const map = workspaceData?.streaks;
    if (map && typeof map === "object") {
        return { missions: pick(map.missions), plan: pick(map.plan) };
    }

    // Sem o mapa, `missions` vem do campo legado e o plano começa em zero.
    return { missions: pick(workspaceData?.weeklyStreaks), plan: 0 };
}

/** Famílias de XP concedido UMA ÚNICA VEZ por categoria (`xpAwardedFor.<grupo>.<id>`). */
export type XpOnceGroup = "planning" | "recurring";

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
    /**
     * Grava `streaks` (mapa) e `weeklyStreaks` (número, = `missions`) na MESMA
     * transação, preservando as chaves não informadas. Os dois campos nunca
     * podem divergir: o app antigo lê o número e o novo lê o mapa.
     */
    updateWorkspaceStreaks(workspaceId: string, streaks: Partial<WorkspaceStreaks>): Promise<void>;
    /** Linhas do `period_summaries` da SEMANA (`{YYYY-Www}`), com join em categories. */
    getWeeklySummaryRows(workspaceId: string, weekId: string): Promise<WeeklySummaryRow[]>;
    /**
     * Concede `xp` UMA ÚNICA VEZ por `(grupo, chave)`, gravando o marcador
     * `xpAwardedFor.<grupo>.<chave>` e o XP na MESMA transação. Devolve `false`
     * quando o marcador já existia (nada foi concedido).
     */
    awardXpOnce(
        workspaceId: string,
        group: XpOnceGroup,
        key: string,
        xp: number,
        reason: string
    ): Promise<boolean>;
    /** Linhas (categoria x mês) do period_summary, já achatadas e com join em categories. */
    getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<PeriodSummaryRow[]>;
    getCategoriesCount(workspaceId: string): Promise<number>;
    getPaidInstallments(workspaceId: string): Promise<any[]>;
    getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<any[]>;
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
