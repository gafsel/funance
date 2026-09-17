import { CategoryModel } from "../../../workspace/domain/models/category.model";
import { fromCents, resolveCents } from "../../../../core/utils/money";

/**
 * F1.10 — DINHEIRO EM CENTAVOS: o mapa de cada campo monetário `double` para o
 * campo inteiro paralelo, por coleção.
 *
 * Esta é a lista ÚNICA. Ela é consumida pelo passo derivado dos gatilhos (que
 * completa os `*Cents` do que o CLIENTE escreve), pelo script
 * `migrate_money_cents` e pelo verificador — três lugares que, se tivessem
 * cada um a sua cópia, divergiriam no primeiro campo novo.
 *
 * `null` do lado do `double` (um `paidAmount` ausente) não gera campo inteiro:
 * ausente continua significando ausente, e não "zero".
 */
export const MONEY_CENTS_FIELDS = {
    orders: { amount: "amountCents" },
    installments: {
        amount: "amountCents",
        paidAmount: "paidAmountCents",
        referenceAmount: "referenceAmountCents",
    },
    accounts: { initialBalance: "initialBalanceCents", limit: "limitCents" },
    goals: { targetAmount: "targetAmountCents", currentAmount: "currentAmountCents" },
    category_planning: { amount: "amountCents", appliedAmount: "appliedAmountCents" },
} as const satisfies Record<string, Record<string, string>>;

/** Coleções cobertas pelo passo derivado e pela migração de centavos. */
export type MoneyCentsCollection = keyof typeof MONEY_CENTS_FIELDS;

/** Os três totais de `period_summaries`, no mesmo formato. */
export const SUMMARY_CENTS_FIELDS = {
    generalPlannedAmount: "generalPlannedAmountCents",
    specificPlannedAmount: "specificPlannedAmountCents",
    actualAmount: "actualAmountCents",
} as const;

/** `delta`/`balance` do saldo diário, no mesmo formato. */
export const BALANCE_CENTS_FIELDS = {
    delta: "deltaCents",
    balance: "balanceCents",
} as const;

export enum OrderStatus {
    active = "active",
    cancelled = "cancelled",
    settled = "settled",
}

export enum OrderType {
    expense = "expense",
    income = "income",
    transfer = "transfer",
}

export enum InstallmentType {
    single = "single",
    installment = "installment",
    recurring = "recurring",
}

export interface OrderModel {
    id: string;
    amount: number;
    /** F1.10 — `amount` em CENTAVOS INTEIROS. Ver `MONEY_CENTS_FIELDS`. */
    amountCents?: number;
    dueDay: number;
    description: string;
    startMonth: string; // YYYY-MM
    endMonth?: string; // YYYY-MM
    installmentCount?: number;
    installmentType: InstallmentType;
    status: OrderStatus;
    type: OrderType;
    installmentCreationStatus?: InstallmentStatus;
    lastGeneratedDueDate?: Date;
    accounts?: Record<string, "debt" | "credit">;
    accountIds: string[];
    category?: CategoryModel;
    isInvoice?: boolean;
    /** Só em order de FATURA — ver `INVOICE_CYCLE_FIELDS`. */
    cycleStart?: Date;
    cycleEnd?: Date;
    closingDate?: Date;
}

export enum InstallmentStatus {
    pending = "pending",
    paid = "paid",
    settled = "settled",
    removed = "removed",
}

export enum ReplicationCascade {
    none = "none",
    all = "all",
    future = "future",
}

export interface InstallmentModel {
    id: string;
    orderId: string;
    amount: number;
    /** F1.10 — `amount` em CENTAVOS INTEIROS. Ver `MONEY_CENTS_FIELDS`. */
    amountCents?: number;
    dueDate: Date;
    description: string;
    paidAmount?: number;
    /** F1.10 — `paidAmount` em CENTAVOS INTEIROS. */
    paidAmountCents?: number;
    paidDate?: Date;
    installmentNumber?: number;
    installmentCount?: number;
    installmentType: InstallmentType;
    status: InstallmentStatus;
    type: OrderType;
    accounts?: Record<string, "debt" | "credit">;
    accountIds: string[];
    category?: CategoryModel;
    replicationCascade?: ReplicationCascade;
    xp?: number;
    referenceDate: Date;
    referenceAmount: number;
    /** F1.10 — `referenceAmount` em CENTAVOS INTEIROS. */
    referenceAmountCents?: number;
    isInvoice?: boolean;
    /**
     * F2.3 — por que esta parcela rendeu ZERO XP.
     *
     * `calculateXp` devolve 0 quando o planejado (`amount`) é zero, que é o
     * caso da parcela que NASCE paga (saldo inicial, compra já liquidada no
     * cartão): o gasto não estava previsto em lugar nenhum. A punição existe
     * desde sempre, mas era MUDA — o usuário via um lançamento sem XP e não
     * tinha como saber o motivo.
     *
     * Este campo dá o motivo ao app, que converte o gasto em limite ou em
     * recorrência (e essa conversão, sim, rende XP). Ausente == a parcela não
     * nasceu paga.
     */
    unplannedReason?: UnplannedReason;
    /** Só em parcela de FATURA — ver `INVOICE_CYCLE_FIELDS`. */
    cycleStart?: Date;
    cycleEnd?: Date;
    closingDate?: Date;
}

