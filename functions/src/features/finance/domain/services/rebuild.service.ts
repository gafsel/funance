/**
 * Job de reconstrução (F1.0): recalcula do zero, para um workspace,
 * tudo o que hoje é mantido de forma incremental pelos gatilhos:
 *
 *  1. `accounts/{id}/balance/{YYYY-MM-DD}`  — semântica de
 *     `FinanceService.applyInstallmentBalance` + `FinanceRepositoryImpl.updateAccountBalance`
 *  2. `period_summaries/{YYYY|YYYY-MM|YYYY-Www}` — semântica de `SummaryService`
 *  3. `weekly_xp/{YYYY-Www}` — semântica de `FinanceService.updateXpOnInstallmentChange`
 *
 * As fontes da verdade são `installments` (exceto as `removed`, que são
 * exclusões lógicas) e `category_planning`.
 *
 * ATENÇÃO (conta apagada): quando uma conta é marcada como `isDeleted`, o
 * gatilho `onAccountUpdated` apaga as orders/parcelas dela
 * (`deleteOrdersByAccountId`), mas NÃO apaga a subcoleção `balance`. Sem
 * parcelas, o rebuild não consegue reconstruir aquele histórico e reporta os
 * documentos de saldo remanescentes como exclusão. Confira o dry-run antes de
 * aplicar num workspace com contas apagadas.
 *
 * REGRA DE OURO: os gatilhos são o oráculo. Onde a implementação atual dos
 * gatilhos e a "regra de negócio ideal" divergirem, este serviço reproduz o
 * gatilho — as divergências conhecidas estão comentadas no código e no
 * relatório do pacote.
 */

import { DEFAULT_FINANCE_CONFIG } from "../../../../core/config/finance.config";
import { getWeekNumber, getWeekYear } from "../../../../core/utils/week.utils";
import { CategoryModel } from "../../../workspace/domain/models/category.model";
import {
    AccountModel,
    CategoryPlanningModel,
    InstallmentModel,
    InstallmentStatus,
    OrderType,
} from "../models/finance.models";
import { ExistingDoc, IRebuildRepository, RebuildWrite } from "../repositories/rebuild.repository";
import { FinanceService } from "./finance.service";
import { resolveTransferAccountIds, resolveVirtualCategory, SummaryService } from "./summary.service";

export interface RebuildOptions {
    /** Padrão `true`: só calcula e devolve o diff, sem escrever nada. */
    dryRun?: boolean;
    /** Data base dos impactos de `category_planning` (padrão: agora). */
    now?: Date;
    /** Operações por batch (máx. 400, o padrão de `commitInChunks`). */
    chunkSize?: number;
    /** Tamanho da página nas leituras (padrão 500). */
    pageSize?: number;
    /** Tolerância de comparação em reais (padrão meio centavo). */
    epsilon?: number;
    /**
     * Apaga também os documentos RESIDUAIS (padrão `false`).
     *
     * Residual é o documento que o rebuild não geraria mas que não muda nada
     * do que o app lê: um `period_summaries`/`weekly_xp` com todos os valores
     * zerados (sobra de um lançamento estornado/removido) ou um documento de
     * saldo num dia sem movimento cujo valor é exatamente o saldo acumulado
     * daquele dia. Eles não contam como divergência.
     */
    pruneResidual?: boolean;
    /** Quantos caminhos de documento listar como amostra por coleção (padrão 10). */
    sampleLimit?: number;
}

export interface CollectionDiff {
    toCreate: number;
    toUpdate: number;
    toDelete: number;
    unchanged: number;
    /** Documentos residuais (ver `RebuildOptions.pruneResidual`). */
    residual: number;
    /** Amostra de caminhos afetados, no formato `criar|alterar|apagar <path>`. */
    samples: string[];
}

export interface RebuildReport {
    workspaceId: string;
    mode: "dryRun" | "apply";
    durationMs: number;
    scanned: {
        installments: number;
        installmentsRemoved: number;
        accounts: number;
        categoryPlannings: number;
    };
    diff: {
        balances: CollectionDiff;
        periodSummaries: CollectionDiff;
        weeklyXp: CollectionDiff;
    };
    /**
     * Soma de criações + alterações + exclusões das três coleções.
     * NÃO inclui os residuais: eles não são divergência de estado.
     */
    totalChanges: number;
    /** Operações efetivamente commitadas (sempre 0 em dry-run). */
    writesCommitted: number;
}

