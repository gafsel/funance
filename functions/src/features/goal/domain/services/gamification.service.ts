import * as logger from "firebase-functions/logger";
import { CategoryType, isSystemCategory } from "../../../workspace/domain/models/category.model";
import { IAIRepository } from "../../../../core/services/ai.service";
import { IIdempotencyService } from "../../../../core/services/idempotency.service";
import { forEachWorkspacePaged } from "../../../../core/utils/cron_runner";
import {
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
    CRON_WORKSPACE_CONCURRENCY,
} from "../../../../core/config/functions.config";
import {
    AutomaticTransactionRow,
    GamificationGoal,
    GamificationInstallment,
    IGamificationRepository,
    WeeklyMissionDocument,
    WeeklyMissionType,
    WeeklyMissionWrite,
    WeeklySummaryRow,
    readWorkspaceStreaks,
} from "../repositories/gamification.repository";
import { CategoryPlanningModel } from "../../../finance/domain/models/finance.models";
import { RawFirestoreDate } from "../../../../core/utils/firestore.utils";
import { GoalType, isAccumulationGoal, isGoalActive, isGoalCompleted, resolveGoalType } from "../models/goal.model";
import { BadgeAudience, resolveAudience } from "../models/audience.model";
import {
    AUDIENCE_FORBIDDEN_TERMS,
    MissionParams,
    MissionProgressRule,
    MissionTemplate,
    WEEKLY_MISSION_TYPES,
    buildMissionName,
    findMissionTemplate,
    selectMissionTemplate,
} from "../models/mission_catalog";
import { WeeklyMissionExpectation } from "../../../../core/services/ai_validation";
import {
    addCalendarDays,
    endOfWeekFromStart,
    getDayIndexInTz,
    getMonthKeyInTz,
    getMonthRangeInTz,
    getWeekId,
    getZonedParts,
    startOfWeekInTz,
} from "./gamification_time.util";

/**
 * Um planning cobre o mês se startMonth <= mês <= endMonth (chaves "YYYY-MM").
 * Plannings sem período definido são considerados sempre ativos.
 */
function planningCoversMonth(planning: Partial<Pick<CategoryPlanningModel, "startMonth" | "endMonth">>, monthKey: string): boolean {
    const start = planning.startMonth || "0000-00";
    const end = planning.endMonth || "9999-12";
    return start <= monthKey && monthKey <= end;
}

/**
 * Converte um campo de data cru do Firestore (Timestamp, string ISO ou Date).
 *
 * É a ÚNICA conversão do módulo: até F1.11 o mesmo `raw?.toDate ? ... : ...`
 * estava copiado em três laços, cada um com um tratamento ligeiramente
 * diferente para o campo ausente.
 */