/**
 * Motivos de XP zero numa parcela. Hoje só existe um; o tipo é um enum de
 * propósito, porque o app faz `switch` nele para escolher o texto do nudge e
 * um motivo novo não pode chegar como string solta.
 */
export enum UnplannedReason {
    /**
     * A parcela nasceu paga/liquidada, então `syncInstallments` zerou o
     * planejado de propósito para a cobrança contar como NÃO planejada.
     */
    bornPaid = "born_paid",
}

/**
 * Motivo do XP zero de uma parcela paga — ou `null` quando ela foi planejada.
 *
 * A REGRA É A MESMA de `FinanceService.calculateXp`: planejado (`amount`) zero
 * vale zero XP. Ela vive aqui, ao lado do enum, para que o teste possa
 * exercitá-la sem montar o serviço inteiro.
 *
 * A FATURA fica de fora. O valor dela é a soma das compras do ciclo, mantida
 * pelo servidor, e não um planejamento que o usuário deixou de fazer: marcar
 * uma fatura como "gasto não planejado" convidaria o app a pedir um limite
 * para algo que já é a consequência de outros lançamentos.
 */
export function resolveUnplannedReason(
    installment: Pick<InstallmentModel, "amount" | "isInvoice">
): UnplannedReason | null {
    if (installment.isInvoice === true) return null;
    return installment.amount === 0 ? UnplannedReason.bornPaid : null;
}

/**
 * F1.8 — a janela do ciclo fica GRAVADA na order e na parcela de fatura.
 *
 * Sem isso, a tela de detalhe teria de recalcular o ciclo a partir do
 * vencimento e do dia de fechamento da conta — que é exatamente a regra
 * duplicada (e divergente) que este pacote eliminou. Uma fatura ANTIGA, aberta
 * pelo histórico, também não tem de onde tirar a janela: `nextInvoice` fala só
 * da próxima.
 *
 * Gravar a janela tem um segundo efeito, desejado: ela fica CONGELADA no que
 * valia quando a fatura foi criada. Mudar o dia de fechamento do cartão hoje
 * não reescreve o que uma fatura de três meses atrás continha.
 *
 * Escritos apenas pelo servidor; o cliente não os envia (`includeToJson: false`
 * no modelo Dart).
 */
export const INVOICE_CYCLE_FIELDS = ["cycleStart", "cycleEnd", "closingDate"] as const;

/**
 * Campos derivados/técnicos da parcela: escritos pelo PRÓPRIO servidor em
 * resposta a um evento (o `xp` calculado, a cascata zerada, carimbos de
 * atualização), nunca uma intenção do usuário.
 *
 * Uma escrita que mexe SOMENTE nestes campos é o eco da execução anterior.
 * Mora aqui, no modelo, porque mais de um gatilho observa a coleção
 * `installments` e todos precisam da mesma definição.
 */
export const INSTALLMENT_DERIVED_FIELDS = new Set([
    "xp",
    "replicationCascade",
    "lastUpdate",
    "updatedAt",
    // F2.3: gravado na MESMA escrita do xp, pelo mesmo caminho. Fora daqui,
    // toda parcela que nasce paga dispararia o gatilho inteiro de novo —
    // sumário, meta, saldo, fatura, XP — só para registrar o motivo do zero.
    "unplannedReason",
    // F1.8: a janela do ciclo é do servidor. Sem ela aqui, o backfill que
    // preenche as faturas antigas dispararia o gatilho inteiro — sumário,
    // meta, saldo, XP — para cada fatura da base, tudo com delta zero.
    ...INVOICE_CYCLE_FIELDS,
    // F1.10: os espelhos inteiros. O passo derivado do gatilho completa os
    // `*Cents` da parcela que o CLIENTE gravou; sem eles aqui essa escrita
    // redispararia sumário, meta, saldo, fatura e XP — para cada uma das
    // parcelas da base durante a migração, todas com delta zero.
    ...Object.values(MONEY_CENTS_FIELDS.installments),
]);

