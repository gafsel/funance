import {
    InstallmentModel,
    InstallmentStatus,
    OrderType,
    CategoryPlanningModel,
    CategoryPlanningMarks,
    PeriodSummaryUpdateModel,
    AccountType,
    AccountModel,
} from "../models/finance.models";
import { CategoryPlanningRef, IFinanceRepository } from "../repositories/finance.repository";
import { DEFAULT_FINANCE_CONFIG } from "../../../../core/config/finance.config";
import {
    daysInMonthKey,
    isMonthKey,
    maxMonthKey,
    minMonthKey,
    monthKeyParts,
    monthKeyRange,
    shiftMonthKey,
    toMonthKey,
} from "../../../../core/utils/month_key";
import { addCalendarDays, getZonedParts, localMidnightInstant } from "../../../../core/utils/timezone.utils";
import {
    CategoryModel,
    categoryWithoutIdWarning,
    hasCategoryId,
    isCategoryRefBroken,
    VIRTUAL_DEBT_EXPENSE_CATEGORY,
    VIRTUAL_DEBT_INCOME_CATEGORY,
    VIRTUAL_INVESTMENT_EXPENSE_CATEGORY,
    VIRTUAL_INVESTMENT_INCOME_CATEGORY
} from "../../../workspace/domain/models/category.model";
import { WeekRef, getWeekNumber, getWeekRef, getWeekStart, getWeekYear } from "../../../../core/utils/week.utils";

/**
 * Sentinela de `summarizedUntil`: o planejamento cabe inteiro no horizonte, não
 * há mais nenhum mês novo a aplicar — nunca mais entra na consulta do cron.
 */
export const PLANNING_FULLY_SUMMARIZED = "9999-12";

/** Página do cron. */
const PLANNING_PAGE_SIZE = 200;

/**
 * Tetos da varredura de legados POR EXECUÇÃO. O que não couber continua na
 * execução seguinte, a partir do checkpoint — e não do começo da coleção.
 *
 *  - adoções: são as ESCRITAS, e é o que o teto precisa limitar de fato;
 *  - leituras: teto separado, para o cron não varrer a base inteira quando
 *    quase todo mundo já está marcado.
 */
const PLANNING_LEGACY_ADOPT_LIMIT = 2000;
const PLANNING_LEGACY_READ_LIMIT = 10000;

/**
 * Campo do checkpoint em `config/cron_checkpoints`: caminho do último
 * planejamento inspecionado pela varredura de legados.
 */
export const PLANNING_LEGACY_CURSOR_FIELD = "planningLegacyScanPath";

/** Intervalo fechado de meses `YYYY-MM`. */
export interface PlanningWindow {
    from: string;
    until: string;
}

/**
 * Horizonte rolante: o último mês que o produto promete projetar a partir de
 * `now` (12 meses de previsibilidade = mês corrente + 11).
 */
export function planningHorizon(now: Date): string {
    const months = DEFAULT_FINANCE_CONFIG.categoryPlanning.predictabilityMonths;
    return shiftMonthKey(toMonthKey(now), Math.max(1, months) - 1);
}

/** Interseção do intervalo com o período do planejamento (null = nada a fazer). */
export function intersectPlanningWindow(
    startMonth: string,
    endMonth: string,
    from: string,
    until: string
): PlanningWindow | null {
    if (!isMonthKey(startMonth) || !isMonthKey(endMonth) || !isMonthKey(from) || !isMonthKey(until)) return null;

    const start = maxMonthKey(startMonth, from);
    const end = minMonthKey(endMonth, until);
    return start <= end ? { from: start, until: end } : null;
}

/**
 * Semanas que PERTENCEM ao mês: aquelas cujo DOMINGO INICIAL cai nele.
 *
 * A regra antiga emitia a semana no dia 1 e em todos os domingos, então um mês
 * que começava no meio da semana contava a mesma semana duas vezes (uma pelo
 * dia 1, outra pelo domingo seguinte) — e a semana partilhada entre dois meses
 * era contada pelos dois. Com o domingo inicial como dono, cada semana tem um
 * mês só e a proporção semanal entra exatamente uma vez.
 */
