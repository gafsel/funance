import { CategoryGroup } from "../../../coaching/domain/models/category_group.model";
import {
    ALLOCATION_TARGETS,
    PLANNING_ALLOCATIONS,
    PLANNING_STATUSES,
    PlanningAllocation,
    PlanningCategoryStatus,
    ProjectedIncomeSource,
    ValidatedAnalysisCategory,
    ValidatedAnalysisGroup,
    ValidatedPlanningAnalysis,
    isValidPlanningAllocation,
} from "../models/planning_analysis.model";
import {
    ESSENTIAL_GROUPS,
    LIFESTYLE_BENCHMARKS,
} from "../../../coaching/domain/services/coaching_context.utils";

/**
 * Funções PURAS da análise ideal 50-30-20 (testáveis sem Firestore).
 * O PlanningAnalysisService apenas coleta os agregados brutos (summaries e
 * categorias) e delega os cálculos e a validação do payload da IA para cá.
 */

// F1.10 — a aritmética monetária vem de `core/utils/money`: a cópia local de
// `Math.round(value * 100) / 100` errava `1.005` (virava `1.00`).
import { round2 } from "../../../../core/utils/money";

function isFiniteNumber(value: any): value is number {
    return typeof value === "number" && isFinite(value);
}

// Os tipos e as tabelas da regra 50-30-20 moraram aqui até F1.11. Eles são
// contrato de PERSISTÊNCIA (o documento de `planning_analysis` os grava), e por
// isso passaram para `domain/models/planning_analysis.model.ts`. A reexportação
// mantém válidos os imports que já apontavam para este módulo.
export {
    ALLOCATION_TARGETS,
    PLANNING_ALLOCATIONS,
    PLANNING_STATUSES,
    PlanningAllocation,
    PlanningCategoryStatus,
    ProjectedIncomeSource,
    ValidatedAnalysisCategory,
    ValidatedAnalysisGroup,
    ValidatedPlanningAnalysis,
    isValidPlanningAllocation,
};

// ===== Receita prevista do mês =====

export interface ProjectedIncomeResult {
    /** Receita prevista mensal em R$, ou null quando não há nenhuma referência. */
    projectedIncome: number | null;
    /** Origem do valor (para o prompt saber a confiabilidade). */
    source: ProjectedIncomeSource | null;
}

/**
 * Receita prevista do mês: soma do specificPlannedAmount das categorias income
 * no period_summary do mês corrente. Fallback: média da receita REALIZADA dos
 * meses completos com receita (janela de 3 meses). Sem nada, null.
 */
export function computeProjectedIncome(
    plannedCurrentMonthIncome: number,
    actualIncomePerFullMonth: number[]
): ProjectedIncomeResult {
    if (plannedCurrentMonthIncome > 0) {
        return { projectedIncome: round2(plannedCurrentMonthIncome), source: "plannedCurrentMonth" };
    }

    const monthsWithIncome = actualIncomePerFullMonth.filter(v => v > 0);
    if (monthsWithIncome.length > 0) {
        const total = monthsWithIncome.reduce((acc, v) => acc + v, 0);
        return { projectedIncome: round2(total / monthsWithIncome.length), source: "avgActual3Months" };
    }

    return { projectedIncome: null, source: null };
}

// ===== Contexto por categoria de despesa =====

/** Agregados brutos de uma categoria de despesa (coletados pelo service). */
export interface PlanningCategoryInput {
    categoryId: string;
    categoryName: string;
    /** Alocação atual da categoria no app (essential/comfort/investment). */
    allocation: PlanningAllocation;
    /** Grupo macro resolvido via CategoryGroupService. */
    group: CategoryGroup;
    /** Planejado do mês corrente: max(generalPlannedAmount, specificPlannedAmount). */
    plannedAmount: number;
    /** Realizado do mês corrente. */
    actualAmount: number;
    /** Média mensal realizada nos últimos 3 meses completos. */
    avgActual3Months: number;
}

