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
 * ATENÇÃO (não é transacional): o job lê o workspace, calcula em memória e só
 * então commita em lotes. Uma escrita feita pelo app entre a leitura e o commit
 * é SOBRESCRITA — aplique numa janela sem uso, com o dry-run refeito logo antes.
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
 *
 * DIVERGÊNCIA CONHECIDA (F1.5, `--rebuild-planning`): o gatilho aplica o
 * planejamento a partir do MÊS CORRENTE (nunca reescreve o passado), enquanto
 * o rebuild cobre o período inteiro a partir de `startMonth`. Para um
 * planejamento que começa no mês corrente ou no futuro os dois coincidem
 * exatamente; para um que começou no passado, o rebuild PREENCHE os meses
 * passados — é a correção pretendida, mas aparece como diferença no dry-run.
 */

import { getZonedParts, toDateKey } from "../../../../core/utils/date_key";
import { fromCents, resolveCents, toCents } from "../../../../core/utils/money";
import { getWeekNumber, getWeekYear } from "../../../../core/utils/week.utils";
import {
    CategoryModel,
    categoryWithoutIdWarning,
    hasCategoryId,
    isCategoryRefBroken,
} from "../../../workspace/domain/models/category.model";
import {
    AccountModel,
    CategoryPlanningModel,
    InstallmentModel,
    InstallmentStatus,
    OrderType,
} from "../models/finance.models";
import {
    ExistingDoc,
    ExistingSummaryData,
    IRebuildRepository,
    RebuildWrite,
} from "../repositories/rebuild.repository";
import { FinanceService } from "./finance.service";
import {
    intersectPlanningWindow,
    planningHorizon,
    resolveTransferAccountIds,
    resolveVirtualCategory,
    SummaryService,
} from "./summary.service";

export interface RebuildOptions {
    /** Padrão `true`: só calcula e devolve o diff, sem escrever nada. */
    dryRun?: boolean;
    /** Data base dos impactos de `category_planning` (padrão: agora). */
    now?: Date;
    /** Operações por batch (máx. 400, o padrão de `commitInChunks`). */
    chunkSize?: number;
    /** Tamanho da página nas leituras (padrão 500). */
    pageSize?: number;
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
    /** Quantos caminhos de documento listar como amostra por coleção (padrão 50). */
    sampleLimit?: number;
    /**
     * Recalcula também o `generalPlannedAmount` (padrão `false`).
     *
     * F1.5 tornou esse recálculo DETERMINÍSTICO: os impactos cobrem todos os
     * meses de `startMonth` até `min(endMonth, horizonte)`, e a única
     * dependência de `now` é o horizonte (mês corrente + 11). Rodar hoje e
     * amanhã dá o mesmo resultado; rodar no mês que vem só acrescenta o mês
     * novo da ponta.
     *
     * Continua sendo uma flag, e não o padrão, por dois motivos:
     *  - o valor gravado pode ter vindo do regime antigo (janela que começava
     *     em `now`), e o recálculo vai MUDÁ-LO — inclusive preenchendo meses
     *     passados que o incremental nunca preencheu;
     *  - quem opera precisa ver no dry-run de onde vem cada alteração
     *    (`generalPlannedChanges` conta os documentos afetados).
     *
     * Sem a flag, o `generalPlannedAmount` gravado é PRESERVADO como está.
     */
    rebuildPlanning?: boolean;
}

export interface CollectionDiff {
    toCreate: number;
    toUpdate: number;
    toDelete: number;
    unchanged: number;
    /** Documentos residuais (ver `RebuildOptions.pruneResidual`). */
    residual: number;
    /**
     * Documentos cuja mudança mexe no `generalPlannedAmount` de alguma
     * categoria. Sempre 0 fora de `period_summaries` e sempre 0 sem
     * `rebuildPlanning`. Contado à parte para o dono saber de onde vem a
     * alteração.
     */
    generalPlannedChanges: number;
    /** Amostra de caminhos afetados, no formato `criar|alterar|apagar <path>`. */
    samples: string[];
}

