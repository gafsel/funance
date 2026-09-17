import * as logger from "firebase-functions/logger";

import { shiftDateKey, toDateKey, toMonthKey } from "../../../../core/utils/date_key";
import { monthKeyParts, shiftMonthKey } from "../../../../core/utils/month_key";
import { addCalendarDays, localMidnightInstant } from "../../../../core/utils/timezone.utils";
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
 * Janela móvel de despesa do Fôlego, em dias, e o divisor que a converte em
 * média MENSAL.
 *
 * Eram três meses de CALENDÁRIO. O problema não era o tamanho da janela, era a
 * borda: em 30/09 ela cobria junho-agosto e em 01/10 pulava para julho-setembro
 * — trinta dias de despesa trocados de uma vez, e a patente do usuário mudava
 * sozinha na virada do mês, sem que ele tivesse feito nada. Uma janela que
 * termina HOJE anda um dia por dia e nunca dá esse salto.
 *
 * 90 dias ÷ 3 é a mesma média mensal de antes; o divisor continua FIXO, e não
 * "meses com movimento": quem tem pouco histórico não tem despesa média baixa,
 * tem pouco histórico — e a média cheia é a leitura conservadora.
 */
export const FOLEGO_WINDOW_DAYS = 90;
export const FOLEGO_WINDOW_MONTHS = 3;

/**
 * Janela móvel da trajetória de dívida do Alívio, em dias.
 *
 * Mesmo defeito, consequência pior: comparar com "o fim do mês anterior"
 * fazia a janela ENCOLHER a cada dia e zerar na virada. Quem passou setembro
 * amortizando via 100 em 30/09 e 50 em 01/10 — a comparação recomeçava contra
 * um saldo de ontem —, ou seja, o placar rebaixava a patente do usuário como
 * punição por o mês ter acabado.
 */
export const ALIVIO_WINDOW_DAYS = 30;

/**
 * Piso de receita para a Poupança usar o mês CORRENTE: ele precisa ter pelo
 * menos esta fração da receita do último mês completo.
 *
 * Sem o piso, a primeira receita do mês — um reembolso de R$ 100 no dia 2 —
 * virava o denominador inteiro da taxa e derrubava o componente de 67 para 0.
 * O gatilho de "já dá para julgar este mês" não é "existe alguma receita", é
 * "a receita deste mês já se parece com a de um mês normal".
 */
export const POUPANCA_MIN_INCOME_RATIO = 0.5;

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

/**
 * Dois retratos são "o mesmo" quando o que o usuário VÊ não mudou: o score, a
 * patente e as notas dos quatro componentes (mais as contagens inteiras da
 * Disciplina).
 *
 * Os valores BRUTOS ficam de fora da comparação de propósito. `months`, `rate`
 * e `delta` são razões entre saldos e despesas: eles se mexem na terceira casa
 * decimal a cada centavo lançado, e compará-los tornaria a guarda inútil —
 * toda execução gravaria. O retrato CORRENTE (`financialHealth`) é reescrito
 * sempre e carrega os valores exatos; o histórico é um ponto de tendência, e
 * um ponto de tendência não precisa da terceira casa.
 */
