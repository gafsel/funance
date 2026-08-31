/**
 * Utilitários de numeração de semana.
 *
 * IMPORTANTE: os documentos semanais de `period_summaries` (id `YYYY-Www`) são gravados
 * por summary.service.ts usando semanas iniciadas no DOMINGO, com o número da semana
 * calculado a partir do domingo que inicia a semana e o ano sendo o ano desse domingo.
 * Qualquer leitura desses documentos DEVE usar exatamente a mesma aritmética,
 * senão os ids não batem (especialmente na virada de ano).
 */

export interface WeekRef {
    year: number;
    week: number;
}

/** Retorna o domingo (00:00) que inicia a semana da data informada. */
export function getWeekStart(d: Date): Date {
    const date = new Date(d.getTime());
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() - date.getDay());
    return date;
}

/** Número da semana (semanas iniciadas no domingo), idêntico a summary.service.ts. */
export function getWeekNumber(d: Date): number {
    const weekStart = getWeekStart(d);
    const firstDayOfYear = new Date(weekStart.getFullYear(), 0, 1);
    const days = Math.floor((weekStart.getTime() - firstDayOfYear.getTime()) / (24 * 60 * 60 * 1000));
    return Math.floor(days / 7) + 1;
}

/** Ano da semana (ano do domingo que inicia a semana), idêntico a summary.service.ts. */
export function getWeekYear(d: Date): number {
    return getWeekStart(d).getFullYear();
}

/** Referência {year, week} da semana da data informada. */
export function getWeekRef(d: Date): WeekRef {
    return { year: getWeekYear(d), week: getWeekNumber(d) };
}

/**
 * Referência da semana que está `weeksAgo` semanas antes da semana da data informada.
 * Trabalha deslocando a data em múltiplos de 7 dias, o que trata corretamente
 * viradas de mês e de ano.
 */
export function getWeekRefBefore(d: Date, weeksAgo: number): WeekRef {
    const shifted = new Date(d.getTime());
    shifted.setDate(shifted.getDate() - (7 * weeksAgo));
    return getWeekRef(shifted);
}
