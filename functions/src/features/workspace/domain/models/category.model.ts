export enum CategoryType {
    income = "income",
    expense = "expense",
}

export interface CategoryModel {
    id: string;
    name: string;
    icon: string;
    color: string;
    type: CategoryType;
    isDeleted: boolean;
    allocation?: "essential" | "comfort" | "investment" | string;
    /**
     * Categoria de sistema: criada e mantida apenas pelas Cloud Functions
     * (Admin SDK). O cliente não pode criar, editar nem apagar; as telas de
     * gestão de categorias devem filtrá-la. Ausente == false.
     */
    isSystem?: boolean;
}

/** Id da categoria sintética usada pelas orders de saldo inicial. */
export const INITIAL_BALANCE_CATEGORY_ID = "initial-balance";

/**
 * Categoria de sistema do saldo inicial.
 *
 * Antes, `finance.service.ts` embutia esse objeto nas orders/installments sem
 * que houvesse um documento correspondente em `workspaces/{wid}/categories`:
 * qualquer lookup por id (coaching, 50-30-20, viabilidade) não a encontrava,
 * embora ela continuasse somada nos period_summaries.
 *
 * O documento persistido é único, portanto tem um `type` fixo (income, o caso
 * dominante — saldo positivo em conta corrente). As orders embutem uma cópia
 * com o `type` correspondente ao sinal do saldo daquela conta.
 */
export const INITIAL_BALANCE_CATEGORY: CategoryModel = {
    id: INITIAL_BALANCE_CATEGORY_ID,
    name: "Saldo Inicial",
    icon: "account_balance_wallet",
    color: "0xFF9E9E9E",
    type: CategoryType.income,
    isDeleted: false,
    isSystem: true,
};

export const VIRTUAL_DEBT_EXPENSE_CATEGORY: CategoryModel = {
    id: "virtual_debt_expense",
    name: "Empréstimo/Dívidas",
    icon: "handshake",
    color: "#E57373",
    type: CategoryType.expense,
    isDeleted: false,
    isSystem: true,
};

export const VIRTUAL_DEBT_INCOME_CATEGORY: CategoryModel = {
    id: "virtual_debt_income",
    name: "Empréstimo/Dívidas",
    icon: "handshake",
    color: "#E57373",
    type: CategoryType.income,
    isDeleted: false,
    isSystem: true,
};

export const VIRTUAL_INVESTMENT_EXPENSE_CATEGORY: CategoryModel = {
    id: "virtual_investment_expense",
    name: "Investimentos",
    icon: "trending_up",
    color: "#81C784",
    type: CategoryType.expense,
    isDeleted: false,
    isSystem: true,
};

export const VIRTUAL_INVESTMENT_INCOME_CATEGORY: CategoryModel = {
    id: "virtual_investment_income",
    name: "Investimentos",
    icon: "trending_up",
    color: "#81C784",
    type: CategoryType.income,
    isDeleted: false,
    isSystem: true,
};

/**
 * Prefixo dos ids das categorias virtuais (contrapartida de transferências:
 * empréstimos/dívidas e investimentos).
 */
export const VIRTUAL_CATEGORY_ID_PREFIX = "virtual_";

/**
 * Todas as categorias de sistema criadas por `createDefaultCategories`.
 * O script `migrate_system_categories` usa esta mesma lista.
 */
export const SYSTEM_CATEGORIES: CategoryModel[] = [
    INITIAL_BALANCE_CATEGORY,
    VIRTUAL_DEBT_EXPENSE_CATEGORY,
    VIRTUAL_DEBT_INCOME_CATEGORY,
    VIRTUAL_INVESTMENT_EXPENSE_CATEGORY,
    VIRTUAL_INVESTMENT_INCOME_CATEGORY,
];

/**
 * Uma categoria é de sistema quando está marcada com `isSystem` ou quando o id
 * pertence ao conjunto conhecido. A checagem por id é necessária para os
 * workspaces legados, cujos documentos ainda não têm a flag (ela só chega com
 * `migrate_system_categories`).
 */
export function isSystemCategory(id: string, data?: { isSystem?: boolean } | null): boolean {
    if (data?.isSystem === true) {
        return true;
    }
    return id === INITIAL_BALANCE_CATEGORY_ID || id.startsWith(VIRTUAL_CATEGORY_ID_PREFIX);
}

/**
 * A categoria é utilizável como CHAVE de agregação (`period_summaries`,
 * planejamento, relatórios) — ou seja, tem um `id` não vazio.
 *
 * Existem em produção parcelas e orders com `category = {id: "", name: "..."}`,
 * criadas pela conciliação/transação automática antes da validação de IA. Um id
 * vazio vira um segmento vazio de `FieldPath` na escrita de `categories.<id>` e
 * o SDK rejeita o documento inteiro ("Element at index 0 should not be an empty
 * string"), derrubando o gatilho ou o `rebuild --apply`.
 *
 * REGRA ÚNICA: categoria sem id é tratada como SEM CATEGORIA para efeito de
 * sumário — ela não entra em `period_summaries` (nem projetado nem realizado).
 * Saldo e XP não dependem da categoria e continuam contando normalmente.
 */
export function hasCategoryId<T extends { id?: string | null }>(
    category?: T | null
): category is T & { id: string } {
    return typeof category?.id === "string" && category.id.length > 0;
}

/**
 * Mensagem única do aviso de categoria sem id, para o gatilho e o rebuild
 * falarem a mesma língua no log (`origem` distingue quem emitiu).
 */
export function categoryWithoutIdWarning(
    origin: string,
    workspaceId: string,
    installmentId: string,
    category?: { name?: string } | null
): string {
    return `[${origin}] Parcela com categoria sem id: workspace=${workspaceId} parcela=${installmentId} categoria="${category?.name ?? ""}". Fora dos period_summaries (projetado e realizado); saldo e XP seguem normalmente. Corrija com o script fix_empty_category.`;
}
