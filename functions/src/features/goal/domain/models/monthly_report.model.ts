/**
 * O RELATÓRIO MENSAL DA ALDEIA —
 * `workspaces/{w}/monthly_reports/{YYYY-MM}`.
 *
 * O XP dos aldeões é concedido uma vez, no fechamento do mês, e depois some
 * dentro do total do workspace. Sem um retrato, o app não teria como mostrar
 * no detalhe do ícone o que aconteceu em agosto — quantos aldeões havia,
 * quantos sobreviveram, se a vila aguentou — e o histórico do HUD seria uma
 * tela vazia com um número de XP sem explicação.
 *
 * É o mesmo papel de `health_history/{YYYY-MM}` para a Bússola: o placar do
 * usuário, escrito só pelo servidor e lido pelo membro.
 *
 * Um documento por mês, SOBRESCRITO por quem recalcular o mês (o cron ou o
 * script retroativo). A sobrescrita é segura porque o conteúdo é derivado do
 * sumário daquele mês: recalcular o mesmo mês dá o mesmo retrato.
 */
export interface MonthlyVillagersReport {
    /** `YYYY-MM` — igual ao id do documento. Redundante e útil na consulta. */
    monthKey: string;
    /** Quantas categorias tinham orçamento no mês. */
    villagersPlanned: number;
    /** Quantas fecharam o mês dentro do orçamento. */
    villagersAlive: number;
    /** A soma do realizado ficou dentro da soma do planejado (com ≥ 3 aldeões). */
    villageAlive: boolean;
    /**
     * O XP que o MÊS rendeu — e não o que esta execução concedeu.
     *
     * A diferença aparece no recálculo: o XP é concedido uma única vez
     * (marcador `xpAwardedFor.monthlyVillagers.<monthKey>`), então uma segunda
     * passada concede zero. Gravar esse zero apagaria do histórico o que o mês
     * valeu, que é justamente o que o app mostra no detalhe.
     */
    xpAwarded: number;
    /** Instante do cálculo, ISO-8601. */
    computedAt: string;
}
