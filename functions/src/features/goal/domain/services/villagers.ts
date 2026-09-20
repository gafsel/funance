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
 * | Aldeão protegido | 15 por categoria | realizado ≤ planejado, teto de 10 categorias (150 XP) |
 * | Vila protegida | 100 | soma do realizado ≤ soma do planejado, com no mínimo 3 aldeões |
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
 * Um aldeão: uma categoria de DESPESA com orçamento no mês, com os dois totais
 * do sumário mensal em centavos inteiros.
 */
export interface VillagerRow {
    categoryId: string;
    /** `generalPlannedAmountCents` — o orçamento do mês. Sempre > 0. */
    plannedCents: number;
    /** `actualAmountCents` — o realizado do mês. */
    actualCents: number;
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
    /** Soma dos orçamentos dos aldeões, em centavos. */
    plannedCents: number;
    /** Soma do realizado dos aldeões, em centavos. */
    actualCents: number;
    /** Ids dos aldeões vivos, em ordem estável. */
    aliveCategoryIds: string[];
    /** Ids dos aldeões mortos, em ordem estável. */
    deadCategoryIds: string[];
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
    let plannedCents = 0;
    let actualCents = 0;

    for (const villager of villagers) {
        plannedCents += villager.plannedCents;
        actualCents += villager.actualCents;

        if (villager.actualCents <= villager.plannedCents) {
            aliveCategoryIds.push(villager.categoryId);
        }
        else {
            deadCategoryIds.push(villager.categoryId);
        }
    }

    const villagersPlanned = villagers.length;
    const villagersAlive = aliveCategoryIds.length;

    const villagersXp = Math.min(villagersAlive, VILLAGER_XP_CATEGORY_CAP) * VILLAGER_ALIVE_XP;

    const villageAlive = villagersPlanned >= VILLAGE_MIN_VILLAGERS && actualCents <= plannedCents;
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
        aliveCategoryIds,
        deadCategoryIds,
    };
}