export interface RebuildReport {
    workspaceId: string;
    mode: "dryRun" | "apply";
    /** `false` (padrão) = o `generalPlannedAmount` gravado foi preservado. */
    rebuildPlanning: boolean;
    durationMs: number;
    scanned: {
        installments: number;
        installmentsRemoved: number;
        /**
         * Parcelas com a referência de categoria QUEBRADA (`isCategoryRefBroken`):
         * `category.id` vazio, ou categoria ausente numa parcela que não é
         * transferência. Contadas em saldo/XP, mas FORA dos `period_summaries`.
         * Qualquer valor > 0 pede o script `fix_empty_category`.
         *
         * Transferência sem categoria (fatura inclusive) NÃO entra: é o desenho
         * normal dela, e contá-la fazia o relatório acusar dezenas de parcelas
         * saudáveis.
         */
        installmentsWithoutCategory: number;
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
    /** F1.10 — os mesmos três totais em CENTAVOS INTEIROS (a fonte da verdade). */
    generalPlannedAmountCents: number;
    specificPlannedAmountCents: number;
    actualAmountCents: number;
}

export interface TargetSummaryDoc {
    year: number;
    month: number | null;
    week: number | null;
    runtimeType: string;
    categories: Record<string, SummaryCategoryTotals>;
}

/** Documento de saldo diário reconstruído. */
export interface TargetBalanceDoc {
    /** Soma dos movimentos do dia. */
    delta: number;
    /** Saldo acumulado ao fim do dia. */
    balance: number;
    /** F1.10 — os mesmos dois valores em CENTAVOS INTEIROS. */
    deltaCents: number;
    balanceCents: number;
}

export interface TargetState {
    /** accountId -> (dateKey -> saldo do dia). */
    balances: Map<string, Map<string, TargetBalanceDoc>>;
    /** id do período -> documento. */
    summaries: Map<string, TargetSummaryDoc>;
    /** YYYY-Www -> documento. */
    weeklyXp: Map<string, { year: number; week: number; xp: number }>;
}

const DEFAULT_PAGE_SIZE = 500;
const DEFAULT_SAMPLE_LIMIT = 50;
/** Teto de operações por batch — `commitInChunks` aceita 500, usamos 400 de folga. */
const MAX_CHUNK_SIZE = 400;

const pad2 = (value: number) => String(value).padStart(2, "0");

/**
 * Id do documento de saldo — idêntico a `FinanceRepositoryImpl.updateAccountBalance`.
 *
 * F1.4: o dia é o dia de calendário no FUSO DO PRODUTO (antes era UTC). O id
 * continua sendo igual ao campo `dateKey`, que é o contrato com o app.
 */
export function balanceDocId(date: Date): string {
    return toDateKey(date);
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
    /**
     * Vem de `category_planning` (`amount/dias*7` para a semana). F1.10 — os
     * impactos já chegam arredondados ao centavo por
     * `SummaryService.calculatePlanningImpacts`, então também aqui a soma é
     * INTEIRA: é o que torna gatilho e rebuild capazes de chegar ao mesmo
     * número, em vez de a um número parecido.
     */
    generalCents: number;
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
 * As parcelas são consumidas em streaming (página a página, nenhuma lista de
 * parcelas fica retida). Os AGREGADOS — saldo por conta/dia, sumários por
 * período/categoria e XP por semana — ficam em memória, e são eles que
 * dimensionam o consumo do job.
 */
export class RebuildAccumulator {
    private balanceDeltaCents = new Map<string, Map<string, number>>();
    private summaries = new Map<string, SummaryAccumulator>();
    private weeklyXp = new Map<string, { year: number; week: number; xp: number }>();
    private accountsById: Map<string, AccountModel>;

    installmentsSeen = 0;
    installmentsRemoved = 0;
    /**
     * Parcelas cuja categoria não tem id (`{id: "", name: "Supermercado"}`) e
     * que por isso ficaram fora dos `period_summaries`. Elas continuam contando
     * em saldo e XP — o contador existe para o relatório do rebuild dizer
     * quantas precisam do `fix_empty_category`.
     */
    installmentsWithoutCategory = 0;

    constructor(
        accounts: AccountModel[],
        private summaryService: SummaryService,
        private financeService: FinanceService,
        /** Só para o log do aviso de categoria sem id. */
        private workspaceId: string = "?"
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

    /**
     * Impactos de `category_planning` no `generalPlannedAmount` (F1.5).
     *
     * DETERMINÍSTICO: cobre todos os meses de `startMonth` até
     * `min(endMonth, horizonte)`, com `horizonte = mês de baseDate + 11`. A
     * única dependência de `now` é o horizonte — o passado não muda conforme o
     * dia em que o job roda, como acontecia quando a janela começava em `now`.
     */
    addPlanning(planning: CategoryPlanningModel, baseDate: Date): void {
        const window = intersectPlanningWindow(
            planning.startMonth,
            planning.endMonth,
            planning.startMonth,
            planningHorizon(baseDate)
        );
        if (!window) return;

        const impacts = this.summaryService.calculatePlanningImpacts(planning, 1, window);

        for (const impact of impacts) {
            // Mesma regra do sumário: sem id não há chave de categoria para
            // gravar. Um planejamento assim é ignorado inteiro.
            if (!hasCategoryId(impact.category)) continue;

            const bucket = this.categoryBucket(impact.year, impact.month, impact.week, impact.category);
            bucket.generalCents += toCents(impact.generalPlannedDelta ?? 0);
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
        // F1.10 — o valor vem do espelho INTEIRO da parcela quando ele existe.
        const paidCents = resolveCents(installment.paidAmount, installment.paidAmountCents);

        for (const [accountId, role] of Object.entries(installment.accounts)) {
            const deltaCents = role === "credit" ? paidCents : -paidCents;

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

        if (!hasCategoryId(category)) {
            // MESMA REGRA DO GATILHO: categoria sem id é "sem categoria" e fica
            // fora dos sumários (o saldo e o XP desta parcela seguem contando).
            // Sem isso o acumulador criava a chave `categories.""` e o
            // `--apply` morria na escrita — o dry-run nem acusava, porque não
            // chega a montar a referência.
            //
            // Só a categoria QUEBRADA é contada e avisada (`isCategoryRefBroken`):
            // uma transferência sem categoria — inclusive fatura, que também é
            // `type: transfer` — é o estado normal dela e segue silenciosa.
            if (isCategoryRefBroken(installment)) {
                this.installmentsWithoutCategory++;
                console.warn(categoryWithoutIdWarning(
                    "rebuild.service",
                    this.workspaceId,
                    installment.id,
                    installment.category
                ));
            }
            return;
        }

        // Projetado: sempre, no `dueDate`, com `amount`.
        this.addSummaryValue(
            installment.dueDate,
            category,
            "specificCents",
            resolveCents(installment.amount, installment.amountCents)
        );

        // Realizado: no `paidDate`, com `paidAmount ?? amount`.
        if (!isPaidStatus(installment.status) || !installment.paidDate) return;
        const actualCents = installment.paidAmount !== undefined && installment.paidAmount !== null
            ? resolveCents(installment.paidAmount, installment.paidAmountCents)
            : resolveCents(installment.amount, installment.amountCents);
        if (!actualCents) return;

        this.addSummaryValue(installment.paidDate, category, "actualCents", actualCents);
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
        // Mês e ano no FUSO DO PRODUTO, como o gatilho (`SummaryService`).
        const { year, month } = getZonedParts(date);

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
            bucket = { generalCents: 0, specificCents: 0, actualCents: 0 };
            summary.categories.set(category.id, bucket);
        }
        return bucket;
    }

    /** Fecha os agregados: acumula os saldos dia a dia e materializa os documentos. */
    build(): TargetState {
        const balances = new Map<string, Map<string, TargetBalanceDoc>>();

        for (const [accountId, perDay] of this.balanceDeltaCents) {
            const days = [...perDay.keys()].sort();
            const running = new Map<string, TargetBalanceDoc>();
            let accumulated = 0;

            for (const day of days) {
                const deltaCents = perDay.get(day)!;
                accumulated += deltaCents;
                running.set(day, {
                    delta: fromCents(deltaCents),
                    balance: fromCents(accumulated),
                    deltaCents,
                    balanceCents: accumulated,
                });
            }
            balances.set(accountId, running);
        }

        const summaries = new Map<string, TargetSummaryDoc>();
        for (const [docId, summary] of this.summaries) {
            const categories: Record<string, SummaryCategoryTotals> = {};
            for (const [categoryId, bucket] of summary.categories) {
                categories[categoryId] = {
                    generalPlannedAmount: fromCents(bucket.generalCents),
                    specificPlannedAmount: fromCents(bucket.specificCents),
                    actualAmount: fromCents(bucket.actualCents),
                    generalPlannedAmountCents: bucket.generalCents,
                    specificPlannedAmountCents: bucket.specificCents,
                    actualAmountCents: bucket.actualCents,
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
    return { toCreate: 0, toUpdate: 0, toDelete: 0, unchanged: 0, residual: 0, generalPlannedChanges: 0, samples: [] };
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

    create(path: string, write: RebuildWrite, generalPlannedChanged = false): void {
        this.diff.toCreate++;
        if (generalPlannedChanged) this.diff.generalPlannedChanges++;
        this.sample(generalPlannedChanged ? "criar (generalPlanned)" : "criar", path);
        this.writes.push(write);
    }

    update(path: string, write: RebuildWrite, generalPlannedChanged = false): void {
        this.diff.toUpdate++;
        if (generalPlannedChanged) this.diff.generalPlannedChanges++;
        this.sample(generalPlannedChanged ? "alterar (generalPlanned)" : "alterar", path);
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
        const sampleLimit = options.sampleLimit ?? DEFAULT_SAMPLE_LIMIT;
        const rebuildPlanning = options.rebuildPlanning === true;
        const baseDate = options.now ?? new Date();

        const accounts = await this.rebuildRepository.getAccounts(workspaceId);
        const plannings = await this.rebuildRepository.getCategoryPlannings(workspaceId);

        const accumulator = new RebuildAccumulator(accounts, this.summaryService, this.financeService, workspaceId);

        await this.rebuildRepository.forEachInstallment(workspaceId, pageSize, (installment) => {
            accumulator.addInstallment(installment);
        });

        if (rebuildPlanning) {
            // Ordem fixa (por id) para que o acúmulo em ponto flutuante seja
            // determinístico entre execuções.
            for (const planning of [...plannings].sort((a, b) => a.id.localeCompare(b.id))) {
                accumulator.addPlanning(planning, baseDate);
            }
        }

        const target = accumulator.build();

        const existingSummaries = await this.rebuildRepository.getExistingPeriodSummaries(workspaceId, pageSize);

        if (!rebuildPlanning) {
            // Padrão: o `generalPlannedAmount` gravado é preservado como está —
            // ver `RebuildOptions.rebuildPlanning`.
            preserveGeneralPlanned(target, existingSummaries);
        }

        const accountIds = new Set<string>(await this.rebuildRepository.listAccountIds(workspaceId));
        for (const accountId of target.balances.keys()) {
            accountIds.add(accountId);
        }

        const balances = await this.diffBalances(workspaceId, [...accountIds].sort(), target, pageSize, sampleLimit);
        const summaries = this.diffSummaries(existingSummaries, target, sampleLimit);
        const weeklyXp = await this.diffWeeklyXp(workspaceId, target, pageSize, sampleLimit);

        const changes = [...balances.writes, ...summaries.writes, ...weeklyXp.writes];
        const residual = [...balances.residualWrites, ...summaries.residualWrites, ...weeklyXp.residualWrites];
        const writes = options.pruneResidual ? [...changes, ...residual] : changes;

        let writesCommitted = 0;
        if (!dryRun && writes.length > 0) {
            const chunkSize = Math.min(Math.max(1, options.chunkSize ?? MAX_CHUNK_SIZE), MAX_CHUNK_SIZE);
            writesCommitted = await this.rebuildRepository.applyWrites(workspaceId, writes, chunkSize);
        }

        const totalChanges = changes.length;

        return {
            workspaceId,
            mode: dryRun ? "dryRun" : "apply",
            rebuildPlanning,
            durationMs: Date.now() - startedAt,
            scanned: {
                installments: accumulator.installmentsSeen,
                installmentsRemoved: accumulator.installmentsRemoved,
                installmentsWithoutCategory: accumulator.installmentsWithoutCategory,
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
        sampleLimit: number
    ): Promise<DiffCollector> {
        const collector = new DiffCollector(sampleLimit);

        for (const accountId of accountIds) {
            const existing = await this.rebuildRepository.getExistingBalances(workspaceId, accountId, pageSize);
            const existingById = new Map(existing.map((doc) => [doc.id, doc]));
            const expected = target.balances.get(accountId) ?? new Map<string, TargetBalanceDoc>();

            for (const docId of [...expected.keys()].sort()) {
                const day = expected.get(docId)!;
                const path = `accounts/${accountId}/balance/${docId}`;
                const current = existingById.get(docId);
                const write: RebuildWrite = {
                    kind: "balance",
                    accountId,
                    docId,
                    op: "set",
                    data: {
                        dateKey: docId,
                        delta: day.delta,
                        balance: day.balance,
                        deltaCents: day.deltaCents,
                        balanceCents: day.balanceCents,
                    },
                };

                if (!current) {
                    collector.create(path, write);
                }
                else if (
                    // F1.10 — a comparação é de CENTAVOS INTEIROS, e o
                    // verificador confere os DOIS lados: o inteiro gravado E o
                    // `double` espelho. Um documento cujo `balanceCents` bate
                    // mas cujo `balance` escorregou continua sendo divergência,
                    // porque é o `double` que o app lê hoje.
                    storedCents(current.data.balance, current.data.balanceCents) !== day.balanceCents ||
                    storedCents(current.data.delta, current.data.deltaCents) !== day.deltaCents ||
                    !mirrorsCents(current.data.balance, day.balanceCents) ||
                    !mirrorsCents(current.data.delta, day.deltaCents) ||
                    current.data.dateKey !== docId
                ) {
                    // O `delta`/`dateKey` ausente é o documento anterior a F1.4:
                    // o valor acumulado pode até estar certo, mas o documento
                    // ainda não está no formato novo.
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
                if (storedCents(doc.data.balance, doc.data.balanceCents) === impliedBalanceCents(expected, expectedDays, doc.id)) {
                    collector.residual(path, write);
                }
                else {
                    collector.remove(path, write);
                }
            }
        }

        return collector;
    }

    /**
     * Compara os `period_summaries` já gravados com o estado-alvo.
     *
     * Recebe os documentos existentes prontos (já foram lidos para preservar o
     * `generalPlannedAmount`), evitando uma segunda varredura da coleção.
     */
    private diffSummaries(
        existing: ExistingDoc<ExistingSummaryData>[],
        target: TargetState,
        sampleLimit: number
    ): DiffCollector {
        const collector = new DiffCollector(sampleLimit);
        const existingById = new Map(existing.map((doc) => [doc.id, doc]));

        for (const docId of [...target.summaries.keys()].sort()) {
            const expected = target.summaries.get(docId)!;
            const path = `period_summaries/${docId}`;
            const current = existingById.get(docId);
            const write: RebuildWrite = { kind: "summary", docId, op: "set", data: expected };

            if (!current) {
                const hasPlanned = Object.values(expected.categories)
                    .some((totals) => totals.generalPlannedAmountCents !== 0);
                collector.create(path, write, hasPlanned);
                continue;
            }

            const comparison = compareSummary(current, expected);

            if (comparison.equal) {
                collector.keep();
            }
            else if (comparison.onlyZeroedCategoriesRemoved) {
                // A única diferença é uma categoria zerada que sairia do
                // documento: nada que o app leia muda.
                collector.residual(path, write);
            }
            else {
                collector.update(path, write, comparison.generalPlannedChanged);
            }
        }

        for (const doc of existing) {
            if (target.summaries.has(doc.id)) continue;

            const path = `period_summaries/${doc.id}`;
            const write: RebuildWrite = { kind: "summary", docId: doc.id, op: "delete" };

            // Id fora do padrão (`YYYY`, `YYYY-MM`, `YYYY-Www`): o job não sabe
            // o que é, então NÃO mexe.
            if (!parsePeriodId(doc.id)) {
                collector.keep();
            }
            else if (isZeroedSummary(doc)) {
                // Documento inteiramente zerado (sobra de lançamento estornado
                // ou removido): equivale à ausência do documento.
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
                // XP não é dinheiro, mas o `calculateXp` devolve meio ponto
                // (15 ± 1,5): comparar em "centavos de XP" é exato do mesmo
                // jeito e dispensa a tolerância.
                toCents(current.data.xp) !== toCents(expected.xp)
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

            if (toCents(doc.data.xp ?? 0) === 0) {
                collector.residual(path, write);
            }
            else {
                collector.remove(path, write);
            }
        }

        return collector;
    }
}

/** Saldo acumulado que o rebuild enxerga no dia (último dia-alvo <= `dayId`), em centavos. */
function impliedBalanceCents(expected: Map<string, TargetBalanceDoc>, sortedDays: string[], dayId: string): number {
    let value = 0;
    for (const day of sortedDays) {
        if (day > dayId) break;
        value = expected.get(day)!.balanceCents;
    }
    return value;
}

/**
 * Centavos de um par (`double`, `*Cents`) JÁ GRAVADO — o inteiro manda.
 *
 * F1.10: enquanto a `migrate_money_cents` não passa, o `*Cents` não existe e
 * quem responde é o espelho.
 */
function storedCents(value: unknown, cents: unknown): number {
    return resolveCents(typeof value === "number" ? value : Number(value), cents);
}

/**
 * O `double` gravado é o espelho EXATO destes centavos?
 *
 * A pergunta é diferente de "os centavos batem": um documento pode ter o
 * inteiro certo e o `double` com resíduo de `FieldValue.increment`, e é o
 * `double` que o app lê hoje. O rebuild corrige os dois.
 */
function mirrorsCents(value: unknown, cents: number): boolean {
    return typeof value === "number" && Number.isFinite(value) && value === fromCents(cents);
}

export interface PeriodIdParts {
    year: number;
    month: number | null;
    week: number | null;
    runtimeType: string;
}

/** Interpreta o id de um `period_summaries` (`YYYY`, `YYYY-MM` ou `YYYY-Www`). */
export function parsePeriodId(docId: string): PeriodIdParts | null {
    const week = /^(\d{4})-W(\d{2})$/.exec(docId);
    if (week) {
        return { year: Number(week[1]), month: null, week: Number(week[2]), runtimeType: "week" };
    }

    const month = /^(\d{4})-(\d{2})$/.exec(docId);
    if (month) {
        return { year: Number(month[1]), month: Number(month[2]), week: null, runtimeType: "month" };
    }

    const year = /^(\d{4})$/.exec(docId);
    if (year) {
        return { year: Number(year[1]), month: null, week: null, runtimeType: "year" };
    }

    return null;
}

/**
 * Copia para o estado-alvo o `generalPlannedAmount` que já está gravado.
 *
 * Esse campo vem de `category_planning` através de uma janela que só olha para
 * a frente, então recalculá-lo apagaria o histórico. Categorias cujo planejado
 * gravado é zero NÃO são copiadas: se nada mais as sustenta, elas somem do
 * documento como residual.
 */
export function preserveGeneralPlanned(target: TargetState, existing: ExistingDoc<ExistingSummaryData>[]): void {
    for (const doc of existing) {
        const parts = parsePeriodId(doc.id);
        if (!parts) continue;

        const categories = doc.data?.categories ?? {};

        for (const [categoryId, totals] of Object.entries(categories)) {
            const generalCents = storedCents(totals?.generalPlannedAmount ?? 0, totals?.generalPlannedAmountCents);
            if (generalCents === 0) continue;

            let summary = target.summaries.get(doc.id);
            if (!summary) {
                summary = {
                    year: parts.year,
                    month: parts.month,
                    week: parts.week,
                    runtimeType: parts.runtimeType,
                    categories: {},
                };
                target.summaries.set(doc.id, summary);
            }

            const bucket = summary.categories[categoryId] ?? {
                generalPlannedAmount: 0,
                specificPlannedAmount: 0,
                actualAmount: 0,
                generalPlannedAmountCents: 0,
                specificPlannedAmountCents: 0,
                actualAmountCents: 0,
            };
            // F1.10 — preservar é preservar a QUANTIA, não o `double` sujo: o
            // inteiro é copiado e o espelho é reescrito a partir dele.
            bucket.generalPlannedAmountCents = generalCents;
            bucket.generalPlannedAmount = fromCents(generalCents);
            summary.categories[categoryId] = bucket;
        }
    }
}

export interface SummaryComparison {
    equal: boolean;
    /** Difere apenas por categorias zeradas que sairiam do documento. */
    onlyZeroedCategoriesRemoved: boolean;
    generalPlannedChanged: boolean;
}

/** Compara o documento gravado com o alvo, separando o que é residual. */
export function compareSummary(current: ExistingDoc<ExistingSummaryData>, expected: TargetSummaryDoc): SummaryComparison {
    const data = current.data || {};
    let different = false;
    let generalPlannedChanged = false;
    let zeroedCategoriesRemoved = false;

    if ((data.year ?? null) !== expected.year) different = true;
    if ((data.month ?? null) !== expected.month) different = true;
    if ((data.week ?? null) !== expected.week) different = true;
    if ((data.runtimeType ?? null) !== expected.runtimeType) different = true;

    const currentCategories = data.categories ?? {};

    for (const [categoryId, expectedTotals] of Object.entries(expected.categories)) {
        const currentTotals = currentCategories[categoryId];

        if (!currentTotals) {
            different = true;
            if (expectedTotals.generalPlannedAmountCents !== 0) generalPlannedChanged = true;
            continue;
        }

        // F1.10 — compara o INTEIRO e, em seguida, se o `double` gravado é o
        // espelho exato dele. As duas perguntas: a quantia está certa? e o
        // campo que o app lê hoje está certo?
        const generalCents = storedCents(currentTotals.generalPlannedAmount ?? 0, currentTotals.generalPlannedAmountCents);
        const specificCents = storedCents(currentTotals.specificPlannedAmount ?? 0, currentTotals.specificPlannedAmountCents);
        const actualCents = storedCents(currentTotals.actualAmount ?? 0, currentTotals.actualAmountCents);

        if (generalCents !== expectedTotals.generalPlannedAmountCents ||
            !mirrorsCents(currentTotals.generalPlannedAmount ?? 0, expectedTotals.generalPlannedAmountCents)) {
            different = true;
            generalPlannedChanged = generalCents !== expectedTotals.generalPlannedAmountCents;
        }
        if (specificCents !== expectedTotals.specificPlannedAmountCents ||
            !mirrorsCents(currentTotals.specificPlannedAmount ?? 0, expectedTotals.specificPlannedAmountCents)) {
            different = true;
        }
        if (actualCents !== expectedTotals.actualAmountCents ||
            !mirrorsCents(currentTotals.actualAmount ?? 0, expectedTotals.actualAmountCents)) {
            different = true;
        }
    }

    for (const [categoryId, currentTotals] of Object.entries(currentCategories)) {
        if (expected.categories[categoryId]) continue;

        const isZeroed = isZeroedTotals(currentTotals);

        if (isZeroed) {
            zeroedCategoriesRemoved = true;
        }
        else {
            different = true;
            if (storedCents(currentTotals?.generalPlannedAmount ?? 0, currentTotals?.generalPlannedAmountCents) !== 0) {
                generalPlannedChanged = true;
            }
        }
    }

    return {
        equal: !different && !zeroedCategoriesRemoved,
        onlyZeroedCategoriesRemoved: !different && zeroedCategoriesRemoved,
        generalPlannedChanged,
    };
}

/** Os três totais de uma categoria estão zerados? (em centavos inteiros). */
function isZeroedTotals(totals: Partial<SummaryCategoryTotals> | undefined): boolean {
    return storedCents(totals?.generalPlannedAmount ?? 0, totals?.generalPlannedAmountCents) === 0 &&
        storedCents(totals?.specificPlannedAmount ?? 0, totals?.specificPlannedAmountCents) === 0 &&
        storedCents(totals?.actualAmount ?? 0, totals?.actualAmountCents) === 0;
}

/** `true` se todas as categorias do documento estão zeradas. */
function isZeroedSummary(doc: ExistingDoc<ExistingSummaryData>): boolean {
    return Object.values(doc.data?.categories ?? {}).every(isZeroedTotals);
}

