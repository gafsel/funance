/**
 * OS ALDEÕES — o fechamento MENSAL do HUD da Arena.
 *
 * Na Arena o embate é SEMANAL (heróis contra o monstro dos compromissos). O
 * rodapé é MENSAL, e o primeiro dos quatro ícones é a aldeia: **cada categoria
 * com orçamento no mês é um aldeão**, cujo HP é o orçamento que sobra. Estourou
 * o limite, o aldeão morreu.
 *
 * Categoria SEM orçamento não é aldeão — ela aparece no detalhe como "sem
 * proteção", e não como aldeão morto. A diferença é o produto inteiro deste
 * pacote: o jogo premia PLANEJAR de propósito, então quem não planejou não
 * perde nada; quem planejou e cumpriu, ganha. Tratar o não planejado como
 * morte puniria justamente quem ainda não começou.
 *
 * ## O que o mês paga
 *
 * | Fonte | XP | Regra |
 * |---|---|---|
 * | Aldeão protegido (despesa comum) | 15 por categoria | realizado ≤ planejado, teto de 10 categorias (150 XP) |
 * | Aldeão protegido (investimento) | 15 por categoria | realizado ≥ planejado — a regra AO CONTRÁRIO, mesmo teto |
 * | Vila protegida | 100 | Σ realizado ≤ Σ planejado nas comuns E Σ realizado ≥ Σ planejado nas de investimento, com no mínimo 3 aldeões |
 *
 * **Por que um teto de 10 aldeões.** Sem ele, o caminho mais curto para o XP
 * seria fatiar o orçamento em trinta categorias de R$ 10 e não gastar em
 * nenhuma — o jogo passaria a premiar fragmentar o planejamento em vez de
 * acertá-lo. Dez é o bastante para cobrir um plano detalhado de verdade.
 *
 * **Por que a vila exige 3 aldeões.** "A soma do realizado ficou abaixo da
 * soma do planejado" é uma afirmação forte quando há um plano de verdade e uma
 * banalidade quando há uma categoria só — que já foi paga pelos 15 do aldeão.
 * Com um mínimo, o bônus de 100 fala de disciplina no CONJUNTO, que é o que o
 * ícone da vila desenha.
 *
 * **Dentro do limite é `<=`, não `<`.** Gastar exatamente o planejado é o
 * alvo, não uma falha por um centavo — a mesma regra do XP semanal (F2.3).
 *
 * ## A exceção do INVESTIMENTO (decisão do dono, 2026-09-20)
 *
 * "As categorias que estiverem como investimento funcionam ao contrário: se
 * não cumprirem o limite é que ficam em risco de morrer."
 *
 * Numa categoria de despesa o orçamento é um TETO; numa categoria de
 * `allocation: "investment"` o mesmo número é um ALVO DE APORTE. Guardar menos
 * do que se planejou guardar é o fracasso, e guardar mais é o acerto — de modo
 * que a comparação vira `realizado >= planejado`. Sem a inversão, o aldeão que
 * dobrasse o aporte do mês morreria por ter investido demais, que é o oposto
 * do que o jogo quer ensinar.
 *
 * O `<=`/`>=` continua valendo nos dois lados: cumprir o alvo EXATO é acerto,
 * não falha por um centavo.
 *
 * **A VILA tem, por isso, DOIS envelopes.** Se a vila continuasse sendo
 * "soma do realizado <= soma do planejado" sobre o conjunto inteiro, o aporte
 * que superasse o alvo empurraria a soma para fora e MATARIA a vila de quem
 * acertou tudo — a mesma contradição, um nível acima. Então a vila só aguenta
 * quando os dois envelopes aguentam:
 *
 *  - as categorias comuns fecham com `Σ realizado <= Σ planejado`;
 *  - as de investimento fecham com `Σ realizado >= Σ planejado`.
 *
 * Num workspace SEM categoria de investimento orçada os dois somatórios do
 * segundo envelope são zero (`0 >= 0`), e a regra degenera EXATAMENTE na
 * antiga — é por isso que ninguém fora do investimento muda de estado.
 *
 * Tudo aqui é função PURA e em CENTAVOS INTEIROS (F1.10): é o que permite que
 * o cron e o script de recálculo retroativo cheguem ao mesmo número.
 */