export function weeksStartingInMonth(monthKey: string): WeekRef[] {
    const { year, month } = monthKeyParts(monthKey);

    let sunday = getWeekStart(localMidnightInstant(year, month, 1));
    if (toMonthKey(sunday) < monthKey) {
        sunday = addCalendarDays(sunday, 7);
    }

    const refs: WeekRef[] = [];
    while (toMonthKey(sunday) === monthKey) {
        refs.push(getWeekRef(sunday));
        sunday = addCalendarDays(sunday, 7);
    }
    return refs;
}

/**
 * O que um planejamento tem aplicado hoje nos sumários.
 *
 * Preferimos sempre os campos persistidos (`appliedAmount/From/Until`): eles
 * dizem o que de fato foi lançado, e é isso que precisa ser estornado. Um
 * planejamento LEGADO (anterior a F1.5) não tem esses campos; nesse caso
 * reconstruímos a janela que o gatilho antigo teria aplicado — 12 meses a
 * partir do mês corrente, recortados pelo período — que é exata quando o
 * planejamento foi escrito neste mês, e aproximada quando foi escrito antes
 * (o `rebuild --rebuild-planning` é o conserto definitivo).
 */
export function resolveAppliedWindow(
    planning: CategoryPlanningModel,
    currentMonth: string,
    horizon: string
): (PlanningWindow & { amount: number }) | null {
    const hasMarks = isMonthKey(planning.summarizedUntil) || planning.summarizedUntil === PLANNING_FULLY_SUMMARIZED;

    if (hasMarks) {
        if (!isMonthKey(planning.appliedFrom) || !isMonthKey(planning.appliedUntil)) return null;
        const amount = typeof planning.appliedAmount === "number" ? planning.appliedAmount : planning.amount;
        return { from: planning.appliedFrom, until: planning.appliedUntil, amount };
    }

    const window = intersectPlanningWindow(planning.startMonth, planning.endMonth, currentMonth, horizon);
    return window ? { ...window, amount: planning.amount } : null;
}

/** `summarizedUntil` depois de processar até `horizon`. */
export function nextSummarizedUntil(endMonth: string, horizon: string): string {
    return isMonthKey(endMonth) && endMonth <= horizon ? PLANNING_FULLY_SUMMARIZED : horizon;
}

export class SummaryService {
    constructor(private financeRepository: IFinanceRepository) {}

    /**
     * Gatilho de criação/alteração/exclusão de planejamento (F1.5).
     *
     * ESTORNA exatamente o que está marcado como aplicado e REAPLICA a janela
     * do horizonte rolante — `max(startMonth, mês corrente)` até
     * `min(endMonth, mês corrente + 11)`. Estorno e aplicação são somados antes
     * de virar escrita, então alterar só o fim do período não reescreve os
     * meses que não mudaram.
     */
    async processCategoryPlanningChange(
        workspaceId: string,
        before: CategoryPlanningModel | null,
        after: CategoryPlanningModel | null,
        now: Date = new Date()
    ): Promise<void> {
        if (!before && !after) return;

        const currentMonth = toMonthKey(now);
        const horizon = planningHorizon(now);
        const impacts: PeriodSummaryUpdateModel[] = [];

        if (before) {
            const applied = resolveAppliedWindow(before, currentMonth, horizon);
            if (applied) {
                // O planejamento do estorno usa o intervalo APLICADO como
                // período: se o usuário encurtou o período, o estorno ainda
                // precisa alcançar os meses que ficaram de fora.
                impacts.push(...this.calculatePlanningImpacts(
                    { ...before, amount: applied.amount, startMonth: applied.from, endMonth: applied.until },
                    -1,
                    { from: applied.from, until: applied.until }
                ));
            }
        }

        let marks: CategoryPlanningMarks | undefined;

        if (after) {
            const window = intersectPlanningWindow(after.startMonth, after.endMonth, currentMonth, horizon);
            if (window) {
                impacts.push(...this.calculatePlanningImpacts(after, 1, window));
            }

            marks = {
                summarizedUntil: nextSummarizedUntil(after.endMonth, horizon),
                appliedAmount: window ? after.amount : null,
                appliedFrom: window ? window.from : null,
                appliedUntil: window ? window.until : null,
            };
        }

        await this.financeRepository.applyPlanningImpacts(
            workspaceId,
            impacts,
            after && marks
                ? { ref: this.financeRepository.getCategoryPlanningRef(workspaceId, after.id), data: marks }
                : undefined
        );
    }