export interface SummaryCategoryTotals {
    generalPlannedAmount: number;
    specificPlannedAmount: number;
    actualAmount: number;
}

export interface TargetSummaryDoc {
    year: number;
    month: number | null;
    week: number | null;
    runtimeType: string;
    categories: Record<string, SummaryCategoryTotals>;
}

export interface TargetState {
    /** accountId -> (YYYY-MM-DD -> saldo acumulado). */
    balances: Map<string, Map<string, number>>;
    /** id do período -> documento. */
    summaries: Map<string, TargetSummaryDoc>;
    /** YYYY-Www -> documento. */
    weeklyXp: Map<string, { year: number; week: number; xp: number }>;
}

const DEFAULT_PAGE_SIZE = 500;
const DEFAULT_EPSILON = 0.005;
const DEFAULT_SAMPLE_LIMIT = 10;

const toCents = (value: number) => Math.round(value * 100);
const fromCents = (cents: number) => cents / 100;
const pad2 = (value: number) => String(value).padStart(2, "0");

/** Id do documento de saldo — idêntico a `FinanceRepositoryImpl.updateAccountBalance`. */
export function balanceDocId(date: Date): string {
    return date.toISOString().split("T")[0];
}

/** Id do documento de período — idêntico a `FinanceRepositoryImpl.getPeriodSummaryDocRef`. */
export function periodSummaryDocId(year: number, month?: number, week?: number): string {
    if (week !== undefined) return `${year}-W${pad2(week)}`;
    if (month !== undefined) return `${year}-${pad2(month)}`;
    return `${year}`;
}

/** Id do documento semanal de XP — idêntico a `FinanceService.updateWeeklyTotalXp`. */
export function weeklyXpDocId(year: number, week: number): string {
    return `${year}-W${pad2(week)}`;
}

const isPaidStatus = (status: InstallmentStatus | undefined) =>
    status === InstallmentStatus.paid || status === InstallmentStatus.settled;

interface CategoryAccumulator {
    /** Vem de `category_planning`: fração (amount/dias*7), acumulada em float. */
    general: number;
    /** Dinheiro: acumulado em centavos inteiros. */
    specificCents: number;
    actualCents: number;
}

interface SummaryAccumulator {
    year: number;
    month: number | null;
    week: number | null;
    runtimeType: string;
    categories: Map<string, CategoryAccumulator>;
}

/**
 * Acumulador determinístico do estado-alvo.
 *
 * Consome parcelas uma a uma (as leituras são paginadas: o workspace inteiro
 * nunca fica em memória) e só mantém os agregados.
 */
export class RebuildAccumulator {
    private balanceDeltaCents = new Map<string, Map<string, number>>();
    private summaries = new Map<string, SummaryAccumulator>();
    private weeklyXp = new Map<string, { year: number; week: number; xp: number }>();
    private accountsById: Map<string, AccountModel>;

    installmentsSeen = 0;
    installmentsRemoved = 0;

    constructor(
        accounts: AccountModel[],
        private summaryService: SummaryService,
        private financeService: FinanceService
    ) {
        this.accountsById = new Map(accounts.map((account) => [account.id, account]));
    }

    addInstallment(installment: InstallmentModel): void {
        // Parcelas `removed` são exclusão lógica: os gatilhos as tratam como
        // inexistentes em saldo, sumário e XP.
        if (installment.status === InstallmentStatus.removed) {
            this.installmentsRemoved++;
            return;
        }

        this.installmentsSeen++;
        this.addBalanceImpact(installment);
        this.addSummaryImpact(installment);
        this.addXpImpact(installment);
    }

    /** Impactos de `category_planning` no `generalPlannedAmount`. */
    addPlanning(planning: CategoryPlanningModel, baseDate: Date): void {
        const impacts = this.summaryService.calculatePlanningImpacts(
            planning,
            1,
            baseDate,
            DEFAULT_FINANCE_CONFIG.categoryPlanning.predictabilityMonths
        );

        for (const impact of impacts) {
            const bucket = this.categoryBucket(impact.year, impact.month, impact.week, impact.category);
            bucket.general += impact.generalPlannedDelta ?? 0;
        }
    }

