/**
 * Validação server-side das respostas do Gemini (F5.2).
 *
 * `responseSchema` obriga o modelo a devolver JSON com a FORMA certa, mas não
 * garante o CONTEÚDO: ele continua podendo inventar um id de categoria, mandar
 * `NaN` num valor, uma data impossível, uma descrição de 40 mil caracteres ou
 * um enum fora da lista. Nada disso pode chegar ao Firestore nem ao cliente.
 *
 * Regras que valem para todos os validadores deste arquivo:
 *
 * - **Nunca lançam por causa de um item ruim.** Um item inválido é descartado
 *   com log e os demais seguem. Uma fatura com 80 lançamentos não pode ser
 *   perdida inteira porque o modelo errou a data de um deles.
 * - **Id só é aceito se veio do prompt.** Quando o conjunto de ids conhecidos
 *   não é passado, o prompt não mandou ids — então qualquer id na resposta é
 *   invenção e vira `null` (semântica de "categoria nova").
 * - **Texto é truncado, não descartado**, a menos que fique vazio.
 * - **Número precisa ser finito** e com o sinal coerente com o tipo do dado.
 */

import { HttpsError } from "firebase-functions/v2/https";
import { GoalFeasibilityPayload } from "../../features/goal/domain/models/goal.model";

// --- Limites -----------------------------------------------------------------

/** Nomes (categoria, conta, meta). */
export const MAX_NAME_LENGTH = 120;
/** Texto livre (descrição de lançamento, nome de missão, justificativa). */
export const MAX_TEXT_LENGTH = 500;
/** Nome de ícone do Material Design. */
export const MAX_ICON_LENGTH = 40;
/** Teto de itens em listas vindas de documento (extrato/fatura). */
export const MAX_DOCUMENT_ITEMS = 500;
/** Teto de metas e planejamentos sugeridos no onboarding. */
export const MAX_SUGGESTED_GOALS = 10;
export const MAX_SUGGESTED_PLANNINGS = 20;
/** Teto de valor monetário aceito (R$ 1 bilhão). Acima disso é erro de leitura. */
export const MAX_AMOUNT = 1_000_000_000;
/** Prazo máximo de uma meta sugerida, em meses. */
export const MAX_DEADLINE_MONTHS = 600;
/** Número máximo de parcelas de uma order extraída de documento. */
export const MAX_INSTALLMENT_COUNT = 480;
/** Alvo máximo de uma missão semanal. */
export const MAX_MISSION_TARGET = 100;

const DEFAULT_ICON = "category";
const DEFAULT_COLOR = "#4A8C9C";

// --- Enums -------------------------------------------------------------------

export const CATEGORY_TYPES = ["income", "expense"] as const;
export type ValidatedCategoryType = typeof CATEGORY_TYPES[number];

export const ORDER_TYPES = ["income", "expense"] as const;
export type ValidatedOrderType = typeof ORDER_TYPES[number];

export const INSTALLMENT_TYPES = ["single", "installment", "recurring"] as const;
export type ValidatedInstallmentType = typeof INSTALLMENT_TYPES[number];

export const ACCOUNT_RUNTIME_TYPES = ["checking", "investment", "creditCard", "debt"] as const;
export type ValidatedAccountRuntimeType = typeof ACCOUNT_RUNTIME_TYPES[number];

export const SUGGESTED_GOAL_TYPES = ["save_money", "reduce_expense", "reduce_credit_card"] as const;
export type ValidatedSuggestedGoalType = typeof SUGGESTED_GOAL_TYPES[number];

// --- Coletor de descartes ----------------------------------------------------

/**
 * Junta os motivos de descarte de um validador e emite UM log no fim.
 * Um log por item transformaria uma resposta ruim em centenas de linhas.
 */
class Discards {
    private readonly reasons: string[] = [];

    constructor(private readonly scope: string) { }

    drop(reason: string): null {
        this.reasons.push(reason);
        return null;
    }

    flush(): void {
        if (this.reasons.length === 0) return;
        const sample = this.reasons.slice(0, 10).join("; ");
        const extra = this.reasons.length > 10 ? ` (+${this.reasons.length - 10})` : "";
        console.warn(`[ai_validation:${this.scope}] ${this.reasons.length} item(ns) descartado(s): ${sample}${extra}`);
    }
}