    /**
     * Impactos de um planejamento no `generalPlannedAmount`, mês a mês.
     *
     * Para cada mês do intervalo (já recortado pelo período do planejamento):
     *  - o documento do MÊS recebe `amount`;
     *  - o documento do ANO recebe `amount` (a soma dos meses aplicados daquele
     *    ano — a regra antiga jogava `amount * 12` de uma vez em janeiro, o que
     *    contava meses fora do período);
     *  - cada SEMANA que começa naquele mês recebe `amount / diasNoMês * 7`.
     *
     * PÚBLICO porque o job de reconstrução (rebuild.service.ts) usa exatamente
     * a mesma aritmética — é o que torna o `--rebuild-planning` determinístico.
     */
    calculatePlanningImpacts(
        planning: CategoryPlanningModel,
        multiplier: number,
        window: PlanningWindow
    ): PeriodSummaryUpdateModel[] {
        const impacts: PeriodSummaryUpdateModel[] = [];
        const effective = intersectPlanningWindow(planning.startMonth, planning.endMonth, window.from, window.until);
        if (!effective) return impacts;

        for (const monthKey of monthKeyRange(effective.from, effective.until)) {
            const { year, month } = monthKeyParts(monthKey);
            const monthlyDelta = planning.amount * multiplier;

            impacts.push({ year, month, category: planning.category, generalPlannedDelta: monthlyDelta });
            impacts.push({ year, category: planning.category, generalPlannedDelta: monthlyDelta });

            const weeklyDelta = (planning.amount / daysInMonthKey(monthKey)) * 7 * multiplier;
            for (const week of weeksStartingInMonth(monthKey)) {
                impacts.push({
                    year: week.year,
                    week: week.week,
                    category: planning.category,
                    generalPlannedDelta: weeklyDelta,
                });
            }
        }

        return impacts;
    }

