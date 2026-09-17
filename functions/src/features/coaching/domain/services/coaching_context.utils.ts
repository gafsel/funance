import { CategoryGroup } from "../models/category_group.model";

/**
 * Funções PURAS do contexto v2 do coaching (testáveis sem Firestore).
 * O CoachingService apenas coleta os agregados brutos e delega os cálculos
 * (percentuais, benchmark de estilo de vida e score de oportunidades) para cá.
 */

// F1.10 — a aritmética monetária vem de `core/utils/money`: a cópia local de
// `Math.round(value * 100) / 100` errava `1.005` (virava `1.00`).
import { round2 } from "../../../../core/utils/money";

function clamp01(value: number): number {
    if (!isFinite(value) || value < 0) return 0;
    return value > 1 ? 1 : value;
}

// ===== Benchmark de estilo de vida (faixas de referência em % da renda mensal) =====

export interface LifestyleBenchmark {
    minPct: number;
    /** null = sem teto (savings_investments é meta mínima, não teto). */
    maxPct: number | null;
    /** true quando a faixa representa uma meta mínima (poupar/investir). */
    isMinimumTarget: boolean;
}

export const LIFESTYLE_BENCHMARKS: Partial<Record<CategoryGroup, LifestyleBenchmark>> = {
    [CategoryGroup.housing]: { minPct: 25, maxPct: 35, isMinimumTarget: false },
    [CategoryGroup.groceries]: { minPct: 10, maxPct: 15, isMinimumTarget: false },
    [CategoryGroup.dining_out]: { minPct: 5, maxPct: 8, isMinimumTarget: false },
    [CategoryGroup.transport]: { minPct: 10, maxPct: 15, isMinimumTarget: false },
    [CategoryGroup.health_pharmacy]: { minPct: 5, maxPct: 10, isMinimumTarget: false },
    [CategoryGroup.education]: { minPct: 5, maxPct: 15, isMinimumTarget: false },
    [CategoryGroup.leisure]: { minPct: 5, maxPct: 10, isMinimumTarget: false },
    [CategoryGroup.subscriptions_services]: { minPct: 3, maxPct: 5, isMinimumTarget: false },
    [CategoryGroup.pets]: { minPct: 2, maxPct: 5, isMinimumTarget: false },
    [CategoryGroup.clothing_shopping]: { minPct: 3, maxPct: 5, isMinimumTarget: false },
    [CategoryGroup.personal_care]: { minPct: 2, maxPct: 4, isMinimumTarget: false },
    [CategoryGroup.debt_financial]: { minPct: 0, maxPct: 15, isMinimumTarget: false },
    [CategoryGroup.savings_investments]: { minPct: 10, maxPct: null, isMinimumTarget: true },
};

/** Grupos essenciais: a recomendação deve ser MÉTODO de economia, não corte de consumo. */
export const ESSENTIAL_GROUPS: ReadonlySet<CategoryGroup> = new Set([
    CategoryGroup.groceries,
    CategoryGroup.health_pharmacy,
    CategoryGroup.transport,
    CategoryGroup.housing,
    CategoryGroup.pets,
    CategoryGroup.education,
]);

// ===== Renda mensal =====

export interface MonthlyIncomeResult {
    /** Renda média mensal em R$, ou null quando não há receitas registradas. */
    monthlyIncome: number | null;
    /** Origem do valor (para o prompt saber a confiabilidade). */
    source: "avg3FullMonths" | "currentMonth" | null;
}

/**
 * Renda mensal de referência: média das receitas dos últimos 3 meses completos
 * (considerando apenas meses com receita registrada). Se nenhum mês completo
 * tiver receita, cai para a receita do mês corrente; se também não houver, null.
 */
export function computeMonthlyIncome(
    incomePerFullMonth: number[],
    currentMonthIncome: number
): MonthlyIncomeResult {
    const monthsWithIncome = incomePerFullMonth.filter(v => v > 0);
    if (monthsWithIncome.length > 0) {
        const total = monthsWithIncome.reduce((acc, v) => acc + v, 0);
        return { monthlyIncome: round2(total / monthsWithIncome.length), source: "avg3FullMonths" };
    }
    if (currentMonthIncome > 0) {
        return { monthlyIncome: round2(currentMonthIncome), source: "currentMonth" };
    }
    return { monthlyIncome: null, source: null };
}

// ===== Perfil por categoria de despesa =====