export function sameSnapshot(a: FinancialHealthSnapshot | null, b: FinancialHealthSnapshot): boolean {
    if (!a) return false;
    if (a.score !== b.score || a.tier !== b.tier) return false;

    const ac = a.components;
    const bc = b.components;
    if (!ac || !bc) return false;

    return ac.folego?.score === bc.folego.score &&
        ac.poupanca?.score === bc.poupanca.score &&
        ac.disciplina?.score === bc.disciplina.score &&
        ac.disciplina?.within === bc.disciplina.within &&
        ac.disciplina?.total === bc.disciplina.total &&
        ac.alivio?.score === bc.alivio.score;
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
 * último instante daquele mês) e ao teste provar que a virada do mês não mexe
 * no score.
 *
 * Nenhuma chamada de IA. As fontes são todas do próprio servidor:
 *  - `installments` pagas (despesa realizada da janela móvel);
 *  - `period_summaries` mensais (receita/despesa do mês);
 *  - `accounts` + o último documento de `balance` de cada uma;
 *  - `category_planning` vigentes no mês avaliado.
 *
 * ## A virada do mês não pode mexer no placar
 *
 * Três dos quatro componentes usam **janelas móveis** — 90 dias de despesa, 30
 * dias de dívida e um piso de receita para trocar de mês — exatamente porque a
 * primeira versão rebaixava a patente do usuário no dia 1 sem que ele tivesse
 * feito nada. Um placar que se mexe sozinho não é um placar.
 *
 * A **Disciplina** é a única que troca de janela na virada, e isso é correto:
 * ela julga o mês fechado, e o mês fechado de fato mudou.
 */
export class FinancialHealthService {
    constructor(private repository: IHealthRepository) {}

    /** Retrato do workspace no instante `now`. */
    async computeHealth(workspaceId: string, now: Date = new Date()): Promise<FinancialHealthSnapshot> {
        const monthKey = toMonthKey(now);
        const previousMonthKey = shiftMonthKey(monthKey, -1);
        const todayKey = toDateKey(now);

        const balances = await this.repository.getAccountBalanceTotals(workspaceId, todayKey);

        // SEM DADO NENHUM. Um workspace sem conta alguma não tem saldo, não tem
        // dívida e não tem de onde tirar despesa: devolver o retrato zerado é
        // mais honesto (e muito mais barato) do que somar quatro zeros com
        // pesos. O app desenha a bússola vazia em vez de um estado de erro.
        if (!balances.hasAnyAccount) {
            return emptySnapshot(monthKey, now);
        }

        const [avgExpense, savings, limits, debtWindowStart] = await Promise.all([
            this.averageMonthlyExpense(workspaceId, now),
            this.savingsRateInput(workspaceId, monthKey, previousMonthKey),
            // A Disciplina julga o mês ANTERIOR: um limite só pode ser julgado
            // depois de o mês fechar. Reprovar quem ainda tem 20 dias para se
            // ajustar seria mentira.
            this.repository.getCategoryLimitOutcomes(workspaceId, previousMonthKey),
            this.repository.getAccountBalanceTotals(
                workspaceId,
                shiftDateKey(todayKey, -ALIVIO_WINDOW_DAYS)
            ),
        ]);

        const within = limits.filter((outcome) => outcome.actual <= outcome.limit).length;

        const components = {
            folego: scoreFolego(balances.liquid, avgExpense),
            poupanca: scorePoupanca(savings.income, savings.expense),
            disciplina: scoreDisciplina(within, limits.length),
            // Saldo de dívida é negativo: amortizar o aproxima de zero, então
            // `hoje − 30 dias atrás` POSITIVO significa dívida menor.
            alivio: scoreAlivio(balances.debt - debtWindowStart.debt, balances.hasDebtAccounts),
        };

        return buildSnapshot(components, monthKey, now);
    }

    /**
     * Média mensal de despesa realizada na janela móvel de 90 dias que termina
     * em `now`, dividida pelo divisor fixo de 3.
     *
     * Por que a janela inclui o mês corrente: numa janela de 90 dias, um mês
     * recém-começado contribui com dois ou três dias e os outros 88 vêm do
     * histórico — não existe o "dia 1 sem despesa" que fazia a reserva parecer
     * infinita quando a janela era de meses de calendário. E, ao andar um dia
     * por dia, ela nunca dá o salto de 30 dias da virada.
     */
    private async averageMonthlyExpense(workspaceId: string, now: Date): Promise<number> {
        const since = addCalendarDays(now, -FOLEGO_WINDOW_DAYS);
        const total = await this.repository.getRealizedExpensesBetween(workspaceId, since, now);
        return Math.max(0, total) / FOLEGO_WINDOW_MONTHS;
    }