    /**
     * Cron mensal (dia 1): empurra cada planejamento até o horizonte novo.
     *
     * Era inerte: procurava `lastSummaryMonth < mês`, campo que nenhum
     * planejamento criado pelo app tinha, e — se achasse algo — reaplicava os
     * 12 meses inteiros sem estornar, dobrando o planejado. Agora:
     *
     *  1. busca por `summarizedUntil < horizonte`, paginando por cursor (sem
     *     limite global), e aplica SÓ os meses ainda não sumarizados;
     *  2. varre os legados (sem o campo) e os ADOTA — grava os marcadores sem
     *     reaplicar impacto nenhum, porque o gatilho antigo já os aplicou.
     *     Reaplicar aqui dobraria o planejado de toda a base. A varredura tem
     *     teto por execução e guarda onde parou em `config/cron_checkpoints`,
     *     retomando dali na execução seguinte.
     */
    async generateCategoryPlanningSummaries(now: Date = new Date()): Promise<void> {
        const currentMonth = toMonthKey(now);
        const horizon = planningHorizon(now);

        let advanced = 0;
        let cursor = null as any;

        for (;;) {
            const page = await this.financeRepository.getCategoryPlanningsPendingSummary(horizon, PLANNING_PAGE_SIZE, cursor);
            for (const planning of page.items) {
                await this.advancePlanning(planning, horizon);
                advanced++;
            }
            if (!page.cursor) break;
            cursor = page.cursor;
        }

        // Varredura de legados: retoma do checkpoint da execução anterior. Sem
        // isso a varredura recomeçava do início do grupo de coleções todo mês e
        // nada além dos primeiros documentos era adotado.
        let afterPath = await this.financeRepository.getCronCheckpoint(PLANNING_LEGACY_CURSOR_FIELD);
        const resumedFrom = afterPath;
        let inspected = 0;
        let adopted = 0;

        for (;;) {
            const page = await this.financeRepository.scanCategoryPlannings(PLANNING_PAGE_SIZE, afterPath);

            for (const planning of page.items) {
                inspected++;
                const hasMarks = isMonthKey(planning.summarizedUntil) ||
                    planning.summarizedUntil === PLANNING_FULLY_SUMMARIZED;
                if (hasMarks) continue;

                await this.adoptLegacyPlanning(planning, currentMonth, horizon);
                adopted++;
            }

            afterPath = page.nextPath;

            // Fim da coleção: o checkpoint é zerado e a próxima execução
            // recomeça do início (já não haverá mais legados a adotar).
            if (!afterPath) break;

            if (adopted >= PLANNING_LEGACY_ADOPT_LIMIT || inspected >= PLANNING_LEGACY_READ_LIMIT) {
                console.warn(`[generateCategoryPlanningSummaries] Varredura de legados interrompida após ${inspected} documento(s) (${adopted} adotado(s)); a próxima execução retoma de ${afterPath}. Rode migrate_planning_summaries para encerrar de vez.`);
                break;
            }
        }

        await this.financeRepository.setCronCheckpoint(PLANNING_LEGACY_CURSOR_FIELD, afterPath);

        console.log(`[generateCategoryPlanningSummaries] horizonte=${horizon}: ${advanced} planejamento(s) avançado(s), ${adopted} legado(s) adotado(s) em ${inspected} inspecionado(s) (varredura de ${resumedFrom ?? "o início"} até ${afterPath ?? "o fim"}).`);
    }

    /** Aplica os meses que faltam entre `summarizedUntil + 1` e o horizonte. */
    private async advancePlanning(planning: CategoryPlanningRef, horizon: string): Promise<void> {
        const alreadyDone = isMonthKey(planning.summarizedUntil)
            ? shiftMonthKey(planning.summarizedUntil, 1)
            : planning.startMonth;

        const window = intersectPlanningWindow(planning.startMonth, planning.endMonth, alreadyDone, horizon);
        const impacts = window ? this.calculatePlanningImpacts(planning, 1, window) : [];

        const marks: CategoryPlanningMarks = {
            summarizedUntil: nextSummarizedUntil(planning.endMonth, horizon),
            appliedAmount: window ? planning.amount : (planning.appliedAmount ?? null),
            appliedFrom: window
                ? minMonthKey(isMonthKey(planning.appliedFrom) ? planning.appliedFrom : window.from, window.from)
                : (planning.appliedFrom ?? null),
            appliedUntil: window
                ? maxMonthKey(isMonthKey(planning.appliedUntil) ? planning.appliedUntil : window.until, window.until)
                : (planning.appliedUntil ?? null),
        };

        await this.financeRepository.applyPlanningImpacts(
            planning.workspaceId,
            impacts,
            { ref: planning.ref, data: marks }
        );
    }

    /** Legado: só registra o que o gatilho antigo já aplicou. Nenhum impacto novo. */
    private async adoptLegacyPlanning(
        planning: CategoryPlanningRef,
        currentMonth: string,
        horizon: string
    ): Promise<void> {
        const window = intersectPlanningWindow(planning.startMonth, planning.endMonth, currentMonth, horizon);

        const marks: CategoryPlanningMarks = {
            summarizedUntil: nextSummarizedUntil(planning.endMonth, horizon),
            appliedAmount: window ? planning.amount : null,
            appliedFrom: window ? window.from : null,
            appliedUntil: window ? window.until : null,
        };

        await this.financeRepository.applyPlanningImpacts(planning.workspaceId, [], { ref: planning.ref, data: marks });
    }

