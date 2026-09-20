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
    /**
     * Percentual das parcelas PAGAS da semana que têm categoria de verdade.
     * Transferências (e faturas, que são transferências) ficam fora da conta:
     * elas não carregam categoria por desenho — ver `isCategoryRefBroken`.
     */
    "categorized_week_installments",
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

/**
 * O que o workspace TEM — a peneira de CAPACIDADE.
 *
 * Os totais planejados dizem se a missão tem como ser MEDIDA naquela semana;
 * estes três dizem se ela tem como ser CUMPRIDA, alguma vez. São coisas
 * diferentes, e faltava a segunda.
 *
 * O RISCO que ela fecha: um workspace sem cartão de crédito podia sortear
 * "fechar a fatura corporativa no prazo", um sem nenhum extrato conciliado
 * podia sortear "conciliar um extrato", e um sem captura por notificação podia
 * sortear "triar lançamentos automáticos". Não seriam missões difíceis —
 * seriam missões que nenhuma ação dentro do app conseguiria concluir, e que
 * ainda impedem a semana perfeita e zeram a streak de quem não fez nada de
 * errado. Nenhum workspace de produção chegou a passar por isso (ver o falso
 * alarme de 2026-W38 no README); a peneira fecha o risco antes.
 *
 * São BOOLEANOS, e não contagens, porque toda pergunta aqui é "existe ao
 * menos um?": as consultas correspondentes usam `limit(1)` e devolver um
 * número seria gravar uma contagem que ninguém mediu.
 */
export interface MissionCapacity {
    /** Ao menos uma conta de cartão de crédito ativa. */
    hasCreditCardAccount: boolean;
    /** Ao menos um extrato conciliado ALGUMA VEZ (não só nesta semana). */
    hasReconciledStatementEver: boolean;
    /** Ao menos um lançamento automático nos últimos 30 dias. */
    hasRecentAutomaticTransaction: boolean;
}

/** Nenhuma capacidade conhecida — o que vale quando ninguém informa uma. */
export const NO_MISSION_CAPACITY: MissionCapacity = {
    hasCreditCardAccount: false,
    hasReconciledStatementEver: false,
    hasRecentAutomaticTransaction: false,
};

/**
 * O que o sorteio da semana sabe sobre o workspace.
 *
 * Duas metades:
 *
 *  - os totais PLANEJADOS da semana, em centavos, lidos do
 *    `period_summaries/{YYYY-Www}` no momento da geração — o que dá para
 *    MEDIR nesta semana;
 *  - a CAPACIDADE (`MissionCapacity`) — o que dá para CUMPRIR, nunca.
 *
 * Só isso: o contexto existe para peneirar templates impossíveis, não para
 * escolher missão por heurística — a escolha continua sendo o hash, que é o
 * que a torna reproduzível fora do gatilho (o script de retag chega ao mesmo
 * template).
 */
export interface MissionSelectionContext extends MissionCapacity {
    plannedIncomeCents: number;
    plannedExpenseCents: number;
}

/** Contexto vazio: nada planejado, nenhuma capacidade. */
export const EMPTY_MISSION_CONTEXT: MissionSelectionContext = {
    plannedIncomeCents: 0,
    plannedExpenseCents: 0,
    ...NO_MISSION_CAPACITY,
};

/**
 * Junta as duas metades num contexto.
 *
 * Existe para que quem lê o sumário (`sumWeeklyTotals`, que devolve também os
 * REALIZADOS) e quem lê a capacidade não precisem conhecer a forma exata do
 * contexto — e para que um campo novo de peneira quebre a COMPILAÇÃO dos dois
 * chamadores em vez de sumir calado com um `false` implícito.
 */
