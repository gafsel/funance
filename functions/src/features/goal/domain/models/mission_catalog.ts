/**
 * CATÁLOGO DETERMINÍSTICO DE MISSÕES SEMANAIS, POR TIPO DE WORKSPACE.
 *
 * O produto atende DOIS tipos de usuário — `workspaces.type` = `personal` |
 * `business` — e isso vale para funcionalidade e texto. Até aqui a missão
 * semanal era escrita pela IA a partir de um prompt que apenas MENCIONAVA o
 * tipo, com fallbacks fixos em linguagem pessoal. O resultado apareceu em
 * produção: um workspace de EMPRESA recebeu "Reduzir gastos com alimentação".
 *
 * A correção não é um prompt melhor. É este catálogo:
 *
 *  - o OBJETIVO da missão (o que conta como progresso, o alvo, o XP e a tela
 *    que resolve a missão) passa a ser **dado**, escrito aqui, por tipo de
 *    workspace e tipo de missão;
 *  - a IA, quando existe, só pode TEMPERAR o texto de um template já escolhido
 *    (ver `ai_validation.validateWeeklyMissionNames`). Ela não escolhe mais o
 *    objetivo, e uma resposta que fuja do template é descartada;
 *  - a variação entre semanas, que era o argumento para usar IA, sai de um
 *    HASH do `weekId` sobre os templates daquele tipo — determinística,
 *    reproduzível e de graça.
 *
 * Todo texto existe em `pt` e `en` com placeholders (`{category}`, `{target}`),
 * e o documento gravado leva `nameKey` + `params` para o app localizar. O
 * `name` em português continua sendo gravado para a build instalada, que só
 * sabe ler o texto pronto.
 */

import { WorkspaceAudience } from "./audience.model";

export type { WorkspaceAudience };
export { WORKSPACE_AUDIENCES, resolveAudience } from "./audience.model";

/** As três missões semanais. O id do documento é `{weekId}_{type}`. */
export const WEEKLY_MISSION_TYPES = ["consistency", "discipline", "organization"] as const;

export type WeeklyMissionType = typeof WEEKLY_MISSION_TYPES[number];

/**
 * O que CONTA como progresso. Cada regra é avaliada por
 * `GamificationService.evaluateMissionRule`, e o nome aqui é o contrato entre
 * o template e aquele avaliador — mudar um valor destes muda o significado de
 * missões já gravadas, então eles são ESTÁVEIS.
 */
export const MISSION_PROGRESS_RULES = [
    /** Categorias com limite > 0 vigente no mês corrente. */
    "planned_categories",
    /** Dias JÁ decorridos da semana em que a maior categoria ficou no limite diário. */
    "days_within_category_limit",
    /** Itens conciliados no extrato do evento (`totalTransactionsProcessed`). */
    "reconciled_statement_items",
    /** Extratos conciliados (documentos `reconciliations` concluídos) na semana. */
    "reconciled_statements",
    /** Lançamentos automáticos da semana já resolvidos (consolidados ou descartados). */
    "categorized_auto_transactions",
    /** Faturas de cartão pagas até o dia do vencimento, na semana. */
    "invoice_paid_on_time",
    /** A semana fechou com margem (receita − despesa) >= a margem planejada. */
    "weekly_margin_above_plan",
    /** Percentual da receita PLANEJADA da semana que de fato entrou. */
    "income_received_vs_planned",
] as const;

export type MissionProgressRule = typeof MISSION_PROGRESS_RULES[number];

/** Placeholders que um nome de missão pode conter. */
export type MissionParamName = "category" | "target";

/** Os valores dos placeholders, como vão para o documento (`params`). */
export interface MissionParams {
    /** Nome da categoria/centro de custo de maior peso. */
    category?: string;
    /** Alvo efetivo da missão. */
    target?: number;
}