    async processInstallmentChange(
        workspaceId: string,
        before: InstallmentModel | null,
        after: InstallmentModel | null
    ): Promise<void> {
        if (!before && !after) return;

        // Um único evento chama estas rotinas até quatro vezes (antes/depois ×
        // projetado/realizado). O aviso de categoria sem id sai UMA VEZ POR
        // PARCELA, não uma por chamada.
        const warned = new Set<string>();

        // 1. Processar Valor Planejado (Projeção) no dueDate
        if (before && before.status !== InstallmentStatus.removed) {
            await this.updateSummaryProjetado(workspaceId, before, -1, warned);
        }
        if (after && after.status !== InstallmentStatus.removed) {
            await this.updateSummaryProjetado(workspaceId, after, 1, warned);
        }

        // 2. Processar Valor Realizado (Fluxo de Caixa) no paidDate
        const isPaidStatus = (s: InstallmentStatus) => s === InstallmentStatus.paid || s === InstallmentStatus.settled;

        if (before && isPaidStatus(before.status) && before.paidDate && (before.paidAmount ?? before.amount)) {
            await this.updateSummaryRealizado(workspaceId, before, -1, warned);
        }
        if (after && isPaidStatus(after.status) && after.paidDate && (after.paidAmount ?? after.amount)) {
            await this.updateSummaryRealizado(workspaceId, after, 1, warned);
        }
    }

    /**
     * Categoria sem id (`{id: "", name: "Supermercado"}`) é SEM CATEGORIA para
     * o sumário: a parcela não entra em `period_summaries`. Avisa uma vez por
     * parcela — `warned` é o conjunto compartilhado pelas quatro chamadas do
     * mesmo evento.
     *
     * Só avisa quando a referência está de fato QUEBRADA (`isCategoryRefBroken`):
     * transferência sem categoria — fatura inclusive — é o desenho normal e
     * fica silenciosa.
     */
    private warnCategoryWithoutIdOnce(
        workspaceId: string,
        inst: InstallmentModel,
        category: CategoryModel | undefined,
        warned: Set<string>
    ): void {
        if (!isCategoryRefBroken(inst)) return;

        const key = `${workspaceId}/${inst.id}`;
        if (warned.has(key)) return;

        warned.add(key);
        console.warn(categoryWithoutIdWarning("summary.service", workspaceId, inst.id, category));
    }

    private async updateSummaryProjetado(
        workspaceId: string,
        inst: InstallmentModel,
        multiplier: number,
        warned: Set<string> = new Set<string>()
    ) {
        let category = inst.category;
        const amount = inst.amount * multiplier;

        if (inst.type === OrderType.transfer) {
            const virtualData = await this.getVirtualCategoryImpact(workspaceId, inst);
            if (!virtualData) return;
            category = virtualData.category;
            // Se for destino (gasto), valor positivo (delta aumenta gasto). 
            // Se for origem (receita), valor negativo (delta aumenta receita - mas aqui o summary guarda valores absolutos de gasto?)
            // No Flutter: destino = gasto, origem = receita.
            // O PeriodSummary do projeto parece somar tudo na categoria.
            // Se a categoria for de gasto, somar aumenta o gasto.
            // Se a regra é "origem => receita", e estamos numa categoria "virtual", 
            // precisamos decidir como o PeriodSummary armazena isso.
            // Normalmente PeriodSummaryCategoryModel tem actualAmount.
        }

        if (!hasCategoryId(category)) {
            this.warnCategoryWithoutIdOnce(workspaceId, inst, category, warned);
            return;
        }

        // Mês e ano no FUSO DO PRODUTO, igual ao dia (`toDateKey`) e à semana.
        const { year, month } = getZonedParts(inst.dueDate);

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, category, {
            specificPlannedDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, category, {
            specificPlannedDelta: amount,
        });

        // Week
        const week = getWeekNumber(inst.dueDate);
        const weekYear = getWeekYear(inst.dueDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, category, {
            specificPlannedDelta: amount,
        }, week);
    }

