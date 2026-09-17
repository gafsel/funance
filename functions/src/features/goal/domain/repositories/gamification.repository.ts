import { CategoryPlanningModel } from "../../../finance/domain/models/finance.models";
import { RawFirestoreDate } from "../../../../core/utils/firestore.utils";
import { MissionParams, WeeklyMissionType } from "../models/mission_catalog";
import { BadgeAudience, WorkspaceAudience } from "../models/audience.model";

/**
 * `WeeklyMissionType` mora no CATÁLOGO (`domain/models/mission_catalog.ts`),
 * junto dos templates que o definem, e é reexportado aqui para não quebrar os
 * quinze importadores que já o pegavam desta interface.
 */
export type { WeeklyMissionType };

/**
 * Linha achatada de um period_summary: uma entrada do mapa `categories` do
 * documento mensal, já com o join em `workspaces/{wid}/categories` feito
 * (categorias `isDeleted` são omitidas). Há um único documento por mês.
 */
export interface PeriodSummaryRow {
    categoryId: string;
    type: string;
    allocation?: string;
    /**
     * Categoria de sistema (saldo inicial, virtuais de transferência). Não
     * representa uma escolha de consumo do usuário e é ignorada pelas
     * avaliações de badge.
     */
    isSystem: boolean;
    actualAmount: number;
    generalPlannedAmount: number;
    specificPlannedAmount: number;
}

/**
 * Uma linha do `period_summaries` SEMANAL (`{YYYY-Www}`), já com o join em
 * `categories`. É a fonte do XP semanal de F2.3 e das missões corporativas de
 * margem e receita.
 *
 * **Os dois "planejados" são coisas diferentes, e confundi-los custou caro.**
 *
 * - `generalPlannedAmount` é o LIMITE da categoria (`category_planning`)
 *   rateado no período (F1.5). É um teto de DESPESA: uma categoria de receita
 *   normalmente tem zero aqui, porque ninguém põe "limite" numa receita.
 * - `specificPlannedAmount` é a soma das PARCELAS PROJETADAS que caem no
 *   período — é onde mora a receita PREVISTA (a nota a receber agendada por
 *   `dueDate`) e também a despesa já agendada.
 *
 * A primeira versão das missões corporativas leu só o `general` para saber a
 * receita prevista da semana, e em produção (workspace a70134c1, 2026-W37) a
 * categoria "Serviços" tinha `generalPlanned = 0`, `specificPlanned = 15850` e
 * `actual = 3850`: a receita prevista existia e o servidor via zero. A missão
 * de receita nunca avaliava e a de margem concluía de graça. Por isso os três
 * totais viajam aqui — e em CENTAVOS, que é a fonte da verdade (F1.10).
 */
export interface WeeklySummaryRow {
    categoryId: string;
    type: string;
    isSystem: boolean;
    actualAmount: number;
    generalPlannedAmount: number;
    /** Parcelas projetadas do período. É aqui que mora a receita PREVISTA. */
    specificPlannedAmount: number;
    /** F1.10 — os mesmos totais em centavos inteiros. São eles que mandam. */
    actualAmountCents: number;
    generalPlannedAmountCents: number;
    specificPlannedAmountCents: number;
}

/**
 * F2.3 — os streaks semanais do workspace.
 *
 * `weeklyStreaks` era (e CONTINUA SENDO) um número: a sequência de semanas com
 * todas as missões concluídas. Com o streak de PLANO (semanas seguidas
 * fechando dentro dos limites) passaram a ser dois, e o novo campo `streaks`
 * carrega os dois num mapa.
 *
 * **Por que não transformar `weeklyStreaks` num mapa.** O app instalado
 * desserializa esse campo como número (`workspace_model.g.dart`: `as num?`).
 * Trocar o tipo faria toda build em campo lançar `TypeError` ao ler o
 * workspace — e o cron semanal escreve nesse campo em TODOS os workspaces, de
 * modo que a quebra chegaria a todo mundo na segunda-feira seguinte ao deploy,
 * sem nenhuma ação do usuário. Um campo novo ao lado não quebra ninguém: o app
 * antigo o ignora.
 *
 * Os dois são escritos na MESMA transação e `weeklyStreaks === streaks.missions`
 * é invariante. O contrato novo para o app é `streaks.plan`.
 */
