import * as logger from "firebase-functions/logger";
import { IGoalService } from "./goal.service";
import { AccountType, InstallmentModel, InstallmentStatus } from "../../../finance/domain/models/finance.models";
import { GoalOutcomeStamp, IGoalRepository, InstallmentLike } from "../repositories/goal.repository";
import {
    GoalModel,
    GoalOutcome,
    GoalType,
    evaluateGoalOutcome,
    resolveGoalCategoryId,
    resolveGoalOutcome,
    resolveGoalType,
    withCurrentAmount,
} from "../models/goal.model";
import { fromCents, resolveCents, sumCents, toCents } from "../../../../core/utils/money";

/**
 * Teto de meses lidos no cálculo de uma meta `reduceExpense`. Uma meta de 10
 * anos custaria 120 leituras por parcela da categoria; acima disso o período é
 * truncado no fim (os meses mais recentes são os que importam) e o corte é
 * logado.
 */
export const MAX_GOAL_SUMMARY_MONTHS = 120;


export class GoalServiceImpl implements IGoalService {
    /**
     * `now` é injetável porque o DESFECHO de uma meta depende da data de hoje
     * (prazo vencido ou não). Sem isso, um teste de meta com prazo em março
     * mudaria de resultado quando março chegasse.
     */
    constructor(
        private goalRepository: IGoalRepository,
        private now: () => Date = () => new Date()
    ) {}

    /**
     * Recalcula as metas afetadas por uma mudança de parcela.
     *
     * Dois caminhos, por custo:
     *
     * - `saveMoney` em conta que NÃO é de investimento, e `reduceCreditCard`
     *   (metas de CONTA) andam pelo DELTA do evento: a contribuição da parcela
     *   antiga sai, a da nova entra. É o comportamento que já existia e não lê
     *   nada além das próprias metas.
     * - `reduceExpense` (meta de CATEGORIA), `payDebt` (meta de CONTA DE
     *   DÍVIDA) e `saveMoney` de COFRINHO (conta de investimento) são
     *   RECALCULADAS do zero pela fonte de verdade — os `period_summaries`
     *   mensais e os saldos diários da conta. Elas não têm delta confiável: o
     *   realizado da categoria e o saldo da conta são mantidos por outros
     *   gatilhos, e somar delta em cima disso divergiria a cada
     *   reprocessamento.
     */
    async processInstallmentChange(workspaceId: string, before: InstallmentModel | null, after: InstallmentModel | null): Promise<void> {
        const accountIds = new Set<string>();
        if (before?.accounts) Object.keys(before.accounts).forEach(id => accountIds.add(id));
        if (after?.accounts) Object.keys(after.accounts).forEach(id => accountIds.add(id));

        const categoryIds = new Set<string>();
        for (const categoryId of [before?.category?.id, after?.category?.id]) {
            if (categoryId) categoryIds.add(categoryId);
        }

        for (const accountId of accountIds) {
            // Metas não deletadas da conta (inclusive as já concluídas: o
            // estorno de um pagamento precisa poder puxar o progresso de volta).
            const goals = await this.goalRepository.getActiveGoalsByAccount(workspaceId, accountId);
            if (goals.length === 0) continue;

            // Uma leitura do tipo da conta por conta do evento, reaproveitada
            // por todas as metas dela — só é buscada se houver alguma
            // `saveMoney`, que é a única que depende do tipo.
            let isSavings: boolean | null = null;
            const savingsAccount = async () => {
                if (isSavings === null) {
                    isSavings = await this.isSavingsBalanceAccount(workspaceId, accountId);
                }
                return isSavings;
            };

            for (const goal of goals) {
                const goalType = resolveGoalType(goal);
                if (!goalType) continue;

                if (goalType === GoalType.payDebt) {
                    // Quanto a dívida já foi amortizada: recálculo pelos saldos.
                    await this.recomputeGoal(workspaceId, goal);
                    continue;
                }

                if (goalType !== GoalType.saveMoney && goalType !== GoalType.reduceCreditCard) {
                    continue;
                }

                // Cofrinho: o progresso É o saldo da conta, não a soma dos
                // aportes deste evento. Como em `payDebt`, o delta não serve —
                // o saldo é mantido por outro gatilho e somar por cima
                // divergiria. Recálculo total, lendo o saldo mais recente.
                if (goalType === GoalType.saveMoney && await savingsAccount()) {
                    const balance = await this.savingsBalance(workspaceId, goal.accountId ?? accountId);
                    // Cofrinho sem saldo gravado: mantém o valor atual, como
                    // `recomputeGoal` faria — a meta ainda passa pelo
                    // `writeProgress` porque o prazo pode ter vencido.
                    await this.writeProgress(workspaceId, goal, balance ?? Number(goal.currentAmount ?? 0));
                    continue;
                }

                // F1.10 — o delta do evento é somado em CENTAVOS INTEIROS. Em
                // `double`, "sai a contribuição antiga, entra a nova" quase
                // nunca dava zero exato quando o valor não mudava, e o resíduo
                // ia parar no progresso da meta a cada reprocessamento.
                let changeCents = 0;
                if (before && isPaidStatus(before.status) && before.paidDate) {
                    if (before.paidDate >= goal.startDate && before.accounts && before.accounts[accountId]) {
                        changeCents -= this.calculateContributionCents(goalType, before, accountId);
                    }
                }
                if (after && isPaidStatus(after.status) && after.paidDate) {
                    if (after.paidDate >= goal.startDate && after.accounts && after.accounts[accountId]) {
                        changeCents += this.calculateContributionCents(goalType, after, accountId);
                    }
                }

                if (changeCents !== 0) {
                    const currentCents = resolveCents(goal.currentAmount || 0, goal.currentAmountCents);
                    await this.writeProgress(workspaceId, goal, fromCents(currentCents + changeCents));
                }
            }
        }

        for (const categoryId of categoryIds) {
            const goals = await this.goalRepository.getActiveGoalsByCategory(workspaceId, categoryId);
            for (const goal of goals) {
                if (resolveGoalType(goal) !== GoalType.reduceExpense) continue;
                await this.recomputeGoal(workspaceId, goal);
            }
        }
    }

