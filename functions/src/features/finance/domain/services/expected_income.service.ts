import * as logger from "firebase-functions/logger";

import {
    EXPECTED_INCOME_FALLBACK_MONTHS,
    ExpectedIncome,
    sameExpectedIncome,
} from "../models/expected_income.model";
import {
    IExpectedIncomeRepository,
    MonthlyIncomeTotals,
} from "../repositories/expected_income.repository";
import { isMonthKey, shiftMonthKey, toMonthKey } from "../../../../core/utils/month_key";

/**
 * A RECEITA PREVISTA DO MÊS — uma regra, um lugar.
 *
 * ## A regra
 *
 * 1. **Planejado.** A soma de `specificPlannedAmount` das categorias de
 *    RECEITA no sumário mensal — as parcelas de receita AGENDADAS para o mês
 *    (a nota a receber, o salário lançado como recorrência). Se for maior que
 *    zero, é ela: o usuário declarou o que espera receber, e a previsão do
 *    jogo não pode discordar do que ele escreveu.
 * 2. **Média.** Só quando o planejado é ZERO: a média das receitas REALIZADAS
 *    dos últimos três meses. É o caso de quem nunca agendou uma receita —
 *    lança o salário como pago, depois que cai. Sem o fallback, esse usuário
 *    teria denominador zero, e as três razões do HUD (poção, ovo, gota) não
 *    existiriam para a maioria da base.
 *
 * ## O que NÃO entra
 *
 * - `generalPlannedAmount`, que é o LIMITE da categoria rateado no período
 *   (F1.5) — um teto de DESPESA. Confundir os dois foi o defeito que fez a
 *   missão corporativa de margem concluir de graça em produção (ver
 *   `WeeklySummaryRow`);
 * - categorias de SISTEMA. O saldo inicial é uma categoria `income`: sem o
 *   filtro, abrir uma conta com saldo viraria receita prevista;
 * - o mês sem documento de sumário, que fica fora do DIVISOR da média — um mês
 *   anterior ao primeiro lançamento do workspace não é um mês sem receita, é
 *   um mês que não aconteceu.
 *
 * ## Por que ela é PUBLICADA, e não calculada no app
 *
 * O app calcula as razões do HUD no cliente, a partir de dados que já lê. O
 * denominador é o único número que os dois lados precisam ter IGUAL — e duas
 * implementações da mesma regra divergem (F1.8, F1.10). Então ele é calculado
 * aqui e publicado em `workspaces/{w}.expectedIncome`.
 */
export class ExpectedIncomeService {
    constructor(private repository: IExpectedIncomeRepository) { }

    /**
     * A receita prevista do mês, em CENTAVOS INTEIROS.
     *
     * É a função de domínio ÚNICA: cron, gatilho, script e qualquer consumidor
     * futuro passam por aqui. `now` só é usado para carimbar `updatedAt`.
     */
    async expectedMonthlyIncomeCents(
        workspaceId: string,
        monthKey: string,
        now: Date = new Date()
    ): Promise<ExpectedIncome> {
        if (!isMonthKey(monthKey)) {
            throw new Error(`[ExpectedIncome] monthKey inválido: ${monthKey}`);
        }

        // O mês pedido + os três anteriores, numa leitura só: o fallback é
        // decidido DEPOIS de ler o planejado, mas ler sob demanda custaria uma
        // segunda ida ao banco (e um segundo join de categorias) justamente no
        // caso mais comum — o usuário que não agenda receita.
        const months = [monthKey];
        for (let offset = 1; offset <= EXPECTED_INCOME_FALLBACK_MONTHS; offset++) {
            months.push(shiftMonthKey(monthKey, -offset));
        }

        const totals = await this.repository.getMonthlyIncomeTotals(workspaceId, months);
        const byMonth = new Map<string, MonthlyIncomeTotals>(totals.map((row) => [row.monthKey, row]));

        const updatedAt = now.toISOString();
        const planned = byMonth.get(monthKey)?.plannedCents ?? 0;

        if (planned > 0) {
            return { monthKey, cents: planned, source: "planned", updatedAt };
        }

        // Só os meses que EXISTEM entram no divisor. Um mês existente sem
        // receita entra como zero, e deve: foi um mês de verdade, sem entrada.
        const history = months
            .slice(1)
            .map((key) => byMonth.get(key))
            .filter((row): row is MonthlyIncomeTotals => row?.exists === true);

        if (history.length === 0) {
            return { monthKey, cents: 0, source: "average", updatedAt };
        }

        const sum = history.reduce((total, row) => total + row.actualCents, 0);
        // A média é um inteiro de centavos: o denominador de uma razão não
        // guarda fração de centavo. Negativo vira zero — um mês de estornos
        // pode fechar com receita negativa, e uma previsão negativa inverteria
        // o sinal de todas as razões do HUD.
        const average = Math.max(0, Math.round(sum / history.length));

        return { monthKey, cents: average, source: "average", updatedAt };
    }

    /**
     * Calcula a receita prevista do mês e a PUBLICA em
     * `workspaces/{w}.expectedIncome` — quando ela mudou.
     *
     * A comparação antes da escrita não é otimização de custo: o documento do
     * workspace é observado por `onWorkspaceUpdated`, e republicar o mesmo
     * valor a cada parcela de receita faria o gatilho de gamificação acordar
     * de graça. (O campo também está em `GAMIFICATION_ONLY_FIELDS`, que é a
     * segunda linha de defesa — esta é a primeira.)
     *
     * Devolve o valor vigente e se houve escrita.
     */
    async publishExpectedIncome(
        workspaceId: string,
        monthKey: string,
        now: Date = new Date()
    ): Promise<{ value: ExpectedIncome, published: boolean }> {
        const [computed, published] = await Promise.all([
            this.expectedMonthlyIncomeCents(workspaceId, monthKey, now),
            this.repository.getPublishedExpectedIncome(workspaceId),
        ]);

        if (sameExpectedIncome(published, computed)) {
            return { value: computed, published: false };
        }

        await this.repository.publishExpectedIncome(workspaceId, computed);
        logger.debug(
            `[ExpectedIncome] ${workspaceId} ${monthKey}: ${computed.cents} centavos (${computed.source}).`
        );
        return { value: computed, published: true };
    }

    /**
     * Publica a previsão do mês CORRENTE.
     *
     * É a forma que os gatilhos usam: o HUD fala sempre do mês em curso, e uma
     * parcela de receita lançada para dezembro não muda a previsão de hoje —
     * mas muda a de dezembro, que será publicada quando dezembro começar (pelo
     * cron mensal) ou na próxima escrita de receita já dentro dele.
     */
    async publishCurrentMonth(workspaceId: string, now: Date = new Date()): Promise<void> {
        await this.publishExpectedIncome(workspaceId, toMonthKey(now), now);
    }
}
