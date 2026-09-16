/**
 * Limites diários de uso das funções de IA, por workspace.
 *
 * Cada chamada ao Gemini é paga, então cada callable de IA tem um teto diário
 * por workspace. Os valores abaixo são o ponto de partida (F0.8) e podem ser
 * revistos com os dados reais de uso. O contador vive em
 * `workspaces/{workspaceId}/quotas/{YYYY-MM-DD}` (ver quota.service.ts).
 */

/** Nomes das funções de IA com quota. É também o nome do campo no documento de quota. */
export type AiQuotaFunction =
    | "analysePlanning"
    | "analyzeAccountDocument"
    | "analyzeReconciliationDocument"
    | "analyzeGoalFeasibility"
    | "generateCoaching"
    | "analyze503020Ideal";

/** Limite de chamadas por dia (fuso America/Sao_Paulo), por workspace. */
export const AI_DAILY_QUOTAS: Record<AiQuotaFunction, number> = {
    analysePlanning: 5,
    // "documento": análise de extrato/fatura para cadastro de conta e para
    // conciliação. Cada uma tem seu próprio contador, com o mesmo teto.
    analyzeAccountDocument: 10,
    analyzeReconciliationDocument: 10,
    analyzeGoalFeasibility: 20,
    generateCoaching: 3,
    analyze503020Ideal: 3,
};

/**
 * Nome amigável usado na mensagem de erro mostrada ao usuário quando o
 * limite é atingido. Sem isso a mensagem citaria o nome técnico da function.
 */
export const AI_QUOTA_LABELS: Record<AiQuotaFunction, string> = {
    analysePlanning: "análises de planejamento por IA",
    analyzeAccountDocument: "análises de documento",
    analyzeReconciliationDocument: "análises de conciliação",
    analyzeGoalFeasibility: "análises de viabilidade de meta",
    generateCoaching: "consultorias do coach financeiro",
    analyze503020Ideal: "análises da regra 50-30-20",
};