export interface MissionTemplate {
    /**
     * Identidade ESTÁVEL do template (`templateKey` no documento). É por ela
     * que o avaliador de progresso e o script de retag reconhecem a missão —
     * renomear uma chave equivale a criar outro template.
     */
    key: string;
    audience: WorkspaceAudience;
    type: WeeklyMissionType;
    /**
     * Chave de i18n para o app (identificador válido de ARB). O servidor
     * continua gravando `name` em português; `nameKey` + `params` são o
     * caminho para o app traduzir sem depender do texto do servidor.
     */
    nameKey: string;
    /** Texto com placeholders, por locale. */
    name: { pt: string; en: string };
    /** Alvo padrão. O documento pode gravar outro (a IA NÃO pode mudá-lo). */
    target: number;
    rewardXp: number;
    progressRule: MissionProgressRule;
    /**
     * Rota interna que resolve a missão — o CTA do card no app. Ver
     * `MISSION_ACTION_PATHS`.
     */
    actionPath: string;
    /** Placeholders que o nome usa, na ordem em que aparecem. */
    params: MissionParamName[];
    /**
     * Valores usados quando o dado do placeholder não existe (workspace sem
     * nenhuma categoria planejada, por exemplo). Sem isto o nome sairia com um
     * `{category}` literal na cara do usuário — ver `buildMissionName`.
     */
    fallbackParams?: { [K in MissionParamName]?: { pt: string; en: string } };
    /**
     * Palavras que o nome REESCRITO pela IA tem obrigatoriamente que conter
     * (comparação por SUBSTRING, sem acento e sem caixa). É o que amarra a
     * resposta ao OBJETIVO do template: sem isto, "temperar o texto" vira
     * inventar outra missão — que foi exatamente o defeito de produção. Ver
     * `validateWeeklyMissionNames`.
     *
     * Os termos são RADICAIS, não palavras inteiras: "centro" (e não "centro
     * de custo") para casar com "centros de custo", "concilia" para casar com
     * "conciliar" e "conciliação". Exigir a flexão exata reprovaria o texto
     * certo só por estar no plural — e a consequência de reprovar é perder o
     * tempero, não a missão, mas perdê-lo em toda resposta esvazia a chamada.
     */
    aiRequiredTerms: string[];
}

/**
 * O que NÃO cabe no vocabulário de cada tipo de workspace.
 *
 * Vai para o prompt (como proibição explícita) e para o validador (como
 * rejeição). A lista de `business` é a que o caso de produção pede: uma missão
 * de empresa não fala de alimentação, lazer nem vida pessoal. A de `personal`
 * é a simétrica: um workspace doméstico não recebe missão sobre margem,
 * fechamento contábil ou centro de custo.
 *
 * Os termos são comparados sem acento e sem caixa, por SUBSTRING — `doméstic`
 * cobre "doméstico" e "doméstica"; `contábil` cobre "contábil" e "contabil".
 */
export const AUDIENCE_FORBIDDEN_TERMS: Record<WorkspaceAudience, string[]> = {
    business: [
        "alimentacao",
        "lazer",
        "vida pessoal",
        "familia",
        "supermercado",
        "mercado",
        "delivery",
        "restaurante",
        "academia",
        "ferias",
        "mesada",
        "domestic",
        "reserva de emergencia",
    ],
    personal: [
        "margem",
        "centro de custo",
        "fechamento contabil",
        "contabil",
        "dre",
        "cnpj",
        "folha de pagamento",
        "faturamento",
        "opex",
        "capital de giro",
    ],
};

/** Minúsculas, sem acento — a forma em que os termos acima são comparados. */
export function normalizeTerm(value: string): string {
    return value
        .normalize("NFD")
        // eslint-disable-next-line no-misleading-character-class
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase();
}

/**
 * As rotas que um `actionPath` de missão pode assumir.
 *
 * É a allowlist do coaching MAIS `/reconciliation`, que o app roteia
 * (`app_router.dart`, com `?accountId=` opcional e um seletor de conta quando
 * ele falta) mas que a allowlist de COACHING não lista. As duas listas
 * continuam separadas de propósito: oferecer `/reconciliation` ao prompt de
 * coaching produziria um slide com botão que a build instalada não desenha
 * (`coaching_slides_screen.dart`), e o CTA da missão é uma superfície nova,
 * sem build antiga para quebrar. Ver "Contratos com o app" no README.
 */
export const MISSION_ACTION_PATHS = [
    "/planning",
    "/planning-50-30-20",
    "/reconciliation",
    "/workspace/categories",
    "/workspace/accounts",
    "/category-details",
    "/transactions/form?status=pending",
] as const;

/**
 * OS TEMPLATES.
 *
 * Pessoal mantém exatamente os três objetivos que já existiam (é o que está em
 * produção e o que o jogo já sabe medir), com o texto reescrito na primeira
 * pessoa: os fallbacks antigos diziam "Equipe planeja limites..." dentro de um
 * workspace doméstico de um usuário só.
 *
 * Empresa ganha objetivos que existem numa empresa e NÃO existem numa casa —
 * centro de custo, margem, conciliação de todas as contas, triagem do que
 * entrou por notificação, fatura corporativa paga no prazo. Nenhum deles fala
 * de alimentação, lazer ou vida pessoal, que é exatamente o defeito que este
 * pacote corrige.
 */
