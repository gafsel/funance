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
}

export const VIRTUAL_DEBT_EXPENSE_CATEGORY: CategoryModel = {
    id: "virtual_debt_expense",
    name: "Empréstimo/Dívidas",
    icon: "handshake",
    color: "#E57373",
    type: CategoryType.expense,
    isDeleted: false,
};

export const VIRTUAL_DEBT_INCOME_CATEGORY: CategoryModel = {
    id: "virtual_debt_income",
    name: "Empréstimo/Dívidas",
    icon: "handshake",
    color: "#E57373",
    type: CategoryType.income,
    isDeleted: false,
};

export const VIRTUAL_INVESTMENT_EXPENSE_CATEGORY: CategoryModel = {
    id: "virtual_investment_expense",
    name: "Investimentos",
    icon: "trending_up",
    color: "#81C784",
    type: CategoryType.expense,
    isDeleted: false,
};

export const VIRTUAL_INVESTMENT_INCOME_CATEGORY: CategoryModel = {
    id: "virtual_investment_income",
    name: "Investimentos",
    icon: "trending_up",
    color: "#81C784",
    type: CategoryType.income,
    isDeleted: false,
};