    /**
     * `FinanceService.applyInstallmentBalance`: só parcelas pagas/liquidadas
     * com `accounts`, `paidAmount` TRUTHY e `paidDate`.
     *
     * Atenção: o gatilho usa `paidAmount` puro (não `paidAmount ?? amount`,
     * como o sumário) e ignora `paidAmount === 0`. Reproduzido tal e qual.
     */
    private addBalanceImpact(installment: InstallmentModel): void {
        if (!isPaidStatus(installment.status)) return;
        if (!installment.accounts || !installment.paidAmount || !installment.paidDate) return;

        const docId = balanceDocId(installment.paidDate);

        for (const [accountId, role] of Object.entries(installment.accounts)) {
            const deltaCents = role === "credit"
                ? toCents(installment.paidAmount)
                : -toCents(installment.paidAmount);

            let perDay = this.balanceDeltaCents.get(accountId);
            if (!perDay) {
                perDay = new Map<string, number>();
                this.balanceDeltaCents.set(accountId, perDay);
            }
            perDay.set(docId, (perDay.get(docId) ?? 0) + deltaCents);
        }
    }

    /** `SummaryService.processInstallmentChange` (projetado + realizado). */
    private addSummaryImpact(installment: InstallmentModel): void {
        const category = this.resolveCategory(installment);
        if (!category) return;

        // Projetado: sempre, no `dueDate`, com `amount`.
        this.addSummaryValue(installment.dueDate, category, "specificCents", toCents(installment.amount));

        // Realizado: no `paidDate`, com `paidAmount ?? amount`.
        if (!isPaidStatus(installment.status) || !installment.paidDate) return;
        const actual = installment.paidAmount ?? installment.amount;
        if (!actual) return;

        this.addSummaryValue(installment.paidDate, category, "actualCents", toCents(actual));
    }

    /** `FinanceService.updateXpOnInstallmentChange` + `updateWeeklyTotalXp`. */
    private addXpImpact(installment: InstallmentModel): void {
        if (!isPaidStatus(installment.status)) return;

        // O gatilho recalcula o XP no pagamento e grava no documento da parcela;
        // a reconstrução recalcula sempre (um `xp` salvo desatualizado não
        // contamina o total).
        const xp = this.financeService.calculateXp(installment);
        // `updateWeeklyTotalXp` sai cedo quando o delta é zero: nenhum documento
        // é criado por uma parcela que vale 0 XP.
        if (!xp) return;

        const date = installment.paidDate || installment.dueDate;
        const year = getWeekYear(date);
        const week = getWeekNumber(date);
        const docId = weeklyXpDocId(year, week);

        const current = this.weeklyXp.get(docId);
        if (current) {
            current.xp += xp;
        }
        else {
            this.weeklyXp.set(docId, { year, week, xp });
        }
    }

    /** Categoria efetiva da parcela (transferência vira categoria virtual). */
    private resolveCategory(installment: InstallmentModel): CategoryModel | undefined {
        if (installment.type !== OrderType.transfer) {
            return installment.category;
        }

        const ids = resolveTransferAccountIds(installment);
        if (!ids) return undefined;

        const source = ids.sourceId ? this.accountsById.get(ids.sourceId) ?? null : null;
        const target = ids.targetId ? this.accountsById.get(ids.targetId) ?? null : null;

        return resolveVirtualCategory(source, target)?.category;
    }

    /** Aplica o valor nos três documentos que o gatilho toca: mês, ano e semana. */
    private addSummaryValue(
        date: Date,
        category: CategoryModel,
        field: "specificCents" | "actualCents",
        cents: number
    ): void {
        const year = date.getFullYear();
        const month = date.getMonth() + 1;

        this.categoryBucket(year, month, undefined, category)[field] += cents;
        this.categoryBucket(year, undefined, undefined, category)[field] += cents;

        // O documento semanal usa o ANO DA SEMANA (domingo que a inicia), que
        // na virada de ano pode diferir do ano da data.
        this.categoryBucket(getWeekYear(date), undefined, getWeekNumber(date), category)[field] += cents;
    }

    private categoryBucket(
        year: number,
        month: number | undefined,
        week: number | undefined,
        category: CategoryModel
    ): CategoryAccumulator {
        const docId = periodSummaryDocId(year, month, week);

        let summary = this.summaries.get(docId);
        if (!summary) {
            summary = {
                year,
                month: month ?? null,
                week: week ?? null,
                runtimeType: week !== undefined ? "week" : month !== undefined ? "month" : "year",
                categories: new Map(),
            };
            this.summaries.set(docId, summary);
        }

        let bucket = summary.categories.get(category.id);
        if (!bucket) {
            bucket = { general: 0, specificCents: 0, actualCents: 0 };
            summary.categories.set(category.id, bucket);
        }
        return bucket;
    }

