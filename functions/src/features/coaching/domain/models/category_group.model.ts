/**
 * Grupos macro de categorias usados pelo coaching para diagnóstico de
 * estilo de vida e priorização de oportunidades de economia.
 */
export enum CategoryGroup {
    housing = "housing",
    groceries = "groceries",
    dining_out = "dining_out",
    transport = "transport",
    health_pharmacy = "health_pharmacy",
    education = "education",
    leisure = "leisure",
    subscriptions_services = "subscriptions_services",
    pets = "pets",
    clothing_shopping = "clothing_shopping",
    personal_care = "personal_care",
    debt_financial = "debt_financial",
    savings_investments = "savings_investments",
    income = "income",
    other = "other",
}

export const CATEGORY_GROUP_VALUES: string[] = Object.values(CategoryGroup);

export function isValidCategoryGroup(value: any): value is CategoryGroup {
    return typeof value === "string" && CATEGORY_GROUP_VALUES.includes(value);
}

/** Entrada do cache em workspaces/{wid}/coaching_meta/category_groups. */
export interface CategoryGroupCacheEntry {
    group: string;
    name: string;
}

export type CategoryGroupCacheMap = Record<string, CategoryGroupCacheEntry>;