// --- Primitivas --------------------------------------------------------------

/** Número finito (rejeita NaN, Infinity, string, null). */
export function finiteNumber(value: unknown): number | null {
    if (typeof value === "string" && value.trim() !== "") {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    }
    return typeof value === "number" && Number.isFinite(value) ? value : null;
}

/**
 * Valor monetário POSITIVO. Neste domínio o sinal vive no `type`
 * (income/expense), nunca no valor — o cliente compara `referenceAmount` (que é
 * positivo) com o valor do documento. Um negativo vira o seu módulo; zero e
 * valores absurdos são descartados.
 */
export function positiveAmount(value: unknown, max: number = MAX_AMOUNT): number | null {
    const num = finiteNumber(value);
    if (num === null) return null;
    const abs = Math.abs(num);
    if (abs === 0 || abs > max) return null;
    return round2(abs);
}

/** Saldo/limite: pode ser negativo (dívida), mas precisa ser finito e plausível. */
export function signedAmount(value: unknown, max: number = MAX_AMOUNT): number | null {
    const num = finiteNumber(value);
    if (num === null || Math.abs(num) > max) return null;
    return round2(num);
}

/** Inteiro dentro de uma faixa fechada. */
export function boundedInteger(value: unknown, min: number, max: number): number | null {
    const num = finiteNumber(value);
    if (num === null) return null;
    const int = Math.trunc(num);
    return int >= min && int <= max ? int : null;
}

export function round2(value: number): number {
    return Math.round(value * 100) / 100;
}

/**
 * Texto limpo e truncado. Remove caracteres de controle (o modelo às vezes
 * devolve \u0000 ao copiar de PDF) e corta no limite. Devolve null se sobrar
 * string vazia.
 */
export function cleanString(value: unknown, maxLength: number): string | null {
    if (typeof value !== "string") return null;
    // eslint-disable-next-line no-control-regex
    const cleaned = value.replace(/[\u0000-\u001F\u007F]/g, " ").replace(/\s+/g, " ").trim();
    if (cleaned.length === 0) return null;
    return cleaned.length > maxLength ? cleaned.slice(0, maxLength) : cleaned;
}

/** Valor de enum: devolve o próprio valor quando está na lista, senão null. */
export function enumValue<T extends string>(value: unknown, allowed: readonly T[]): T | null {
    return typeof value === "string" && (allowed as readonly string[]).includes(value)
        ? (value as T)
        : null;
}

/** Cor hexadecimal #RRGGBB (aceita #RGB e maiúsculas/minúsculas). */
export function hexColor(value: unknown, fallback: string = DEFAULT_COLOR): string {
    if (typeof value !== "string") return fallback;
    const trimmed = value.trim();
    if (/^#[0-9a-fA-F]{6}$/.test(trimmed)) return trimmed;
    if (/^#[0-9a-fA-F]{3}$/.test(trimmed)) {
        const [, r, g, b] = trimmed;
        return `#${r}${r}${g}${g}${b}${b}`;
    }
    return fallback;
}

/** Nome de ícone do Material Design (snake_case). */
export function iconName(value: unknown, fallback: string = DEFAULT_ICON): string {
    if (typeof value !== "string") return fallback;
    const trimmed = value.trim();
    return /^[A-Za-z0-9_]+$/.test(trimmed) && trimmed.length <= MAX_ICON_LENGTH
        ? trimmed
        : fallback;
}

/**
 * Data normalizada para `YYYY-MM-DD`.
 *
 * Aceita `YYYY-MM-DD`, ISO 8601 completo e o formato brasileiro `DD/MM/YYYY`
 * (que o modelo às vezes copia do documento). Rejeita data que não existe no
 * calendário (2025-02-30) e anos fora de 1970–2100 — um "0025-01-01" lido
 * errado de um PDF viraria lançamento fantasma.
 */
export function isoDate(value: unknown): string | null {
    if (typeof value !== "string") return null;
    const trimmed = value.trim();

    let year: number, month: number, day: number;

    const isoMatch = trimmed.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ].*)?$/);
    const brMatch = trimmed.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);

    if (isoMatch) {
        year = Number(isoMatch[1]);
        month = Number(isoMatch[2]);
        day = Number(isoMatch[3]);
    }
    else if (brMatch) {
        day = Number(brMatch[1]);
        month = Number(brMatch[2]);
        year = Number(brMatch[3]);
    }
    else {
        return null;
    }

    if (year < 1970 || year > 2100) return null;
    const date = new Date(Date.UTC(year, month - 1, day));
    if (
        date.getUTCFullYear() !== year ||
        date.getUTCMonth() !== month - 1 ||
        date.getUTCDate() !== day
    ) {
        return null;
    }
    return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