    /** Fecha os agregados: acumula os saldos dia a dia e materializa os documentos. */
    build(): TargetState {
        const balances = new Map<string, Map<string, number>>();

        for (const [accountId, perDay] of this.balanceDeltaCents) {
            const days = [...perDay.keys()].sort();
            const running = new Map<string, number>();
            let accumulated = 0;

            for (const day of days) {
                accumulated += perDay.get(day)!;
                running.set(day, fromCents(accumulated));
            }
            balances.set(accountId, running);
        }

        const summaries = new Map<string, TargetSummaryDoc>();
        for (const [docId, summary] of this.summaries) {
            const categories: Record<string, SummaryCategoryTotals> = {};
            for (const [categoryId, bucket] of summary.categories) {
                categories[categoryId] = {
                    generalPlannedAmount: bucket.general,
                    specificPlannedAmount: fromCents(bucket.specificCents),
                    actualAmount: fromCents(bucket.actualCents),
                };
            }
            summaries.set(docId, {
                year: summary.year,
                month: summary.month,
                week: summary.week,
                runtimeType: summary.runtimeType,
                categories,
            });
        }

        return { balances, summaries, weeklyXp: new Map(this.weeklyXp) };
    }
}

function emptyDiff(): CollectionDiff {
    return { toCreate: 0, toUpdate: 0, toDelete: 0, unchanged: 0, residual: 0, samples: [] };
}

class DiffCollector {
    readonly diff = emptyDiff();
    /** Escritas que corrigem divergências reais. */
    readonly writes: RebuildWrite[] = [];
    /** Exclusões de documentos residuais (só entram com `pruneResidual`). */
    readonly residualWrites: RebuildWrite[] = [];

    constructor(private sampleLimit: number) {}

    private sample(action: string, path: string): void {
        if (this.diff.samples.length < this.sampleLimit) {
            this.diff.samples.push(`${action} ${path}`);
        }
    }

    create(path: string, write: RebuildWrite): void {
        this.diff.toCreate++;
        this.sample("criar", path);
        this.writes.push(write);
    }

    update(path: string, write: RebuildWrite): void {
        this.diff.toUpdate++;
        this.sample("alterar", path);
        this.writes.push(write);
    }

    remove(path: string, write: RebuildWrite): void {
        this.diff.toDelete++;
        this.sample("apagar", path);
        this.writes.push(write);
    }

    keep(): void {
        this.diff.unchanged++;
    }

    residual(path: string, write: RebuildWrite): void {
        this.diff.residual++;
        this.sample("residual", path);
        this.residualWrites.push(write);
    }
}

export class RebuildService {
    constructor(
        private rebuildRepository: IRebuildRepository,
        private summaryService: SummaryService,
        private financeService: FinanceService
    ) {}