/** Agregados brutos de uma categoria de despesa (coletados pelo service). */
export interface CategoryProfileInput {
    categoryId: string;
    categoryName: string;
    group: CategoryGroup;
    /** Soma do realizado (period_summaries) nos últimos 3 meses completos. */
    sumLast3Months: number;
    /** Meses com summary existente na janela (1 a 3) — usado como divisor da média. */
    monthsWithData: number;
    /** Número de parcelas/lançamentos realizados na janela (installments). */
    txCount: number;
    /** Total realizado na janela segundo as installments (base do ticket/recorrência). */
    installmentsTotal: number;
    /** Parte de installmentsTotal vinda de installments com installmentType 'recurring'. */
    recurringAmount: number;
    /** Média mensal dos 3 meses ANTERIORES à janela (meses 4-6), ou null sem dados. */
    prevAvgMonthly: number | null;
}

export interface CategoryProfileEntry {
    categoryId: string;
    categoryName: string;
    group: CategoryGroup;
    totalLast3Months: number;
    avgMonthly: number;
    txCount: number;
    avgTicket: number | null;
    pctOfIncome: number | null;
    pctOfExpenses: number | null;
    /** Fração (0-1) do valor vinda de lançamentos recorrentes/contratados. */
    recurringShare: number;
    /** Variação % da média mensal vs os 3 meses anteriores (null sem histórico). */
    trendPct: number | null;
}

export function buildCategoryProfile(
    inputs: CategoryProfileInput[],
    monthlyIncome: number | null
): CategoryProfileEntry[] {
    const withAvg = inputs
        .map(input => ({
            input,
            avgMonthly: input.monthsWithData > 0 ? input.sumLast3Months / input.monthsWithData : 0,
        }))
        .filter(({ input, avgMonthly }) => avgMonthly > 0 || input.txCount > 0);

    const totalMonthlyExpenses = withAvg.reduce((acc, { avgMonthly }) => acc + avgMonthly, 0);

    return withAvg
        .map(({ input, avgMonthly }) => {
            const recurringShare = input.installmentsTotal > 0
                ? clamp01(input.recurringAmount / input.installmentsTotal)
                : 0;

            return {
                categoryId: input.categoryId,
                categoryName: input.categoryName,
                group: input.group,
                totalLast3Months: round2(input.sumLast3Months),
                avgMonthly: round2(avgMonthly),
                txCount: input.txCount,
                avgTicket: input.txCount > 0 ? round2(input.installmentsTotal / input.txCount) : null,
                pctOfIncome: (monthlyIncome !== null && monthlyIncome > 0)
                    ? round2((avgMonthly / monthlyIncome) * 100)
                    : null,
                pctOfExpenses: totalMonthlyExpenses > 0
                    ? round2((avgMonthly / totalMonthlyExpenses) * 100)
                    : null,
                recurringShare: round2(recurringShare),
                trendPct: (input.prevAvgMonthly !== null && input.prevAvgMonthly > 0)
                    ? round2(((avgMonthly - input.prevAvgMonthly) / input.prevAvgMonthly) * 100)
                    : null,
            };
        })
        .sort((a, b) => b.avgMonthly - a.avgMonthly);
}

// ===== Diagnóstico de estilo de vida por grupo macro =====

export type BenchmarkStatus = "below" | "within" | "above";

export interface BenchmarkResult {
    referenceMinPct: number | null;
    referenceMaxPct: number | null;
    isMinimumTarget: boolean;
    status: BenchmarkStatus | null;
    /** Quanto o gasto mensal excede o teto da faixa, em R$/mês (0 quando não excede). */
    deltaMonthlyBRL: number;
}

export function computeBenchmarkStatus(
    group: CategoryGroup,
    actualPctOfIncome: number | null,
    monthlyIncome: number | null
): BenchmarkResult {
    const benchmark = LIFESTYLE_BENCHMARKS[group];
    if (!benchmark) {
        return { referenceMinPct: null, referenceMaxPct: null, isMinimumTarget: false, status: null, deltaMonthlyBRL: 0 };
    }

    const base: BenchmarkResult = {
        referenceMinPct: benchmark.minPct,
        referenceMaxPct: benchmark.maxPct,
        isMinimumTarget: benchmark.isMinimumTarget,
        status: null,
        deltaMonthlyBRL: 0,
    };

    if (actualPctOfIncome === null || monthlyIncome === null || monthlyIncome <= 0) {
        return base;
    }

    if (benchmark.isMinimumTarget) {
        // Meta mínima (savings_investments): abaixo do mínimo = below, senão within.
        base.status = actualPctOfIncome < benchmark.minPct ? "below" : "within";
        return base;
    }

    if (actualPctOfIncome < benchmark.minPct) {
        base.status = "below";
    }
    else if (benchmark.maxPct !== null && actualPctOfIncome > benchmark.maxPct) {
        base.status = "above";
        base.deltaMonthlyBRL = round2(((actualPctOfIncome - benchmark.maxPct) / 100) * monthlyIncome);
    }
    else {
        base.status = "within";
    }

    return base;
}