// --- Categoria sugerida ------------------------------------------------------

export interface ValidatedCategorySuggestion {
    /** Id de categoria EXISTENTE, ou null quando é categoria nova. */
    id: string | null;
    name: string;
    icon: string;
    color: string;
    type: ValidatedCategoryType;
}

/**
 * Categoria devolvida pela IA.
 *
 * `knownCategoryIds` é o conjunto de ids que o prompt de fato enviou. Quando é
 * `null`, o prompt mandou só nomes: qualquer id na resposta é alucinação e o
 * item vira categoria nova (`id: null`). Quando é um Set, um id fora dele é
 * descartado pelo mesmo motivo — apontar para uma categoria que não existe
 * criaria lançamento órfão.
 */
export function validateCategorySuggestion(
    raw: any,
    knownCategoryIds: Set<string> | null,
    fallbackType: ValidatedCategoryType
): ValidatedCategorySuggestion | null {
    if (!raw || typeof raw !== "object") return null;

    const name = cleanString(raw.name, MAX_NAME_LENGTH);
    if (!name) return null;

    const id = typeof raw.id === "string" && knownCategoryIds !== null && knownCategoryIds.has(raw.id)
        ? raw.id
        : null;

    return {
        id,
        name,
        icon: iconName(raw.icon),
        color: hexColor(raw.color),
        type: enumValue(raw.type, CATEGORY_TYPES) ?? fallbackType,
    };
}

// --- 1. goals (sugestão de metas e planejamentos no onboarding) --------------

export interface ValidatedGoalSuggestion {
    name: string;
    targetAmount: number;
    type: ValidatedSuggestedGoalType;
    deadlineMonths: number;
    icon: string;
}

export interface ValidatedPlanningSuggestion {
    category: ValidatedCategorySuggestion;
    amount: number;
}

export interface ValidatedGoalSuggestions {
    goals: ValidatedGoalSuggestion[];
    plannings: ValidatedPlanningSuggestion[];
}

export function validateGoalSuggestions(raw: any): ValidatedGoalSuggestions {
    const discards = new Discards("goals");

    const goals: ValidatedGoalSuggestion[] = [];
    for (const item of asArray(raw?.goals).slice(0, MAX_SUGGESTED_GOALS)) {
        if (!item || typeof item !== "object") {
            discards.drop("meta não é objeto");
            continue;
        }
        const name = cleanString(item.name, MAX_NAME_LENGTH);
        const targetAmount = positiveAmount(item.targetAmount);
        const type = enumValue(item.type, SUGGESTED_GOAL_TYPES);
        const deadlineMonths = boundedInteger(item.deadlineMonths, 1, MAX_DEADLINE_MONTHS);

        if (!name) {
            discards.drop("meta sem nome");
            continue;
        }
        if (targetAmount === null) {
            discards.drop(`meta "${name}" com targetAmount inválido`);
            continue;
        }
        if (!type) {
            discards.drop(`meta "${name}" com type fora do enum`);
            continue;
        }
        if (deadlineMonths === null) {
            discards.drop(`meta "${name}" com deadlineMonths inválido`);
            continue;
        }

        goals.push({ name, targetAmount, type, deadlineMonths, icon: iconName(item.icon, "flag") });
    }

    const plannings: ValidatedPlanningSuggestion[] = [];
    for (const item of asArray(raw?.plannings).slice(0, MAX_SUGGESTED_PLANNINGS)) {
        if (!item || typeof item !== "object") {
            discards.drop("planejamento não é objeto");
            continue;
        }
        const amount = positiveAmount(item.amount);
        if (amount === null) {
            discards.drop("planejamento com amount inválido");
            continue;
        }
        // O prompt de goals manda só NOMES de categoria: id nenhum é confiável.
        const category = validateCategorySuggestion(item.category, null, "expense");
        if (!category) {
            discards.drop("planejamento sem categoria válida");
            continue;
        }
        plannings.push({ category, amount });
    }

    discards.flush();
    return { goals, plannings };
}

