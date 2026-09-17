/**
 * O documento de `workspaces/{wid}/planning_analysis/{YYYY-MM}` — a análise
 * ideal 50-30-20 do mês.
 *
 * Escrito EXCLUSIVAMENTE pelo servidor (`PlanningAnalysisService`, via Admin
 * SDK); o cliente só lê. Até F1.11 o repositório recebia e devolvia `any`, e o
 * formato do documento existia apenas na cabeça de quem tinha escrito o
 * serviço.
 *
 * Os tipos da VALIDAÇÃO (grupos, categorias, alocação) moravam em
 * `domain/services/planning_analysis.utils.ts`. Eles vieram para o modelo
 * porque passaram a ser contrato de persistência, e não detalhe do validador —
 * o `utils` os reexporta para não quebrar quem já os importava de lá.
 */

// ===== Alvos da regra 50-30-20 (% da renda prevista) =====

export type PlanningAllocation = "essential" | "comfort" | "investment";

export const PLANNING_ALLOCATIONS: PlanningAllocation[] = ["essential", "comfort", "investment"];

export const ALLOCATION_TARGETS: Record<PlanningAllocation, number> = {
    essential: 50,
    comfort: 30,
    investment: 20,
};

export function isValidPlanningAllocation(value: unknown): value is PlanningAllocation {
    return typeof value === "string" && (PLANNING_ALLOCATIONS as string[]).includes(value);
}

/**
 * De onde saiu a receita prevista do mês. Vai para o prompt (e para o
 * documento) porque muda a confiabilidade da análise: um mês com receita
 * PLANEJADA vale mais do que a média dos três meses anteriores.
 */
export type ProjectedIncomeSource = "plannedCurrentMonth" | "avgActual3Months";

/** A categoria está dentro, acima ou abaixo do ideal calculado. */
export type PlanningCategoryStatus = "ok" | "above" | "below";

export const PLANNING_STATUSES: PlanningCategoryStatus[] = ["ok", "above", "below"];

/** Um dos três grupos da regra, com o quanto ele pesa hoje e o quanto deveria. */
export interface ValidatedAnalysisGroup {
    allocation: PlanningAllocation;
    currentPct: number;
    targetPct: number;
    /** Quanto sobra (positivo) ou falta (negativo) para o alvo, em R$. */
    deltaBRL: number;
}

/** O veredito da IA sobre UMA categoria, já validado. */
export interface ValidatedAnalysisCategory {
    categoryId: string;
    idealMonthlyAmount: number;
    idealPctOfIncome: number;
    status: PlanningCategoryStatus;
    /**
     * Alocação sugerida — `null` quando não há reclassificação a propor. Anda
     * junto de `shouldReclassify`: uma sem a outra não chega ao app.
     */
    suggestedAllocation: PlanningAllocation | null;
    shouldReclassify: boolean;
    reason: string;
    savingTip: string | null;
}

/** A saída do validador, antes do enriquecimento com os dados do servidor. */
export interface ValidatedPlanningAnalysis {
    summary: string;
    groups: ValidatedAnalysisGroup[];
    categories: ValidatedAnalysisCategory[];
    insights: string[];
}

/**
 * A categoria como ela é GRAVADA: o veredito da IA mais o que o servidor sabe
 * (nome, alocação vigente, planejado e realizado do mês).
 *
 * O nome e a alocação atual são do SERVIDOR de propósito: se viessem da IA,
 * uma alucinação renomearia a categoria do usuário no histórico.
 */
export interface PlanningAnalysisCategory extends ValidatedAnalysisCategory {
    categoryName: string;
    currentAllocation: PlanningAllocation;
    plannedAmount: number;
    actualAmount: number;
}

/** O corpo da análise — o mesmo objeto que é gravado e que vira resposta. */
export interface PlanningAnalysisPayload {
    /** `YYYY-MM`. */
    month: string;
    summary: string;
    groups: ValidatedAnalysisGroup[];
    categories: PlanningAnalysisCategory[];
    insights: string[];
    projectedIncome: number;
    /** `null` em documento legado gravado antes do campo existir. */
    incomeSource: ProjectedIncomeSource | null;
    generatedBy: string;
}

/** O que vai para o Firestore: o corpo mais o instante da geração. */
export interface PlanningAnalysisWrite extends PlanningAnalysisPayload {
    createdAt: Date;
}

/**
 * O que é LIDO. Todos os campos do corpo existem sempre porque o LEITOR
 * normaliza (ver `toPlanningAnalysisDocument`): um documento legado sem
 * `insights` chega como lista vazia, e não como `undefined` atravessando o
 * serviço.
 */
export interface PlanningAnalysisDocument extends PlanningAnalysisPayload {
    id: string;
    /** `null` quando o documento não tem o carimbo — aí o cache não vale. */
    createdAt: Date | null;
}

/** A resposta da callable `analyze503020Ideal` — o contrato com o app. */
export interface PlanningAnalysisResponse extends Omit<PlanningAnalysisPayload, "generatedBy"> {
    id: string;
    /** ISO-8601. */
    createdAt: string;
}

/** Converte um valor cru de data (Timestamp, Date ou ISO) em `Date`. */
function toDateOrNull(value: unknown): Date | null {
    if (!value) return null;
    if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
    const timestamp = value as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") return timestamp.toDate();
    if (typeof value === "string") {
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    return null;
}

/**
 * Documento cru -> `PlanningAnalysisDocument`.
 *
 * Os padrões (texto vazio, listas vazias, zero) estavam duplicados no
 * `formatResponse` do serviço; agora existem uma vez só, aqui, onde o
 * documento entra no processo.
 */
export function toPlanningAnalysisDocument(
    id: string,
    data: Record<string, unknown> | undefined
): PlanningAnalysisDocument {
    const incomeSource = data?.incomeSource;

    return {
        id,
        month: typeof data?.month === "string" ? data.month : id,
        summary: typeof data?.summary === "string" ? data.summary : "",
        groups: Array.isArray(data?.groups) ? data.groups as ValidatedAnalysisGroup[] : [],
        categories: Array.isArray(data?.categories) ? data.categories as PlanningAnalysisCategory[] : [],
        insights: Array.isArray(data?.insights) ? data.insights as string[] : [],
        projectedIncome: typeof data?.projectedIncome === "number" && Number.isFinite(data.projectedIncome)
            ? data.projectedIncome
            : 0,
        incomeSource: incomeSource === "plannedCurrentMonth" || incomeSource === "avgActual3Months"
            ? incomeSource
            : null,
        generatedBy: typeof data?.generatedBy === "string" ? data.generatedBy : "",
        createdAt: toDateOrNull(data?.createdAt),
    };
}