    async recomputeGoal(workspaceId: string, goal: GoalModel): Promise<number | null> {
        const computed = await this.computeCurrentAmount(workspaceId, goal);
        // Mesmo sem valor novo, a meta passa pelo `writeProgress`: o desfecho
        // pode ter mudado só porque o prazo venceu, sem ninguém mexer no valor.
        const next = computed ?? Number(goal.currentAmount ?? 0);
        const written = await this.writeProgress(workspaceId, goal, next);
        return computed === null ? null : written;
    }

    /**
     * Fecha as metas do workspace cujo prazo já venceu e que ainda não têm
     * desfecho. É o caminho do cron `closeExpiredGoals`: sem ele, uma meta de
     * redução que atravessa o prazo dentro do teto ficaria para sempre "em
     * andamento", porque nenhum evento acontece no dia do vencimento.
     *
     * Devolve as metas fechadas (já com `outcome` aplicado) para quem chamou
     * disparar os badges.
     */
    async closeExpiredGoals(workspaceId: string, now: Date = this.now()): Promise<GoalModel[]> {
        const goals = await this.goalRepository.getGoals(workspaceId);
        const closed: GoalModel[] = [];

        for (const goal of goals) {
            if (goal.isDeleted === true || resolveGoalOutcome(goal) !== null) {
                continue;
            }
            if (!goal.deadline || goal.deadline.getTime() >= startOfDay(now).getTime()) {
                continue;
            }

            const outcome = evaluateGoalOutcome(goal, now);
            if (!outcome) {
                continue;
            }

            const stamp: GoalOutcomeStamp = { outcome, at: now };
            await this.goalRepository.updateGoalOutcome(workspaceId, goal.id, stamp);
            closed.push(applyOutcome(goal, stamp));
        }

        return closed;
    }