function toDate(raw: RawFirestoreDate | null | undefined): Date | null {
    if (!raw) {
        return null;
    }
    const timestamp = raw as { toDate?: () => Date };
    const date = typeof timestamp.toDate === "function" ? timestamp.toDate() : new Date(raw as string | number | Date);
    return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * O documento que disparou o evento.
 *
 * Só o ramo de CONCILIAÇÃO lê o conteúdo; os de transação e planejamento
 * releem o estado do workspace e ignoram o documento. Por isso os dois campos
 * são os da conciliação — e opcionais, porque o gatilho também dispara com o
 * documento apagado.
 */
export interface WeeklyMissionEventData {
    status?: string;
    totalTransactionsProcessed?: number;
}

/**
 * De onde veio a oportunidade de avaliar o progresso.
 *
 * Os três primeiros são os gatilhos de documento que já existiam.
 * `weekly_close` é o cron semanal: ele dá uma ÚLTIMA passada na semana que
 * fechou antes de decidir a streak. Sem ele, as regras que leem o
 * `period_summaries` semanal (margem e receita recebida) dependeriam de o
 * último evento da semana ter chegado DEPOIS de o sumário ter sido escrito —
 * uma corrida que a plataforma não promete ganhar.
 */
export type MissionEventType = "transaction" | "reconciliation" | "planning" | "weekly_close";

/**
 * Quais eventos podem MOVER cada regra.
 *
 * É o que impede a avaliação de virar uma bateria de consultas a cada parcela
 * gravada: um evento de conciliação não tem por que reler planejamentos, e um
 * evento de planejamento não tem por que contar extratos.
 */
const RULE_EVENT_SOURCES: Record<MissionProgressRule, MissionEventType[]> = {
    planned_categories: ["transaction", "planning", "weekly_close"],
    days_within_category_limit: ["transaction", "weekly_close"],
    // Só o EVENTO carrega quantos itens o extrato processou — não há como
    // recontá-los depois, nem no fechamento da semana.
    reconciled_statement_items: ["reconciliation"],
    reconciled_statements: ["reconciliation", "weekly_close"],
    // A consolidação de um lançamento automático CRIA uma transação, e é essa
    // escrita que chega aqui como evento.
    categorized_auto_transactions: ["transaction", "weekly_close"],
    invoice_paid_on_time: ["transaction", "weekly_close"],
    weekly_margin_above_plan: ["transaction", "weekly_close"],
    income_received_vs_planned: ["transaction", "weekly_close"],
};

/** Razão do XP, por tipo de missão (vai para o log da transação de XP). */
const MISSION_COMPLETION_REASON: Record<WeeklyMissionType, string> = {
    consistency: "Missão Semanal de Consistência Concluída",
    discipline: "Missão Semanal de Disciplina Concluída",
    organization: "Missão Semanal de Organização Concluída",
};

/**
 * Teto de lançamentos automáticos lidos por avaliação.
 *
 * A coleção é uma caixa de ENTRADA de notificações, não um histórico: o app
 * consolida ou descarta, e o que sobra é pequeno. O teto existe para o caso
 * patológico (um workspace que nunca triou nada) não transformar cada evento
 * de transação numa varredura — a consequência de bater no teto é a missão
 * subcontar, nunca a função estourar.
 */
const AUTOMATIC_TRANSACTIONS_SCAN_LIMIT = 500;

/** Leituras compartilhadas entre as três missões de UMA avaliação. */
interface MissionReads {
    plannings?: Promise<PlanningAggregate>;
    paidInstallments?: Promise<GamificationInstallment[]>;
    weeklySummary?: Promise<WeeklySummaryRow[]>;
    reconciledStatements?: Promise<number>;
    automaticTransactions?: Promise<AutomaticTransactionRow[]>;
}

interface MissionEvaluationContext {
    workspaceId: string;
    weekId: string;
    /** `YYYY-MM` usado para filtrar os planejamentos vigentes. */
    monthKey: string;
    startOfWeek: Date;
    endOfWeek: Date;
    /** Dias da semana JÁ decorridos por completo (0 a 7). */
    elapsedFullDays: number;
    eventType: MissionEventType;
    eventData: WeeklyMissionEventData | null | undefined;
    reads: MissionReads;
    /**
     * Missões que o chamador JÁ leu, por tipo. Os dois chamadores leem
     * `weekly_missions` antes de chamar — um para saber se precisa gerar a
     * semana, o outro para decidir a streak —, e reler os mesmos três
     * documentos custaria três leituras por evento em toda a base. Um tipo
     * ausente aqui é lido sob demanda.
     */
    preloaded?: Partial<Record<WeeklyMissionType, WeeklyMissionDocument | null>>;
}

interface MissionEvaluation {
    progress: number;
    completed: boolean;
}

/** Uma missão já escolhida pelo catálogo, antes de virar documento. */
interface PlannedMission {
    type: WeeklyMissionType;
    template: MissionTemplate;
    params: MissionParams;
    /** Texto do catálogo com os placeholders resolvidos, em português. */
    name: string;
}

/** O que as missões precisam saber sobre os planejamentos do mês. */
interface PlanningAggregate {
    /** Categorias com limite > 0 vigente no mês. */
    plannedCategoriesCount: number;
    /** Nomes das categorias planejadas (contexto do prompt). */
    categoryNames: string[];
    /** A categoria de maior limite, ou `null` se não há nenhuma. */
    topCategory: string | null;
    /** O limite MENSAL dessa categoria. */
    topAmount: number;
}

/**
 * Achata os planejamentos do mês no que as missões medem.
 *
 * Existia em DUAS cópias — uma na geração, outra no avanço do progresso —, e
 * elas divergiam: a da geração contava qualquer planejamento com nome de
 * categoria, a do progresso só os de valor positivo. Uma única função remove a
 * chance de a missão ser criada com um alvo que o avaliador nunca alcança.
 */
function aggregatePlannings(plannings: CategoryPlanningModel[], monthKey: string): PlanningAggregate {
    const result: PlanningAggregate = {
        plannedCategoriesCount: 0,
        categoryNames: [],
        topCategory: null,
        topAmount: 0,
    };

    for (const planning of plannings) {
        if (!planningCoversMonth(planning, monthKey)) continue;
        if (!(planning.amount > 0)) continue;

        result.plannedCategoriesCount++;

        const name = planning.category?.name;
        if (!name) continue;
        result.categoryNames.push(name);
        if (planning.amount > result.topAmount) {
            result.topAmount = planning.amount;
            result.topCategory = name;
        }
    }

    return result;
}

interface WeeklyTotals {
    plannedIncome: number;
    plannedExpense: number;
    actualIncome: number;
    actualExpense: number;
}

/**
 * Totais de receita e despesa da semana, a partir do `period_summaries`
 * semanal. Categorias de SISTEMA (saldo inicial, virtuais de transferência)
 * ficam de fora: elas não são decisão de ninguém e inflariam a margem.
 */
function sumWeeklyTotals(rows: WeeklySummaryRow[]): WeeklyTotals {
    const totals: WeeklyTotals = { plannedIncome: 0, plannedExpense: 0, actualIncome: 0, actualExpense: 0 };
    for (const row of rows) {
        if (row.isSystem) continue;
        if (row.type === CategoryType.income) {
            totals.plannedIncome += row.generalPlannedAmount || 0;
            totals.actualIncome += row.actualAmount || 0;
        }
        else if (row.type === CategoryType.expense) {
            totals.plannedExpense += row.generalPlannedAmount || 0;
            totals.actualExpense += row.actualAmount || 0;
        }
    }
    return totals;
}

/** A forma de longe mais comum: progresso é uma contagem e o alvo é um piso. */
function atLeast(progress: number, target: number): MissionEvaluation {
    return { progress, completed: progress >= target };
}

/** Chave `YYYY-MM-DD` do dia em que o instante cai, no fuso do produto. */
function dayKeyInTz(date: Date): string {
    const parts = getZonedParts(date);
    return `${parts.year}-${String(parts.month).padStart(2, "0")}-${String(parts.day).padStart(2, "0")}`;
}

export function calculateLevel(xp: number): number {
    if (xp <= 0) {
        return 1;
    }
    return Math.floor(Math.log2(xp / 300 + 1)) + 1;
}

/**
 * Categorias do catálogo de badges, publicadas em `config/badges` e usadas
 * pelo app para agrupar as seções da vitrine.
 */
export const BADGE_CATEGORIES = [
    "advanced",
    "first_steps",
    "consistency",
    "savings",
    "goals",
    "team",
] as const;

export type BadgeCategory = typeof BADGE_CATEGORIES[number];

export interface BadgeConfig {
    id: string;
    name: string;
    icon: string;
    /**
     * XP concedido ao desbloquear. **Zero é um valor legítimo**: desde F2.3 os
     * badges de CONTAGEM (5 contas, 100 transações, 10 categorias, número
     * redondo, aniversário do workspace, os `first_*` triviais) continuam
     * existindo como conquista, mas não pagam mais XP.
     *
     * O motivo é o propósito do produto: o jogo tem que premiar PLANEJAR, e
     * esses badges premiavam usar o app. Um usuário que cadastrasse cinco
     * contas e lançasse cem transações desorganizadas subia de nível mais
     * rápido do que quem manteve três limites em dia por dois meses — o placar
     * dizia o contrário do que o produto ensina. O XP que saiu daqui foi para
     * a tabela `XP_SOURCES`, que paga limite, recorrência e semana dentro do
     * plano.
     */
    xpReward: number;
    /** Seção da vitrine. Ver `BADGE_CATEGORIES`. */
    category: BadgeCategory;
    /** Como se ganha o badge, em português. Servido ao app por `config/badges`. */
    description: string;
    /**
     * A quem o badge se aplica. Ausente == `both`, que é o caso da esmagadora
     * maioria: conciliar, planejar, cadastrar conta e concluir meta valem igual
     * numa casa e numa empresa.
     *
     * O recorte existe para os badges ancorados numa regra de finança PESSOAL
     * — a 50-30-20 (essencial/conforto/investimento) e o "poupar X% da renda".
     * Uma empresa não divide faturamento em "conforto", e ver na vitrine uma
     * conquista que ela nunca pode alcançar é o mesmo defeito da missão
     * "Reduzir gastos com alimentação" num workspace de empresa.
     *
     * Um badge fora da audiência não é avaliado nem concedido (o filtro mora na
     * transação de `unlockBadge`) e viaja no catálogo com a marcação, para o
     * app não desenhá-lo.
     */
    audience?: BadgeAudience;
}

export const BADGES: Record<string, BadgeConfig> = {
    first_step: {
        id: "first_step", name: "Primeiro Passo", icon: "rocket_launch", xpReward: 100, category: "advanced",
        description: "O workspace é criado e o onboarding é concluído com sucesso.",
    },
    first_account: {
        id: "first_account", name: "Primeira Conta", icon: "account_balance", xpReward: 150, category: "advanced",
        description: "A primeira conta bancária ou cartão é cadastrado no workspace.",
    },
    first_transaction: {
        id: "first_transaction", name: "Ponto de Partida", icon: "add_circle", xpReward: 150, category: "advanced",
        description: "A primeira transação real (installment) é registrada com status paid.",
    },
    planner: {
        id: "planner", name: "Planejador Estrategista", icon: "assignment", xpReward: 200, category: "advanced",
        description: "Limites de planejamento são criados para pelo menos 5 categorias.",
    },
    reconcile_junior: {
        id: "reconcile_junior", name: "Conciliador Júnior", icon: "point_of_sale", xpReward: 300, category: "advanced",
        description: "A primeira conciliação bancária bem-sucedida é concluída (pelo menos 1 match confirmado).",
    },
    cash_detective: {
        id: "cash_detective", name: "Detetive de Caixa", icon: "fact_check", xpReward: 500, category: "advanced",
        description: "Conciliação completa de um arquivo de extrato contendo pelo menos 10 transações.",
    },
    reconcile_master: {
        id: "reconcile_master", name: "Mestre da Conciliação", icon: "workspace_premium", xpReward: 1000, category: "advanced",
        description: "O workspace acumula 10 conciliações de extratos concluídas com sucesso.",
    },
    zero_friction: {
        id: "zero_friction", name: "Atrito Zero", icon: "bolt", xpReward: 800, category: "advanced",
        description: "Conciliar um extrato mensal inteiro sem necessitar criar lançamentos manuais extras.",
    },
    savings_seed: {
        id: "savings_seed", name: "Semente de Poupança", icon: "savings", xpReward: 500, category: "advanced",
        description: "A primeira meta (goal) cadastrada no workspace atinge 100% de progresso.",
    },
    goal_bronze: {
        id: "goal_bronze", name: "Colecionador de Metas", icon: "military_tech", xpReward: 1000, category: "advanced",
        description: "O workspace conclui com sucesso 3 metas financeiras diferentes.",
    },
    goal_silver: {
        id: "goal_silver", name: "Foco Inabalável", icon: "stars", xpReward: 2000, category: "advanced",
        description: "O workspace conclui com sucesso 5 metas financeiras diferentes.",
    },
    under_control: {
        id: "under_control", name: "Tudo Sob Controle", icon: "check_circle", xpReward: 1500, category: "advanced",
        description: "Fechar o mês sem estourar nenhuma categoria planejada na regra 50-30-20.",
        audience: "personal",
    },
    golden_rule: {
        id: "golden_rule", name: "Regra de Ouro", icon: "pie_chart", xpReward: 1200, category: "advanced",
        description: "Alocar limites em todos os 3 pools (Essencial, Conforto, Investimento) no mesmo mês.",
        audience: "personal",
    },
    future_focus: {
        id: "future_focus", name: "Visão de Futuro", icon: "trending_up", xpReward: 1000, category: "advanced",
        description: "Poupar e investir efetivamente pelo menos 20% das receitas totais do workspace no mês.",
        audience: "personal",
    },
    cost_cutter: {
        id: "cost_cutter", name: "Tesoura de Gastos", icon: "content_cut", xpReward: 800, category: "advanced",
        description: "Reduzir os gastos totais do pool de Conforto (supérfluos) em 20% em relação ao mês anterior.",
        audience: "personal",
    },
    united_front: {
        id: "united_front", name: "Equipe Unida", icon: "groups", xpReward: 600, category: "advanced",
        description: "Workspace com 3 ou mais membros ativos adicionados e aceitos.",
    },
    iron_consistency: {
        id: "iron_consistency", name: "Consistência de Aço", icon: "calendar_month", xpReward: 2500, category: "advanced",
        description: "Concluir com sucesso as missões semanais por 4 semanas consecutivas.",
    },

    // ── Simple Badges — Primeiros Passos (10) ────────────────────────────────────────
    first_category: {
        id: "first_category", name: "Organizador", icon: "label", xpReward: 0, category: "first_steps",
        description: "Criar a primeira categoria personalizada no workspace.",
    },
    first_planning: {
        id: "first_planning", name: "Planejador Novato", icon: "event_note", xpReward: 50, category: "first_steps",
        description: "Criar o primeiro planejamento de categoria com valor definido.",
    },
    first_goal: {
        id: "first_goal", name: "Sonhador", icon: "flag", xpReward: 50, category: "first_steps",
        description: "Criar a primeira meta financeira no workspace.",
    },
    first_invite: {
        id: "first_invite", name: "Anfitrião", icon: "person_add", xpReward: 75, category: "first_steps",
        description: "Convidar o primeiro membro para o workspace.",
    },
    profile_complete: {
        id: "profile_complete", name: "Perfil Completo", icon: "verified", xpReward: 25, category: "first_steps",
        description: "Definir nome e tipo do workspace.",
    },
    first_income: {
        id: "first_income", name: "Receita Registrada", icon: "south_east", xpReward: 0, category: "first_steps",
        description: "Registrar a primeira receita paga no workspace.",
    },
    first_expense: {
        id: "first_expense", name: "Gasto Registrado", icon: "north_west", xpReward: 0, category: "first_steps",
        description: "Registrar o primeiro gasto pago no workspace.",
    },
    first_transfer: {
        id: "first_transfer", name: "Transferidor", icon: "swap_horiz", xpReward: 0, category: "first_steps",
        description: "Registrar a primeira transferência entre contas.",
    },
    workspace_named: {
        id: "workspace_named", name: "Identidade Própria", icon: "edit", xpReward: 25, category: "first_steps",
        description: "Dar um nome personalizado ao workspace.",
    },
    first_month: {
        id: "first_month", name: "Primeiro Mês", icon: "calendar_today", xpReward: 0, category: "first_steps",
        description: "Ter pelo menos uma transação registrada em um mês completo.",
    },

    // ── Simple Badges — Registro Consistente (10) ────────────────────────────
    five_transactions: {
        id: "five_transactions", name: "Ativo!", icon: "flash_on", xpReward: 0, category: "consistency",
        description: "Registrar 5 transações pagas no total.",
    },
    twenty_transactions: {
        id: "twenty_transactions", name: "Comprometido", icon: "trending_up", xpReward: 0, category: "consistency",
        description: "Registrar 20 transações pagas no total.",
    },
    fifty_transactions: {
        id: "fifty_transactions", name: "Vetarano", icon: "workspace_premium", xpReward: 0, category: "consistency",
        description: "Registrar 50 transações pagas no total.",
    },
    hundred_transactions: {
        id: "hundred_transactions", name: "Centenário", icon: "emoji_events", xpReward: 0, category: "consistency",
        description: "Registrar 100 transações pagas no total.",
    },
    week_complete: {
        id: "week_complete", name: "Semana Completa", icon: "date_range", xpReward: 100, category: "consistency",
        description: "Registrar ao menos uma transação em 7 dias consecutivos.",
    },
    two_accounts: {
        id: "two_accounts", name: "Multi-Conta", icon: "account_balance_wallet", xpReward: 0, category: "consistency",
        description: "Cadastrar 2 contas no workspace.",
    },
    three_accounts: {
        id: "three_accounts", name: "Gerenciador", icon: "dashboard", xpReward: 0, category: "consistency",
        description: "Cadastrar 3 contas no workspace.",
    },
    five_accounts: {
        id: "five_accounts", name: "Portfólio", icon: "business_center", xpReward: 0, category: "consistency",
        description: "Cadastrar 5 contas no workspace.",
    },
    five_categories: {
        id: "five_categories", name: "Categorizado", icon: "category", xpReward: 0, category: "consistency",
        description: "Criar ao menos 5 categorias.",
    },
    ten_categories: {
        id: "ten_categories", name: "Mestre Categorizador", icon: "workspaces", xpReward: 0, category: "consistency",
        description: "Criar ao menos 10 categorias.",
    },

    // ── Simple Badges — Gastos e Economias (10) ──────────────────────────────
    round_number: {
        id: "round_number", name: "Número Redondo", icon: "radio_button_checked", xpReward: 0, category: "savings",
        description: "Registrar uma transação de valor exato sem centavos.",
    },
    big_transaction: {
        id: "big_transaction", name: "Grande Negócio", icon: "payments", xpReward: 0, category: "savings",
        description: "Registrar uma transação individual acima de R$ 1.000.",
    },
    small_transactions_ten: {
        id: "small_transactions_ten", name: "Detalhe Minucioso", icon: "grain", xpReward: 0, category: "savings",
        description: "Registrar 10 transações de valor inferior a R$ 10.",
    },
    income_registered: {
        id: "income_registered", name: "Bem Documentado", icon: "receipt_long", xpReward: 50, category: "savings",
        description: "Registrar ao menos uma receita no workspace.",
    },
    expense_under_income: {
        id: "expense_under_income", name: "Saldo Positivo", icon: "balance", xpReward: 100, category: "savings",
        description: "Fechar o mês com despesas menores que as receitas.",
    },
    three_categories_month: {
        id: "three_categories_month", name: "Diversificado", icon: "donut_small", xpReward: 0, category: "savings",
        description: "Ter gastos em 3 categorias diferentes no mesmo mês.",
    },
    five_categories_month: {
        id: "five_categories_month", name: "Abrangente", icon: "donut_large", xpReward: 0, category: "savings",
        description: "Ter gastos em 5 categorias diferentes no mesmo mês.",
    },
    savings_10pct: {
        id: "savings_10pct", name: "Poupador Iniciante", icon: "percent", xpReward: 100, category: "savings",
        description: "Poupar ao menos 10% da receita total no mês.",
        audience: "personal",
    },
    savings_start: {
        id: "savings_start", name: "Primeiro Centavo", icon: "monetization_on", xpReward: 75, category: "savings",
        description: "Fazer o primeiro depósito em qualquer meta financeira.",
    },
    no_credit_debt: {
        id: "no_credit_debt", name: "Livre de Juros", icon: "credit_score", xpReward: 75, category: "savings",
        description: "Fechar o mês sem nenhuma fatura de crédito em aberto.",
    },

    // ── Simple Badges — Metas (10) ───────────────────────────────────────────────────
    goal_halfway: {
        id: "goal_halfway", name: "Na Metade do Caminho", icon: "looks_two", xpReward: 50, category: "goals",
        description: "Uma meta financeira atingir 50% do valor alvo.",
    },
    goal_75pct: {
        id: "goal_75pct", name: "Quase Lá", icon: "looks_3", xpReward: 75, category: "goals",
        description: "Uma meta financeira atingir 75% do valor alvo.",
    },
    goal_under_deadline: {
        id: "goal_under_deadline", name: "No Prazo", icon: "timer", xpReward: 100, category: "goals",
        description: "Concluir uma meta antes da data limite estabelecida.",
    },
    two_active_goals: {
        id: "two_active_goals", name: "Ambicioso", icon: "offline_bolt", xpReward: 0, category: "goals",
        description: "Ter 2 metas ativas ao mesmo tempo.",
    },
    five_active_goals: {
        id: "five_active_goals", name: "Multitarefas", icon: "dynamic_feed", xpReward: 0, category: "goals",
        description: "Ter 5 metas ativas ao mesmo tempo.",
    },
    long_term_goal: {
        id: "long_term_goal", name: "Visão de Longo Prazo", icon: "public", xpReward: 75, category: "goals",
        description: "Criar uma meta com prazo superior a 12 meses.",
    },
    short_term_goal: {
        id: "short_term_goal", name: "Sprint Financeiro", icon: "bolt", xpReward: 75, category: "goals",
        description: "Concluir uma meta em menos de 30 dias.",
    },
    goal_deposit: {
        id: "goal_deposit", name: "Primeiro Depósito", icon: "add_card", xpReward: 50, category: "goals",
        description: "Fazer o primeiro depósito em uma meta financeira.",
    },
    goal_debt_paid: {
        id: "goal_debt_paid", name: "Livre de Dívidas", icon: "free_cancellation", xpReward: 150, category: "goals",
        description: "Concluir uma meta do tipo 'Quitar Dívida'.",
    },
    goal_linked_account: {
        id: "goal_linked_account", name: "Meta Vinculada", icon: "link", xpReward: 50, category: "goals",
        description: "Criar uma meta associada a uma conta bancária.",
    },

    // ── Simple Badges — Equipe e Consistência (10) ───────────────────────────
    second_member: {
        id: "second_member", name: "Dupla!", icon: "group_add", xpReward: 50, category: "team",
        description: "Um segundo membro aceitar o convite para o workspace.",
    },
    reconcile_second: {
        id: "reconcile_second", name: "Conciliador Frequente", icon: "refresh", xpReward: 75, category: "team",
        description: "Concluir a segunda conciliação bancária.",
    },
    reconcile_five: {
        id: "reconcile_five", name: "Conciliador Hábil", icon: "sync_alt", xpReward: 0, category: "team",
        description: "Concluir 5 conciliações bancárias ao total.",
    },
    mission_first: {
        id: "mission_first", name: "Primeira Missão", icon: "task_alt", xpReward: 75, category: "team",
        description: "Completar a primeira missão semanal.",
    },
    mission_three: {
        id: "mission_three", name: "Triatleta Financeiro", icon: "sports_score", xpReward: 100, category: "team",
        description: "Completar 3 missões semanais ao total.",
    },
    planning_month: {
        id: "planning_month", name: "Planejamento do Mês", icon: "event_available", xpReward: 75, category: "team",
        description: "Criar planejamento para ao menos 5 categorias no mês.",
    },
    two_months_active: {
        id: "two_months_active", name: "Constante", icon: "repeat", xpReward: 0, category: "team",
        description: "Registrar transações em 2 meses diferentes.",
    },
    workspace_one_year: {
        id: "workspace_one_year", name: "Aniversário!", icon: "cake", xpReward: 0, category: "team",
        description: "O workspace completa 1 ano de existência.",
    },
    invite_accepted: {
        id: "invite_accepted", name: "Bem-vindo ao Time", icon: "waving_hand", xpReward: 50, category: "team",
        description: "Aceitar o convite para entrar em um workspace.",
    },
    all_missions_week: {
        id: "all_missions_week", name: "Semana Perfeita", icon: "star", xpReward: 100, category: "team",
        description: "Completar todas as missões semanais disponíveis em uma semana.",
    },
};

/**
 * F2.3 — TABELA DE XP QUE PREMIA PLANEJAR.
 *
 * O jogo já dizia "gasto não planejado vale zero". O que faltava era o outro
 * lado: **planejar de propósito precisa valer alguma coisa**. Antes desta
 * tabela, quase todo o XP do produto vinha de badges de CONTAGEM — cadastrar
 * cinco contas, registrar cem transações, completar um ano de workspace —, que
 * premiam usar o app, não organizar a vida financeira.
 *
 * Os valores estão aqui, e não espalhados pelo código, porque eles também são
 * PUBLICADOS: `config/badges.xpSources` é a tabela que o app mostra na tela
 * "como ganhar XP". Mudar um número aqui muda o hash do catálogo e o cron
 * `publishBadgeCatalog` republica sozinho.
 */
export const XP_VALUES = {
    /** Por categoria com limite que fechou a semana DENTRO do limite. */
    weeklyCategoryWithinLimit: 20,
    /** Bônus quando TODAS as categorias com limite fecharam dentro. */
    weeklyAllWithinLimit: 50,
    /** Multiplicador do bônus de streak de semanas dentro do plano. */
    weeklyPlanStreakStep: 10,
    /** Teto do bônus de streak — a partir de 10 semanas ele para de crescer. */
    weeklyPlanStreakCap: 100,
    /** Ao criar o PRIMEIRO limite de uma categoria (uma vez por categoria). */
    planningCreated: 30,
    /** Ao criar a PRIMEIRA recorrência de uma categoria (uma vez por categoria). */
    recurringCreated: 30,
} as const;

/** Uma linha da tabela publicada em `config/badges.xpSources`. */
export interface XpSourceConfig {
    id: string;
    name: { pt: string, en: string };
    xp: number;
    description: { pt: string, en: string };
    /**
     * A quem a fonte de XP se aplica. Hoje TODAS são `both`, e o campo existe
     * mesmo assim por dois motivos: ele viaja no `config/badges` junto com o
     * `audience` dos badges, então o app filtra as duas listas com o mesmo
     * código; e acrescentar amanhã uma fonte só de empresa (margem acima do
     * plano, fechamento no prazo) passa a ser uma linha nesta tabela, e não
     * uma mudança de forma do documento que o app tem de acompanhar.
     */
    audience?: BadgeAudience;
}

/**
 * As fontes de XP, como o app as exibe. `xp` é o valor unitário; a descrição
 * explica a regra por extenso, inclusive os tetos que o número sozinho não
 * revela.
 */
export const XP_SOURCES: XpSourceConfig[] = [
    {
        id: "category_within_limit",
        name: { pt: "Categoria dentro do limite", en: "Category within its limit" },
        xp: XP_VALUES.weeklyCategoryWithinLimit,
        description: {
            pt: "Cada categoria com limite que fecha a semana sem estourar o planejado.",
            en: "Each category with a limit that closes the week without exceeding the plan.",
        },
    },
    {
        id: "all_categories_within_limit",
        name: { pt: "Semana redonda", en: "Perfect week" },
        xp: XP_VALUES.weeklyAllWithinLimit,
        description: {
            pt: "Bônus quando TODAS as categorias com limite fecham a semana dentro do planejado.",
            en: "Bonus when EVERY category with a limit closes the week within plan.",
        },
    },
    {
        id: "plan_streak",
        name: { pt: "Sequência no plano", en: "Plan streak" },
        xp: XP_VALUES.weeklyPlanStreakStep,
        description: {
            pt: `Multiplicado pelo número de semanas seguidas dentro do plano, até ${XP_VALUES.weeklyPlanStreakCap} XP. Estourar um limite zera a sequência.`,
            en: `Multiplied by the number of consecutive weeks within plan, up to ${XP_VALUES.weeklyPlanStreakCap} XP. Going over a limit resets the streak.`,
        },
    },
    {
        id: "planning_created",
        name: { pt: "Limite criado", en: "Limit created" },
        xp: XP_VALUES.planningCreated,
        description: {
            pt: "Ao definir o primeiro limite de uma categoria. Uma vez por categoria.",
            en: "When you set the first limit for a category. Once per category.",
        },
    },
    {
        id: "recurring_created",
        name: { pt: "Recorrência criada", en: "Recurring created" },
        xp: XP_VALUES.recurringCreated,
        description: {
            pt: "Ao criar o primeiro lançamento recorrente de uma categoria. Uma vez por categoria.",
            en: "When you create the first recurring entry for a category. Once per category.",
        },
    },
    {
        id: "installment_paid",
        name: { pt: "Lançamento planejado pago", en: "Planned entry paid" },
        xp: 15,
        description: {
            pt: "Pagar um lançamento que estava planejado. Gasto NÃO planejado (que nasce pago) vale zero.",
            en: "Paying an entry that was planned. An UNPLANNED expense (born paid) is worth zero.",
        },
    },
    {
        id: "weekly_mission",
        name: { pt: "Missão semanal", en: "Weekly mission" },
        xp: 150,
        description: {
            pt: "Cada missão semanal concluída (150 a 250 XP, conforme a missão).",
            en: "Each weekly mission completed (150 to 250 XP, depending on the mission).",
        },
    },
];

/**
 * Escrita do XP na barra semanal (`weekly_xp/{YYYY-Www}`).
 *
 * É INJETADA, e não importada: a implementação vive em
 * `FinanceService.updateWeeklyTotalXp` (a única do projeto desde F1.9), mas
 * alcançá-la por `import { container }` aqui arrastaria o container inteiro —
 * e, com ele, o SDK do Gemini e o `ofx-js` — para dentro de qualquer arquivo
 * que apenas leia o catálogo de badges. O container faz a ligação.
 */
export type WeeklyXpWriter = (workspaceId: string, date: Date, deltaXp: number) => Promise<void>;

export class GamificationService {
    constructor(
        private gamificationRepository: IGamificationRepository,
        private aiRepository?: IAIRepository,
        private idempotencyService?: IIdempotencyService,
        private weeklyXpWriter?: WeeklyXpWriter
    ) { }

    async addXp(workspaceId: string, amount: number, reason: string): Promise<void> {
        await this.gamificationRepository.addXp(workspaceId, amount, reason);
    }

    /**
     * F2.3 — XP que também entra na BARRA DA SEMANA (`weekly_xp/{YYYY-Www}`).
     *
     * O XP total do workspace e o XP semanal são dois contadores distintos: o
     * primeiro move o nível, o segundo desenha a barra de progresso da semana.
     * Só o pagamento de parcela alimentava o segundo — então a semana em que o
     * usuário criou cinco limites e fechou todos dentro do plano aparecia
     * VAZIA na barra, que é o oposto da mensagem do produto.
     *
     * `weekDate` é qualquer instante DENTRO da semana que deve receber o XP.
     * Para o cron semanal isso é a semana AVALIADA (a que acabou), não a
     * corrente: o XP é mérito daquela semana e é nela que a barra histórica
     * precisa mostrá-lo.
     *
     * A escrita em `weekly_xp` é best-effort e vem DEPOIS do XP do workspace:
     * o total é a fonte da verdade (é ele que move o nível), a barra é
     * apresentação. Uma falha aqui não pode desfazer o XP já concedido nem
     * derrubar o cron para os demais workspaces.
     */
    private async addXpWithWeekly(
        workspaceId: string,
        amount: number,
        reason: string,
        weekDate: Date
    ): Promise<void> {
        await this.addXp(workspaceId, amount, reason);

        if (!this.weeklyXpWriter) return;

        try {
            await this.weeklyXpWriter(workspaceId, weekDate, amount);
        }
        catch (e) {
            logger.error(`[GamificationService] XP ${amount} concedido a ${workspaceId}, mas a barra semanal não atualizou:`, e);
        }
    }

    async unlockBadge(workspaceId: string, badgeId: string): Promise<boolean> {
        const badge = BADGES[badgeId];
        if (!badge) {
            logger.error(`[GamificationService] Badge ${badgeId} not configured.`);
            return false;
        }

        return this.gamificationRepository.unlockBadge(
            workspaceId,
            badgeId,
            badge.xpReward,
            badge.name,
            badge.audience ?? "both"
        );
    }

    async checkFirstStep(workspaceId: string, onboardingCompleted: boolean): Promise<void> {
        if (onboardingCompleted) {
            await this.unlockBadge(workspaceId, "first_step");
        }
    }

    async checkUnitedFront(workspaceId: string, membersCount: number): Promise<void> {
        if (membersCount >= 3) {
            await this.unlockBadge(workspaceId, "united_front");
        }
    }

    async checkFirstAccount(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getAccountsCount(workspaceId);
        if (count >= 1) {
            await this.unlockBadge(workspaceId, "first_account");
        }
    }

    async checkFirstTransaction(workspaceId: string): Promise<void> {
        const hasTx = await this.gamificationRepository.hasPaidTransaction(workspaceId);
        if (hasTx) {
            await this.unlockBadge(workspaceId, "first_transaction");
        }
    }

    async checkPlanner(workspaceId: string): Promise<void> {
        const plannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let count = 0;
        for (const p of plannings) {
            if (p.amount > 0) {
                count++;
            }
        }

        if (count >= 5) {
            await this.unlockBadge(workspaceId, "planner");
        }
    }

    async checkGoldenRule(workspaceId: string): Promise<void> {
        const plannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let hasEssential = false;
        let hasComfort = false;
        let hasInvestment = false;

        for (const p of plannings) {
            if (p.amount > 0 && p.category) {
                const allocation = p.category.allocation;
                if (allocation === "essential") {
                    hasEssential = true;
                }
                if (allocation === "comfort") {
                    hasComfort = true;
                }
                if (allocation === "investment") {
                    hasInvestment = true;
                }
            }
        }

        if (hasEssential && hasComfort && hasInvestment) {
            await this.unlockBadge(workspaceId, "golden_rule");
        }
    }

    async checkReconciliationBadges(
        workspaceId: string,
        confirmedMatchesCount: number,
        totalTransactionsProcessed: number,
        createdTransactionsCount: number
    ): Promise<void> {
        if (totalTransactionsProcessed >= 1) {
            await this.unlockBadge(workspaceId, "reconcile_junior");
        }

        if (totalTransactionsProcessed >= 10) {
            await this.unlockBadge(workspaceId, "cash_detective");
        }

        if (createdTransactionsCount === 0 && totalTransactionsProcessed > 0) {
            await this.unlockBadge(workspaceId, "zero_friction");
        }

        const count = await this.gamificationRepository.getCompletedReconciliationsCount(workspaceId, 10);
        if (count >= 10) {
            await this.unlockBadge(workspaceId, "reconcile_master");
        }
    }

    async checkGoalBadges(workspaceId: string, goalDoc: GamificationGoal): Promise<void> {
        // `status` NÃO existe no documento de meta (o cliente nunca gravou um).
        // Conclusão é o desfecho `outcome == "success"` gravado pelo servidor —
        // ver `isGoalCompleted`. Meta de redução com o teto estourado tem
        // `outcome == "failed"` e não conta para badge nenhum.
        if (isGoalCompleted(goalDoc)) {
            const completedSnapshot = await this.gamificationRepository.getGoals(workspaceId);
            let completedCount = 0;
            for (const g of completedSnapshot) {
                if (g.isDeleted === true) {
                    continue;
                }
                if (isGoalCompleted(g)) {
                    completedCount++;
                }
            }

            if (completedCount >= 1) {
                await this.unlockBadge(workspaceId, "savings_seed");
            }
            if (completedCount >= 3) {
                await this.unlockBadge(workspaceId, "goal_bronze");
            }
            if (completedCount >= 5) {
                await this.unlockBadge(workspaceId, "goal_silver");
            }
        }
    }

    async updateWeeklyMissionsProgress(
        workspaceId: string,
        eventType: "transaction" | "reconciliation" | "planning",
        eventData: WeeklyMissionEventData | null | undefined
    ): Promise<void> {
        const now = new Date();
        // Fronteiras de semana calculadas no fuso America/Sao_Paulo (util único).
        const startOfWeek = startOfWeekInTz(now);
        const endOfWeek = endOfWeekFromStart(startOfWeek);
        const weekId = getWeekId(startOfWeek);
        const monthKey = getMonthKeyInTz(now);

        let consistencyDoc = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "consistency");
        if (!consistencyDoc) {
            const generateMissions = async () => {
                await this.generateWeeklyMissions(workspaceId, weekId, monthKey);
            };
            if (this.idempotencyService) {
                // Chave por workspace+semana: escritas paralelas de installments
                // não disparam geração (e chamadas de IA) duplicadas.
                await this.idempotencyService.runIdempotency(
                    `${workspaceId}_${weekId}`,
                    "generateWeeklyMissions",
                    generateMissions
                );
            }
            else {
                await generateMissions();
            }
            // Recém-criada: `progress` 0 e `status` pending, sem leitura nova.
            // Numa corrida em que outra escrita gerou a semana primeiro, o
            // `create` do repositório não sobrescreve nada e o documento que o
            // laço quer é o que ficou lá — por isso o reread só acontece aqui.
            consistencyDoc = await this.gamificationRepository.getWeeklyMission(workspaceId, weekId, "consistency");
        }

        await this.advanceWeeklyMissions({
            workspaceId,
            weekId,
            monthKey,
            startOfWeek,
            endOfWeek,
            // Dias JÁ decorridos por completo: o dia de hoje ainda pode receber
            // gastos e não pode contar como "dentro do orçamento".
            elapsedFullDays: getDayIndexInTz(now),
            eventType,
            eventData,
            reads: {},
            // Só a de consistência: as outras duas nunca foram lidas aqui.
            preloaded: { consistency: consistencyDoc },
        });
    }

    /**
     * Percorre as três missões da semana e avança a que a REGRA do seu template
     * souber medir a partir deste evento.
     *
     * Antes deste pacote, o avanço era um `if/else` escrito em cima do EVENTO:
     * evento de planejamento mexia na missão de consistência, evento de
     * transação na de disciplina, evento de conciliação na de organização. Com
     * um catálogo por tipo de workspace isso deixa de funcionar — a missão de
     * organização de uma empresa pode ser "conciliar 2 extratos" (conta
     * documentos da semana), "triar 10 lançamentos automáticos" ou "pagar a
     * fatura no prazo" (que chega como evento de TRANSAÇÃO). Quem decide o que
     * medir passa a ser o `progressRule` do template, e o evento vira apenas o
     * gatilho que autoriza a leitura.
     */
    private async advanceWeeklyMissions(ctx: MissionEvaluationContext): Promise<void> {
        for (const type of WEEKLY_MISSION_TYPES) {
            const mission = ctx.preloaded && type in ctx.preloaded
                ? ctx.preloaded[type] ?? null
                : await this.gamificationRepository.getWeeklyMission(ctx.workspaceId, ctx.weekId, type);
            if (!mission || mission.status === "completed") {
                continue;
            }

            const template = this.resolveMissionTemplate(mission, type, ctx.weekId);
            if (!template) {
                continue;
            }

            const rule = template.progressRule;
            if (!RULE_EVENT_SOURCES[rule].includes(ctx.eventType)) {
                // Este evento não toca no dado que a regra mede: nada a ler.
                continue;
            }

            const target = mission.target ?? template.target;
            const evaluation = await this.evaluateMissionRule(rule, target, ctx);
            if (!evaluation) {
                continue;
            }

            if (evaluation.completed) {
                // Checagem de "já concluída" + concessão de XP em uma única
                // transação Firestore (sem corrida entre escritas paralelas).
                await this.gamificationRepository.completeMissionAndAwardXp(
                    ctx.workspaceId,
                    ctx.weekId,
                    type,
                    evaluation.progress,
                    mission.rewardXp ?? template.rewardXp,
                    MISSION_COMPLETION_REASON[type]
                );
            }
            else if (evaluation.progress !== (mission.progress ?? 0)) {
                // Escreve só quando o número MUDA: o gatilho de installment
                // dispara em cada parcela, e reescrever o mesmo progresso
                // custaria uma escrita por evento sem mover a barra.
                await this.gamificationRepository.updateWeeklyMission(ctx.workspaceId, ctx.weekId, type, {
                    progress: evaluation.progress,
                    status: "pending",
                });
            }
        }
    }

    /**
     * O template de uma missão GRAVADA.
     *
     * `templateKey` é o caminho normal. Uma missão da semana corrente criada
     * pelo servidor ANTERIOR a este pacote não tem o campo — e não pode ficar
     * parada até a virada da semana —, então ela cai na seleção determinística
     * da sua audiência. Sem `workspaceType` no documento a audiência é
     * `personal`, que é o comportamento que essas missões sempre tiveram (os
     * fallbacks antigos eram todos pessoais). O script `retag_weekly_missions`
     * existe para não depender desse fallback por muito tempo.
     */
    private resolveMissionTemplate(
        mission: WeeklyMissionDocument,
        type: WeeklyMissionType,
        weekId: string
    ): MissionTemplate | null {
        const byKey = findMissionTemplate(mission.templateKey);
        if (byKey) return byKey;
        return selectMissionTemplate(resolveAudience(mission.workspaceType), type, weekId);
    }

    /**
     * Avalia UMA regra de progresso.
     *
     * Devolve `null` quando a regra não tem como ser medida agora (o evento não
     * traz o dado, ou o workspace não tem plano nenhum): nesse caso o progresso
     * gravado fica como está, em vez de ser zerado. Zerar seria pior do que não
     * escrever — a barra andaria para trás na tela sem que nada tivesse
     * acontecido.
     */
    private async evaluateMissionRule(
        rule: MissionProgressRule,
        target: number,
        ctx: MissionEvaluationContext
    ): Promise<MissionEvaluation | null> {
        switch (rule) {
        case "planned_categories": {
            const plannings = await this.readPlannings(ctx);
            return atLeast(plannings.plannedCategoriesCount, target);
        }

        case "days_within_category_limit": {
            const plannings = await this.readPlannings(ctx);
            if (!plannings.topCategory || plannings.topAmount <= 0) {
                // Sem NENHUMA categoria com limite não há o que medir. O
                // código antigo inventava um teto de R$ 250/semana sobre
                // uma categoria "Alimentação" que podia nem existir — num
                // workspace de empresa isso era a própria missão errada, e
                // em qualquer workspace era XP por um plano que ninguém fez.
                return null;
            }
            const installments = await this.readPaidInstallments(ctx);
            const dailyLimit = plannings.topAmount / 7;
            const spentByDay: Record<number, number> = {};

            for (const inst of installments) {
                if (inst.status === "removed" || inst.type !== "expense") continue;
                const name = inst.category?.name;
                if (!name || name.toLowerCase() !== plannings.topCategory.toLowerCase()) continue;
                // paidDate consistentemente; dueDate apenas como fallback.
                const date = toDate(inst.paidDate ?? inst.dueDate);
                if (!date) continue;
                const day = getDayIndexInTz(date);
                spentByDay[day] = (spentByDay[day] || 0) + (inst.paidAmount || inst.amount || 0);
            }

            let withinBudget = 0;
            for (let day = 0; day < ctx.elapsedFullDays; day++) {
                if ((spentByDay[day] || 0) <= dailyLimit) {
                    withinBudget++;
                }
            }

            // Exige que pelo menos `target` dias tenham decorrido antes de
            // permitir a conclusão: sem isso a missão fechava na primeira
            // transação da semana, contando dias futuros como cumpridos.
            return {
                progress: withinBudget,
                completed: withinBudget >= target && ctx.elapsedFullDays >= target,
            };
        }

        case "reconciled_statement_items": {
            // O único dado que vem do EVENTO: quantos itens o extrato
            // recém-concluído processou. Não há como recontá-lo depois.
            const doc = ctx.eventData ?? {};
            if (doc.status !== "completed") return null;
            const processed = doc.totalTransactionsProcessed ?? 0;
            return atLeast(processed, target);
        }

        case "reconciled_statements": {
            const count = await this.readReconciledStatements(ctx);
            return atLeast(count, target);
        }

        case "categorized_auto_transactions": {
            const rows = await this.readAutomaticTransactions(ctx);
            let resolved = 0;
            for (const row of rows) {
                const date = toDate(row.date);
                if (!date || date < ctx.startOfWeek || date > ctx.endOfWeek) continue;
                // Consolidado (virou lançamento, com categoria escolhida) ou
                // descartado de propósito. A sugestão da IA NÃO conta: ela
                // preenche `categoryId` sozinha, e contá-la faria a missão
                // fechar sem ninguém ter feito nada.
                if (row.isConsolidated === true || row.isIgnored === true) {
                    resolved++;
                }
            }
            return atLeast(resolved, target);
        }

        case "invoice_paid_on_time": {
            const installments = await this.readPaidInstallments(ctx);
            let onTime = 0;
            for (const inst of installments) {
                if (inst.isInvoice !== true || inst.status === "removed") continue;
                const paid = toDate(inst.paidDate);
                const due = toDate(inst.dueDate);
                if (!paid || !due) continue;
                // Comparação por DIA de calendário no fuso do produto: o
                // vencimento da fatura é gravado ao MEIO-DIA (ver
                // `nextInvoice` no README), então comparar instantes
                // reprovaria quem pagou às 18h do próprio dia.
                if (dayKeyInTz(paid) <= dayKeyInTz(due)) {
                    onTime++;
                }
            }
            return atLeast(onTime, target);
        }

        case "weekly_margin_above_plan": {
            const rows = await this.readWeeklySummary(ctx);
            const totals = sumWeeklyTotals(rows);
            // Sem plano não há "acima do planejado": a missão de margem
            // pressupõe uma margem planejada, e premiar a sua ausência
            // seria premiar não planejar.
            if (totals.plannedIncome + totals.plannedExpense <= 0) return null;
            const plannedMargin = totals.plannedIncome - totals.plannedExpense;
            const actualMargin = totals.actualIncome - totals.actualExpense;
            const reached = actualMargin >= plannedMargin;
            return { progress: reached ? target : 0, completed: reached };
        }

        case "income_received_vs_planned": {
            const rows = await this.readWeeklySummary(ctx);
            const totals = sumWeeklyTotals(rows);
            if (totals.plannedIncome <= 0) return null;
            // O alvo é um PERCENTUAL (80 = 80% da receita prevista).
            const percent = Math.min(100, Math.floor((totals.actualIncome / totals.plannedIncome) * 100));
            return atLeast(percent, target);
        }
        }
    }

    // ── Leituras memoizadas por avaliação ───────────────────────────────────
    //
    // As três missões da semana podem depender da MESMA consulta (as duas de
    // empresa que leem o sumário semanal, por exemplo). O cache vive no
    // contexto de UMA avaliação — não no serviço —, de modo que ele nunca
    // serve dado velho para o evento seguinte.

    private readPlannings(ctx: MissionEvaluationContext): Promise<PlanningAggregate> {
        ctx.reads.plannings ??= this.gamificationRepository
            .getCategoryPlannings(ctx.workspaceId)
            .then((plannings) => aggregatePlannings(plannings, ctx.monthKey));
        return ctx.reads.plannings;
    }

    private readPaidInstallments(ctx: MissionEvaluationContext): Promise<GamificationInstallment[]> {
        ctx.reads.paidInstallments ??= this.gamificationRepository.getPaidInstallmentsInPeriod(
            ctx.workspaceId,
            ctx.startOfWeek,
            ctx.endOfWeek
        );
        return ctx.reads.paidInstallments;
    }

    private readWeeklySummary(ctx: MissionEvaluationContext): Promise<WeeklySummaryRow[]> {
        ctx.reads.weeklySummary ??= this.gamificationRepository.getWeeklySummaryRows(ctx.workspaceId, ctx.weekId);
        return ctx.reads.weeklySummary;
    }

    private readReconciledStatements(ctx: MissionEvaluationContext): Promise<number> {
        ctx.reads.reconciledStatements ??= this.gamificationRepository.getCompletedReconciliationsInPeriod(
            ctx.workspaceId,
            ctx.startOfWeek,
            ctx.endOfWeek
        );
        return ctx.reads.reconciledStatements;
    }

    private readAutomaticTransactions(ctx: MissionEvaluationContext): Promise<AutomaticTransactionRow[]> {
        ctx.reads.automaticTransactions ??= this.gamificationRepository.getAutomaticTransactions(
            ctx.workspaceId,
            AUTOMATIC_TRANSACTIONS_SCAN_LIMIT
        );
        return ctx.reads.automaticTransactions;
    }

    /**
     * Gera as três missões semanais da semana, PELO CATÁLOGO do tipo do
     * workspace. Deve ser invocada sob idempotência (workspaceId + weekId) para
     * não duplicar chamadas de IA em escritas paralelas.
     *
     * O objetivo, o alvo, o XP, a rota do CTA e a chave de i18n saem do
     * template escolhido por hash da semana. A IA é OPCIONAL e entra só depois,
     * para reescrever o texto — e o que ela devolve é aceito apenas se
     * referenciar o template escolhido (ver `validateWeeklyMissionNames`).
     */
    private async generateWeeklyMissions(workspaceId: string, weekId: string, monthKey: string): Promise<void> {
        let workspaceType = "personal";
        try {
            const workspaceDoc = await this.gamificationRepository.getWorkspaceById(workspaceId);
            if (workspaceDoc) {
                workspaceType = workspaceDoc.type || "personal";
            }
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching workspace type:", e);
        }
        const audience = resolveAudience(workspaceType);

        logger.info(
            `[GamificationService] Gerando missões semanais (${audience}) para o workspace ${workspaceId}, semana ${weekId}.`
        );

        const categoriesList: string[] = [];
        let topCategory: string | null = null;
        try {
            const plannings = await this.gamificationRepository.getCategoryPlannings(workspaceId);
            const aggregate = aggregatePlannings(plannings, monthKey);
            categoriesList.push(...aggregate.categoryNames);
            topCategory = aggregate.topCategory;
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching category plannings:", e);
        }

        const goalsList: string[] = [];
        try {
            const goalsSnapshot = await this.gamificationRepository.getGoals(workspaceId);
            for (const g of goalsSnapshot) {
                if (g.name && isGoalActive(g)) {
                    goalsList.push(g.name);
                }
            }
        }
        catch (e) {
            logger.error("[GamificationService] Error fetching goals:", e);
        }

        // 1. O CATÁLOGO escolhe — determinístico, sem rede.
        const planned = WEEKLY_MISSION_TYPES
            .map((type) => {
                const template = selectMissionTemplate(audience, type, weekId);
                if (!template) return null;
                const params: MissionParams = { target: template.target };
                if (template.params.includes("category") && topCategory) {
                    params.category = topCategory;
                }
                return { type, template, params, name: buildMissionName(template, "pt", params) };
            })
            .filter((entry): entry is PlannedMission => entry !== null);

        // 2. A IA (se houver) apenas TEMPERA o texto; o que não passar na
        //    validação volta null e o texto do catálogo prevalece.
        let aiNames: Partial<Record<WeeklyMissionType, string>> = {};
        if (this.aiRepository) {
            try {
                const expectations: WeeklyMissionExpectation[] = planned.map((entry) => ({
                    type: entry.type,
                    templateKey: entry.template.key,
                    baseName: entry.name,
                    target: entry.template.target,
                    requiredTerms: entry.template.aiRequiredTerms,
                    forbiddenTerms: AUDIENCE_FORBIDDEN_TERMS[audience],
                    // O nome da categoria veio do Firestore: ele não conta como
                    // vocabulário inventado pelo modelo.
                    dataValues: topCategory ? [topCategory] : [],
                }));
                const validated = await this.aiRepository.generateWeeklyMissions(
                    workspaceId,
                    audience,
                    categoriesList,
                    goalsList,
                    expectations
                );
                aiNames = {
                    consistency: validated.consistency?.name,
                    discipline: validated.discipline?.name,
                    organization: validated.organization?.name,
                };
            }
            catch (e) {
                logger.error("[GamificationService] Falha ao temperar as missões via Gemini. Usando o catálogo.", e);
            }
        }

        // 3. Grava.
        for (const entry of planned) {
            const write: WeeklyMissionWrite = {
                id: entry.type,
                name: aiNames[entry.type] || entry.name,
                type: entry.type,
                status: "pending",
                rewardXp: entry.template.rewardXp,
                progress: 0,
                target: entry.template.target,
                weekId,
                createdAt: new Date().toISOString(),
                templateKey: entry.template.key,
                workspaceType: audience,
                actionPath: entry.template.actionPath,
                nameKey: entry.template.nameKey,
            };
            if (entry.template.params.length > 0) {
                write.params = entry.params;
            }
            await this.gamificationRepository.createWeeklyMission(workspaceId, weekId, entry.type, write);
        }
    }

    async evaluateWeeklyMissionsCron(workspaceId: string, now: Date = new Date()): Promise<void> {
        // O cron roda na virada da semana (segunda de madrugada): a semana a
        // avaliar é a ANTERIOR, já completa. Avaliar a semana corrente (recém
        // iniciada e vazia) zeraria a streak permanentemente.
        const currentWeekStart = startOfWeekInTz(now);
        const startOfWeek = addCalendarDays(currentWeekStart, -7);
        const endOfWeek = endOfWeekFromStart(startOfWeek);
        const weekId = getWeekId(startOfWeek);

        let snapshot = await this.gamificationRepository.getWeeklyMissionsByWeek(workspaceId, weekId);

        // ÚLTIMA passada na semana que fechou, ANTES de decidir a streak.
        //
        // As regras que leem o `period_summaries` semanal (margem acima do
        // plano, receita recebida vs prevista) dependeriam, sem isto, de o
        // último evento da semana ter chegado DEPOIS de o sumário ter sido
        // escrito — e nada promete essa ordem. Aqui a semana está fechada e o
        // sumário, parado: é o único momento em que o número é definitivo.
        //
        // Só roda quando há missão EM ABERTO, e reaproveita a consulta acima:
        // este cron varre a base inteira, e reavaliar uma semana já toda
        // concluída seriam três leituras jogadas fora em todo workspace que
        // vai bem.
        //
        // Falhar aqui não pode derrubar a streak nem os badges de missão, que
        // são o trabalho principal deste cron.
        if (snapshot.some((mission) => mission.status !== "completed")) {
            try {
                const preloaded: Partial<Record<WeeklyMissionType, WeeklyMissionDocument | null>> = {};
                for (const type of WEEKLY_MISSION_TYPES) {
                    preloaded[type] = snapshot.find((mission) => mission.type === type) ?? null;
                }

                await this.advanceWeeklyMissions({
                    workspaceId,
                    weekId,
                    // A semana pertence ao mês do seu DOMINGO (ver F1.5 no
                    // README): numa semana que atravessa a virada, o
                    // planejamento a olhar é o do mês em que ela começou.
                    monthKey: getMonthKeyInTz(startOfWeek),
                    startOfWeek,
                    endOfWeek,
                    // A semana está inteira decorrida.
                    elapsedFullDays: 7,
                    eventType: "weekly_close",
                    eventData: null,
                    reads: {},
                    preloaded,
                });

                // A passada final pode ter FECHADO missão: reler é o que
                // permite a streak subir na MESMA execução, em vez de o
                // usuário perder a sequência por um problema de ordem de
                // escrita que o servidor acabou de corrigir.
                snapshot = await this.gamificationRepository.getWeeklyMissionsByWeek(workspaceId, weekId);
            }
            catch (e) {
                logger.error("[GamificationService] Falha na avaliação final das missões da semana:", e);
            }
        }


        let allCompleted = true;
        let count = 0;
        for (const mission of snapshot) {
            count++;
            if (mission.status !== "completed") {
                allCompleted = false;
            }
        }

        if (count === 0) {
            allCompleted = false;
        }

        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        if (!workspaceData) {
            return;
        }

        // F2.3: os streaks vivem em `streaks` (mapa). O leitor cai no
        // `weeklyStreaks` numérico quando o mapa ainda não existe, então
        // nenhuma sequência se perde na virada.
        const currentStreaks = readWorkspaceStreaks(workspaceData);

        if (allCompleted) {
            const missions = currentStreaks.missions + 1;
            await this.gamificationRepository.updateWorkspaceStreaks(workspaceId, { missions });

            if (missions >= 4) {
                await this.unlockBadge(workspaceId, "iron_consistency");
            }
        }
        else {
            await this.gamificationRepository.updateWorkspaceStreaks(workspaceId, { missions: 0 });
        }

        // Badges de missões (mission_first, mission_three, all_missions_week):
        // antes estas checagens nunca eram invocadas.
        try {
            const completedMissionsTotal = await this.gamificationRepository.getCompletedMissionsCount(workspaceId);
            await this.checkMissionBadges(workspaceId, completedMissionsTotal, allCompleted ? 1 : 0);
        }
        catch (e) {
            logger.error("[GamificationService] Error checking mission badges:", e);
        }
    }

    /**
     * F2.3 — XP DA SEMANA QUE FECHOU DENTRO DO PLANO.
     *
     * Roda no cron semanal (segunda de madrugada) e avalia a semana ANTERIOR,
     * já completa, a partir do `period_summaries/{YYYY-Www}` — o mesmo
     * documento que o app mostra. Para cada categoria de DESPESA com limite
     * vigente naquela semana (`generalPlannedAmount > 0`, a proporção semanal
     * do limite mensal — ver F1.5):
     *
     *   +20  por categoria que fechou dentro do limite
     *   +50  se TODAS fecharam dentro
     *   +10 × streak  de semanas consecutivas dentro do plano (teto 100)
     *
     * Duas decisões que valem explicar:
     *
     * - **Sem nenhuma categoria com limite, a streak ZERA.** "Semanas dentro do
     *   plano" pressupõe um plano; apagar todos os limites não pode ser uma
     *   forma de preservar a sequência indefinidamente.
     * - **Dentro do limite é `<=`, não `<`.** Gastar exatamente o planejado é
     *   o alvo, não uma falha por um centavo.
     *
     * Idempotente pela chave `workspaceId_weekId`: uma reexecução do cron (ou
     * duas instâncias no mesmo minuto) não concede o XP duas vezes.
     */
    async evaluateWeeklyPlanXp(workspaceId: string, now: Date = new Date()): Promise<void> {
        // Mesma janela do `evaluateWeeklyMissionsCron`: a semana anterior.
        const previousWeekStart = addCalendarDays(startOfWeekInTz(now), -7);
        const weekId = getWeekId(previousWeekStart);

        const award = async () => {
            const rows = await this.gamificationRepository.getWeeklySummaryRows(workspaceId, weekId);

            const limited = rows.filter((row) => {
                // Categorias de sistema (saldo inicial, virtuais de
                // transferência) não são escolha de consumo — ver o mesmo
                // filtro em `evaluateMonthlyMissionsCron`.
                if (row.isSystem) return false;
                if (row.type !== CategoryType.expense) return false;
                return (row.generalPlannedAmount || 0) > 0;
            });

            const within = limited.filter((row) => {
                return (row.actualAmount || 0) <= row.generalPlannedAmount;
            });

            const allWithin = limited.length > 0 && within.length === limited.length;

            const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
            if (!workspaceData) return;

            const streaks = readWorkspaceStreaks(workspaceData);
            const planStreak = allWithin ? streaks.plan + 1 : 0;

            if (planStreak !== streaks.plan) {
                await this.gamificationRepository.updateWorkspaceStreaks(workspaceId, { plan: planStreak });
            }

            let xp = within.length * XP_VALUES.weeklyCategoryWithinLimit;
            const parts = [`${within.length}/${limited.length} categorias dentro do limite`];

            if (allWithin) {
                xp += XP_VALUES.weeklyAllWithinLimit;
                parts.push("todas dentro");

                const bonus = Math.min(
                    XP_VALUES.weeklyPlanStreakStep * planStreak,
                    XP_VALUES.weeklyPlanStreakCap
                );
                xp += bonus;
                parts.push(`streak ${planStreak} (+${bonus})`);
            }

            if (xp <= 0) return;

            // O XP vai para o total do workspace E para a barra da semana
            // AVALIADA — `previousWeekStart` é um instante dentro dela.
            await this.addXpWithWeekly(
                workspaceId,
                xp,
                `Plano da semana ${weekId}: ${parts.join(", ")}`,
                previousWeekStart
            );
        };

        if (this.idempotencyService) {
            await this.idempotencyService.runIdempotency(`${workspaceId}_${weekId}`, "weeklyPlanXp", award);
        }
        else {
            await award();
        }
    }

    /**
     * F2.3 — +30 XP na PRIMEIRA vez que uma categoria ganha um limite.
     *
     * Uma vez por categoria por workspace, garantido pelo marcador
     * `xpAwardedFor.planning.<categoryId>` no documento do workspace (gravado
     * na mesma transação do XP). Sem essa marca, apagar e recriar o mesmo
     * limite seria uma máquina de XP, e o jogo passaria a premiar mexer no
     * formulário em vez de planejar.
     */
    async awardPlanningCreationXp(workspaceId: string, planningDoc: any, now: Date = new Date()): Promise<boolean> {
        if (!planningDoc) return false;
        // Limite zerado não é limite: é o usuário desligando o planejamento.
        if (!((planningDoc.amount || 0) > 0)) return false;

        const categoryId = planningDoc.category?.id;
        if (typeof categoryId !== "string" || categoryId.length === 0) return false;
        if (isSystemCategory(categoryId, planningDoc.category)) return false;

        return this.awardOnceAndCredit(
            workspaceId,
            "planning",
            categoryId,
            XP_VALUES.planningCreated,
            "Limite criado para uma categoria nova",
            now
        );
    }

    /**
     * Concede o XP único e, quando ele de fato saiu, credita a barra da semana.
     *
     * A ordem importa: quem decide se há XP é a TRANSAÇÃO do repositório (o
     * marcador e o XP são gravados juntos). Só depois de ela dizer "sim" é que
     * a barra semanal é tocada — creditar antes faria a segunda criação do
     * mesmo limite inflar a semana sem inflar o total.
     */
    private async awardOnceAndCredit(
        workspaceId: string,
        group: "planning" | "recurring",
        categoryId: string,
        xp: number,
        reason: string,
        now: Date
    ): Promise<boolean> {
        const awarded = await this.gamificationRepository.awardXpOnce(
            workspaceId,
            group,
            categoryId,
            xp,
            reason
        );

        if (!awarded) return false;
        if (!this.weeklyXpWriter) return true;

        try {
            await this.weeklyXpWriter(workspaceId, now, xp);
        }
        catch (e) {
            logger.error(`[GamificationService] XP único ${group}/${categoryId} concedido a ${workspaceId}, mas a barra semanal não atualizou:`, e);
        }
        return true;
    }

    /**
     * F2.3 — +30 XP na PRIMEIRA order RECORRENTE de uma categoria.
     *
     * Recorrência é planejamento declarado: o usuário está dizendo "isto se
     * repete todo mês". Mesma idempotência do limite, em
     * `xpAwardedFor.recurring.<categoryId>`.
     *
     * Fatura e saldo inicial ficam de fora: são orders que o SERVIDOR cria, e
     * premiar o usuário por elas seria conceder XP por ter um cartão.
     */
    async awardRecurringCreationXp(workspaceId: string, orderDoc: any, now: Date = new Date()): Promise<boolean> {
        if (!orderDoc) return false;
        if (orderDoc.installmentType !== "recurring") return false;
        if (orderDoc.isInvoice === true) return false;
        if (orderDoc.status === "cancelled") return false;

        const categoryId = orderDoc.category?.id;
        if (typeof categoryId !== "string" || categoryId.length === 0) return false;
        if (isSystemCategory(categoryId, orderDoc.category)) return false;

        return this.awardOnceAndCredit(
            workspaceId,
            "recurring",
            categoryId,
            XP_VALUES.recurringCreated,
            "Recorrência criada para uma categoria nova",
            now
        );
    }

    async evaluateMonthlyMissionsCron(workspaceId: string): Promise<void> {
        const now = new Date();
        // Mês anterior completo, no fuso America/Sao_Paulo.
        const lastMonth = getMonthRangeInTz(now, -1);
        const year = lastMonth.year;

        // Linhas achatadas (uma por categoria) já com o join em `categories`.
        const rows = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            year,
            lastMonth.month
        );

        let underControl = true;
        // Só faz sentido premiar "tudo sob controle" quando houve de fato
        // planejamento de despesa no mês. Antes, qualquer workspace com um
        // period_summary qualquer ganhava o badge.
        let plannedExpenseCount = 0;

        let totalComfortExpenses = 0;
        let totalInvestmentSavings = 0;
        let totalIncomes = 0;

        for (const row of rows) {
            // Categorias de sistema (saldo inicial, virtuais de transferência)
            // não são escolha de consumo do usuário: o saldo inicial de um
            // cartão/dívida entrava como receita e as virtuais de empréstimo/
            // aporte tornavam `under_control` inatingível para quem as usa.
            if (row.isSystem) {
                continue;
            }

            const actual = row.actualAmount || 0;
            const planned = row.generalPlannedAmount || 0;

            if (row.type === CategoryType.expense) {
                if (planned > 0) {
                    plannedExpenseCount++;
                }
                if (actual > planned) {
                    underControl = false;
                }
                if (row.allocation === "comfort") {
                    totalComfortExpenses += actual;
                }
                if (row.allocation === "investment") {
                    totalInvestmentSavings += actual;
                }
            }
            else if (row.type === CategoryType.income) {
                totalIncomes += actual;
            }
        }

        if (underControl && plannedExpenseCount > 0) {
            await this.unlockBadge(workspaceId, "under_control");
        }

        if (totalIncomes > 0 && (totalInvestmentSavings / totalIncomes) >= 0.20) {
            await this.unlockBadge(workspaceId, "future_focus");
        }

        const prevMonth = getMonthRangeInTz(now, -2);

        const prevRows = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            prevMonth.year,
            prevMonth.month
        );

        let prevComfortExpenses = 0;
        for (const row of prevRows) {
            if (row.isSystem) {
                continue;
            }
            if (row.type === CategoryType.expense && row.allocation === "comfort") {
                prevComfortExpenses += (row.actualAmount || 0);
            }
        }

        if (prevComfortExpenses > 0 && totalComfortExpenses <= 0.8 * prevComfortExpenses) {
            await this.unlockBadge(workspaceId, "cost_cutter");
        }
    }

    /**
     * Badge no_credit_debt ("Livre de Juros"): concedido no cron mensal quando
     * o workspace possui pelo menos uma conta de cartão de crédito e nenhuma
     * parcela PENDENTE vinculada a cartão com vencimento no mês anterior.
     */
    async checkNoCreditDebtBadge(workspaceId: string): Promise<void> {
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        if (!workspaceData) {
            return;
        }
        const unlockedBadges = workspaceData.unlockedBadges || {};
        if (unlockedBadges["no_credit_debt"]) {
            return;
        }

        const cardAccountIds = await this.gamificationRepository.getCreditCardAccountIds(workspaceId);
        if (cardAccountIds.length === 0) {
            // Sem cartão de crédito, o badge não faz sentido.
            return;
        }

        const lastMonth = getMonthRangeInTz(new Date(), -1);
        const hasDebt = await this.gamificationRepository.hasPendingInstallmentsForAccounts(
            workspaceId,
            cardAccountIds,
            lastMonth.start,
            lastMonth.end
        );

        if (!hasDebt) {
            await this.unlockBadge(workspaceId, "no_credit_debt");
        }
    }

    /**
     * Executa a rotina semanal para todos os workspaces (chamado pelo
     * scheduler toda segunda-feira, 03:00 America/Sao_Paulo).
     *
     * A varredura é paginada, concorrente e com checkpoint (F5.5): antes, a
     * lista inteira de workspaces vinha para a memória e era percorrida em
     * série — quando o timeout estourava, a execução seguinte recomeçava do
     * zero e os últimos workspaces nunca eram avaliados.
     */
    async runWeeklyCronForAllWorkspaces(): Promise<void> {
        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "gamification_weekly",
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                await this.evaluateWeeklyMissionsCron(workspaceId);
                // F2.3: o XP que premia PLANEJAR. Vem depois das missões de
                // propósito — as duas leem a mesma semana já encerrada, e o
                // streak de plano é independente do de missões.
                await this.evaluateWeeklyPlanXp(workspaceId);
                await this.checkFinancialHealthBadges(workspaceId);
            }
        );

        logger.info(
            `[GamificationService] Weekly cron: ${result.processed} processados, ${result.failed} com falha, ` +
            `varredura ${result.completed ? "completa" : `interrompida em ${result.lastWorkspaceId}`}.`
        );
    }

    /**
     * Executa a rotina mensal para todos os workspaces (chamado pelo
     * scheduler todo dia 1, 03:00 America/Sao_Paulo). Mesma varredura
     * paginada com checkpoint do cron semanal.
     */
    async runMonthlyCronForAllWorkspaces(): Promise<void> {
        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "gamification_monthly",
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                await this.evaluateMonthlyMissionsCron(workspaceId);
                await this.checkFinancialHealthBadges(workspaceId);
                await this.checkNoCreditDebtBadge(workspaceId);
            }
        );

        logger.info(
            `[GamificationService] Monthly cron: ${result.processed} processados, ${result.failed} com falha, ` +
            `varredura ${result.completed ? "completa" : `interrompida em ${result.lastWorkspaceId}`}.`
        );
    }

    async checkSimpleWorkspaceBadges(workspaceId: string, workspaceData: any): Promise<void> {
        const name: string = workspaceData.name || "";
        const type: string = workspaceData.type || "";
        const members: string[] = workspaceData.members || [];
        const unlockedBadges = workspaceData.unlockedBadges || {};
        const createdAt: Date = workspaceData.createdAt?.toDate
            ? workspaceData.createdAt.toDate()
            : new Date(workspaceData.createdAt || Date.now());

        if (!unlockedBadges["profile_complete"] && name.trim().length > 0 && type.trim().length > 0) {
            await this.unlockBadge(workspaceId, "profile_complete");
        }
        if (!unlockedBadges["workspace_named"] && name.trim().length > 0) {
            await this.unlockBadge(workspaceId, "workspace_named");
        }
        if (!unlockedBadges["second_member"] && members.length >= 2) {
            await this.unlockBadge(workspaceId, "second_member");
        }

        const oneYearAgo = new Date();
        oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
        if (!unlockedBadges["workspace_one_year"] && createdAt <= oneYearAgo) {
            await this.unlockBadge(workspaceId, "workspace_one_year");
        }
    }

    async checkSimpleCategoryBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getCategoriesCount(workspaceId);
        if (count >= 1) {
            await this.unlockBadge(workspaceId, "first_category");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "five_categories");
        }
        if (count >= 10) {
            await this.unlockBadge(workspaceId, "ten_categories");
        }
    }

    async checkSimplePlanningBadges(workspaceId: string): Promise<void> {
        const snap = await this.gamificationRepository.getCategoryPlannings(workspaceId);
        let activeCount = 0;
        for (const p of snap) {
            if ((p.amount || 0) > 0) {
                activeCount++;
            }
        }
        if (activeCount >= 1) {
            await this.unlockBadge(workspaceId, "first_planning");
        }
        if (activeCount >= 5) {
            await this.unlockBadge(workspaceId, "planning_month");
        }
    }

    async checkSimpleGoalBadges(workspaceId: string, goalDoc: GamificationGoal): Promise<void> {
        const data = goalDoc;

        // Early-return por badge já desbloqueado: evita abrir transações e
        // consultas desnecessárias em cada escrita de goal.
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        const unlockedBadges = workspaceData?.unlockedBadges || {};
        const isLocked = (badgeId: string) => {
            return !unlockedBadges[badgeId];
        };

        if (isLocked("first_goal")) {
            await this.unlockBadge(workspaceId, "first_goal");
        }

        if (isLocked("goal_linked_account") && (data.accountId || data.accountIdTarget)) {
            await this.unlockBadge(workspaceId, "goal_linked_account");
        }

        // O documento de meta tem `startDate` e `deadline` (ver
        // lib/features/goal/domain/models/goal_model.dart). Os campos
        // `targetDate`, `createdAt` e `completedAt` NÃO existem: lidos como
        // antes, caíam em Date.now() e distorciam todos os cálculos abaixo.
        const startDate = toDate(data.startDate);
        const deadline = toDate(data.deadline);

        if (isLocked("long_term_goal") && startDate && deadline) {
            const monthsDiff = (deadline.getFullYear() - startDate.getFullYear()) * 12
                + deadline.getMonth() - startDate.getMonth();
            if (monthsDiff > 12) {
                await this.unlockBadge(workspaceId, "long_term_goal");
            }
        }

        // Só consulta a lista de goals se algum badge de contagem ainda falta.
        if (isLocked("two_active_goals") || isLocked("five_active_goals")) {
            const allGoals = await this.gamificationRepository.getGoals(workspaceId);
            let activeGoals = 0;
            for (const g of allGoals) {
                // `status === "active"` nunca casava: o documento de meta não
                // tem `status`. A definição única de meta ativa vive em
                // `isGoalActive` (não deletada, alvo não alcançado, no prazo).
                if (isGoalActive(g)) {
                    activeGoals++;
                }
            }
            if (isLocked("two_active_goals") && activeGoals >= 2) {
                await this.unlockBadge(workspaceId, "two_active_goals");
            }
            if (isLocked("five_active_goals") && activeGoals >= 5) {
                await this.unlockBadge(workspaceId, "five_active_goals");
            }
        }

        const current = data.currentAmount || 0;
        const target = data.targetAmount || 1;
        const pct = current / target;

        // Badges de PROGRESSO — só para metas de acúmulo.
        //
        // Numa meta de redução, `currentAmount` é o quanto já foi GASTO contra
        // um teto: "Primeiro Depósito" por ter gasto os primeiros reais e "Na
        // Metade do Caminho" por ter consumido metade do orçamento premiavam
        // exatamente o oposto do que a meta pede.
        if (isAccumulationGoal(resolveGoalType(data))) {
            if (current > 0) {
                if (isLocked("goal_deposit")) {
                    await this.unlockBadge(workspaceId, "goal_deposit");
                }
                if (isLocked("savings_start")) {
                    await this.unlockBadge(workspaceId, "savings_start");
                }
            }
            if (isLocked("goal_halfway") && pct >= 0.5) {
                await this.unlockBadge(workspaceId, "goal_halfway");
            }
            if (isLocked("goal_75pct") && pct >= 0.75) {
                await this.unlockBadge(workspaceId, "goal_75pct");
            }
        }

        // Daqui para baixo, SÓ meta concluída com sucesso (`outcome ==
        // "success"`). Uma meta que falhou — teto estourado ou prazo vencido sem
        // atingir — não concede nada.
        if (isGoalCompleted(data)) {
            // `completedAt` é carimbado pelo servidor junto com o desfecho
            // (`GoalServiceImpl.writeProgress` / cron `closeExpiredGoals`). Só
            // quando ele ainda não existe é que "agora" serve de aproximação.
            const completedAt = toDate(data.completedAt) ?? new Date();

            // "Sprint Financeiro": a meta foi PLANEJADA para menos de 30 dias.
            // Antes, createdAt/completedAt inexistentes davam daysDiff = 0 e o
            // badge era liberado para qualquer meta concluída.
            if (isLocked("short_term_goal") && startDate && deadline) {
                const plannedDays = (deadline.getTime() - startDate.getTime()) / 86400000;
                if (plannedDays > 0 && plannedDays < 30) {
                    await this.unlockBadge(workspaceId, "short_term_goal");
                }
            }

            if (isLocked("goal_under_deadline") && deadline && completedAt <= deadline) {
                await this.unlockBadge(workspaceId, "goal_under_deadline");
            }

            if (isLocked("goal_debt_paid") && resolveGoalType(data) === GoalType.payDebt) {
                await this.unlockBadge(workspaceId, "goal_debt_paid");
            }
        }
    }

    async checkSimpleTransactionBadges(workspaceId: string, installmentData: GamificationInstallment): Promise<void> {
        const type: string = installmentData.type || "";
        const amount: number = Math.abs(installmentData.referenceAmount || installmentData.amount || 0);

        // Early-return por badge já desbloqueado ANTES de qualquer consulta:
        // evita baixar todas as parcelas do workspace a cada transação.
        const workspaceData = await this.gamificationRepository.getWorkspaceById(workspaceId);
        const unlockedBadges = workspaceData?.unlockedBadges || {};
        const isLocked = (badgeId: string) => {
            return !unlockedBadges[badgeId];
        };

        if (isLocked("first_income") && type === "income") {
            await this.unlockBadge(workspaceId, "first_income");
        }
        if (isLocked("first_expense") && type === "expense") {
            await this.unlockBadge(workspaceId, "first_expense");
        }
        if (isLocked("first_transfer") && type === "transfer") {
            await this.unlockBadge(workspaceId, "first_transfer");
        }

        if (isLocked("round_number") && amount > 0 && amount % 1 === 0) {
            await this.unlockBadge(workspaceId, "round_number");
        }

        if (isLocked("big_transaction") && amount >= 1000) {
            await this.unlockBadge(workspaceId, "big_transaction");
        }

        if (isLocked("income_registered") && type === "income" && amount > 0) {
            await this.unlockBadge(workspaceId, "income_registered");
        }

        const countBadges: Array<[string, number]> = [
            ["five_transactions", 5],
            ["twenty_transactions", 20],
            ["fifty_transactions", 50],
            ["hundred_transactions", 100],
        ];
        const needsCount = countBadges.some(([badgeId]) => {
            return isLocked(badgeId);
        });
        const needsDocs = isLocked("small_transactions_ten") ||
            isLocked("first_month") ||
            isLocked("two_months_active");

        if (!needsCount && !needsDocs) {
            return;
        }

        if (needsCount) {
            // Só o número importa: aggregate count() em vez de baixar os docs.
            const settledCount = await this.gamificationRepository.getPaidInstallmentsCount(workspaceId);
            for (const [badgeId, threshold] of countBadges) {
                if (isLocked(badgeId) && settledCount >= threshold) {
                    await this.unlockBadge(workspaceId, badgeId);
                }
            }
        }

        if (needsDocs) {
            const settledSnap = await this.gamificationRepository.getPaidInstallments(workspaceId);

            if (isLocked("small_transactions_ten")) {
                let smallCount = 0;
                for (const d of settledSnap) {
                    const a = Math.abs(d.referenceAmount || d.amount || 0);
                    if (a < 10 && a > 0) {
                        smallCount++;
                    }
                }
                if (smallCount >= 10) {
                    await this.unlockBadge(workspaceId, "small_transactions_ten");
                }
            }

            if (isLocked("first_month") || isLocked("two_months_active")) {
                const paidDates = new Set<string>();
                for (const d of settledSnap) {
                    const pd = toDate(d.paidDate);
                    if (pd) {
                        paidDates.add(getMonthKeyInTz(pd));
                    }
                }
                if (isLocked("first_month") && paidDates.size >= 1) {
                    await this.unlockBadge(workspaceId, "first_month");
                }
                if (isLocked("two_months_active") && paidDates.size >= 2) {
                    await this.unlockBadge(workspaceId, "two_months_active");
                }
            }
        }
    }

    async checkSimpleAccountBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getAccountsCount(workspaceId);
        if (count >= 2) {
            await this.unlockBadge(workspaceId, "two_accounts");
        }
        if (count >= 3) {
            await this.unlockBadge(workspaceId, "three_accounts");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "five_accounts");
        }
    }

    async checkSimpleReconciliationBadges(workspaceId: string): Promise<void> {
        const count = await this.gamificationRepository.getCompletedReconciliationsCount(workspaceId);
        if (count >= 2) {
            await this.unlockBadge(workspaceId, "reconcile_second");
        }
        if (count >= 5) {
            await this.unlockBadge(workspaceId, "reconcile_five");
        }
    }

    async checkInviteAcceptedBadge(workspaceId: string): Promise<void> {
        await this.unlockBadge(workspaceId, "invite_accepted");
        await this.unlockBadge(workspaceId, "first_invite");
    }

    async checkMissionBadges(workspaceId: string, completedMissionsTotal: number, perfectWeeks: number): Promise<void> {
        if (completedMissionsTotal >= 1) {
            await this.unlockBadge(workspaceId, "mission_first");
        }
        if (completedMissionsTotal >= 3) {
            await this.unlockBadge(workspaceId, "mission_three");
        }
        if (perfectWeeks >= 1) {
            await this.unlockBadge(workspaceId, "all_missions_week");
        }
    }

    async checkFinancialHealthBadges(workspaceId: string): Promise<void> {
        const now = new Date();
        const currentMonth = getMonthRangeInTz(now, 0);

        const rows = await this.gamificationRepository.getPeriodSummaries(
            workspaceId,
            currentMonth.year,
            currentMonth.month
        );

        let totalIncome = 0;
        let totalExpenses = 0;
        const categoryIds = new Set<string>();

        for (const row of rows) {
            // Ver evaluateMonthlyMissionsCron: categorias de sistema ficam fora.
            if (row.isSystem) {
                continue;
            }

            if (row.type === CategoryType.income) {
                totalIncome += row.actualAmount || 0;
            }
            else if (row.type === CategoryType.expense) {
                totalExpenses += row.actualAmount || 0;
                // Só conta a categoria que teve movimento realizado no mês.
                if ((row.actualAmount || 0) !== 0) {
                    categoryIds.add(row.categoryId);
                }
            }
        }

        if (totalIncome > 0 && totalExpenses < totalIncome) {
            await this.unlockBadge(workspaceId, "expense_under_income");
        }
        if (categoryIds.size >= 3) {
            await this.unlockBadge(workspaceId, "three_categories_month");
        }
        if (categoryIds.size >= 5) {
            await this.unlockBadge(workspaceId, "five_categories_month");
        }

        const saved = totalIncome - totalExpenses;
        if (totalIncome > 0 && saved >= 0.1 * totalIncome) {
            await this.unlockBadge(workspaceId, "savings_10pct");
        }

        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
        const weekSnap = await this.gamificationRepository.getPaidInstallmentsSince(workspaceId, sevenDaysAgo);

        const activeDays = new Set<string>();
        for (const d of weekSnap) {
            const pd = toDate(d.paidDate);
            if (pd) {
                const parts = getZonedParts(pd);
                activeDays.add(`${parts.year}-${parts.month}-${parts.day}`);
            }
        }
        if (activeDays.size >= 7) {
            await this.unlockBadge(workspaceId, "week_complete");
        }
    }
}