/**
 * As rotas internas que um slide de coaching pode acionar — UMA lista, usada
 * por três lugares que antes a repetiam:
 *
 *  1. o PROMPT (`ai.config.ts`), que enumera as rotas para a IA;
 *  2. o VALIDADOR (`sanitizeActionPath`), que descarta o que a IA alucinar;
 *  3. o CLIENTE Flutter, que ignora o botão de uma rota que não conhece.
 *
 * Os três divergiram. O backend aceitava `/` e recusava `/goals/form`,
 * `/accounts/form`, `/category-details`, `/workspace/badges` e
 * `/coaching/history`; o cliente fazia exatamente o contrário. O efeito era
 * mudo dos dois lados: uma rota que o backend recusava saía do servidor SEM
 * BOTÃO (o slide perdia a ação e ninguém via erro), e uma rota que o cliente
 * não reconhecia chegava com botão que simplesmente não aparecia.
 *
 * A lista agora é a UNIÃO das duas, e o prompt é gerado dela: acrescentar uma
 * rota aqui a oferece à IA e a libera no validador na mesma edição. O cliente
 * precisa aceitar esta mesma lista — ver "Contratos com o app" no
 * `functions/README.md`.
 */

/** Rota do formulário de lançamento — a única com query string obrigatória. */
export const TRANSACTION_FORM_PATH = "/transactions/form";

/** Uma rota da allowlist, com o texto que explica à IA QUANDO usá-la. */
export interface CoachingActionRoute {
    /** O caminho, sem query string. */
    path: string;
    /** Como o caminho é oferecido à IA (pode já trazer a query obrigatória). */
    promptPath: string;
    /** Quando usar — vai literalmente para o prompt. */
    whenToUse: string;
}

/**
 * A allowlist, na ordem em que o prompt a apresenta: primeiro as telas de
 * PLANEJAR (que é o que o produto quer premiar), depois as de registrar, por
 * fim as de consulta.
 */
export const COACHING_ACTION_ROUTES: CoachingActionRoute[] = [
    {
        path: "/planning",
        promptPath: "/planning",
        whenToUse: "definir ou revisar o LIMITE mensal de categorias de despesa/receita",
    },
    {
        path: "/planning-50-30-20",
        promptPath: "/planning-50-30-20",
        whenToUse: "rebalancear a divisão essencial/conforto/investimento da renda (regra 50-30-20)",
    },
    {
        path: TRANSACTION_FORM_PATH,
        promptPath: `${TRANSACTION_FORM_PATH}?status=pending`,
        whenToUse: "AGENDAR/PLANEJAR um lançamento que ainda vai acontecer",
    },
    {
        path: TRANSACTION_FORM_PATH,
        promptPath: `${TRANSACTION_FORM_PATH}?status=paid`,
        whenToUse: "REGISTRAR um lançamento que JÁ aconteceu",
    },
    {
        path: "/goals/form",
        promptPath: "/goals/form",
        whenToUse: "criar uma META (guardar, quitar dívida, reduzir um gasto)",
    },
    {
        path: "/accounts/form",
        promptPath: "/accounts/form",
        whenToUse: "cadastrar uma CONTA ou cartão que falta",
    },
    {
        path: "/workspace/categories",
        promptPath: "/workspace/categories",
        whenToUse: "criar, renomear ou reclassificar CATEGORIAS",
    },
    {
        path: "/workspace/accounts",
        promptPath: "/workspace/accounts",
        whenToUse: "ver a lista de contas e os saldos",
    },
    {
        path: "/category-details",
        promptPath: "/category-details",
        whenToUse: "ver o RELATÓRIO detalhado de gasto por categoria",
    },
    {
        path: "/workspace/badges",
        promptPath: "/workspace/badges",
        whenToUse: "ver as conquistas e o que falta para a próxima",
    },
    {
        path: "/coaching/history",
        promptPath: "/coaching/history",
        whenToUse: "reler os insights anteriores",
    },
    {
        path: "/",
        promptPath: "/",
        whenToUse: "voltar à tela principal (Dashboard) — use só quando nenhuma das anteriores servir",
    },
];

/** Os caminhos aceitos, sem repetição (`/transactions/form` aparece duas vezes acima). */
export const ALLOWED_ACTION_PATHS: string[] = [
    ...new Set(COACHING_ACTION_ROUTES.map((route) => route.path)),
];

/**
 * Query string aceita por rota: `{ rota: { parâmetro: valores permitidos } }`.
 *
 * O `actionPath` vira `context.push` no app, e o formulário de lançamento lê
 * `status` e `type` da query (`app_router.dart`). Qualquer outro parâmetro (ou
 * valor fora da lista) é DESCARTADO: a IA alucina query string com a mesma
 * facilidade com que alucina rota, e o que chega aqui vai direto para a
 * navegação do cliente.
 *
 * As demais rotas não aceitam query NENHUMA — não porque o app a ignore
 * (`/planning` e `/category-details` leem `type`), mas porque o prompt não as
 * oferece com parâmetro: liberar aqui o que a IA não foi instruída a mandar só
 * aumentaria a superfície da alucinação.
 */
export const ALLOWED_ACTION_QUERY: Record<string, Record<string, string[]>> = {
    [TRANSACTION_FORM_PATH]: {
        status: ["pending", "paid"],
        type: ["expense", "income", "transfer"],
    },
};

/**
 * O trecho do prompt que enumera as rotas — gerado da lista acima para que
 * prompt e validador não possam divergir de novo.
 */
export function buildActionPathPromptList(indent = "                    "): string {
    return COACHING_ACTION_ROUTES
        .map((route) => `${indent}* "${route.promptPath}" (${route.whenToUse})`)
        .join("\n");
}