export const MISSION_CATALOG: MissionTemplate[] = [
    // ── PESSOAL ──────────────────────────────────────────────────────────────
    {
        key: "personal_consistency_plan_limits",
        audience: "personal",
        type: "consistency",
        nameKey: "missionPersonalConsistencyPlanLimits",
        name: {
            pt: "Planejar limites para pelo menos {target} categorias e organizar a semana.",
            en: "Set limits for at least {target} categories to organise the week.",
        },
        target: 3,
        rewardXp: 150,
        progressRule: "planned_categories",
        actionPath: "/planning",
        params: ["target"],
        aiRequiredTerms: ["limite"],
    },
    {
        key: "personal_discipline_top_category",
        audience: "personal",
        type: "discipline",
        nameKey: "missionPersonalDisciplineTopCategory",
        name: {
            pt: "Manter a categoria {category} dentro do orçamento planejado por {target} dias.",
            en: "Keep the {category} category within its planned budget for {target} days.",
        },
        target: 5,
        rewardXp: 250,
        progressRule: "days_within_category_limit",
        actionPath: "/planning",
        params: ["category", "target"],
        fallbackParams: { category: { pt: "de maior gasto", en: "highest-spending" } },
        aiRequiredTerms: ["dia"],
    },
    {
        key: "personal_organization_reconcile_items",
        audience: "personal",
        type: "organization",
        nameKey: "missionPersonalOrganizationReconcileItems",
        name: {
            pt: "Fazer a conciliação completa de um extrato com pelo menos {target} itens.",
            en: "Fully reconcile a statement with at least {target} items.",
        },
        target: 5,
        rewardXp: 200,
        progressRule: "reconciled_statement_items",
        actionPath: "/reconciliation",
        params: ["target"],
        aiRequiredTerms: ["concilia", "extrato"],
    },

    // ── EMPRESA ──────────────────────────────────────────────────────────────
    {
        key: "business_consistency_cost_centers",
        audience: "business",
        type: "consistency",
        nameKey: "missionBusinessConsistencyCostCenters",
        name: {
            pt: "Planejar o limite de {target} centros de custo para o mês.",
            en: "Plan the limit for {target} cost centres this month.",
        },
        target: 5,
        rewardXp: 150,
        progressRule: "planned_categories",
        actionPath: "/planning",
        params: ["target"],
        aiRequiredTerms: ["limite", "centro"],
    },
    {
        key: "business_consistency_income_forecast",
        audience: "business",
        type: "consistency",
        nameKey: "missionBusinessConsistencyIncomeForecast",
        name: {
            pt: "Confirmar o recebimento de {target}% da receita prevista para a semana.",
            en: "Confirm {target}% of the revenue forecast for the week.",
        },
        target: 80,
        rewardXp: 150,
        progressRule: "income_received_vs_planned",
        actionPath: "/planning",
        params: ["target"],
        aiRequiredTerms: ["receita"],
    },
    {
        key: "business_discipline_top_cost_center",
        audience: "business",
        type: "discipline",
        nameKey: "missionBusinessDisciplineTopCostCenter",
        name: {
            pt: "Manter o centro de custo {category} dentro do plano por {target} dias.",
            en: "Keep the {category} cost centre within plan for {target} days.",
        },
        target: 5,
        rewardXp: 250,
        progressRule: "days_within_category_limit",
        actionPath: "/planning",
        params: ["category", "target"],
        fallbackParams: { category: { pt: "de maior peso", en: "heaviest" } },
        aiRequiredTerms: ["centro", "dia"],
    },
    {
        key: "business_discipline_margin",
        audience: "business",
        type: "discipline",
        nameKey: "missionBusinessDisciplineMargin",
        name: {
            pt: "Fechar a semana com a margem (receita − despesa) acima da planejada.",
            en: "Close the week with margin (revenue − expense) above plan.",
        },
        target: 1,
        rewardXp: 250,
        progressRule: "weekly_margin_above_plan",
        actionPath: "/planning",
        params: [],
        aiRequiredTerms: ["margem"],
    },
    {
        key: "business_organization_reconcile_statements",
        audience: "business",
        type: "organization",
        nameKey: "missionBusinessOrganizationReconcileStatements",
        name: {
            pt: "Conciliar {target} extratos das contas da empresa nesta semana.",
            en: "Reconcile {target} company account statements this week.",
        },
        target: 2,
        rewardXp: 200,
        progressRule: "reconciled_statements",
        actionPath: "/reconciliation",
        params: ["target"],
        aiRequiredTerms: ["concilia", "extrato"],
    },
    {
        key: "business_organization_categorize_auto",
        audience: "business",
        type: "organization",
        nameKey: "missionBusinessOrganizationCategorizeAuto",
        name: {
            pt: "Categorizar ou descartar {target} lançamentos automáticos antes do fechamento.",
            en: "Categorise or dismiss {target} automatic entries before closing.",
        },
        target: 10,
        rewardXp: 200,
        progressRule: "categorized_auto_transactions",
        actionPath: "/workspace/categories",
        params: ["target"],
        aiRequiredTerms: ["automatic"],
    },
    {
        key: "business_organization_invoice_on_time",
        audience: "business",
        type: "organization",
        nameKey: "missionBusinessOrganizationInvoiceOnTime",
        name: {
            pt: "Fechar {target} fatura do cartão corporativo pagando até o vencimento.",
            en: "Close {target} corporate card invoice by paying before the due date.",
        },
        target: 1,
        rewardXp: 200,
        progressRule: "invoice_paid_on_time",
        actionPath: "/workspace/accounts",
        params: ["target"],
        aiRequiredTerms: ["fatura", "vencimento"],
    },
];