// --- 2/3. documento (extrato, fatura, contrato) e OFX ------------------------

export interface ValidatedDocumentAccount {
    name: string | null;
    runtimeType: ValidatedAccountRuntimeType | null;
    color: string | null;
    icon: string | null;
    currentBalance: number | null;
    interestRate: number | null;
    limit: number | null;
    dueDay: number | null;
    closingDay: number | null;
}

export interface ValidatedDocumentOrder {
    type: ValidatedOrderType;
    description: string;
    amount: number;
    dueDate: string;
    installmentType: ValidatedInstallmentType;
    installmentCount: number;
    category: ValidatedCategorySuggestion | null;
}

export interface ValidatedDocumentAnalysis {
    /** Preenchido quando o modelo recusou o documento (não é extrato/fatura). */
    error: string | null;
    account: ValidatedDocumentAccount | null;
    orders: ValidatedDocumentOrder[];
}

/** Uma order extraída de documento. Usada pelo fluxo de conta e pelo de OFX. */
function validateDocumentOrder(
    raw: any,
    knownCategoryIds: Set<string> | null,
    discards: Discards
): ValidatedDocumentOrder | null {
    if (!raw || typeof raw !== "object") {
        return discards.drop("lançamento não é objeto");
    }

    const description = cleanString(raw.description, MAX_TEXT_LENGTH);
    if (!description) return discards.drop("lançamento sem descrição");

    const amount = positiveAmount(raw.amount);
    if (amount === null) return discards.drop(`lançamento "${description}" com amount inválido`);

    const dueDate = isoDate(raw.dueDate ?? raw.date);
    if (!dueDate) return discards.drop(`lançamento "${description}" com data inválida`);

    // Sem `type` válido o item é DESCARTADO. Inferir pelo sinal parecia
    // esperto, mas o caso perigoso é justamente o valor positivo sem type:
    // assumir "income" transforma uma compra em receita no extrato do
    // usuário, calado. `type` é obrigatório nos dois schemas, então uma
    // resposta sem ele já é resposta fora do contrato.
    const type = enumValue(raw.type, ORDER_TYPES);
    if (!type) return discards.drop(`lançamento "${description}" sem type válido`);

    const installmentType = enumValue(raw.installmentType, INSTALLMENT_TYPES) ?? "single";
    const installmentCount = installmentType === "single"
        ? 1
        : (boundedInteger(raw.installmentCount, 1, MAX_INSTALLMENT_COUNT) ?? 1);

    return {
        type,
        description,
        amount,
        dueDate,
        installmentType,
        installmentCount,
        category: validateCategorySuggestion(raw.category, knownCategoryIds, type),
    };
}

function validateDocumentAccount(raw: any): ValidatedDocumentAccount | null {
    if (!raw || typeof raw !== "object") return null;
    return {
        name: cleanString(raw.name, MAX_NAME_LENGTH),
        runtimeType: enumValue(raw.runtimeType, ACCOUNT_RUNTIME_TYPES),
        color: typeof raw.color === "string" ? hexColor(raw.color) : null,
        icon: typeof raw.icon === "string" ? iconName(raw.icon, "account_balance") : null,
        // Saldo pode ser negativo (dívida) — usa signedAmount, não positiveAmount.
        currentBalance: signedAmount(raw.currentBalance),
        interestRate: (() => {
            const rate = finiteNumber(raw.interestRate);
            return rate !== null && rate >= 0 && rate <= 1000 ? round2(rate) : null;
        })(),
        limit: (() => {
            const limit = finiteNumber(raw.limit);
            return limit !== null && limit >= 0 && limit <= MAX_AMOUNT ? round2(limit) : null;
        })(),
        dueDay: boundedInteger(raw.dueDay, 1, 31),
        closingDay: boundedInteger(raw.closingDay, 1, 31),
    };
}