/**
 * F1.10 — campos da ORDER escritos pelo próprio servidor como espelho inteiro.
 *
 * A order não tinha guarda por conteúdo: qualquer escrita nela dispara
 * `onOrderWritten`, que reexecuta `syncInstallments` e grava um documento em
 * `orders/{id}/history`. Sem esta lista, completar o `amountCents` de mil
 * orders na migração criaria mil registros de histórico do nada.
 */
export const ORDER_DERIVED_FIELDS = new Set<string>([
    ...Object.values(MONEY_CENTS_FIELDS.orders),
]);

/**
 * F1.10 — campos da META escritos pelo servidor como espelho inteiro.
 *
 * Mesmo motivo: `onGoalWritten` recalcula o progresso e reavalia os badges a
 * cada escrita, e o backfill dos `*Cents` não é uma mudança de meta.
 */
export const GOAL_DERIVED_FIELDS = new Set<string>([
    ...Object.values(MONEY_CENTS_FIELDS.goals),
]);

/**
 * Planejamento por categoria (`workspaces/{wid}/category_planning/{id}`).
 *
 * Os quatro últimos campos são mantidos EXCLUSIVAMENTE pelo servidor (F1.5) e
 * registram o que já foi lançado nos sumários:
 *
 *  - `summarizedUntil` — último mês já sumarizado. `PLANNING_FULLY_SUMMARIZED`
 *    ("9999-12") marca o planejamento que cabe inteiro no horizonte e não tem
 *    mais nada a aplicar;
 *  - `appliedAmount`/`appliedFrom`/`appliedUntil` — o que exatamente foi
 *    aplicado (valor e intervalo), para que uma alteração estorne o que foi
 *    aplicado, e não um chute.
 */
export interface CategoryPlanningModel {
    id: string;
    category: CategoryModel;
    amount: number;
    /** F1.10 — `amount` em CENTAVOS INTEIROS. Ver `MONEY_CENTS_FIELDS`. */
    amountCents?: number;
    startMonth: string; // YYYY-MM
    endMonth: string; // YYYY-MM
    /** LEGADO (pré-F1.5): ninguém grava mais; substituído por `summarizedUntil`. */
    lastSummaryMonth?: string; // YYYY-MM
    summarizedUntil?: string; // YYYY-MM | "9999-12"
    appliedAmount?: number | null;
    /** F1.10 — `appliedAmount` em CENTAVOS INTEIROS. */
    appliedAmountCents?: number | null;
    appliedFrom?: string | null; // YYYY-MM
    appliedUntil?: string | null; // YYYY-MM
}

/**
 * Campos do planejamento escritos pelo PRÓPRIO servidor em resposta a um
 * evento. Uma escrita que mexe só neles é o eco da execução anterior e não
 * pode disparar o gatilho de novo (senão o estorno/reaplicação vira laço).
 */
export const CATEGORY_PLANNING_DERIVED_FIELDS = new Set<string>([
    "summarizedUntil",
    "appliedAmount",
    "appliedFrom",
    "appliedUntil",
    "lastSummaryMonth",
    "lastUpdate",
    "updatedAt",
    // F1.10: o espelho inteiro do valor e do valor aplicado. Sem eles aqui, o
    // passo derivado que completa `amountCents` estornaria e reaplicaria o
    // planejamento inteiro — em laço, que é exatamente o que a guarda evita.
    ...Object.values(MONEY_CENTS_FIELDS.category_planning),
]);

/** Marcadores gravados no planejamento depois de aplicar os impactos. */
export interface CategoryPlanningMarks {
    summarizedUntil: string;
    appliedAmount: number | null;
    /** F1.10 — espelho inteiro de `appliedAmount`. */
    appliedAmountCents: number | null;
    appliedFrom: string | null;
    appliedUntil: string | null;
}

/** Granularidade de um documento de `period_summaries`. */
export enum PeriodSummaryRuntimeType {
    year = "year",
    month = "month",
    week = "week",
}

/**
 * Uma linha do mapa `categories` de um `period_summaries`: os três totais de
 * UMA categoria naquele período.
 *
 * Os três campos são OBRIGATÓRIOS no modelo, embora o documento cru possa não
 * ter algum deles (um sumário que só recebeu `actualDelta` nasce sem
 * `generalPlannedAmount`). Quem lê normaliza — ver `toPeriodSummaryDocument`.
 * Deixá-los opcionais espalharia `?? 0` por todo consumidor e, pior,
 * permitiria que um deles fosse esquecido numa soma.
 */
