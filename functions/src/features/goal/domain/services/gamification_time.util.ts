/**
 * Utilitários de data/hora para a gamificação.
 *
 * Todos os cálculos de calendário (dia, semana, mês) são feitos no fuso
 * horário oficial do produto (America/Sao_Paulo), independentemente do fuso
 * do servidor (UTC nas Cloud Functions). As funções retornam instantes
 * (objetos Date, sempre absolutos/UTC) que correspondem às fronteiras
 * LOCAIS de dia/semana/mês no fuso configurado.
 *
 * Convenção de semana: a semana começa no DOMINGO (weekday 0), seguindo a
 * convenção já usada no restante do projeto (cálculos baseados em getDay(),
 * ver finance.service.ts#getWeekNumber).
 *
 * O formato de weekId ("YYYY-Www") replica a fórmula legada
 * (dias desde 1º de janeiro do início da semana / 7 + 1) para manter
 * compatibilidade com os documentos weekly_missions já existentes.
 */

export const GAMIFICATION_TIME_ZONE = "America/Sao_Paulo";

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export interface ZonedParts {
    year: number;
    /** 1-12 */
    month: number;
    day: number;
    /** 0 = domingo ... 6 = sábado */
    weekday: number;
    hour: number;
    minute: number;
    second: number;
}

/** Extrai os componentes de calendário de um instante no fuso informado. */
export function getZonedParts(date: Date, timeZone: string = GAMIFICATION_TIME_ZONE): ZonedParts {
    const dtf = new Intl.DateTimeFormat("en-US", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        weekday: "short",
        hour12: false,
    });
    const parts: Record<string, string> = {};
    for (const p of dtf.formatToParts(date)) {
        parts[p.type] = p.value;
    }
    return {
        year: parseInt(parts.year, 10),
        month: parseInt(parts.month, 10),
        day: parseInt(parts.day, 10),
        weekday: WEEKDAYS.indexOf(parts.weekday),
        // Alguns runtimes formatam meia-noite como "24".
        hour: parseInt(parts.hour, 10) % 24,
        minute: parseInt(parts.minute, 10),
        second: parseInt(parts.second, 10),
    };
}

/** Offset (ms) do fuso em relação ao UTC no instante informado. */
function getTimeZoneOffsetMs(date: Date, timeZone: string): number {
    const p = getZonedParts(date, timeZone);
    const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
    const truncated = date.getTime() - (((date.getTime() % 1000) + 1000) % 1000);
    return asUtc - truncated;
}

/** Instante correspondente à meia-noite local do dia (year, month 1-12, day). */
export function localMidnightInstant(
    year: number,
    month: number,
    day: number,
    timeZone: string = GAMIFICATION_TIME_ZONE
): Date {
    const utcGuess = new Date(Date.UTC(year, month - 1, day));
    const offset = getTimeZoneOffsetMs(utcGuess, timeZone);
    let instant = new Date(utcGuess.getTime() - offset);
    // Refinamento para bordas de horário de verão (o offset na meia-noite
    // local pode diferir do offset no palpite inicial).
    const offset2 = getTimeZoneOffsetMs(instant, timeZone);
    if (offset2 !== offset) {
        instant = new Date(utcGuess.getTime() - offset2);
    }
    return instant;
}

/** Instante da meia-noite local do dia em que `date` cai no fuso. */
export function startOfDayInTz(date: Date, timeZone: string = GAMIFICATION_TIME_ZONE): Date {
    const p = getZonedParts(date, timeZone);
    return localMidnightInstant(p.year, p.month, p.day, timeZone);
}

/**
 * Soma `days` dias de CALENDÁRIO a um instante de meia-noite local,
 * retornando a meia-noite local do dia resultante (robusto a DST).
 */
export function addCalendarDays(
    dayStart: Date,
    days: number,
    timeZone: string = GAMIFICATION_TIME_ZONE
): Date {
    const p = getZonedParts(dayStart, timeZone);
    const cal = new Date(Date.UTC(p.year, p.month - 1, p.day));
    cal.setUTCDate(cal.getUTCDate() + days);
    return localMidnightInstant(cal.getUTCFullYear(), cal.getUTCMonth() + 1, cal.getUTCDate(), timeZone);
}

/** Instante do início (domingo 00:00 local) da semana em que `date` cai. */
export function startOfWeekInTz(date: Date, timeZone: string = GAMIFICATION_TIME_ZONE): Date {
    const p = getZonedParts(date, timeZone);
    return addCalendarDays(startOfDayInTz(date, timeZone), -p.weekday, timeZone);
}

/** Último instante (sábado 23:59:59.999 local) da semana iniciada em `weekStart`. */
export function endOfWeekFromStart(weekStart: Date, timeZone: string = GAMIFICATION_TIME_ZONE): Date {
    return new Date(addCalendarDays(weekStart, 7, timeZone).getTime() - 1);
}

/** Índice do dia da semana (0 = domingo) de `date` no fuso. */
export function getDayIndexInTz(date: Date, timeZone: string = GAMIFICATION_TIME_ZONE): number {
    return getZonedParts(date, timeZone).weekday;
}

/** weekId "YYYY-Www" da semana iniciada em `weekStart` (fórmula legada). */
export function getWeekId(weekStart: Date, timeZone: string = GAMIFICATION_TIME_ZONE): string {
    const p = getZonedParts(weekStart, timeZone);
    const firstDayOfYear = Date.UTC(p.year, 0, 1);
    const days = Math.floor((Date.UTC(p.year, p.month - 1, p.day) - firstDayOfYear) / DAY_MS);
    const week = Math.floor(days / 7) + 1;
    return `${p.year}-W${String(week).padStart(2, "0")}`;
}

/** Chave "YYYY-MM" do mês em que `date` cai no fuso. */
export function getMonthKeyInTz(date: Date, timeZone: string = GAMIFICATION_TIME_ZONE): string {
    const p = getZonedParts(date, timeZone);
    return `${p.year}-${String(p.month).padStart(2, "0")}`;
}

/**
 * Intervalo [start, end] (instantes) e (year, month) do mês em que `date`
 * cai no fuso, deslocado por `monthOffset` meses (-1 = mês anterior).
 */
export function getMonthRangeInTz(
    date: Date,
    monthOffset = 0,
    timeZone: string = GAMIFICATION_TIME_ZONE
): { start: Date; end: Date; year: number; month: number } {
    const p = getZonedParts(date, timeZone);
    const cal = new Date(Date.UTC(p.year, p.month - 1 + monthOffset, 1));
    const year = cal.getUTCFullYear();
    const month = cal.getUTCMonth() + 1;
    const start = localMidnightInstant(year, month, 1, timeZone);
    const nextCal = new Date(Date.UTC(year, month, 1));
    const end = new Date(
        localMidnightInstant(nextCal.getUTCFullYear(), nextCal.getUTCMonth() + 1, 1, timeZone).getTime() - 1
    );
    return { start, end, year, month };
}
