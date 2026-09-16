/**
 * F1.9 — DEFINIÇÃO ÚNICA DE SEMANA DO PROJETO.
 *
 * Antes existiam TRÊS aritméticas de semana: esta (UTC), uma cópia privada em
 * `finance.service.ts` (usada pelo `weekly_xp`) e `gamification_time.util.ts`
 * (America/Sao_Paulo, usada pelas missões semanais). Os ids divergiam no sábado
 * à noite — um pagamento às 21h de sábado em São Paulo já era domingo em UTC,
 * e caía numa semana diferente da missão semanal.
 *
 * Agora há uma só, no fuso do produto (`PRODUCT_TIME_ZONE`), e ela vale para:
 *  - `weekly_xp/{YYYY-Www}`         (FinanceService.updateWeeklyTotalXp)
 *  - `period_summaries/{YYYY-Www}`  (SummaryService)
 *  - `weekly_missions`              (GamificationService, via gamification_time.util)
 *  - o job de reconstrução          (rebuild.service.ts)
 *
 * CONVENÇÃO: a semana começa no DOMINGO 00:00 local. O número da semana é o
 * legado (dias decorridos desde 1º de janeiro do ano do domingo, dividido por
 * 7, mais 1) e o ANO é o do domingo que inicia a semana — o que importa na
 * virada de ano. A fórmula foi preservada para não invalidar os ids já
 * gravados em `weekly_missions`.
 *
 * O cliente Dart NÃO deve recalcular isso por conta própria: o servidor grava
 * `currentWeekId`/`currentWeekStart` no documento do workspace (ver
 * `week_sync.service.ts`). Enquanto o app ainda calcular, ele precisa passar no
 * mesmo vetor de teste: `src/test/fixtures/week_vectors.json`.
 */

import {
    PRODUCT_TIME_ZONE,
    addCalendarDays,
    getZonedParts,
    localMidnightInstant,
    startOfDayInTz,
} from "./timezone.utils";

const DAY_MS = 24 * 60 * 60 * 1000;

export interface WeekRef {
    year: number;
    week: number;
}

/** Instante do domingo 00:00 (local) que inicia a semana de `date`. */
export function getWeekStart(date: Date, timeZone: string = PRODUCT_TIME_ZONE): Date {
    const p = getZonedParts(date, timeZone);
    return addCalendarDays(startOfDayInTz(date, timeZone), -p.weekday, timeZone);
}

/** Alias histórico de `getWeekStart` (nome usado pela gamificação). */
export const startOfWeekInTz = getWeekStart;

/** Último instante (sábado 23:59:59.999 local) da semana iniciada em `weekStart`. */
export function endOfWeekFromStart(weekStart: Date, timeZone: string = PRODUCT_TIME_ZONE): Date {
    return new Date(addCalendarDays(weekStart, 7, timeZone).getTime() - 1);
}

/** Número da semana (1-based) da semana iniciada em `weekStart`. */
function weekNumberFromStart(weekStart: Date, timeZone: string): number {
    const p = getZonedParts(weekStart, timeZone);
    const firstDayOfYear = Date.UTC(p.year, 0, 1);
    const days = Math.floor((Date.UTC(p.year, p.month - 1, p.day) - firstDayOfYear) / DAY_MS);
    return Math.floor(days / 7) + 1;
}

/** Número da semana (semanas iniciadas no domingo, fuso do produto). */
export function getWeekNumber(date: Date, timeZone: string = PRODUCT_TIME_ZONE): number {
    return weekNumberFromStart(getWeekStart(date, timeZone), timeZone);
}

/** Ano da semana (ano do domingo que a inicia, fuso do produto). */
export function getWeekYear(date: Date, timeZone: string = PRODUCT_TIME_ZONE): number {
    return getZonedParts(getWeekStart(date, timeZone), timeZone).year;
}

/** Referência `{year, week}` da semana de `date`. */
export function getWeekRef(date: Date, timeZone: string = PRODUCT_TIME_ZONE): WeekRef {
    const weekStart = getWeekStart(date, timeZone);
    return {
        year: getZonedParts(weekStart, timeZone).year,
        week: weekNumberFromStart(weekStart, timeZone),
    };
}

/** Id `YYYY-Www` a partir de uma referência de semana. */
export function formatWeekId(ref: WeekRef): string {
    return `${ref.year}-W${String(ref.week).padStart(2, "0")}`;
}

/**
 * Id `YYYY-Www` da semana de `date`.
 *
 * Aceita qualquer instante da semana (inclusive o próprio `weekStart`, que é
 * como a gamificação sempre chamou esta função).
 */
export function getWeekId(date: Date, timeZone: string = PRODUCT_TIME_ZONE): string {
    return formatWeekId(getWeekRef(date, timeZone));
}

/**
 * Referência da semana que está `weeksAgo` semanas antes da semana de `date`.
 * O deslocamento é feito em dias de CALENDÁRIO a partir do domingo inicial,
 * o que trata corretamente viradas de mês, de ano e de horário de verão.
 */
export function getWeekRefBefore(date: Date, weeksAgo: number, timeZone: string = PRODUCT_TIME_ZONE): WeekRef {
    const shifted = addCalendarDays(getWeekStart(date, timeZone), -7 * weeksAgo, timeZone);
    return getWeekRef(shifted, timeZone);
}

/**
 * Domingo 00:00 local de uma referência de semana — a volta de `getWeekRef`.
 * Usado para gravar `currentWeekStart` no workspace.
 */
export function weekStartFromRef(ref: WeekRef, timeZone: string = PRODUCT_TIME_ZONE): Date {
    // A semana 1 é a do PRIMEIRO domingo em 1º de janeiro ou depois (o número
    // vem do dia do ano desse domingo, que é 0..6). Daí em diante é de 7 em 7.
    const firstDay = localMidnightInstant(ref.year, 1, 1, timeZone);
    const firstSunday = getWeekStart(addCalendarDays(firstDay, 6, timeZone), timeZone);
    return addCalendarDays(firstSunday, (ref.week - 1) * 7, timeZone);
}