    async computeCurrentAmount(workspaceId: string, goal: GoalModel): Promise<number | null> {
        const goalType = resolveGoalType(goal);
        if (!goalType) {
            return null;
        }

        switch (goalType) {
        case GoalType.reduceExpense:
            return this.computeReduceExpense(workspaceId, goal);
        case GoalType.payDebt:
            return this.computePayDebt(workspaceId, goal);
        case GoalType.saveMoney:
            return this.computeSaveMoney(workspaceId, goal);
        case GoalType.reduceCreditCard:
            return this.computeFromAccountInstallments(workspaceId, goal, goalType);
        }
    }

    /**
     * `saveMoney`: duas fontes de verdade, escolhidas pelo TIPO DA CONTA.
     *
     * - conta de INVESTIMENTO (cofrinho, reserva): o progresso é o SALDO ATUAL
     *   da conta, com piso zero. O dinheiro que está lá É o que foi guardado —
     *   inclusive o que já estava antes da meta existir. Somar só os aportes
     *   desde o `startDate` fazia uma meta criada hoje sobre um cofrinho cheio
     *   nascer em zero: caso real "Disney 2030", conta "Cofrinho Disney" com
     *   R$ 263,41 e `startDate` = hoje, mostrando 0 de 263,41 guardados.
     * - qualquer outro tipo (corrente, cartão, dívida): o progresso é o que
     *   ENTROU desde o início — créditos menos débitos das parcelas pagas. Uma
     *   conta corrente tem saldo por mil motivos alheios à meta; ali só o
     *   aporte conta.
     */
    private async computeSaveMoney(workspaceId: string, goal: GoalModel): Promise<number | null> {
        const accountId = goal.accountId;
        if (!accountId) {
            return null;
        }

        if (!(await this.isSavingsBalanceAccount(workspaceId, accountId))) {
            return this.computeFromAccountInstallments(workspaceId, goal, GoalType.saveMoney);
        }

        return this.savingsBalance(workspaceId, accountId);
    }

    /**
     * Saldo do cofrinho com piso zero. `null` quando a conta não tem nenhum
     * saldo gravado — nada a afirmar sobre o progresso, mesma postura de
     * `payDebt`.
     */
    private async savingsBalance(workspaceId: string, accountId: string): Promise<number | null> {
        const balance = await this.goalRepository.getCurrentBalance(workspaceId, accountId);
        if (balance === null) {
            return null;
        }
        return balance > 0 ? balance : 0;
    }

    /** A conta da meta é um cofrinho (conta de investimento)? */
    private async isSavingsBalanceAccount(workspaceId: string, accountId?: string): Promise<boolean> {
        if (!accountId) return false;
        const type = await this.goalRepository.getAccountType(workspaceId, accountId);
        return type === AccountType.investment;
    }

    /**
     * `reduceExpense`: o realizado da categoria da meta dentro do período da
     * meta.
     *
     * DECISÃO — a soma vem dos `period_summaries` MENSAIS, não de uma varredura
     * de parcelas. O documento mensal já é a consolidação que o servidor mantém
     * (`actualAmount` = soma de `paidAmount ?? amount` das parcelas pagas por
     * `paidDate`), então a regra é a mesma; a diferença é o custo. A varredura
     * cresce com o número de parcelas da categoria e seria refeita a cada
     * pagamento; a leitura mensal custa um documento por mês do período (com
     * máscara de campo, só a entrada da categoria) e não cresce com o uso.
     *
     * Consequência aceita: os meses entram INTEIROS. Uma meta que começa dia 10
     * conta também o gasto dos dias 1 a 9 daquele mês. Contar meio mês exigiria
     * exatamente a varredura que estamos evitando.
     */
    private async computeReduceExpense(workspaceId: string, goal: GoalModel): Promise<number | null> {
        const categoryId = resolveGoalCategoryId(goal);
        if (!categoryId) {
            logger.warn(`[GoalService] Meta reduceExpense ${goal.id} sem categoria: progresso mantido.`);
            return null;
        }

        const monthKeys = monthKeysBetween(goal.startDate, goal.deadline ?? new Date(), goal.id);
        return this.goalRepository.getCategoryActualByMonths(workspaceId, categoryId, monthKeys);
    }

