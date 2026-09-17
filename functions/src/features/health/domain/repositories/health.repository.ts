/**
 * F2.2 — insumos e persistência da Bússola da Liberdade.
 *
 * A interface existe para que `FinancialHealthService` não toque no Firestore:
 * a regra de pontuação é testada com mocks (quatro cenários de perfil) e o
 * acesso a dados é testado no emulador.
 */

import { FinancialHealthSnapshot } from "../models/financial_health.model";

/** Saldo somado por família de conta, num instante (chave de dia) específico. */
export interface AccountBalanceTotals {
    /** Soma do último saldo conhecido das contas `checking` + `investment`. */
    liquid: number;
    /** Soma do último saldo conhecido das contas `debt` + `creditCard`. */
    debt: number;
    /** Existe pelo menos uma conta `debt`/`creditCard` não deletada. */
    hasDebtAccounts: boolean;
    /** Existe pelo menos uma conta não deletada (de qualquer tipo). */
    hasAnyAccount: boolean;
}

/** Realizado de um mês, já separado por natureza e sem categorias de sistema. */
export interface MonthlyTotals {
    income: number;
    expense: number;
}

/** Uma categoria com limite vigente e o quanto ela de fato consumiu no período. */
export interface CategoryLimitOutcome {
    categoryId: string;
    /** O limite que o usuário definiu em `category_planning.amount`. */
    limit: number;
    /** `actualAmount` da categoria no `period_summaries` do período. */
    actual: number;
}

export interface IHealthRepository {
    /**
     * Saldos somados por família de conta, considerando o ÚLTIMO documento de
     * `balance` com `dateKey <= asOfDateKey` de cada conta não deletada.
     */
    getAccountBalanceTotals(workspaceId: string, asOfDateKey: string): Promise<AccountBalanceTotals>;

    /**
     * Realizado (receita/despesa) do mês, somado a partir de
     * `period_summaries/{YYYY-MM}` com join em `categories` — categorias de
     * sistema e deletadas ficam de fora.
     */
    getMonthlyTotals(workspaceId: string, monthKey: string): Promise<MonthlyTotals>;

    /**
     * Categorias de DESPESA com limite vigente no mês (`category_planning` com
     * `amount > 0` cobrindo o mês) e o realizado de cada uma naquele mês.
     */
    getCategoryLimitOutcomes(workspaceId: string, monthKey: string): Promise<CategoryLimitOutcome[]>;

    /** Grava `workspaces/{w}.financialHealth` (merge) — nunca cria o workspace. */
    saveCurrent(workspaceId: string, snapshot: FinancialHealthSnapshot): Promise<void>;

    /** Grava `workspaces/{w}/health_history/{monthKey}` (sobrescreve). */
    saveHistory(workspaceId: string, snapshot: FinancialHealthSnapshot): Promise<void>;

    /** Retrato gravado hoje no workspace, ou `null` se ainda não há nenhum. */
    getCurrent(workspaceId: string): Promise<FinancialHealthSnapshot | null>;

    /** Carimba `healthDirtyAt` no workspace. Uma escrita, sem leitura nenhuma. */
    markDirty(workspaceId: string): Promise<void>;

    /** Remove `healthDirtyAt` depois do recálculo. */
    clearDirty(workspaceId: string): Promise<void>;
}