export interface PeriodSummaryCategoryTotals {
    /** Limite da categoria (`category_planning`) rateado no período. */
    generalPlannedAmount: number;
    /** Soma das parcelas PROJETADAS que caem no período. */
    specificPlannedAmount: number;
    /** Soma do que de fato foi pago/recebido no período. */
    actualAmount: number;
    /**
     * F1.10 — os mesmos três totais em CENTAVOS INTEIROS. São eles a FONTE DA
     * VERDADE; os `double` acima são o espelho `round2`.
     *
     * Opcionais porque a base ainda tem documentos anteriores à migração
     * (`migrate_money_cents`). Quem soma usa `resolveCents(double, cents)`.
     */
    generalPlannedAmountCents?: number;
    specificPlannedAmountCents?: number;
    actualAmountCents?: number;
}

/**
 * O documento REAL de `workspaces/{wid}/period_summaries/{id}`, onde o id é
 * `YYYY`, `YYYY-MM` ou `YYYY-Www`.
 *
 * Há UM documento por período, com um mapa de categorias dentro — e não um
 * documento por categoria, como dizia o modelo antigo (`PeriodSummaryModel`),
 * que não correspondia a nada gravado e por isso nunca foi usado por ninguém.
 *
 * `month` e `week` são `null` (e não ausentes) quando não se aplicam: é assim
 * que o servidor os grava, para que a consulta `where("month", "==", m)`
 * encontre o documento mensal e ignore o anual.
 */
export interface PeriodSummaryDocument {
    /** Id do documento — `YYYY`, `YYYY-MM` ou `YYYY-Www`. */
    id: string;
    year: number;
    /** 1-12 no documento mensal; `null` no anual e no semanal. */
    month: number | null;
    /** Número ISO da semana no documento semanal; `null` nos demais. */
    week: number | null;
    categories: Record<string, PeriodSummaryCategoryTotals>;
    runtimeType: PeriodSummaryRuntimeType;
    /** Carimbo da última escrita. `null` em documento legado sem o campo. */
    lastUpdate: Date | null;
}