    /**
     * `payDebt`: quanto a dívida encolheu desde o início da meta.
     *
     * O saldo de uma conta de dívida é NEGATIVO (o app grava a dívida como
     * saldo devedor — ver `goal_form_provider.dart`), e amortizar aproxima esse
     * saldo de zero. Então o amortizado desde `startDate` é
     * `saldoAtual - saldoNoStartDate` — a mesma conta que
     * `dívidaNoStartDate - dívidaAtual` em módulo de dívida.
     *
     * Dívida que CRESCEU não vira progresso negativo: o piso é zero.
     */
    private async computePayDebt(workspaceId: string, goal: GoalModel): Promise<number | null> {
        const accountId = goal.accountId;
        if (!accountId) {
            logger.warn(`[GoalService] Meta payDebt ${goal.id} sem conta: progresso mantido.`);
            return null;
        }

        const { startBalance, currentBalance } = await this.goalRepository.getBalancesForGoal(
            workspaceId,
            accountId,
            goal.startDate
        );

        if (currentBalance === null) {
            // Conta sem nenhum saldo gravado: nada a afirmar sobre o progresso.
            return null;
        }

        // Sem saldo até o startDate, a dívida começou em zero naquele ponto.
        // F1.10 — a subtração é em centavos: dois saldos "iguais" em `double`
        // podiam diferir num resto de 1e-13 e virar progresso.
        const reductionCents = toCents(currentBalance) - toCents(startBalance ?? 0);
        return reductionCents > 0 ? fromCents(reductionCents) : 0;
    }

    /**
     * Recálculo total a partir das parcelas pagas da conta desde `startDate` —
     * a MESMA regra que o caminho incremental aplica parcela a parcela. Vale
     * para `reduceCreditCard` e para `saveMoney` em conta que não é cofrinho.
     * Só é usado fora do gatilho (criação da meta e script de recálculo).
     */
    private async computeFromAccountInstallments(
        workspaceId: string,
        goal: GoalModel,
        goalType: GoalType
    ): Promise<number | null> {
        const accountId = goal.accountId;
        if (!accountId) {
            return null;
        }

        const installments = await this.goalRepository.getPaidInstallmentsByAccountSince(
            workspaceId,
            accountId,
            goal.startDate
        );

        return fromCents(sumCents(
            installments.map((installment) => fromCents(contributionCentsOf(goalType, installment, accountId)))
        ));
    }

    /**
     * Grava o novo progresso quando ele mudou de fato — e, junto, o DESFECHO,
     * quando a meta acabou de desfechar.
     *
     * O desfecho é TERMINAL: uma meta que já tem `outcome` não é reavaliada. O
     * motivo é que o desfecho tem efeito colateral fora do documento (badges
     * concedidos, XP creditado) e badge não se devolve; um estorno que derruba
     * o valor de volta não pode desconceder o que já foi dado.
     *
     * A escrita acontece também quando o valor NÃO mudou, se o desfecho mudou:
     * é assim que uma meta de redução fecha no vencimento sem que nada tenha
     * sido pago naquele dia.
     */
    private async writeProgress(workspaceId: string, goal: GoalModel, nextAmount: number): Promise<number | null> {
        if (!Number.isFinite(nextAmount)) {
            logger.warn(`[GoalService] Valor não finito calculado para a meta ${goal.id}: ignorado.`);
            return null;
        }

        // F1.10 — "mudou?" é uma comparação de INTEIROS, sem folga: a meia
        // folga de centavo existia só para o `double` não acusar mudança onde
        // não houve nenhuma.
        const current = Number(goal.currentAmount ?? 0);
        const nextCents = toCents(nextAmount);
        const amountChanged = nextCents !== resolveCents(current, goal.currentAmountCents);

        const now = this.now();
        const outcome = resolveGoalOutcome(goal) === null
            // `withCurrentAmount` e não `{ ...goal, currentAmount }`: o spread
            // cru carregaria o `currentAmountCents` ANTIGO e o veredito sairia
            // sobre o valor velho (F1.10).
            ? evaluateGoalOutcome(withCurrentAmount(goal, nextAmount), now)
            : null;
        const stamp: GoalOutcomeStamp | null = outcome ? { outcome, at: now } : null;

        if (!amountChanged && !stamp) {
            return null;
        }

        await this.goalRepository.updateGoalProgress(workspaceId, goal.id, nextCents, stamp);

        goal.currentAmount = fromCents(nextCents);
        goal.currentAmountCents = nextCents;
        if (stamp) {
            applyOutcome(goal, stamp);
        }
        return goal.currentAmount;
    }

