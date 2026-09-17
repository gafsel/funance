/**
 * AUDIÊNCIA: o tipo de usuário a que um conteúdo do jogo se aplica.
 *
 * O produto atende dois tipos de usuário — `workspaces.type` = `personal` |
 * `business` — e a decisão vale para funcionalidade E texto. A audiência é
 * usada por três consumidores que precisam concordar:
 *
 *  - o catálogo de missões (`mission_catalog.ts`), que escolhe o objetivo da
 *    semana pelo tipo do workspace;
 *  - o catálogo de badges (`gamification.service.ts` + `config/badges`), que
 *    deixa de avaliar e de exibir o que não se aplica;
 *  - os prompts de IA, que recebem o tipo e a lista do que NÃO cabe nele.
 *
 * Ela vive num arquivo próprio porque é o vocabulário comum dos três, e não
 * propriedade de nenhum: colocá-la no catálogo de missões obrigaria a interface
 * do repositório de gamificação a importar missões para falar de badge.
 */

/** Os dois tipos de workspace, como o produto os nomeia. */
export const WORKSPACE_AUDIENCES = ["personal", "business"] as const;

export type WorkspaceAudience = typeof WORKSPACE_AUDIENCES[number];

/**
 * A quem um badge (ou uma fonte de XP) se aplica. `both` é o padrão: a maioria
 * do catálogo — conciliar, planejar, concluir metas — vale igual nos dois
 * tipos, e só o que é ancorado em regra de finança PESSOAL precisa de recorte.
 */
export type BadgeAudience = WorkspaceAudience | "both";

/**
 * Normaliza `workspaces.type` para uma audiência.
 *
 * Qualquer coisa que não seja exatamente `business` vira `personal`: o campo é
 * opcional em documento legado, e o padrão histórico do produto (e do prompt
 * antigo) é o workspace pessoal. Errar para `business` transformaria todo
 * workspace sem tipo num escritório.
 */
export function resolveAudience(rawType: string | null | undefined): WorkspaceAudience {
    return rawType === "business" ? "business" : "personal";
}

/** O conteúdo marcado com `audience` vale para um workspace daquele tipo? */
export function appliesToAudience(
    audience: BadgeAudience | null | undefined,
    workspaceAudience: WorkspaceAudience
): boolean {
    // Ausente == `both`: um badge sem marcação é um badge que ninguém recortou
    // ainda, e some-lo da vitrine por omissão seria uma regressão muda.
    if (!audience || audience === "both") return true;
    return audience === workspaceAudience;
}
