import { resolveCents } from "../../../../core/utils/money";

/**
 * Tipos de meta, com os valores REALMENTE persistidos no Firestore.
 *
 * O cliente Flutter usa uma union freezed (`GoalModel.payDebt`,
 * `GoalModel.saveMoney`, ...) cujo discriminador é gravado no campo
 * `runtimeType` com o nome do factory em camelCase. O campo `type` do modelo
 * Flutter é um getter e NÃO é serializado — por isso os valores snake_case
 * que este enum usava antes (`save_money`, ...) nunca casavam com nada.
 */
export enum GoalType {
  payDebt = "payDebt",
  saveMoney = "saveMoney",
  reduceExpense = "reduceExpense",
  reduceCreditCard = "reduceCreditCard",
}

/**
 * Lê o tipo de uma meta cru do Firestore. Prioriza `runtimeType` (formato
 * atual da union freezed) e cai para `type` por segurança.
 */
export function resolveGoalType(goal: any): GoalType | undefined {
    const raw = goal?.runtimeType ?? goal?.type;
    const values = Object.values(GoalType) as string[];
    return values.includes(raw) ? (raw as GoalType) : undefined;
}

/**
 * Id da categoria de uma meta `reduceExpense`.
 *
 * O cliente grava a categoria inteira (mapa `CategoryModel`) no campo
 * `category`; `categoryId` é aceito como forma alternativa por segurança.
 */
export function resolveGoalCategoryId(goal: any): string | undefined {
    const raw = goal?.category?.id ?? goal?.categoryId;
    return typeof raw === "string" && raw.length > 0 ? raw : undefined;
}

export interface GoalModel {
  id: string;
  name: string;
  targetAmount: number;
  /** F1.10 — `targetAmount` em CENTAVOS INTEIROS. Ver `MONEY_CENTS_FIELDS`. */
  targetAmountCents?: number;
  currentAmount: number;
  /** F1.10 — `currentAmount` em CENTAVOS INTEIROS. */
  currentAmountCents?: number;
  /** Pode faltar em documentos legados: o cliente sempre grava. */
  deadline?: Date;
  icon?: string;
  type: GoalType;
  /** `runtimeType` é o discriminador real gravado pelo cliente. */
  runtimeType?: string;
  accountId?: string;
  /** Categoria da meta `reduceExpense` (mapa `CategoryModel` do cliente). */
  category?: Record<string, any>;
  startDate: Date;
  /**
   * Desfecho da meta. `null`/ausente = ainda em andamento. Escrito
   * EXCLUSIVAMENTE pelo servidor (as rules negam a escrita pelo cliente) e
   * TERMINAL: o primeiro desfecho é o que vale, nunca é reescrito.
   */
  outcome?: GoalOutcome | null;
  /** Instante do desfecho `success`. */
  completedAt?: Date | null;
  /** Instante do desfecho `failed`. */
  failedAt?: Date | null;
  metadata?: Record<string, any>;
  isDeleted: boolean;
}

/**
 * Desfecho de uma meta. Só existe depois que a meta ACABA — enquanto ela corre,
 * o campo é `null`.
 *
 * Por que um campo em vez de comparar `currentAmount` com `targetAmount`: nas
 * metas de REDUÇÃO os dois números querem dizer o oposto. `currentAmount` é o
 * quanto já foi GASTO contra um teto, então passar do alvo é FRACASSO, e o
 * sucesso só se conhece quando o prazo acaba com o gasto ainda abaixo do teto.
 * Nenhuma comparação instantânea distingue "vai bem, ainda dentro do teto" de
 * "terminou dentro do teto" — por isso o desfecho é gravado, não inferido.
 */
export enum GoalOutcome {
  success = "success",
  failed = "failed",
}

/**
 * Metas de ACÚMULO (`saveMoney`, `payDebt`): `currentAmount` é conquista e
 * alcançar o alvo é vitória. As de REDUÇÃO são o contrário — ver `GoalOutcome`.
 */
export function isAccumulationGoal(type: GoalType | undefined): boolean {
    return type === GoalType.saveMoney || type === GoalType.payDebt;
}

/** Lê o desfecho já gravado no documento (ou `null`). */
export function resolveGoalOutcome(goal: any): GoalOutcome | null {
    const raw = goal?.outcome;
    return raw === GoalOutcome.success || raw === GoalOutcome.failed ? raw : null;
}