    private calculateContributionCents(goalType: GoalType, inst: InstallmentModel, accountId: string): number {
        return contributionCentsOf(goalType, inst as InstallmentLike, accountId);
    }
}

/** Espelha no objeto em memória o desfecho que acabou de ser gravado. */
function applyOutcome(goal: GoalModel, stamp: GoalOutcomeStamp): GoalModel {
    goal.outcome = stamp.outcome;
    if (stamp.outcome === GoalOutcome.success) {
        goal.completedAt = stamp.at;
    }
    else {
        goal.failedAt = stamp.at;
    }
    return goal;
}

function startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function isPaidStatus(status: InstallmentStatus): boolean {
    return status === InstallmentStatus.paid || status === InstallmentStatus.settled;
}

/**
 * Contribuição de UMA parcela paga para uma meta de conta.
 *
 * `saveMoney`: crédito soma, débito subtrai (é o saldo que a meta persegue).
 * `reduceCreditCard`: só o gasto (débito) conta — é um teto, não um saldo.
 */
function contributionCentsOf(goalType: GoalType, inst: InstallmentLike, accountId: string): number {
    const role = inst.accounts?.[accountId];
    if (!role) return 0;

    // Mesma escolha de valor de antes (`paidAmount || amount`, com o zero
    // caindo para o planejado), agora em CENTAVOS INTEIROS.
    const paidCents = resolveCents(inst.paidAmount, inst.paidAmountCents);
    const amountCents = paidCents !== 0 ? paidCents : resolveCents(inst.amount, inst.amountCents);

    if (goalType === GoalType.saveMoney) {
        return role === "credit" ? amountCents : -amountCents;
    }
    if (goalType === GoalType.reduceCreditCard) {
        return role === "debt" ? amountCents : 0;
    }
    return 0;
}

/**
 * Chaves `YYYY-MM` dos `period_summaries` mensais cobertos pelo período da
 * meta, do mês de `start` ao mês de `end` (inclusive).
 */
export function monthKeysBetween(start: Date, end: Date, goalId?: string): string[] {
    if (!(start instanceof Date) || Number.isNaN(start.getTime())) {
        return [];
    }
    const last = end instanceof Date && !Number.isNaN(end.getTime()) ? end : start;
    if (last.getTime() < start.getTime()) {
        return [];
    }

    const keys: string[] = [];
    const cursor = new Date(start.getFullYear(), start.getMonth(), 1);
    const limit = new Date(last.getFullYear(), last.getMonth(), 1);

    while (cursor.getTime() <= limit.getTime()) {
        keys.push(`${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, "0")}`);
        cursor.setMonth(cursor.getMonth() + 1);
    }

    if (keys.length > MAX_GOAL_SUMMARY_MONTHS) {
        logger.warn(`[GoalService] Meta ${goalId ?? "?"} cobre ${keys.length} meses; lendo só os ${MAX_GOAL_SUMMARY_MONTHS} últimos.`);
        return keys.slice(keys.length - MAX_GOAL_SUMMARY_MONTHS);
    }

    return keys;
}