export interface WorkspaceStreaks {
    /** Semanas consecutivas com TODAS as missões semanais concluídas. */
    missions: number;
    /** Semanas consecutivas fechando TODAS as categorias com limite dentro do limite. */
    plan: number;
}

/**
 * Lê os streaks do documento do workspace, tolerando as duas gerações:
 * `streaks` (mapa, quando existe) e o `weeklyStreaks` numérico, que é a única
 * fonte de `missions` num workspace que ainda não passou pelo cron novo.
 */
export function readWorkspaceStreaks(workspaceData: WorkspaceStreaksSource | null | undefined): WorkspaceStreaks {
    const pick = (value: unknown) =>
        typeof value === "number" && Number.isFinite(value) ? Math.max(0, Math.trunc(value)) : 0;

    const map = workspaceData?.streaks;
    if (map && typeof map === "object") {
        return { missions: pick(map.missions), plan: pick(map.plan) };
    }

    // Sem o mapa, `missions` vem do campo legado e o plano começa em zero.
    return { missions: pick(workspaceData?.weeklyStreaks), plan: 0 };
}

/**
 * O mínimo de que `readWorkspaceStreaks` precisa: as DUAS gerações do campo.
 *
 * Os dois são opcionais e podem vir sujos (`null`, string) de um documento
 * legado — é por isso que a função normaliza em vez de confiar no tipo.
 */
export interface WorkspaceStreaksSource {
    /**
     * Os valores são `unknown` DE PROPÓSITO. Este é o documento cru: um
     * workspace antigo pode ter `weeklyStreaks` como string e um mapa
     * `streaks` com `plan: null`. Prometer `number` aqui seria mentir
     * justamente para a função que existe para limpar essa sujeira.
     */
    streaks?: { missions?: unknown, plan?: unknown } | null;
    weeklyStreaks?: unknown;
}

/** Famílias de XP concedido UMA ÚNICA VEZ por categoria (`xpAwardedFor.<grupo>.<id>`). */
export type XpOnceGroup = "planning" | "recurring";

/**
 * O documento do workspace do ponto de vista da GAMIFICAÇÃO.
 *
 * Tudo é opcional porque tudo é acumulado ao longo da vida do workspace: um
 * workspace recém-criado não tem `xp`, nem badge, nem streak. O tipo é
 * deliberadamente MENOR que `WorkspaceModel` — a gamificação não lê `members`
 * nem `createdAt`, e declará-los aqui convidaria alguém a usá-los sem que o
 * repositório converta os `Timestamp`.
 */
export interface GamificationWorkspace extends WorkspaceStreaksSource {
    id: string;
    /** `personal` | `business`. Ausente em documento legado. */
    type?: string;
    xp?: number;
    level?: number;
    /** `badgeId` -> instante ISO do desbloqueio. */
    unlockedBadges?: Record<string, string>;
    /** Marcadores de XP único: grupo -> chave -> instante ISO. Ver `awardXpOnce`. */
    xpAwardedFor?: Partial<Record<XpOnceGroup, Record<string, string>>>;
    onboardingCompleted?: boolean;
}

/**
 * Uma META como ela é LIDA pela gamificação: o documento CRU, sem conversão de
 * datas.
 *
 * Não é `GoalModel` de propósito. O `GoalModel` promete `startDate: Date` e
 * `isDeleted: boolean`, e nada disso é verdade no documento cru — `deadline`
 * chega como `Timestamp` e um documento legado pode não ter `isDeleted`. Quem
 * precisa da data usa `toGoalDate`, que trata as três formas.
 */