/** +15 XP por categoria que fechou o mês dentro do orçamento. */
export const VILLAGER_ALIVE_XP = 15;

/** Teto de aldeões pagos por mês (10 × 15 = 150 XP). */
export const VILLAGER_XP_CATEGORY_CAP = 10;

/** +100 XP quando a VILA inteira fecha o mês dentro do plano. */
export const VILLAGE_ALIVE_XP = 100;

/** Mínimo de aldeões para a vila poder ser protegida. */
export const VILLAGE_MIN_VILLAGERS = 3;

/**
 * O valor de `categories/{id}.allocation` que INVERTE a regra do aldeão.
 *
 * É a mesma string de `CategoryModel.allocation` ("essential" | "comfort" |
 * "investment"); mora aqui para que a regra pura não dependa do modelo de
 * outro feature, e é a ÚNICA comparação do pacote com esse literal.
 */
export const VILLAGER_INVESTMENT_ALLOCATION = "investment";

/**
 * Por que um aldeão caiu.
 *
 *  - `over_budget` — despesa comum que estourou o teto (`realizado > planejado`);
 *  - `under_target` — investimento que não alcançou o aporte planejado
 *    (`realizado < planejado`).
 *
 * As duas frases são a MESMA ideia ("não cumpriu o que planejou") vistas dos
 * dois lados, e o app precisa distingui-las para não dizer "você gastou
 * demais" a quem guardou de menos.
 */
export type VillagerDeathReason = "over_budget" | "under_target";

/**
 * Um aldeão: uma categoria de DESPESA com orçamento no mês, com os dois totais
 * do sumário mensal em centavos inteiros.
 */
export interface VillagerRow {
    categoryId: string;
    /** `generalPlannedAmountCents` — o orçamento do mês. Sempre > 0. */
    plannedCents: number;
    /** `actualAmountCents` — o realizado do mês. */
    actualCents: number;
    /**
     * `allocation === "investment"` no documento ATUAL da categoria: o
     * orçamento é um ALVO DE APORTE, e não um teto. Ausente == categoria
     * comum, que é o caso de toda linha anterior a este pacote.
     */
    isInvestment?: boolean;
}

/** O desfecho do mês, como o cron o concede e o app o mostra no detalhe. */
export interface VillagersOutcome {
    /** Quantas categorias tinham orçamento no mês (quantos aldeões existiam). */
    villagersPlanned: number;
    /** Quantos fecharam o mês vivos. */
    villagersAlive: number;
    /** A vila inteira fechou dentro do plano? */
    villageAlive: boolean;
    /** XP dos aldeões individuais, já com o teto aplicado. */
    villagersXp: number;
    /** XP da vila (0 ou `VILLAGE_ALIVE_XP`). */
    villageXp: number;
    /** O total que o mês rende. */
    xpAwarded: number;
    /** Soma dos orçamentos de TODOS os aldeões, em centavos. */
    plannedCents: number;
    /** Soma do realizado de TODOS os aldeões, em centavos. */
    actualCents: number;
    /** Envelope das categorias COMUNS: soma dos tetos, em centavos. */
    expensePlannedCents: number;
    /** Envelope das categorias COMUNS: soma do realizado, em centavos. */
    expenseActualCents: number;
    /** Envelope de INVESTIMENTO: soma dos alvos de aporte, em centavos. */
    investmentPlannedCents: number;
    /** Envelope de INVESTIMENTO: soma do aportado, em centavos. */
    investmentActualCents: number;
    /** Quantos aldeões eram de investimento (0 == mês sem a regra invertida). */
    investmentVillagers: number;
    /** Ids dos aldeões vivos, em ordem estável. */
    aliveCategoryIds: string[];
    /** Ids dos aldeões mortos, em ordem estável. */
    deadCategoryIds: string[];
    /**
     * Por que cada aldeão de `deadCategoryIds` caiu.
     *
     * NÃO vai para `monthly_reports`: o retrato guarda contagens, e inventar
     * nele um detalhe por aldeão que o app ainda não lê seria contrato
     * fantasma. Serve ao log do cron e ao dry-run do recálculo, que precisam
     * dizer QUAL regra derrubou cada um.
     */
    deadReasons: Record<string, VillagerDeathReason>;
}