    /**
     * Recalcula saldos, sumários e XP semanal do workspace.
     *
     * Em `dryRun` (padrão) nada é escrito: o retorno descreve o que mudaria.
     * Rodar em `apply` duas vezes seguidas produz o mesmo estado — a segunda
     * execução não reporta nenhuma diferença.
     */
    async rebuildWorkspace(workspaceId: string, options: RebuildOptions = {}): Promise<RebuildReport> {
        const startedAt = Date.now();
        const dryRun = options.dryRun !== false;
        const pageSize = options.pageSize ?? DEFAULT_PAGE_SIZE;
        const epsilon = options.epsilon ?? DEFAULT_EPSILON;
        const sampleLimit = options.sampleLimit ?? DEFAULT_SAMPLE_LIMIT;
        const baseDate = options.now ?? new Date();

        const accounts = await this.rebuildRepository.getAccounts(workspaceId);
        const plannings = await this.rebuildRepository.getCategoryPlannings(workspaceId);

        const accumulator = new RebuildAccumulator(accounts, this.summaryService, this.financeService);

        await this.rebuildRepository.forEachInstallment(workspaceId, pageSize, (installment) => {
            accumulator.addInstallment(installment);
        });

        // Ordem fixa (por id) para que o acúmulo em ponto flutuante seja
        // determinístico entre execuções.
        for (const planning of [...plannings].sort((a, b) => a.id.localeCompare(b.id))) {
            accumulator.addPlanning(planning, baseDate);
        }

        const target = accumulator.build();

        const accountIds = new Set<string>(await this.rebuildRepository.listAccountIds(workspaceId));
        for (const accountId of target.balances.keys()) {
            accountIds.add(accountId);
        }

        const balances = await this.diffBalances(workspaceId, [...accountIds].sort(), target, pageSize, epsilon, sampleLimit);
        const summaries = await this.diffSummaries(workspaceId, target, pageSize, epsilon, sampleLimit);
        const weeklyXp = await this.diffWeeklyXp(workspaceId, target, pageSize, epsilon, sampleLimit);

        const changes = [...balances.writes, ...summaries.writes, ...weeklyXp.writes];
        const residual = [...balances.residualWrites, ...summaries.residualWrites, ...weeklyXp.residualWrites];
        const writes = options.pruneResidual ? [...changes, ...residual] : changes;

        let writesCommitted = 0;
        if (!dryRun && writes.length > 0) {
            writesCommitted = await this.rebuildRepository.applyWrites(workspaceId, writes, options.chunkSize ?? 400);
        }

        const totalChanges = changes.length;

        return {
            workspaceId,
            mode: dryRun ? "dryRun" : "apply",
            durationMs: Date.now() - startedAt,
            scanned: {
                installments: accumulator.installmentsSeen,
                installmentsRemoved: accumulator.installmentsRemoved,
                accounts: accounts.length,
                categoryPlannings: plannings.length,
            },
            diff: {
                balances: balances.diff,
                periodSummaries: summaries.diff,
                weeklyXp: weeklyXp.diff,
            },
            totalChanges,
            writesCommitted,
        };
    }

    private async diffBalances(
        workspaceId: string,
        accountIds: string[],
        target: TargetState,
        pageSize: number,
        epsilon: number,
        sampleLimit: number
    ): Promise<DiffCollector> {
        const collector = new DiffCollector(sampleLimit);

        for (const accountId of accountIds) {
            const existing = await this.rebuildRepository.getExistingBalances(workspaceId, accountId, pageSize);
            const existingById = new Map(existing.map((doc) => [doc.id, doc]));
            const expected = target.balances.get(accountId) ?? new Map<string, number>();

            for (const docId of [...expected.keys()].sort()) {
                const balance = expected.get(docId)!;
                const path = `accounts/${accountId}/balance/${docId}`;
                const current = existingById.get(docId);
                const write: RebuildWrite = { kind: "balance", accountId, docId, op: "set", data: { balance } };

                if (!current) {
                    collector.create(path, write);
                }
                else if (!numbersEqual(current.data.balance, balance, epsilon)) {
                    collector.update(path, write);
                }
                else {
                    collector.keep();
                }
            }

            const expectedDays = [...expected.keys()].sort();

            for (const doc of existing) {
                if (expected.has(doc.id)) continue;

                const path = `accounts/${accountId}/balance/${doc.id}`;
                const write: RebuildWrite = { kind: "balance", accountId, docId: doc.id, op: "delete" };

                // Dia sem movimento: o documento só repete o saldo acumulado
                // até ali (sobra de um pagamento estornado). Nenhuma consulta
                // enxerga diferença, então não é divergência — é residual.
                if (numbersEqual(doc.data.balance, impliedBalance(expected, expectedDays, doc.id), epsilon)) {
                    collector.residual(path, write);
                }
                else {
                    collector.remove(path, write);
                }
            }
        }

        return collector;
    }

    private async diffSummaries(
        workspaceId: string,
        target: TargetState,
        pageSize: number,
        epsilon: number,
        sampleLimit: number
    ): Promise<DiffCollector> {
        const collector = new DiffCollector(sampleLimit);
        const existing = await this.rebuildRepository.getExistingPeriodSummaries(workspaceId, pageSize);
        const existingById = new Map(existing.map((doc) => [doc.id, doc]));

        for (const docId of [...target.summaries.keys()].sort()) {
            const expected = target.summaries.get(docId)!;
            const path = `period_summaries/${docId}`;
            const current = existingById.get(docId);
            const write: RebuildWrite = { kind: "summary", docId, op: "set", data: expected };

            if (!current) {
                collector.create(path, write);
            }
            else if (!summaryEquals(current, expected, epsilon)) {
                collector.update(path, write);
            }
            else {
                collector.keep();
            }
        }

        for (const doc of existing) {
            if (target.summaries.has(doc.id)) continue;

            const path = `period_summaries/${doc.id}`;
            const write: RebuildWrite = { kind: "summary", docId: doc.id, op: "delete" };

            // Documento inteiramente zerado (sobra de lançamento estornado ou
            // removido): equivale à ausência do documento.
            if (isZeroedSummary(doc, epsilon)) {
                collector.residual(path, write);
            }
            else {
                collector.remove(path, write);
            }
        }

        return collector;
    }

