export interface FinanceConfig {
    recurrence: {
        predictabilityMonths: number;
    };
}

export const DEFAULT_FINANCE_CONFIG: FinanceConfig = {
    recurrence: {
        predictabilityMonths: 12,
    },
};
