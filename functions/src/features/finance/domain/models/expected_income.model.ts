/**
 * RECEITA PREVISTA DO MÊS — o denominador do HUD mensal da Arena.
 *
 * Três dos quatro ícones do rodapé da Arena (poção/investimentos, ovo/cartões,
 * gota/dívidas) são RAZÕES cujo denominador é a receita prevista do mês. O app
 * calcula as razões no cliente, a partir de dados que ele já lê (saldos das
 * contas de investimento, `accounts.nextInvoice`, contas de dívida) — mas o
 * denominador NÃO pode ser calculado nos dois lados.
 *
 * Duas implementações da mesma regra divergem; foi o que aconteceu com a
 * fatura (F1.8) e com o arredondamento de dinheiro (F1.10), e as duas vezes o
 * usuário viu números diferentes na mesma tela. Por isso a receita prevista é
 * calculada UMA vez, no servidor (`ExpectedIncomeService`), e PUBLICADA em
 * `workspaces/{w}.expectedIncome`: o app lê, não recalcula.
 */

/** Como a receita prevista foi obtida. É contrato: o app mostra a origem. */
export type ExpectedIncomeSource =
    /** Do PLANEJADO: as parcelas de receita agendadas para o mês. */
    | "planned"
    /** Do HISTÓRICO: média das receitas realizadas dos últimos 3 meses. */
    | "average";

/**
 * O documento publicado em `workspaces/{w}.expectedIncome`.
 *
 * `cents` é INTEIRO e é a fonte da verdade (F1.10): não há espelho `double`
 * aqui porque o campo nasceu depois da etapa B e nenhuma build instalada o lê
 * como `double`. O app divide inteiro por inteiro e formata no fim.
 */
export interface ExpectedIncome {
    /** `YYYY-MM` — o mês a que a previsão se refere. */
    monthKey: string;
    /** Receita prevista do mês, em CENTAVOS INTEIROS. Nunca negativa. */
    cents: number;
    source: ExpectedIncomeSource;
    /**
     * Instante do cálculo, em ISO-8601. Informativo (mesmo papel do
     * `financialHealth.computedAt`): ele é o que permite ver, olhando o
     * documento, se a previsão ficou para trás do mês corrente.
     */
    updatedAt: string;
}

/**
 * Quantos meses de histórico entram na média do fallback.
 *
 * Três: um mês só transforma um décimo terceiro em salário permanente, e seis
 * arrastam um emprego antigo para dentro do mês corrente. O mesmo horizonte
 * que a Bússola usa para o Fôlego.
 */
export const EXPECTED_INCOME_FALLBACK_MONTHS = 3;

/** As duas previsões são a MESMA? (o `updatedAt` não entra na comparação) */
export function sameExpectedIncome(
    a: ExpectedIncome | null | undefined,
    b: ExpectedIncome | null | undefined
): boolean {
    if (!a || !b) return false;
    return a.monthKey === b.monthKey && a.cents === b.cents && a.source === b.source;
}
