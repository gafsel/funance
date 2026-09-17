import * as logger from "firebase-functions/logger";

import { toDateKey, toMonthKey } from "../../../../core/utils/date_key";
import { monthKeyParts, shiftMonthKey } from "../../../../core/utils/month_key";
import { localMidnightInstant } from "../../../../core/utils/timezone.utils";
import { IHealthRepository } from "../repositories/health.repository";
import {
    FinancialHealthSnapshot,
    buildSnapshot,
    emptySnapshot,
    scoreAlivio,
    scoreDisciplina,
    scoreFolego,
    scorePoupanca,
} from "../models/financial_health.model";

/**
 * Meses de histórico usados na média de despesa do Fôlego. Três é o menor
 * número que ainda dilui um mês atípico (IPVA, décimo terceiro) sem exigir
 * um histórico que o usuário novo não tem.
 */
export const FOLEGO_LOOKBACK_MONTHS = 3;

/**
 * Debounce do recálculo: um workspace recalculado há menos que isto fica sujo
 * para o ciclo seguinte do cron. É o que impede que uma tarde de conciliação
 * (dezenas de parcelas em minutos) vire dezenas de recálculos completos.
 */
export const HEALTH_MIN_RECOMPUTE_INTERVAL_MS = 10 * 60 * 1000;

/** Último instante (23:59:59.999 no fuso do produto) do mês `monthKey`. */
export function endOfMonthInstant(monthKey: string): Date {
    const next = shiftMonthKey(monthKey, 1);
    const { year, month } = monthKeyParts(next);
    return new Date(localMidnightInstant(year, month, 1).getTime() - 1);
}

export interface RefreshResult {
    /** `null` quando o recálculo foi adiado pelo debounce. */
    snapshot: FinancialHealthSnapshot | null;
    /** `true` quando o retrato foi recalculado e gravado nesta chamada. */
    computed: boolean;
    /** `true` quando o recálculo foi pulado por causa do intervalo mínimo. */
    debounced: boolean;
}

/**
 * F2.2 — cálculo da Bússola da Liberdade.
 *
 * Um `computeHealth(workspaceId, now)` inteiramente parametrizado por `now`:
 * é isso que permite ao cron mensal FECHAR o mês anterior (basta chamar com o
 * último instante daquele mês) e ao teste de integração provar que a segunda
 * execução não muda nada.
 *
 * Nenhuma chamada de IA. As fontes são todas do próprio servidor:
 *  - `period_summaries` mensais (realizado por categoria);
 *  - `accounts` + o último documento de `balance` de cada uma;
 *  - `category_planning` vigentes no mês avaliado.
 */
export class FinancialHealthService {
    constructor(private repository: IHealthRepository) {}

    /**
     * Retrato do workspace no instante `now`.
     *
     * Escolhas de janela, todas deliberadas:
     *
     *  - **Fôlego** usa os TRÊS MESES COMPLETOS anteriores ao mês de `now`. O
     *    mês corrente fica de fora de propósito: no dia 2 ele ainda não tem
     *    despesa nenhuma, e incluí-lo faria a reserva parecer infinita todo
     *    dia 1 e encolher ao longo do mês.
     *  - **Poupança** usa o mês CORRENTE — é o mês que o usuário está jogando.
     *    Quando ele ainda não tem receita lançada (tipicamente os primeiros
     *    dias), cai para o mês anterior em vez de exibir zero: a virada de mês
     *    não pode derrubar o placar sozinha.
     *  - **Disciplina** usa o mês ANTERIOR, porque um limite só pode ser
     *    julgado depois de o mês fechar. Julgar o mês corrente reprovaria
     *    quem ainda tem 20 dias para se ajustar.
     *  - **Alívio** compara a dívida de hoje com a do fim do mês anterior.
     */
    async computeHealth(workspaceId: string, now: Date = new Date()): Promise<FinancialHealthSnapshot> {
        const monthKey = toMonthKey(now);
        const previousMonthKey = shiftMonthKey(monthKey, -1);

        const balances = await this.repository.getAccountBalanceTotals(workspaceId, toDateKey(now));

        // SEM DADO NENHUM. Um workspace sem conta alguma não tem saldo, não tem
        // dívida e não tem de onde tirar despesa: devolver o retrato zerado é
        // mais honesto (e muito mais barato) do que somar quatro zeros com
        // pesos. O app desenha a bússola vazia em vez de um estado de erro.
        if (!balances.hasAnyAccount) {
            return emptySnapshot(monthKey, now);
        }

        const [avgExpense, savings, limits, previousDebt] = await Promise.all([
            this.averageMonthlyExpense(workspaceId, monthKey),
            this.savingsRateInput(workspaceId, monthKey, previousMonthKey),
            this.repository.getCategoryLimitOutcomes(workspaceId, previousMonthKey),
            this.repository.getAccountBalanceTotals(workspaceId, toDateKey(endOfMonthInstant(previousMonthKey))),
        ]);

        const within = limits.filter((outcome) => outcome.actual <= outcome.limit).length;

        const components = {
            folego: scoreFolego(balances.liquid, avgExpense),
            poupanca: scorePoupanca(savings.income, savings.expense),
            disciplina: scoreDisciplina(within, limits.length),
            // Saldo de dívida é negativo: amortizar o aproxima de zero, então
            // `atual − anterior` POSITIVO significa dívida menor.
            alivio: scoreAlivio(balances.debt - previousDebt.debt, balances.hasDebtAccounts),
        };

        return buildSnapshot(components, monthKey, now);
    }