export function validateDocumentAnalysis(
    raw: any,
    knownCategoryIds: Set<string> | null = null
): ValidatedDocumentAnalysis {
    const discards = new Discards("document");

    const error = cleanString(raw?.error, MAX_TEXT_LENGTH);
    if (error) {
        discards.flush();
        return { error, account: null, orders: [] };
    }

    const orders: ValidatedDocumentOrder[] = [];
    for (const item of asArray(raw?.orders).slice(0, MAX_DOCUMENT_ITEMS)) {
        const order = validateDocumentOrder(item, knownCategoryIds, discards);
        if (order) orders.push(order);
    }

    discards.flush();
    return { error: null, account: validateDocumentAccount(raw?.account), orders };
}

/** Classificação das transações de um OFX: só `orders`, sem dados de conta. */
export function validateOfxClassification(
    raw: any,
    knownCategoryIds: Set<string> | null = null
): { orders: ValidatedDocumentOrder[] } {
    const discards = new Discards("documentOfx");

    const orders: ValidatedDocumentOrder[] = [];
    for (const item of asArray(raw?.orders).slice(0, MAX_DOCUMENT_ITEMS)) {
        const order = validateDocumentOrder(item, knownCategoryIds, discards);
        if (order) orders.push(order);
    }

    discards.flush();
    return { orders };
}

// --- 4. conciliação ----------------------------------------------------------

export interface ValidatedReconciliationTransaction {
    description: string;
    amount: number;
    /** Sempre `YYYY-MM-DD`. */
    date: string;
    type: ValidatedOrderType;
    category: ValidatedCategorySuggestion | null;
}

export interface ValidatedReconciliation {
    error: string | null;
    transactions: ValidatedReconciliationTransaction[];
}

export function validateReconciliation(
    raw: any,
    knownCategoryIds: Set<string> | null = null
): ValidatedReconciliation {
    const discards = new Discards("reconciliation");

    const error = cleanString(raw?.error, MAX_TEXT_LENGTH);
    if (error) {
        discards.flush();
        return { error, transactions: [] };
    }

    // O modelo já respondeu com nomes diferentes em produção; os aliases ficam
    // como rede de segurança para a resposta que escapar do responseSchema.
    const rawList = asArray(raw?.transactions ?? raw?.orders ?? raw?.items);

    const transactions: ValidatedReconciliationTransaction[] = [];
    for (const item of rawList.slice(0, MAX_DOCUMENT_ITEMS)) {
        if (!item || typeof item !== "object") {
            discards.drop("transação não é objeto");
            continue;
        }

        const description = cleanString(item.description ?? item.memo ?? item.text, MAX_TEXT_LENGTH);
        if (!description) {
            discards.drop("transação sem descrição");
            continue;
        }

        const rawAmount = item.amount ?? item.value ?? item.total;
        const amount = positiveAmount(rawAmount);
        if (amount === null) {
            discards.drop(`transação "${description}" com amount inválido`);
            continue;
        }

        const date = isoDate(item.date ?? item.dueDate ?? item.timestamp);
        if (!date) {
            discards.drop(`transação "${description}" com data inválida`);
            continue;
        }

        // Mesma regra do lançamento de documento: sem `type` válido,
        // descarta. Assumir "income" inverteria o sinal de um gasto.
        const type = enumValue(item.type, ORDER_TYPES);
        if (!type) {
            discards.drop(`transação "${description}" sem type válido`);
            continue;
        }

        transactions.push({
            description,
            amount,
            date,
            type,
            category: validateCategorySuggestion(item.category, knownCategoryIds, type),
        });
    }

    discards.flush();
    return { error: null, transactions };
}

// --- 5. transação automática (notificação do celular) ------------------------

export interface ValidatedAutomaticTransaction {
    category: ValidatedCategorySuggestion | null;
    /** Id de conta EXISTENTE, ou null. */
    accountId: string | null;
}

/**
 * Aqui os ids importam de verdade: o prompt manda as categorias e contas do
 * workspace com id, e o resultado é gravado direto em `categoryId`/`accountId`
 * da transação automática. Um id inventado apontaria para nada.
 */