export interface PlanningCategoryContextEntry extends PlanningCategoryInput {
    /** % da renda prevista comprometida pelo planejado do mês. */
    plannedPctOfIncome: number;
    /** % da renda prevista consumida pelo realizado do mês. */
    actualPctOfIncome: number;
    /** % da renda prevista da média realizada dos 3 meses completos. */
    avgActualPctOfIncome: number;
    /** true quando o grupo macro é de consumo essencial (método > corte). */
    isEssentialGroup: boolean;
}

/** Limite de categorias enviadas no prompt (mantém o custo razoável). */
export const MAX_CONTEXT_CATEGORIES = 30;

/**
 * Monta o contexto por categoria com percentuais sobre a renda prevista,
 * ordenado do maior para o menor compromisso mensal. Categorias sem nenhum
 * sinal (planejado, realizado e média zerados) são descartadas, a menos que
 * NENHUMA categoria tenha sinal — nesse caso todas entram (workspace novo).
 */
export function buildPlanningCategoryContext(
    inputs: PlanningCategoryInput[],
    projectedIncome: number
): PlanningCategoryContextEntry[] {
    const withSignal = inputs.filter(i => i.plannedAmount > 0 || i.actualAmount > 0 || i.avgActual3Months > 0);
    const base = withSignal.length > 0 ? withSignal : inputs;

    return base
        .map(input => ({
            ...input,
            plannedAmount: round2(input.plannedAmount),
            actualAmount: round2(input.actualAmount),
            avgActual3Months: round2(input.avgActual3Months),
            plannedPctOfIncome: projectedIncome > 0 ? round2((input.plannedAmount / projectedIncome) * 100) : 0,
            actualPctOfIncome: projectedIncome > 0 ? round2((input.actualAmount / projectedIncome) * 100) : 0,
            avgActualPctOfIncome: projectedIncome > 0 ? round2((input.avgActual3Months / projectedIncome) * 100) : 0,
            isEssentialGroup: ESSENTIAL_GROUPS.has(input.group),
        }))
        .sort((a, b) =>
            (b.plannedAmount + b.actualAmount + b.avgActual3Months) -
            (a.plannedAmount + a.actualAmount + a.avgActual3Months))
        .slice(0, MAX_CONTEXT_CATEGORIES);
}

// ===== Totais por alocação vs alvos 50/30/20 =====

export interface AllocationTotalsEntry {
    allocation: PlanningAllocation;
    /** Alvo da regra em % da renda prevista (50/30/20). */
    targetPct: number;
    /** Alvo da regra em R$ (targetPct × renda prevista). */
    targetBRL: number;
    plannedBRL: number;
    plannedPct: number;
    actualBRL: number;
    actualPct: number;
    /** plannedBRL − targetBRL (positivo = planejado acima do envelope). */
    plannedDeltaBRL: number;
    /** actualBRL − targetBRL (positivo = realizado acima do envelope). */
    actualDeltaBRL: number;
}

export function buildAllocationTotals(
    entries: PlanningCategoryContextEntry[],
    projectedIncome: number
): AllocationTotalsEntry[] {
    return PLANNING_ALLOCATIONS.map(allocation => {
        const targetPct = ALLOCATION_TARGETS[allocation];
        const targetBRL = round2((targetPct / 100) * projectedIncome);

        let plannedBRL = 0;
        let actualBRL = 0;
        for (const entry of entries) {
            if (entry.allocation !== allocation) continue;
            plannedBRL += entry.plannedAmount;
            actualBRL += entry.actualAmount;
        }

        return {
            allocation,
            targetPct,
            targetBRL,
            plannedBRL: round2(plannedBRL),
            plannedPct: projectedIncome > 0 ? round2((plannedBRL / projectedIncome) * 100) : 0,
            actualBRL: round2(actualBRL),
            actualPct: projectedIncome > 0 ? round2((actualBRL / projectedIncome) * 100) : 0,
            plannedDeltaBRL: round2(plannedBRL - targetBRL),
            actualDeltaBRL: round2(actualBRL - targetBRL),
        };
    });
}

// ===== Benchmarks por grupo macro resolvidos para R$ do usuário =====