    /** Média de despesa realizada dos `FOLEGO_LOOKBACK_MONTHS` meses anteriores. */
    private async averageMonthlyExpense(workspaceId: string, monthKey: string): Promise<number> {
        const keys: string[] = [];
        for (let offset = 1; offset <= FOLEGO_LOOKBACK_MONTHS; offset++) {
            keys.push(shiftMonthKey(monthKey, -offset));
        }

        const totals = await Promise.all(
            keys.map((key) => this.repository.getMonthlyTotals(workspaceId, key))
        );

        // O divisor é FIXO (3), não "meses com movimento": um usuário de dois
        // meses que gastou só num deles não tem uma despesa média baixa, ele
        // tem pouco histórico — e a média cheia é a leitura conservadora.
        const sum = totals.reduce((acc, month) => acc + Math.max(0, month.expense), 0);
        return sum / FOLEGO_LOOKBACK_MONTHS;
    }

    /**
     * Receita/despesa do mês da taxa de poupança, com o recuo para o mês
     * anterior quando o corrente ainda não tem receita (ver `computeHealth`).
     */
    private async savingsRateInput(
        workspaceId: string,
        monthKey: string,
        previousMonthKey: string
    ): Promise<{ income: number, expense: number }> {
        const current = await this.repository.getMonthlyTotals(workspaceId, monthKey);
        if (current.income > 0) return current;

        return this.repository.getMonthlyTotals(workspaceId, previousMonthKey);
    }

    /**
     * Recalcula e persiste: `workspaces/{w}.financialHealth` e
     * `workspaces/{w}/health_history/{monthKey}`.
     *
     * O documento de histórico do mês corrente é SOBRESCRITO a cada execução.
     * Quando o mês vira, a última escrita daquele mês já está congelada ali —
     * o cron mensal só garante que todo workspace recebeu essa última passada.
     */
    async refreshHealth(
        workspaceId: string,
        now: Date = new Date(),
        options: { historyOnly?: boolean } = {}
    ): Promise<FinancialHealthSnapshot> {
        const snapshot = await this.computeHealth(workspaceId, now);

        await this.repository.saveHistory(workspaceId, snapshot);
        if (!options.historyOnly) {
            await this.repository.saveCurrent(workspaceId, snapshot);
        }

        return snapshot;
    }

    /**
     * Recálculo do cron de 15 minutos, com o debounce de 10 minutos.
     *
     * O marcador sujo é limpo APENAS quando o retrato é de fato recalculado.
     * Um workspace adiado pelo debounce continua sujo e entra no ciclo
     * seguinte — é isso que garante que nenhuma mudança se perde.
     */
    async refreshIfDue(workspaceId: string, now: Date = new Date()): Promise<RefreshResult> {
        const current = await this.repository.getCurrent(workspaceId);

        if (current && now.getTime() - current.computedAt.getTime() < HEALTH_MIN_RECOMPUTE_INTERVAL_MS) {
            return { snapshot: null, computed: false, debounced: true };
        }

        const snapshot = await this.refreshHealth(workspaceId, now);
        await this.repository.clearDirty(workspaceId);

        return { snapshot, computed: true, debounced: false };
    }

    /**
     * Marca o workspace para recálculo. Chamado dos gatilhos quentes (sumário
     * do mês corrente, saldo de conta): uma escrita barata, sem leitura.
     *
     * NUNCA lança para quem chama: sujar a Bússola não pode derrubar o
     * pagamento que disparou o gatilho.
     */
    async markHealthDirty(workspaceId: string): Promise<void> {
        try {
            await this.repository.markDirty(workspaceId);
        }
        catch (error) {
            logger.warn(`[FinancialHealth] falha ao marcar ${workspaceId} como sujo:`, error);
        }
    }

    /**
     * Fecha o histórico do mês ANTERIOR e reabre o corrente (cron do dia 1).
     *
     * Duas passadas de propósito: a primeira com `now` no último instante do
     * mês que acabou, gravando só o histórico daquele mês (o retrato corrente
     * não pode ficar apontando para o passado); a segunda com o `now` real,
     * que reabre `financialHealth` e cria o documento do mês novo.
     */
    async closeMonth(workspaceId: string, now: Date = new Date()): Promise<void> {
        const previousMonthKey = shiftMonthKey(toMonthKey(now), -1);

        await this.refreshHealth(workspaceId, endOfMonthInstant(previousMonthKey), { historyOnly: true });
        await this.refreshHealth(workspaceId, now);
        await this.repository.clearDirty(workspaceId);
    }
}