/**
 * Avalia a aldeia do mês. Só recebe ALDEÕES — categorias de despesa, não de
 * sistema, com orçamento maior que zero; a peneira é de quem lê o sumário.
 */
export function evaluateVillagers(rows: ReadonlyArray<VillagerRow>): VillagersOutcome {
    // Ordem estável: o XP concedido (e os ids gravados no relatório) não podem
    // depender da ordem em que o Firestore devolveu as chaves do mapa.
    const villagers = [...rows].sort((a, b) => a.categoryId.localeCompare(b.categoryId));

    const aliveCategoryIds: string[] = [];
    const deadCategoryIds: string[] = [];
    const deadReasons: Record<string, VillagerDeathReason> = {};
    let expensePlannedCents = 0;
    let expenseActualCents = 0;
    let investmentPlannedCents = 0;
    let investmentActualCents = 0;
    let investmentVillagers = 0;

    for (const villager of villagers) {
        // O envelope de cada um é separado de propósito: misturá-los deixaria
        // um aporte acima do alvo pagando o estouro de uma despesa, que é
        // compensação entre duas coisas que o jogo julga por critérios
        // opostos.
        if (villager.isInvestment === true) {
            investmentVillagers++;
            investmentPlannedCents += villager.plannedCents;
            investmentActualCents += villager.actualCents;

            // AO CONTRÁRIO: o orçamento é o alvo do aporte. Cumprir o alvo
            // EXATO é acerto (`>=`), pela mesma razão que gastar exatamente o
            // teto não mata a despesa comum.
            if (villager.actualCents >= villager.plannedCents) {
                aliveCategoryIds.push(villager.categoryId);
            }
            else {
                deadCategoryIds.push(villager.categoryId);
                deadReasons[villager.categoryId] = "under_target";
            }
        }
        else {
            expensePlannedCents += villager.plannedCents;
            expenseActualCents += villager.actualCents;

            if (villager.actualCents <= villager.plannedCents) {
                aliveCategoryIds.push(villager.categoryId);
            }
            else {
                deadCategoryIds.push(villager.categoryId);
                deadReasons[villager.categoryId] = "over_budget";
            }
        }
    }

    const plannedCents = expensePlannedCents + investmentPlannedCents;
    const actualCents = expenseActualCents + investmentActualCents;

    const villagersPlanned = villagers.length;
    const villagersAlive = aliveCategoryIds.length;

    const villagersXp = Math.min(villagersAlive, VILLAGER_XP_CATEGORY_CAP) * VILLAGER_ALIVE_XP;

    // Sem aldeão de investimento, os dois somatórios do segundo envelope são
    // zero e `0 >= 0` é verdadeiro: a vila volta a ser exatamente a regra
    // antiga. É essa degeneração que garante que o pacote não mexe em ninguém
    // fora do investimento.
    const villageAlive = villagersPlanned >= VILLAGE_MIN_VILLAGERS
        && expenseActualCents <= expensePlannedCents
        && investmentActualCents >= investmentPlannedCents;
    const villageXp = villageAlive ? VILLAGE_ALIVE_XP : 0;

    return {
        villagersPlanned,
        villagersAlive,
        villageAlive,
        villagersXp,
        villageXp,
        xpAwarded: villagersXp + villageXp,
        plannedCents,
        actualCents,
        expensePlannedCents,
        expenseActualCents,
        investmentPlannedCents,
        investmentActualCents,
        investmentVillagers,
        aliveCategoryIds,
        deadCategoryIds,
        deadReasons,
    };
}