export function validateAutomaticTransaction(
    raw: any,
    knownCategoryIds: Set<string>,
    knownAccountIds: Set<string>
): ValidatedAutomaticTransaction | null {
    if (!raw || typeof raw !== "object") return null;

    const discards = new Discards("automaticTransaction");

    if (typeof raw.category?.id === "string" && !knownCategoryIds.has(raw.category.id)) {
        discards.drop(`categoryId inexistente "${raw.category.id}" — tratada como categoria nova`);
    }
    const category = validateCategorySuggestion(raw.category, knownCategoryIds, "expense");

    let accountId: string | null = null;
    if (typeof raw.accountId === "string" && raw.accountId.trim().length > 0) {
        if (knownAccountIds.has(raw.accountId)) {
            accountId = raw.accountId;
        }
        else {
            discards.drop(`accountId inexistente "${raw.accountId}" — ignorado`);
        }
    }

    discards.flush();
    if (!category && !accountId) return null;
    return { category, accountId };
}

// --- 6. missões semanais -----------------------------------------------------

export interface ValidatedMission {
    name: string;
    target: number;
}

export interface ValidatedWeeklyMissions {
    consistency: ValidatedMission | null;
    discipline: ValidatedMission | null;
    organization: ValidatedMission | null;
}

/**
 * Missão inválida vira `null` de propósito: o GamificationService já tem um
 * texto padrão para cada tipo (`aiMissions?.consistency?.name || fallback`),
 * então a semana nunca fica sem missão.
 */
export function validateWeeklyMissions(raw: any): ValidatedWeeklyMissions {
    const discards = new Discards("weeklyMissions");

    const one = (key: "consistency" | "discipline" | "organization"): ValidatedMission | null => {
        const item = raw?.[key];
        if (!item || typeof item !== "object") return discards.drop(`missão ${key} ausente`);

        const name = cleanString(item.name, MAX_TEXT_LENGTH);
        if (!name) return discards.drop(`missão ${key} sem nome`);

        const target = boundedInteger(item.target, 1, MAX_MISSION_TARGET);
        if (target === null) return discards.drop(`missão ${key} com target inválido`);

        return { name, target };
    };

    const result = {
        consistency: one("consistency"),
        discipline: one("discipline"),
        organization: one("organization"),
    };
    discards.flush();
    return result;
}

// --- Entrada: goalPayload de analyzeGoalFeasibility --------------------------

/**
 * Valida o `goalPayload` que o CLIENTE manda para `analyzeGoalFeasibility`
 * ANTES de ele virar prompt. Diferente dos validadores acima, este LANÇA
 * `invalid-argument`: é entrada do usuário, não saída do modelo, e mandar lixo
 * para o Gemini gastaria cota e devolveria uma análise sem sentido.
 */
export function validateGoalFeasibilityPayload(raw: any): GoalFeasibilityPayload {
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
        throw new HttpsError("invalid-argument", "goalPayload deve ser um objeto.");
    }

    const name = cleanString(raw.name, MAX_NAME_LENGTH);
    if (!name) {
        throw new HttpsError("invalid-argument", "goalPayload.name é obrigatório (texto de 1 a 120 caracteres).");
    }

    const targetAmount = finiteNumber(raw.targetAmount);
    if (targetAmount === null || targetAmount <= 0 || targetAmount > MAX_AMOUNT) {
        throw new HttpsError(
            "invalid-argument",
            `goalPayload.targetAmount deve ser um número maior que zero e no máximo ${MAX_AMOUNT}.`
        );
    }

    const deadlineDays = boundedInteger(raw.deadlineDays, 1, 366 * 50);
    if (deadlineDays === null) {
        throw new HttpsError("invalid-argument", "goalPayload.deadlineDays deve ser um inteiro entre 1 e 18300.");
    }

    const monthlyRequired = finiteNumber(raw.monthlyRequired);
    if (monthlyRequired === null || monthlyRequired < 0 || monthlyRequired > MAX_AMOUNT) {
        throw new HttpsError(
            "invalid-argument",
            `goalPayload.monthlyRequired deve ser um número entre zero e ${MAX_AMOUNT}.`
        );
    }

    const type = cleanString(raw.type, MAX_NAME_LENGTH);
    if (!type) {
        throw new HttpsError("invalid-argument", "goalPayload.type é obrigatório.");
    }

    // Só os campos conhecidos seguem para o prompt: qualquer extra que o cliente
    // mandasse entraria no template como texto livre.
    return { name, targetAmount: round2(targetAmount), deadlineDays, monthlyRequired: round2(monthlyRequired), type };
}

// --- utilitário --------------------------------------------------------------

function asArray(value: unknown): any[] {
    return Array.isArray(value) ? value : [];
}