/** Número tolerante a campo ausente/sujo em documento legado. */
function summaryNumber(value: unknown): number {
    return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

/**
 * Documento cru -> `PeriodSummaryDocument`, com os totais NORMALIZADOS.
 *
 * Mora no modelo, e não no repositório, porque o job de reconstrução lê a
 * mesma coleção por outro caminho e precisa da mesma leitura.
 */
export function toPeriodSummaryDocument(
    id: string,
    data: Record<string, unknown> | undefined
): PeriodSummaryDocument {
    const rawCategories = (data?.categories ?? {}) as Record<string, Record<string, unknown> | undefined>;
    const categories: Record<string, PeriodSummaryCategoryTotals> = {};

    for (const [categoryId, totals] of Object.entries(rawCategories)) {
        // F1.10 — o INTEIRO manda: onde `*Cents` existe, o `double` entregue ao
        // consumidor é o espelho exato dele. Num documento ainda não migrado o
        // `double` responde sozinho, como sempre respondeu.
        const generalCents = resolveCents(summaryNumber(totals?.generalPlannedAmount), totals?.generalPlannedAmountCents);
        const specificCents = resolveCents(summaryNumber(totals?.specificPlannedAmount), totals?.specificPlannedAmountCents);
        const actualCents = resolveCents(summaryNumber(totals?.actualAmount), totals?.actualAmountCents);

        categories[categoryId] = {
            generalPlannedAmount: fromCents(generalCents),
            specificPlannedAmount: fromCents(specificCents),
            actualAmount: fromCents(actualCents),
            generalPlannedAmountCents: generalCents,
            specificPlannedAmountCents: specificCents,
            actualAmountCents: actualCents,
        };
    }

    const rawRuntimeType = data?.runtimeType;
    const runtimeType = (Object.values(PeriodSummaryRuntimeType) as string[]).includes(rawRuntimeType as string)
        ? rawRuntimeType as PeriodSummaryRuntimeType
        : PeriodSummaryRuntimeType.month;

    const rawLastUpdate = data?.lastUpdate as { toDate?: () => Date } | undefined;

    return {
        id,
        year: summaryNumber(data?.year),
        month: typeof data?.month === "number" ? data.month : null,
        week: typeof data?.week === "number" ? data.week : null,
        categories,
        runtimeType,
        lastUpdate: typeof rawLastUpdate?.toDate === "function" ? rawLastUpdate.toDate() : null,
    };
}

export enum AccountType {
    checking = "checking",
    investment = "investment",
    creditCard = "creditCard",
    debt = "debt",
}

export enum BankLogo {
    none = "none",
    nubank = "nubank",
    inter = "inter",
    itau = "itau",
    bradesco = "bradesco",
    santander = "santander",
    bb = "bb",
    caixa = "caixa",
    c6 = "c6",
    xp = "xp",
    btg = "btg",
    visa = "visa",
    mastercard = "mastercard",
    elo = "elo",
    amex = "amex",
}

/**
 * F1.8 — resumo da PRÓXIMA fatura de um cartão, denormalizado em
 * `accounts/{accountId}.nextInvoice`.
 *
 * Existe para que o cliente **leia** o vencimento, o fechamento e a janela do
 * ciclo em vez de calculá-los: havia duas implementações da mesma regra (TS e
 * Dart) e elas divergiam, de modo que app e servidor podiam apontar para
 * faturas diferentes — o id da order de fatura deriva da data.
 *
 * Escrito **apenas pelo servidor** (`InvoiceSyncService`, via Admin SDK). As
 * security rules negam ao cliente incluir o campo num create ou update da
 * conta.
 */
export interface NextInvoiceModel {
    /** Vencimento da fatura (meio-dia no fuso do produto). */
    dueDate: Date;
    /** Fechamento que gerou esta fatura (00:00 no fuso do produto). */
    closingDate: Date;
    /** Primeira compra que pertence a esta fatura — 00:00, inclusive. */
    cycleStart: Date;
    /** Última compra que pertence a esta fatura — 23:59:59.999, inclusive. */
    cycleEnd: Date;
    /** Valor da fatura em aberto. `0` quando ainda não há nenhuma compra. */
    amount: number;
    /** F1.10 — `amount` em CENTAVOS INTEIROS. */
    amountCents: number;
    /** Id da order de fatura (`invoice-{accountId}-{YYYY-MM-DD}`). */
    orderId: string;
    /** Parcela da fatura, ou `null` enquanto a fatura não existe de fato. */
    installmentId: string | null;
    /** Status da parcela da fatura (sempre `pending` quando não existe). */
    status: InstallmentStatus;
    /** Carimbo da última sincronização. */
    updatedAt?: Date;
}

export interface AccountModel {
    id: string;
    name: string;
    icon: string;
    color: string;
    runtimeType: AccountType;
    isDeleted: boolean;
    initialBalance: number;
    /** F1.10 — `initialBalance` em CENTAVOS INTEIROS. */
    initialBalanceCents?: number;
    initialBalanceDate: Date;
    closingDay?: number;
    dueDay?: number;
    limit?: number;
    /** F1.10 — `limit` em CENTAVOS INTEIROS. */
    limitCents?: number;
    interestRate?: number;
    bankLogo?: BankLogo;
    ownerIds?: string[];
    /** Somente leitura para o cliente — ver `NextInvoiceModel`. */
    nextInvoice?: NextInvoiceModel | null;
}

/**
 * Saldo diário: `accounts/{accountId}/balance/{dateKey}`.
 *
 * O id do documento é SEMPRE igual ao `dateKey` — é assim que o cliente Flutter
 * lê os últimos saldos (`orderBy(documentId, desc)`), e por isso o contrato do
 * id não mudou em F1.4. O que mudou é o significado: o dia agora é o dia de
 * calendário no fuso do produto (antes era UTC) e o documento passou a guardar
 * também o movimento do dia.
 */
export interface AccountBalanceModel {
    id: string; // YYYY-MM-DD (igual ao dateKey)
    /** YYYY-MM-DD no fuso do produto. Ausente nos documentos anteriores a F1.4. */
    dateKey?: string;
    /** Soma dos movimentos DO DIA. Ausente nos documentos anteriores a F1.4. */
    delta?: number;
    /** Saldo acumulado ao FIM do dia. */
    balance: number;
    /**
     * F1.10 — `delta`/`balance` em CENTAVOS INTEIROS. Esta é a FONTE DA VERDADE
     * do saldo: o `double` ao lado é o espelho, e é ele que acumulava erro ao
     * ser somado com `FieldValue.increment` pagamento após pagamento.
     * Ausentes nos documentos anteriores à `migrate_money_cents`.
     */
    deltaCents?: number;
    balanceCents?: number;
    updatedAt: Date;
}

export interface PeriodSummaryUpdateModel {
    year: number;
    month?: number;
    week?: number;
    category: CategoryModel;
    /**
     * F1.10 — os deltas são valores monetários JÁ ARREDONDADOS a duas casas
     * (`round2`) por quem os produziu. O repositório converte cada um em
     * centavos com `toCents`, que é exato justamente porque o valor já é um
     * decimal de duas casas.
     */
    generalPlannedDelta?: number;
    specificPlannedDelta?: number;
    actualDelta?: number;
}