/**
 * Desfecho que o ESTADO ATUAL da meta impõe, ou `null` se ela continua em
 * andamento. Não lê nem escreve nada: é a regra única que o serviço, o cron de
 * vencimento e os testes compartilham.
 *
 * - Acúmulo: alcançou o alvo → `success` (a qualquer momento). Prazo venceu sem
 *   alcançar → `failed`.
 * - Redução: passou do teto → `failed` (a qualquer momento). Prazo venceu com o
 *   gasto dentro do teto → `success`.
 *
 * Uma meta sem `deadline` e sem `targetAmount` válido nunca desfecha sozinha.
 */
export function evaluateGoalOutcome(goal: any, now: Date = new Date()): GoalOutcome | null {
    // F1.10 — a comparação é em CENTAVOS INTEIROS. A folga de meio centavo que
    // existia aqui (`AMOUNT_EPSILON = 0.005`) era exatamente o arredondamento
    // que `toCents` agora faz de forma exata: "alcançou o alvo" passou a
    // significar "alcançou, ao centavo", sem uma margem que o código carregava
    // só para não ser traído pelo `double`.
    const current = Number(goal?.currentAmount ?? 0);
    const target = Number(goal?.targetAmount ?? 0);
    const hasAmounts = Number.isFinite(current) && Number.isFinite(target) && target > 0;
    const accumulation = isAccumulationGoal(resolveGoalType(goal));

    if (hasAmounts) {
        const currentCents = resolveCents(current, goal?.currentAmountCents);
        const targetCents = resolveCents(target, goal?.targetAmountCents);

        if (accumulation && currentCents >= targetCents) {
            return GoalOutcome.success;
        }
        if (!accumulation && currentCents > targetCents) {
            return GoalOutcome.failed;
        }
    }

    const deadline = toGoalDate(goal?.deadline);
    if (!deadline || deadline.getTime() >= startOfDay(now).getTime()) {
        return null;
    }

    // Prazo vencido: acúmulo que não alcançou falhou; redução que não estourou
    // (e é o caso, senão já teria retornado acima) cumpriu o teto.
    return accumulation ? GoalOutcome.failed : GoalOutcome.success;
}

/**
 * Definição ÚNICA de "meta ativa", usada pelos badges (`two_active_goals`,
 * `five_active_goals`, missões) e pelo relatório do script de recálculo.
 *
 * Ativa = existe, ainda não desfechou e ainda está no prazo. Note que o VALOR
 * não entra na conta: uma meta de redução com o teto estourado não é "ativa
 * porque ainda não chegou no alvo" — ela já falhou, e quem diz isso é o campo
 * `outcome`.
 *
 * O documento de meta NÃO tem campo `status` — o cliente nunca gravou um. Os
 * badges liam `status === "active"` e por isso jamais disparavam.
 */
export function isGoalActive(goal: any, now: Date = new Date()): boolean {
    if (!goal || goal.isDeleted === true) {
        return false;
    }

    if (resolveGoalOutcome(goal) !== null) {
        return false;
    }

    const deadline = toGoalDate(goal.deadline);
    if (deadline && deadline.getTime() < startOfDay(now).getTime()) {
        return false;
    }

    return true;
}

/**
 * Meta CONCLUÍDA COM SUCESSO — e só isso libera os badges de conclusão.
 *
 * Antes bastava `currentAmount >= targetAmount`, o que premiava uma meta de
 * redução por ter ESTOURADO o teto. Agora a resposta é o desfecho gravado.
 */
export function isGoalCompleted(goal: any): boolean {
    return resolveGoalOutcome(goal) === GoalOutcome.success;
}

/** Meta encerrada sem sucesso (teto estourado ou prazo vencido sem atingir). */
export function isGoalFailed(goal: any): boolean {
    return resolveGoalOutcome(goal) === GoalOutcome.failed;
}

/** Converte Timestamp/ISO/Date num `Date` válido (ou `null`). */
export function toGoalDate(raw: any): Date | null {
    if (!raw) {
        return null;
    }
    const date = raw?.toDate ? raw.toDate() : new Date(raw);
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
}

function startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export interface GoalFeasibilityPayload {
  name: string;
  targetAmount: number;
  deadlineDays: number;
  monthlyRequired: number;
  type: string;
}

export interface MonthlyBreakdownEntry {
  month: string;
  totalIncome: number;
  totalExpense: number;
  categories: { name: string; type: string; amount: number }[];
}
