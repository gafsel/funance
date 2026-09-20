import { ExpectedIncome } from "../models/expected_income.model";

/**
 * Os dois totais de RECEITA de um mês, já somados em centavos inteiros e já
 * filtrados: categorias de sistema (saldo inicial, virtuais de transferência)
 * e categorias deletadas ficam de fora.
 *
 * Por que os dois viajam juntos: o planejado responde pelo mês corrente e o
 * realizado pelos três meses do fallback. Separá-los em duas chamadas faria o
 * mesmo documento de sumário ser lido duas vezes.
 */
export interface MonthlyIncomeTotals {
    /** `YYYY-MM`. */
    monthKey: string;
    /**
     * O documento `period_summaries/{YYYY-MM}` EXISTE.
     *
     * É diferente de "existe e soma zero": um mês anterior ao primeiro
     * lançamento do workspace não é um mês sem receita, é um mês que não
     * aconteceu — e entrar no divisor da média puxaria a previsão para baixo
     * por um período em que o usuário nem tinha conta.
     */
    exists: boolean;
    /**
     * `specificPlannedAmountCents` somado nas categorias de RECEITA: as
     * parcelas de receita AGENDADAS para o mês.
     *
     * Não é o `generalPlannedAmount`: aquele é o LIMITE da categoria rateado
     * no período (F1.5), um teto de DESPESA. Ler o `general` para saber a
     * receita prevista foi exatamente o defeito que derrubou as missões
     * corporativas de margem em produção — ver `WeeklySummaryRow`.
     */
    plannedCents: number;
    /** `actualAmountCents` somado nas mesmas categorias: o que de fato entrou. */
    actualCents: number;
}

/**
 * Acesso a Firestore da receita prevista. A REGRA (planejado, e só na falta
 * dele a média) mora no serviço; aqui só há leitura e escrita.
 */
export interface IExpectedIncomeRepository {
    /**
     * Totais de receita de vários meses numa chamada.
     *
     * Em lote de propósito: o join em `categories` é o mesmo para todos os
     * meses, e uma chamada por mês pagaria a coleção de categorias quatro
     * vezes para responder uma pergunta só.
     */
    getMonthlyIncomeTotals(workspaceId: string, monthKeys: string[]): Promise<MonthlyIncomeTotals[]>;

    /** `workspaces/{w}.expectedIncome` como está publicado hoje, ou `null`. */
    getPublishedExpectedIncome(workspaceId: string): Promise<ExpectedIncome | null>;

    /** Grava `workspaces/{w}.expectedIncome` (merge) — nunca cria o workspace. */
    publishExpectedIncome(workspaceId: string, value: ExpectedIncome): Promise<void>;
}