    /**
     * Receita/despesa do mês usado na taxa de poupança.
     *
     * O mês CORRENTE só é usado quando já tem receita suficiente para ser
     * comparável a um mês normal (`POUPANCA_MIN_INCOME_RATIO` da receita do
     * último mês completo). Caso contrário vale o último mês completo.
     *
     * É essa regra que impede o tombo de 67 para 0 quando cai um reembolso de
     * R$ 100 no dia 2 — e que, ao mesmo tempo, faz o componente trocar para o
     * mês novo assim que o salário entra.
     */
    private async savingsRateInput(
        workspaceId: string,
        monthKey: string,
        previousMonthKey: string
    ): Promise<{ income: number, expense: number }> {
        const [current, previous] = await Promise.all([
            this.repository.getMonthlyTotals(workspaceId, monthKey),
            this.repository.getMonthlyTotals(workspaceId, previousMonthKey),
        ]);

        // Sem receita no mês corrente não há taxa a calcular.
        if (current.income <= 0) return previous;
        // Sem baseline (primeiro mês do workspace), o corrente é tudo que há.
        if (previous.income <= 0) return current;

        return current.income >= POUPANCA_MIN_INCOME_RATIO * previous.income ? current : previous;
    }

    /**
     * Recalcula e persiste: `workspaces/{w}.financialHealth` (sempre) e
     * `workspaces/{w}/health_history/{monthKey}` (só quando o retrato MUDOU).
     *
     * O histórico é um ponto de tendência: reescrevê-lo a cada 15 minutos com
     * o mesmo score é uma escrita por workspace por ciclo que não conta nada a
     * ninguém. O retrato corrente, esse, é reescrito sempre — é dele que sai o
     * `computedAt` que ancora o debounce, e ele carrega os valores exatos.
     */
    async refreshHealth(
        workspaceId: string,
        now: Date = new Date(),
        options: { historyOnly?: boolean, forceHistory?: boolean } = {}
    ): Promise<FinancialHealthSnapshot> {
        const snapshot = await this.computeHealth(workspaceId, now);

        // `forceHistory` é o fechamento do mês: ali a escrita importa mesmo
        // quando o score não mudou, porque o que ela grava é o CARIMBO de
        // fechamento (`computedAt` = último instante do mês) — é ele que diz
        // "este mês já está fechado" na execução seguinte do cron.
        const stored = options.forceHistory
            ? null
            : await this.repository.getHistory(workspaceId, snapshot.monthKey);

        if (options.forceHistory || !sameSnapshot(stored, snapshot)) {
            await this.repository.saveHistory(workspaceId, snapshot);
        }

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
     * Marca o workspace para recálculo. Chamado dos gatilhos que mexem nas
     * fontes do índice (parcela, conta apagada, limite de categoria): uma
     * escrita barata, sem leitura.
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
     *
     * IDEMPOTENTE: um mês já fechado não é reescrito. O carimbo de fechamento é
     * o próprio `computedAt` — durante o mês ele é sempre anterior ao fim do
     * mês, e o fechamento grava exatamente o último instante. Sem esta guarda,
     * uma segunda execução do cron (reentrega, execução manual) recalcularia o
     * mês fechado com os dados de HOJE: a Disciplina passaria a julgar outro
     * mês e o retrato congelado mudaria depois de congelado.
     */
    async closeMonth(workspaceId: string, now: Date = new Date()): Promise<void> {
        const previousMonthKey = shiftMonthKey(toMonthKey(now), -1);
        const closingInstant = endOfMonthInstant(previousMonthKey);

        const alreadyClosed = await this.repository.getHistory(workspaceId, previousMonthKey);
        if (!alreadyClosed || alreadyClosed.computedAt.getTime() < closingInstant.getTime()) {
            await this.refreshHealth(workspaceId, closingInstant, { historyOnly: true, forceHistory: true });
        }

        await this.refreshHealth(workspaceId, now);
        await this.repository.clearDirty(workspaceId);
    }
}