export interface LifestyleGroupEntry {
    group: CategoryGroup;
    avgMonthly: number;
    actualPctOfIncome: number | null;
    pctOfExpenses: number | null;
    referenceMinPct: number | null;
    referenceMaxPct: number | null;
    isMinimumTarget: boolean;
    status: BenchmarkStatus | null;
    deltaMonthlyBRL: number;
}

/**
 * Agrega o perfil de categorias por grupo macro e compara com as faixas de
 * referência. Com monthlyIncome null, actualPctOfIncome/status ficam null e o
 * diagnóstico se limita a pctOfExpenses.
 */
export function buildLifestyleDiagnosis(
    profile: CategoryProfileEntry[],
    monthlyIncome: number | null
): LifestyleGroupEntry[] {
    const totals = new Map<CategoryGroup, number>();
    for (const entry of profile) {
        if (entry.group === CategoryGroup.income) continue;
        totals.set(entry.group, (totals.get(entry.group) || 0) + entry.avgMonthly);
    }

    const totalExpenses = [...totals.values()].reduce((acc, v) => acc + v, 0);

    return [...totals.entries()]
        .filter(([, avgMonthly]) => avgMonthly > 0)
        .map(([group, avgMonthly]) => {
            const actualPctOfIncome = (monthlyIncome !== null && monthlyIncome > 0)
                ? round2((avgMonthly / monthlyIncome) * 100)
                : null;
            const benchmark = computeBenchmarkStatus(group, actualPctOfIncome, monthlyIncome);

            return {
                group,
                avgMonthly: round2(avgMonthly),
                actualPctOfIncome,
                pctOfExpenses: totalExpenses > 0 ? round2((avgMonthly / totalExpenses) * 100) : null,
                referenceMinPct: benchmark.referenceMinPct,
                referenceMaxPct: benchmark.referenceMaxPct,
                isMinimumTarget: benchmark.isMinimumTarget,
                status: benchmark.status,
                deltaMonthlyBRL: benchmark.deltaMonthlyBRL,
            };
        })
        .sort((a, b) => b.avgMonthly - a.avgMonthly);
}

// ===== Oportunidades de economia =====

export interface SavingsOpportunityEntry {
    categoryName: string;
    group: CategoryGroup;
    isEssential: boolean;
    avgMonthly: number;
    recurringShare: number;
    trendPct: number | null;
    groupStatus: BenchmarkStatus | null;
    score: number;
}

/**
 * score = avgMonthly × (1 − 0.5×recurringShare) × (grupo acima da faixa ? 1.5 : 1) × (1 + max(0, trendPct)/100)
 * Quanto maior, mais fácil/impactante deve ser a economia naquela categoria.
 */
export function computeOpportunityScore(
    avgMonthly: number,
    recurringShare: number,
    groupIsAboveBenchmark: boolean,
    trendPct: number | null
): number {
    const recurringFactor = 1 - 0.5 * clamp01(recurringShare);
    const benchmarkFactor = groupIsAboveBenchmark ? 1.5 : 1;
    const trendFactor = 1 + Math.max(0, trendPct ?? 0) / 100;
    return round2(avgMonthly * recurringFactor * benchmarkFactor * trendFactor);
}

/**
 * Top 5 categorias de despesa por score. Grupos income e savings_investments
 * são excluídos (cortar investimento não é economia).
 */
export function buildSavingsOpportunities(
    profile: CategoryProfileEntry[],
    lifestyle: LifestyleGroupEntry[]
): SavingsOpportunityEntry[] {
    const statusByGroup = new Map<CategoryGroup, BenchmarkStatus | null>(
        lifestyle.map(entry => [entry.group, entry.status])
    );

    return profile
        .filter(entry =>
            entry.group !== CategoryGroup.income &&
            entry.group !== CategoryGroup.savings_investments &&
            entry.avgMonthly > 0)
        .map(entry => {
            const groupStatus = statusByGroup.get(entry.group) ?? null;
            return {
                categoryName: entry.categoryName,
                group: entry.group,
                isEssential: ESSENTIAL_GROUPS.has(entry.group),
                avgMonthly: entry.avgMonthly,
                recurringShare: entry.recurringShare,
                trendPct: entry.trendPct,
                groupStatus,
                score: computeOpportunityScore(
                    entry.avgMonthly,
                    entry.recurringShare,
                    groupStatus === "above",
                    entry.trendPct
                ),
            };
        })
        .sort((a, b) => b.score - a.score)
        .slice(0, 5);
}