    private async updateSummaryRealizado(
        workspaceId: string,
        inst: InstallmentModel,
        multiplier: number,
        warned: Set<string> = new Set<string>()
    ) {
        if (!inst.paidDate) return;

        let category = inst.category;
        const amount = (inst.paidAmount ?? inst.amount) * multiplier;

        if (inst.type === OrderType.transfer) {
            const virtualData = await this.getVirtualCategoryImpact(workspaceId, inst);
            if (!virtualData) return;
            category = virtualData.category;
        }

        if (!hasCategoryId(category)) {
            this.warnCategoryWithoutIdOnce(workspaceId, inst, category, warned);
            return;
        }

        // Mês e ano no FUSO DO PRODUTO: um pagamento às 23h30 de 31/10 em São
        // Paulo é 01/11 em UTC e ia parar no sumário de novembro.
        const { year, month } = getZonedParts(inst.paidDate);

        // Month
        await this.financeRepository.updatePeriodSummary(workspaceId, year, month, category, {
            actualDelta: amount,
        });

        // Year
        await this.financeRepository.updatePeriodSummary(workspaceId, year, undefined, category, {
            actualDelta: amount,
        });

        // Week
        const week = getWeekNumber(inst.paidDate);
        const weekYear = getWeekYear(inst.paidDate);
        await this.financeRepository.updatePeriodSummary(workspaceId, weekYear, undefined, category, {
            actualDelta: amount,
        }, week);
    }

    private async getVirtualCategoryImpact(workspaceId: string, inst: InstallmentModel): Promise<{ category: CategoryModel, type: "income" | "expense" } | null> {
        const ids = resolveTransferAccountIds(inst);
        if (!ids) return null;

        const sourceAccount = ids.sourceId ? await this.financeRepository.getAccountById(workspaceId, ids.sourceId) : null;
        const targetAccount = ids.targetId ? await this.financeRepository.getAccountById(workspaceId, ids.targetId) : null;

        return resolveVirtualCategory(sourceAccount, targetAccount);
    }
}

/**
 * Contas de origem (`debt`) e destino (`credit`) de uma transferência.
 * Retorna `null` quando não há nenhuma das duas (nada a fazer).
 *
 * Extraído de `getVirtualCategoryImpact` sem mudança de semântica, para que o
 * job de reconstrução (rebuild.service.ts) resolva as categorias virtuais com
 * um mapa de contas já carregado, em vez de uma leitura por parcela.
 */
export function resolveTransferAccountIds(inst: InstallmentModel): { sourceId?: string, targetId?: string } | null {
    const accounts = inst.accounts || {};
    const accountIds = Object.keys(accounts);
    if (accountIds.length === 0) return null;

    const sourceId = inst.type === OrderType.transfer
        ? accountIds.find(id => accounts[id] === "debt")
        : undefined;
    const targetId = inst.type === OrderType.transfer
        ? accountIds.find(id => accounts[id] === "credit")
        : undefined;

    if (!sourceId && !targetId) return null;

    return { sourceId, targetId };
}

/** Categoria virtual da transferência a partir das contas de origem/destino. */
export function resolveVirtualCategory(
    sourceAccount: AccountModel | null,
    targetAccount: AccountModel | null
): { category: CategoryModel, type: "income" | "expense" } | null {
    if (targetAccount && (targetAccount.runtimeType === AccountType.debt || targetAccount.runtimeType === AccountType.investment)) {
        return {
            category: getVirtualCategoryForAccountType(targetAccount.runtimeType, "expense"),
            type: "expense"
        };
    }
    else if (sourceAccount && (sourceAccount.runtimeType === AccountType.debt || sourceAccount.runtimeType === AccountType.investment)) {
        return {
            category: getVirtualCategoryForAccountType(sourceAccount.runtimeType, "income"),
            type: "income"
        };
    }

    return null;
}

function getVirtualCategoryForAccountType(type: AccountType, categoryType: "income" | "expense"): CategoryModel {
    if (type === AccountType.debt) {
        return categoryType === "expense" ? VIRTUAL_DEBT_EXPENSE_CATEGORY : VIRTUAL_DEBT_INCOME_CATEGORY;
    }
    return categoryType === "expense" ? VIRTUAL_INVESTMENT_EXPENSE_CATEGORY : VIRTUAL_INVESTMENT_INCOME_CATEGORY;
}
