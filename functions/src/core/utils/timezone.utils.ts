/**
 * Aritmética de calendário no fuso do PRODUTO.
 *
 * Todos os cálculos de calendário (dia, semana, mês) são feitos em
 * `America/Sao_Paulo`, independentemente do fuso do servidor (UTC nas Cloud
 * Functions). As funções retornam instantes (objetos `Date`, sempre
 * absolutos/UTC) que correspondem às fronteiras LOCAIS de dia/semana/mês no
 * fuso configurado.
 *
 * Este arquivo nasceu como `features/goal/domain/services/gamification_time.util.ts`
 * (gamificação) e foi promovido a utilitário de núcleo em F1.9: a semana, o dia
 * e o mês precisam ser os mesmos para finanças, sumários e gamificação. O
 * arquivo antigo continua existindo como REEXPORTAÇÃO, para não quebrar
 * importações da gamificação.
 *
 * A definição de SEMANA mora em `week.utils.ts`, que é a única fonte de ids
 * `YYYY-Www` do projeto.
 */

/** Fuso oficial do produto. Toda data de negócio é interpretada nele. */
export const PRODUCT_TIME_ZONE = "America/Sao_Paulo";

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
export function getZonedParts(date: Date, timeZone: string = PRODUCT_TIME_ZONE): ZonedParts {
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

/** `true` se o instante cai no dia local informado. */
function isSameLocalDay(instant: Date, year: number, month: number, day: number, timeZone: string): boolean {
    const p = getZonedParts(instant, timeZone);
    return p.year === year && p.month === month && p.day === day;
}

/**
 * Instante correspondente à meia-noite local do dia (year, month 1-12, day).
 *
 * Duas bordas de horário de verão precisam de cuidado (o Brasil não tem mais
 * DST desde 2019, mas dados históricos e outros fusos sim):
 *  - a meia-noite pode NÃO EXISTIR (adiantou 00:00 -> 01:00). O início do dia
 *    passa a ser o primeiro instante que já pertence ao dia pedido;
 *  - a meia-noite pode acontecer DUAS vezes (atrasou 00:00 -> 23:00). Fica
 *    valendo a primeira ocorrência, para o dia não começar duas vezes.
 */
export function localMidnightInstant(
    year: number,
    month: number,
    day: number,
    timeZone: string = PRODUCT_TIME_ZONE
): Date {
    const utcGuess = new Date(Date.UTC(year, month - 1, day));
    const first = new Date(utcGuess.getTime() - getTimeZoneOffsetMs(utcGuess, timeZone));
    const second = new Date(utcGuess.getTime() - getTimeZoneOffsetMs(first, timeZone));

    const candidates = first.getTime() === second.getTime() ? [first] : [first, second];
    const onTheDay = candidates
        .filter((candidate) => isSameLocalDay(candidate, year, month, day, timeZone))
        .sort((a, b) => a.getTime() - b.getTime());

    if (onTheDay.length === 0) {
        // Nenhum palpite caiu no dia pedido: devolve o primeiro palpite, que é
        // o comportamento histórico (e só é alcançável em fusos exóticos).
        return first;
    }

    const exactMidnight = onTheDay.find((candidate) => {
        const p = getZonedParts(candidate, timeZone);
        return p.hour === 0 && p.minute === 0 && p.second === 0;
    });

    return exactMidnight ?? onTheDay[0];
}

/** Instante da meia-noite local do dia em que `date` cai no fuso. */
export function startOfDayInTz(date: Date, timeZone: string = PRODUCT_TIME_ZONE): Date {
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
    timeZone: string = PRODUCT_TIME_ZONE
): Date {
    const p = getZonedParts(dayStart, timeZone);
    const cal = new Date(Date.UTC(p.year, p.month - 1, p.day));
    cal.setUTCDate(cal.getUTCDate() + days);
    return localMidnightInstant(cal.getUTCFullYear(), cal.getUTCMonth() + 1, cal.getUTCDate(), timeZone);
}

/** Índice do dia da semana (0 = domingo) de `date` no fuso. */
export function getDayIndexInTz(date: Date, timeZone: string = PRODUCT_TIME_ZONE): number {
    return getZonedParts(date, timeZone).weekday;
}

/** Chave "YYYY-MM" do mês em que `date` cai no fuso. */
export function getMonthKeyInTz(date: Date, timeZone: string = PRODUCT_TIME_ZONE): string {
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
    timeZone: string = PRODUCT_TIME_ZONE
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