export function buildMissionSelectionContext(
    totals: { plannedIncomeCents: number; plannedExpenseCents: number },
    capacity: MissionCapacity
): MissionSelectionContext {
    return {
        plannedIncomeCents: totals.plannedIncomeCents,
        plannedExpenseCents: totals.plannedExpenseCents,
        hasCreditCardAccount: capacity.hasCreditCardAccount,
        hasReconciledStatementEver: capacity.hasReconciledStatementEver,
        hasRecentAutomaticTransaction: capacity.hasRecentAutomaticTransaction,
    };
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
     * **São termos em PORTUGUÊS, e só.** O prompt pede o nome em português
     * (`ai.config.ts`, regra 6 de `weeklyMissions`) e o documento grava `name`
     * em português para a build instalada; o inglês do catálogo é resolvido no
     * app a partir de `nameKey` + `params`, sem passar pela IA. O dia em que o
     * prompt passar a pedir outro idioma, este campo vira um mapa por locale —
     * até lá, um `aiRequiredTerms` genérico seria um nome mentindo sobre o que
     * o campo cobre.
     *
     * Os termos são RADICAIS, não palavras inteiras: "centro" (e não "centro
     * de custo") para casar com "centros de custo", "concilia" para casar com
     * "conciliar" e "conciliação". Exigir a flexão exata reprovaria o texto
     * certo só por estar no plural — e a consequência de reprovar é perder o
     * tempero, não a missão, mas perdê-lo em toda resposta esvazia a chamada.
     */
    aiRequiredTermsPt: string[];
    /**
     * Quando o template PODE ser sorteado para a semana.
     *
     * Ausente == sempre elegível. Existe porque duas missões corporativas
     * dependem de um dado que pode simplesmente não existir naquela semana: a
     * de receita prevista precisa de receita prevista, e a de margem precisa
     * dos dois lados do plano. Sem a peneira, o hash sorteava uma missão que o
     * avaliador nunca conseguiria medir — uma missão em 0% a semana inteira,
     * que ainda por cima impede a semana perfeita e zera a streak.
     *
     * A peneira roda ANTES do hash: o sorteio acontece entre os elegíveis, de
     * modo que a semana sem receita prevista recebe a outra missão do mesmo
     * tipo, e não um buraco.
     */
    isEligible?: (context: MissionSelectionContext) => boolean;
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
        aiRequiredTermsPt: ["limite"],
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
        aiRequiredTermsPt: ["dia"],
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
        aiRequiredTermsPt: ["concilia", "extrato"],
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
        aiRequiredTermsPt: ["limite", "centro"],
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
        aiRequiredTermsPt: ["receita"],
        // Sem receita prevista na semana não há de que receber 80%.
        isEligible: (context) => context.plannedIncomeCents > 0,
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
        aiRequiredTermsPt: ["centro", "dia"],
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
        aiRequiredTermsPt: ["margem"],
        // Margem planejada exige os DOIS lados do plano.
        isEligible: (context) => context.plannedIncomeCents > 0 && context.plannedExpenseCents > 0,
    },
    {
        key: "business_organization_reconcile_statements",
        audience: "business",
        type: "organization",
        nameKey: "missionBusinessOrganizationReconcileStatements",
        name: {
            pt: "Conciliar {target} extrato das contas da empresa nesta semana.",
            en: "Reconcile {target} company account statement this week.",
        },
        // Calibrado contra a única empresa real da base, que fez DUAS
        // conciliações na vida inteira. Um alvo de 2 por semana era um alvo
        // que ninguém jamais bateu — e uma missão inalcançável não ensina
        // nada, só trava a semana perfeita e zera a streak.
        target: 1,
        rewardXp: 200,
        progressRule: "reconciled_statements",
        actionPath: "/reconciliation",
        params: ["target"],
        aiRequiredTermsPt: ["concilia", "extrato"],
        // Conciliar exige extrato, e extrato exige o hábito (ou ao menos a
        // conta configurada para isso). Quem nunca conciliou nada não tem
        // como começar E terminar dentro da semana — a peneira olha se o
        // workspace já conciliou ALGUMA VEZ, não nesta semana.
        isEligible: (context) => context.hasReconciledStatementEver,
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
        // Mesma calibração: a empresa real recebeu DOIS lançamentos
        // automáticos na semana medida. Dez era metade de um mês de
        // notificações.
        target: 3,
        rewardXp: 200,
        progressRule: "categorized_auto_transactions",
        actionPath: "/workspace/categories",
        params: ["target"],
        aiRequiredTermsPt: ["automatic"],
        // Lançamento automático chega por notificação: quem não tem a captura
        // ligada (ou não recebeu nada no último mês) não tem o que triar.
        isEligible: (context) => context.hasRecentAutomaticTransaction,
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
        aiRequiredTermsPt: ["fatura", "vencimento"],
        // Sem conta de cartão de crédito não existe fatura corporativa para
        // fechar: a missão seria incumprível.
        isEligible: (context) => context.hasCreditCardAccount,
    },
    {
        // A missão de organização que SEMPRE dá para cumprir.
        //
        // As outras três de empresa dependem de o workspace ter cartão, ter o
        // hábito de conciliar ou receber lançamento automático. Uma empresa
        // que não tem nenhuma das três ficaria sem missão de organização —
        // e, sem este template, a peneira cairia no `all` (o sorteio entre
        // TODOS os candidatos) e devolveria justamente a missão impossível
        // que ela acabou de descartar.
        //
        // Categorizar o que foi pago na semana é o trabalho de organização
        // que existe em QUALQUER workspace que movimente dinheiro, é medido
        // com as parcelas que a avaliação já sabe ler (no máximo UMA consulta
        // a mais, e nenhuma quando a disciplina da semana também as lê — ver
        // `categorized_week_installments` no avaliador) e é o mesmo hábito
        // que o `fix_empty_category` existe para reparar.
        key: "business_organization_categorize_week",
        audience: "business",
        type: "organization",
        nameKey: "missionBusinessOrganizationCategorizeWeek",
        name: {
            pt: "Categorizar {target}% dos lançamentos pagos na semana.",
            en: "Categorise {target}% of the entries paid this week.",
        },
        target: 100,
        rewardXp: 200,
        progressRule: "categorized_week_installments",
        actionPath: "/workspace/categories",
        params: ["target"],
        aiRequiredTermsPt: ["categoriz", "lancamento"],
        // Sem `isEligible`: é ela que garante que a organização da empresa
        // nunca fique sem candidato possível.
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
 * A escolha é uma função pura de `(weekId, audience, type, context)`: duas
 * execuções do gatilho na mesma semana — ou o script de retag rodando dias
 * depois — chegam ao MESMO template, sem precisar reler o que já foi gravado.
 *
 * O `context` apenas PENEIRA (ver `MissionTemplate.isEligible`); quem escolhe
 * continua sendo o hash. Se a peneira não deixar ninguém de pé, o sorteio
 * volta a correr entre TODOS os candidatos: uma semana sem missão seria pior
 * que uma missão difícil de medir, porque o card some da tela e a streak
 * quebra sem explicação.
 *
 * Devolve `null` apenas se o catálogo não tiver nenhum candidato, o que hoje é
 * impossível (os dois tipos cobrem os três tipos de missão) e é coberto por
 * teste justamente para continuar impossível.
 */
export function selectMissionTemplate(
    audience: WorkspaceAudience,
    type: WeeklyMissionType,
    weekId: string,
    context: MissionSelectionContext = EMPTY_MISSION_CONTEXT
): MissionTemplate | null {
    const all = missionTemplatesFor(audience, type);
    if (all.length === 0) return null;

    const eligible = all.filter((template) => !template.isEligible || template.isEligible(context));
    const candidates = eligible.length > 0 ? eligible : all;

    // O hash corre sobre a lista PENEIRADA, e isso é deliberado: numa semana
    // sem receita prevista, a consistência da empresa cai sempre na missão de
    // centros de custo, e é isso que se quer. O preço é que a escolha só é
    // reproduzível junto com o contexto — por isso o documento grava
    // `templateKey`, e é ele (não um novo sorteio) que o avaliador de
    // progresso usa depois.
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
