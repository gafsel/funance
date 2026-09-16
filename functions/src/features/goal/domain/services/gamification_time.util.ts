/**
 * REEXPORTAÇÃO (F1.9).
 *
 * A aritmética de calendário que morava aqui foi promovida a utilitário de
 * núcleo, porque finanças, sumários e gamificação precisam da MESMA definição
 * de dia, semana e mês:
 *
 *  - `core/utils/timezone.utils.ts` — dia/mês no fuso do produto;
 *  - `core/utils/week.utils.ts`     — a única definição de semana (id `YYYY-Www`).
 *
 * Este arquivo continua existindo apenas para não quebrar as importações da
 * gamificação. Não acrescente lógica nova aqui.
 */

import { PRODUCT_TIME_ZONE } from "../../../../core/utils/timezone.utils";

/** Alias histórico: o fuso da gamificação é o fuso do produto. */
export const GAMIFICATION_TIME_ZONE = PRODUCT_TIME_ZONE;

export {
    PRODUCT_TIME_ZONE,
    addCalendarDays,
    getDayIndexInTz,
    getMonthKeyInTz,
    getMonthRangeInTz,
    getZonedParts,
    localMidnightInstant,
    startOfDayInTz,
} from "../../../../core/utils/timezone.utils";
export type { ZonedParts } from "../../../../core/utils/timezone.utils";

export {
    endOfWeekFromStart,
    getWeekId,
    startOfWeekInTz,
} from "../../../../core/utils/week.utils";
