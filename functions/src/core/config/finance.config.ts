export interface FinanceConfig {
    recurrence: {
        predictabilityMonths: number;
    };
    categoryPlanning: {
        predictabilityMonths: number;
    };
}

export const DEFAULT_FINANCE_CONFIG: FinanceConfig = {
    recurrence: {
        predictabilityMonths: 12,
    },
    categoryPlanning: {
        predictabilityMonths: 12,
    },
};
