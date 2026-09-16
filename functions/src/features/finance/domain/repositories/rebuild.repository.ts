import { AccountModel, CategoryPlanningModel, InstallmentModel } from "../models/finance.models";

/**
 * Documento já existente no Firestore, lido para comparação com o estado
 * recalculado. `data` é o payload cru (sem conversão de Timestamps).
 */
export interface ExistingDoc {
    id: string;
    data: Record<string, any>;
}

/**
 * Saldo diário reconstruído: `workspaces/{wid}/accounts/{aid}/balance/{dateKey}`.
 * O `docId` é sempre igual ao `dateKey` (contrato com o app).
 */
export interface BalanceWrite {
    kind: "balance";
    accountId: string;
    docId: string;
    op: "set" | "delete";
    data?: { dateKey: string, delta: number, balance: number };
}

/** Sumário reconstruído: `workspaces/{wid}/period_summaries/{id}`. */
export interface SummaryWrite {
    kind: "summary";
    docId: string;
    op: "set" | "delete";
    data?: {
        year: number;
        month: number | null;
        week: number | null;
        runtimeType: string;
        categories: Record<string, {
            generalPlannedAmount: number;
            specificPlannedAmount: number;
            actualAmount: number;
        }>;
    };
}

/** XP semanal reconstruído: `workspaces/{wid}/weekly_xp/{YYYY-Www}`. */
export interface WeeklyXpWrite {
    kind: "weeklyXp";
    docId: string;
    op: "set" | "delete";
    data?: { year: number; week: number; xp: number };
}

export type RebuildWrite = BalanceWrite | SummaryWrite | WeeklyXpWrite;

/**
 * Leituras paginadas e escritas em lote usadas pelo job de reconstrução.
 *
 * Existe separado de `IFinanceRepository` por dois motivos:
 *  - as leituras aqui são PAGINADAS (workspaces grandes não cabem em memória
 *    numa query só) e CRUAS: as datas são convertidas exatamente como o
 *    gatilho `onInstallmentWritten` converte (`Timestamp.toDate()` puro, sem o
 *    `setHours(12)` que `FinanceRepositoryImpl.getInstallments` aplica);
 *  - o serviço de rebuild precisa enxergar contas apagadas logicamente
 *    (`isDeleted: true`), que `FinanceRepositoryImpl.getAccounts` filtra.
 */
export interface IRebuildRepository {
    /**
     * Percorre TODAS as parcelas do workspace, paginando por documentId
     * ascendente (o emulador não suporta varredura descendente por chave).
     * As parcelas `removed` são entregues também — quem filtra é o serviço,
     * que precisa saber que elas existem.
     */
    forEachInstallment(
        workspaceId: string,
        pageSize: number,
        visit: (installment: InstallmentModel) => void
    ): Promise<void>;

    /** Contas do workspace, INCLUSIVE as marcadas como `isDeleted`. */
    getAccounts(workspaceId: string): Promise<AccountModel[]>;

    /**
     * Ids de TODOS os documentos da coleção `accounts`, inclusive os
     * "fantasmas" (documento apagado que ainda tem subcoleção `balance`).
     */
    listAccountIds(workspaceId: string): Promise<string[]>;

    /** Planejamentos por categoria do workspace. */
    getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]>;

    /** Documentos de saldo diário já gravados para a conta. */
    getExistingBalances(workspaceId: string, accountId: string, pageSize: number): Promise<ExistingDoc[]>;

    /** Documentos de `period_summaries` já gravados. */
    getExistingPeriodSummaries(workspaceId: string, pageSize: number): Promise<ExistingDoc[]>;

    /** Documentos de `weekly_xp` já gravados. */
    getExistingWeeklyXp(workspaceId: string, pageSize: number): Promise<ExistingDoc[]>;

    /**
     * Aplica as escritas em lotes de no máximo `chunkSize` operações.
     * Retorna quantas operações foram commitadas.
     */
    applyWrites(workspaceId: string, writes: RebuildWrite[], chunkSize: number): Promise<number>;
}