export interface BenchmarkBRLEntry {
    group: CategoryGroup;
    minPct: number;
    maxPct: number | null;
    minBRL: number;
    /** null = sem teto (metas mínimas, ex.: savings_investments). */
    maxBRL: number | null;
    isMinimumTarget: boolean;
}

export function resolveBenchmarksBRL(projectedIncome: number): BenchmarkBRLEntry[] {
    return Object.entries(LIFESTYLE_BENCHMARKS).map(([group, benchmark]) => ({
        group: group as CategoryGroup,
        minPct: benchmark.minPct,
        maxPct: benchmark.maxPct,
        minBRL: round2((benchmark.minPct / 100) * projectedIncome),
        maxBRL: benchmark.maxPct !== null ? round2((benchmark.maxPct / 100) * projectedIncome) : null,
        isMinimumTarget: benchmark.isMinimumTarget,
    }));
}

// ===== Validação server-side do payload da IA =====

/**
 * Valida o payload retornado pela IA:
 * - categoryId precisa existir no contexto (desconhecidos são descartados);
 * - alocações fora do enum são descartadas/neutralizadas;
 * - números não finitos invalidam a entrada;
 * - shouldReclassify só se mantém com suggestedAllocation válida, DIFERENTE da
 *   atual e com justificativa não vazia.
 */
export function validatePlanningAnalysis(
    raw: any,
    currentAllocationByCategoryId: Map<string, PlanningAllocation>
): ValidatedPlanningAnalysis {
    const groups: ValidatedAnalysisGroup[] = [];
    for (const item of Array.isArray(raw?.groups) ? raw.groups : []) {
        if (!item || typeof item !== "object") continue;
        if (!isValidPlanningAllocation(item.allocation)) continue;
        if (!isFiniteNumber(item.currentPct) || !isFiniteNumber(item.targetPct) || !isFiniteNumber(item.deltaBRL)) continue;

        groups.push({
            allocation: item.allocation,
            currentPct: round2(item.currentPct),
            targetPct: round2(item.targetPct),
            deltaBRL: round2(item.deltaBRL),
        });
    }

    const categories: ValidatedAnalysisCategory[] = [];
    const seenIds = new Set<string>();
    for (const item of Array.isArray(raw?.categories) ? raw.categories : []) {
        if (!item || typeof item !== "object") continue;
        if (typeof item.categoryId !== "string") continue;

        const currentAllocation = currentAllocationByCategoryId.get(item.categoryId);
        if (!currentAllocation) continue; // categoryId desconhecido — descarta
        if (seenIds.has(item.categoryId)) continue;
        if (!isFiniteNumber(item.idealMonthlyAmount) || !isFiniteNumber(item.idealPctOfIncome)) continue;
        if (item.idealMonthlyAmount < 0) continue;

        const suggestedAllocation = isValidPlanningAllocation(item.suggestedAllocation)
            ? item.suggestedAllocation
            : null;
        const reason = typeof item.reason === "string" ? item.reason.trim() : "";
        const shouldReclassify = item.shouldReclassify === true
            && suggestedAllocation !== null
            && suggestedAllocation !== currentAllocation
            && reason.length > 0;

        seenIds.add(item.categoryId);
        categories.push({
            categoryId: item.categoryId,
            idealMonthlyAmount: round2(item.idealMonthlyAmount),
            idealPctOfIncome: round2(item.idealPctOfIncome),
            status: PLANNING_STATUSES.includes(item.status) ? item.status : "ok",
            suggestedAllocation: shouldReclassify ? suggestedAllocation : null,
            shouldReclassify,
            reason,
            savingTip: (typeof item.savingTip === "string" && item.savingTip.trim().length > 0)
                ? item.savingTip.trim()
                : null,
        });
    }

    const insights = (Array.isArray(raw?.insights) ? raw.insights : [])
        .filter((i: any) => typeof i === "string" && i.trim().length > 0)
        .map((i: string) => i.trim());

    return {
        summary: typeof raw?.summary === "string" ? raw.summary.trim() : "",
        groups,
        categories,
        insights,
    };
}