const TEMPLATES_BY_KEY = new Map<string, MissionTemplate>(
    MISSION_CATALOG.map((template) => [template.key, template])
);

/** O template daquela chave, ou `null` se ela não existe (documento antigo). */
export function findMissionTemplate(key: string | null | undefined): MissionTemplate | null {
    if (!key) return null;
    return TEMPLATES_BY_KEY.get(key) ?? null;
}

/** Os candidatos daquele par (audiência, tipo), na ordem do catálogo. */
export function missionTemplatesFor(
    audience: WorkspaceAudience,
    type: WeeklyMissionType
): MissionTemplate[] {
    return MISSION_CATALOG.filter((t) => t.audience === audience && t.type === type);
}

/**
 * Hash FNV-1a de 32 bits.
 *
 * Qualquer hash serve; o que importa é ser ESTÁVEL entre execuções e entre
 * processos. `String.hashCode` não existe em JS e somar charCodes agruparia
 * semanas vizinhas na mesma posição (os ids `2026-W31` e `2026-W32` diferem
 * em um único caractere).
 */
export function hashString(value: string): number {
    let hash = 0x811c9dc5;
    for (let i = 0; i < value.length; i++) {
        hash ^= value.charCodeAt(i);
        // Multiplicação pelo primo FNV (16777619) em aritmética de 32 bits.
        hash = Math.imul(hash, 0x01000193) >>> 0;
    }
    return hash >>> 0;
}

/**
 * Escolhe UM template por semana, por tipo de missão e por audiência.
 *
 * A escolha é uma função pura de `(weekId, audience, type)`: duas execuções do
 * gatilho na mesma semana — ou o script de retag rodando dias depois —
 * chegam ao MESMO template, sem precisar reler o que já foi gravado.
 *
 * Devolve `null` apenas se o catálogo não tiver nenhum candidato, o que hoje é
 * impossível (os dois tipos cobrem os três tipos de missão) e é coberto por
 * teste justamente para continuar impossível.
 */
export function selectMissionTemplate(
    audience: WorkspaceAudience,
    type: WeeklyMissionType,
    weekId: string
): MissionTemplate | null {
    const candidates = missionTemplatesFor(audience, type);
    if (candidates.length === 0) return null;
    const index = hashString(`${weekId}|${audience}|${type}`) % candidates.length;
    return candidates[index];
}

/**
 * Preenche os placeholders do nome.
 *
 * Um placeholder sem valor cai no `fallbackParams` do template — "Manter a
 * categoria **de maior gasto** dentro do orçamento". Sem esse fallback o nome
 * sairia com um `{category}` literal na cara do usuário (ou, pior, com um
 * buraco: "Manter a categoria  dentro do orçamento"), que foi o preço de o
 * código antigo defaultar a categoria para "Alimentação" mesmo num workspace
 * sem nenhum planejamento.
 *
 * Um placeholder sem valor E sem fallback é mantido literal, de propósito: um
 * buraco visível denuncia o dado que faltou, em vez de sumir calado.
 */
export function buildMissionName(
    template: MissionTemplate,
    locale: "pt" | "en",
    params: MissionParams
): string {
    return template.name[locale].replace(/\{(category|target)\}/g, (match, token: string) => {
        if (token === "category") {
            if (params.category !== undefined && params.category !== null) {
                return params.category;
            }
            return template.fallbackParams?.category?.[locale] ?? match;
        }
        if (params.target !== undefined && params.target !== null) {
            return String(params.target);
        }
        return template.fallbackParams?.target?.[locale] ?? match;
    });
}