    private async diffWeeklyXp(
        workspaceId: string,
        target: TargetState,
        pageSize: number,
        epsilon: number,
        sampleLimit: number
    ): Promise<DiffCollector> {
        const collector = new DiffCollector(sampleLimit);
        const existing = await this.rebuildRepository.getExistingWeeklyXp(workspaceId, pageSize);
        const existingById = new Map(existing.map((doc) => [doc.id, doc]));

        for (const docId of [...target.weeklyXp.keys()].sort()) {
            const expected = target.weeklyXp.get(docId)!;
            const path = `weekly_xp/${docId}`;
            const current = existingById.get(docId);
            const write: RebuildWrite = { kind: "weeklyXp", docId, op: "set", data: expected };

            if (!current) {
                collector.create(path, write);
            }
            else if (
                current.data.year !== expected.year ||
                current.data.week !== expected.week ||
                !numbersEqual(current.data.xp, expected.xp, epsilon)
            ) {
                collector.update(path, write);
            }
            else {
                collector.keep();
            }
        }

        for (const doc of existing) {
            if (target.weeklyXp.has(doc.id)) continue;

            const path = `weekly_xp/${doc.id}`;
            const write: RebuildWrite = { kind: "weeklyXp", docId: doc.id, op: "delete" };

            if (numbersEqual(doc.data.xp ?? 0, 0, epsilon)) {
                collector.residual(path, write);
            }
            else {
                collector.remove(path, write);
            }
        }

        return collector;
    }
}

/** Saldo acumulado que o rebuild enxerga no dia (último dia-alvo <= `dayId`). */
function impliedBalance(expected: Map<string, number>, sortedDays: string[], dayId: string): number {
    let value = 0;
    for (const day of sortedDays) {
        if (day > dayId) break;
        value = expected.get(day)!;
    }
    return value;
}

/** `true` se todas as categorias do documento estão zeradas. */
function isZeroedSummary(doc: ExistingDoc, epsilon: number): boolean {
    const categories: Record<string, any> = doc.data?.categories || {};

    return Object.values(categories).every((totals: any) =>
        numbersEqual(totals?.generalPlannedAmount ?? 0, 0, epsilon) &&
        numbersEqual(totals?.specificPlannedAmount ?? 0, 0, epsilon) &&
        numbersEqual(totals?.actualAmount ?? 0, 0, epsilon)
    );
}

function numbersEqual(current: any, expected: number, epsilon: number): boolean {
    const value = typeof current === "number" ? current : Number(current);
    if (!Number.isFinite(value)) return false;
    return Math.abs(value - expected) <= epsilon;
}

function summaryEquals(current: ExistingDoc, expected: TargetSummaryDoc, epsilon: number): boolean {
    const data = current.data || {};

    if ((data.year ?? null) !== expected.year) return false;
    if ((data.month ?? null) !== expected.month) return false;
    if ((data.week ?? null) !== expected.week) return false;
    if ((data.runtimeType ?? null) !== expected.runtimeType) return false;

    const currentCategories: Record<string, any> = data.categories || {};
    const currentIds = Object.keys(currentCategories);
    const expectedIds = Object.keys(expected.categories);

    if (currentIds.length !== expectedIds.length) return false;

    for (const categoryId of expectedIds) {
        const currentTotals = currentCategories[categoryId];
        if (!currentTotals) return false;

        const expectedTotals = expected.categories[categoryId];
        if (!numbersEqual(currentTotals.generalPlannedAmount ?? 0, expectedTotals.generalPlannedAmount, epsilon)) return false;
        if (!numbersEqual(currentTotals.specificPlannedAmount ?? 0, expectedTotals.specificPlannedAmount, epsilon)) return false;
        if (!numbersEqual(currentTotals.actualAmount ?? 0, expectedTotals.actualAmount, epsilon)) return false;
    }

    return true;
}