export interface GamificationGoal {
    /**
     * Opcional porque o id NÃO está no documento: ele é o id do doc. O
     * repositório o acrescenta; o gatilho, que já tem a meta na mão, passa o
     * documento cru como veio.
     */
    id?: string;
    name?: string;
    isDeleted?: boolean;
    /**
     * Desfecho gravado pelo servidor. `null`/ausente = em andamento.
     * `string`, e não `GoalOutcome`: o documento é cru e quem valida o valor é
     * `resolveGoalOutcome`.
     */
    outcome?: string | null;
    /** Instante do desfecho `success`, carimbado pelo servidor. */
    completedAt?: RawFirestoreDate | null;
    /** Instante do desfecho `failed`, carimbado pelo servidor. */
    failedAt?: RawFirestoreDate | null;
    deadline?: RawFirestoreDate | null;
    startDate?: RawFirestoreDate | null;
    currentAmount?: number;
    targetAmount?: number;
    /** Discriminador da union freezed do cliente (`payDebt`, `saveMoney`, ...). */
    runtimeType?: string;
    type?: string;
    accountId?: string;
    accountIdTarget?: string;
    category?: { id?: string } | null;
    categoryId?: string;
}

/**
 * Uma PARCELA como ela é LIDA pela gamificação: o documento CRU.
 *
 * Mesma razão de `GamificationGoal` — `paidDate` e `dueDate` chegam como
 * `Timestamp`, e `InstallmentModel` promete `Date`.
 */
export interface GamificationInstallment {
    /** Ver `GamificationGoal.id`: o id mora no documento, não nos campos. */
    id?: string;
    status?: string;
    type?: string;
    amount?: number;
    paidAmount?: number;
    referenceAmount?: number;
    dueDate?: RawFirestoreDate | null;
    paidDate?: RawFirestoreDate | null;
    category?: { id?: string; name?: string } | null;
    accountIds?: string[];
    /**
     * Parcela de FATURA de cartão. É o que separa "a empresa pagou a fatura no
     * prazo" de "a empresa pagou uma compra qualquer" na regra
     * `invoice_paid_on_time`.
     */
    isInvoice?: boolean;
}

export type WeeklyMissionStatus = "pending" | "completed";

/**
 * O documento de `workspaces/{wid}/weekly_missions/{weekId}_{type}` como ele é
 * GRAVADO na criação — aqui tudo é obrigatório, porque quem cria é o servidor
 * e ele preenche tudo.
 */
export interface WeeklyMissionWrite {
    /** Igual ao `type`. Redundante no documento, mas o app o lê. */
    id: WeeklyMissionType;
    /**
     * Texto da missão em PORTUGUÊS — o template escolhido, opcionalmente
     * temperado pela IA (ver `validateWeeklyMissionNames`). Continua
     * obrigatório porque a build instalada só sabe ler o texto pronto; o
     * caminho novo é `nameKey` + `params`.
     */
    name: string;
    type: WeeklyMissionType;
    status: WeeklyMissionStatus;
    rewardXp: number;
    progress: number;
    target: number;
    /** `YYYY-Www`. É por ele que o cron avalia a semana fechada. */
    weekId: string;
    /** ISO-8601. */
    createdAt: string;
    /** Chave do template do catálogo (`mission_catalog.ts`). */
    templateKey: string;
    /** `personal` | `business` — a audiência para a qual a missão foi gerada. */
    workspaceType: WorkspaceAudience;
    /** Rota interna do CTA da missão. Ver `MISSION_ACTION_PATHS`. */
    actionPath: string;
    /** Chave de i18n do nome, para o app traduzir sem depender do `name`. */
    nameKey: string;
    /**
     * Valores dos placeholders do nome. Ausente quando o template não tem
     * placeholder — `ignoreUndefinedProperties` está DESLIGADO, então a chave
     * some via `stripUndefined` em vez de derrubar a escrita.
     */
    params?: MissionParams;
}

/** O que uma atualização de progresso pode mexer. */
export type WeeklyMissionUpdate = Partial<Pick<
    WeeklyMissionWrite,
    "progress" | "status" | "name" | "target" | "rewardXp" |
    "templateKey" | "workspaceType" | "actionPath" | "nameKey" | "params"
>>;

/**
 * O documento como ele é LIDO. Tudo opcional: a missão pode ter sido gravada
 * por uma versão anterior do servidor, e o chamador já aplica os padrões
 * (`target || 3`, `rewardXp || 150`) que existem desde antes deste pacote.
 */
export interface WeeklyMissionDocument extends Partial<WeeklyMissionWrite> {
    /** Carimbo da conclusão (`serverTimestamp`), só na missão concluída. */
    completedAt?: RawFirestoreDate | null;
}

export interface IGamificationRepository {
    getWorkspaceById(workspaceId: string): Promise<GamificationWorkspace | null>;
    addXp(workspaceId: string, amount: number, reason: string): Promise<void>;
    /**
     * `audience` é a audiência do BADGE (`personal` | `business` | `both`). A
     * checagem contra `workspaces.type` acontece DENTRO da transação que já lê
     * o documento do workspace — assim o filtro por tipo não custa nenhuma
     * leitura a mais, e um badge que não se aplica àquele tipo simplesmente
     * não é concedido (devolve `false`, como um badge já desbloqueado).
     */
    unlockBadge(
        workspaceId: string,
        badgeId: string,
        xpReward: number,
        badgeName: string,
        audience: BadgeAudience
    ): Promise<boolean>;
    getAccountsCount(workspaceId: string): Promise<number>;
    hasPaidTransaction(workspaceId: string): Promise<boolean>;
    /** Planejamentos por categoria do workspace (documento cru + id). */
    getCategoryPlannings(workspaceId: string): Promise<CategoryPlanningModel[]>;
    getCompletedReconciliationsCount(workspaceId: string, limit?: number): Promise<number>;
    getGoals(workspaceId: string): Promise<GamificationGoal[]>;
    /** Parcelas pagas/liquidadas com `paidDate` no intervalo (inclusive). */
    getPaidInstallmentsInPeriod(workspaceId: string, start: Date, end: Date): Promise<GamificationInstallment[]>;
    getWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType): Promise<WeeklyMissionDocument | null>;
    /** `create`: uma missão já existente NÃO é sobrescrita. */
    createWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType, data: WeeklyMissionWrite): Promise<void>;
    updateWeeklyMission(workspaceId: string, weekId: string, type: WeeklyMissionType, data: WeeklyMissionUpdate): Promise<void>;
    getWeeklyMissionsByWeek(workspaceId: string, weekId: string): Promise<WeeklyMissionDocument[]>;
    /**
     * Grava `streaks` (mapa) e `weeklyStreaks` (número, = `missions`) na MESMA
     * transação, preservando as chaves não informadas. Os dois campos nunca
     * podem divergir: o app antigo lê o número e o novo lê o mapa.
     */
    updateWorkspaceStreaks(workspaceId: string, streaks: Partial<WorkspaceStreaks>): Promise<void>;
    /** Linhas do `period_summaries` da SEMANA (`{YYYY-Www}`), com join em categories. */
    getWeeklySummaryRows(workspaceId: string, weekId: string): Promise<WeeklySummaryRow[]>;
    /**
     * Concede `xp` UMA ÚNICA VEZ por `(grupo, chave)`, gravando o marcador
     * `xpAwardedFor.<grupo>.<chave>` e o XP na MESMA transação. Devolve `false`
     * quando o marcador já existia (nada foi concedido).
     */
    awardXpOnce(
        workspaceId: string,
        group: XpOnceGroup,
        key: string,
        xp: number,
        reason: string
    ): Promise<boolean>;
    /** Linhas (categoria x mês) do period_summary, já achatadas e com join em categories. */
    getPeriodSummaries(workspaceId: string, year: number, month: number): Promise<PeriodSummaryRow[]>;
    getCategoriesCount(workspaceId: string): Promise<number>;
    getPaidInstallments(workspaceId: string): Promise<GamificationInstallment[]>;
    getPaidInstallmentsSince(workspaceId: string, since: Date): Promise<GamificationInstallment[]>;
    /**
     * Marca a missão como concluída e concede o XP na MESMA transação.
     * Retorna false (sem conceder nada) se a missão já estava concluída.
     */
    completeMissionAndAwardXp(
        workspaceId: string,
        weekId: string,
        type: WeeklyMissionType,
        progress: number,
        rewardXp: number,
        reason: string
    ): Promise<boolean>;
    /** Contagem (aggregate count) de installments pagas/settled do workspace. */
    getPaidInstallmentsCount(workspaceId: string): Promise<number>;
    /** Contagem (aggregate count) de missões semanais concluídas do workspace. */
    getCompletedMissionsCount(workspaceId: string): Promise<number>;
    /** IDs das contas do tipo cartão de crédito (não deletadas). */
    getCreditCardAccountIds(workspaceId: string): Promise<string[]>;
    /** Existe installment pendente no período vinculada a alguma das contas? */
    hasPendingInstallmentsForAccounts(
        workspaceId: string,
        accountIds: string[],
        start: Date,
        end: Date
    ): Promise<boolean>;
    /**
     * Quantos EXTRATOS foram conciliados com sucesso no período — documentos
     * de `reconciliations` com `status: completed` e `createdAt` na janela.
     *
     * É a regra `reconciled_statements` das missões de empresa, e é diferente
     * de `getCompletedReconciliationsCount` (que conta a vida inteira do
     * workspace, para os badges).
     */
    getCompletedReconciliationsInPeriod(workspaceId: string, start: Date, end: Date): Promise<number>;
    /**
     * Lançamentos automáticos numa JANELA de data.
     *
     * `startIso`/`endIso` são carimbos de RELÓGIO LOCAL
     * (`YYYY-MM-DDTHH:mm:ss.SSS`, sem fuso), comparados como STRING, porque é
     * exatamente assim que o app grava o campo: `AutomaticTransactionModel.date`
     * é um `DateTime` serializado pelo `toJson` do freezed, sem conversor, e
     * sai no horário local sem sufixo. Num formato de largura fixa a ordem
     * lexicográfica é a ordem cronológica, então o Firestore consegue filtrar.
     *
     * **Um `where` por `Timestamp` devolveria ZERO documentos, em silêncio** —
     * o Firestore ordena por TIPO antes de ordenar por valor, e Timestamp e
     * String são tipos diferentes. Foi o que motivou a primeira versão a ler a
     * coleção inteira com `limit(500)` e filtrar em memória; numa caixa de
     * entrada com 532 documentos (ordenados por UUID, porque não havia
     * `orderBy`), os 12 da semana simplesmente não entravam na página, a
     * missão ficava em zero para sempre e cada evento custava 500 leituras.
     *
     * O chamador ainda confere a janela em memória: a folga que ele pede nas
     * bordas cobre o documento legado gravado em UTC (com sufixo `Z`), que a
     * comparação de string sozinha classificaria com três horas de erro.
     */
    getAutomaticTransactions(
        workspaceId: string,
        startIso: string,
        endIso: string,
        limit: number
    ): Promise<AutomaticTransactionRow[]>;
}

/**
 * Um lançamento automático como a gamificação o lê. Só os campos que decidem
 * se ele já foi TRATADO pela equipe — a sugestão da IA (`suggestedCategory`,
 * e o `categoryId` que ela grava sozinha) de propósito não está aqui: se ela
 * contasse, a missão fecharia sem ninguém fazer nada.
 */
export interface AutomaticTransactionRow {
    id: string;
    /** Timestamp ou string ISO — o app grava string. Ver `getAutomaticTransactions`. */
    date?: RawFirestoreDate | null;
    /** `true` quando virou lançamento de verdade (com categoria escolhida). */
    isConsolidated?: boolean;
    /** `true` quando foi descartado conscientemente. */
    isIgnored?: boolean;
}
