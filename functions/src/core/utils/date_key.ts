/**
 * F1.4 — a ÚNICA função que transforma um instante na chave de dia do produto.
 *
 * A chave `YYYY-MM-DD` é o id (e o campo `dateKey`) dos documentos de saldo
 * diário `accounts/{id}/balance/{dateKey}`. Antes ela era calculada com
 * `date.toISOString().split("T")[0]`, ou seja, em **UTC**: um pagamento às
 * 23h30 de São Paulo caía no dia seguinte, e o saldo do dia aparecia errado
 * para o usuário.
 *
 * Aqui o dia é sempre o dia de calendário no fuso do produto
 * (`America/Sao_Paulo`), o mesmo usado pela semana (`week.utils.ts`) e pelas
 * quotas de IA.
 */

import { PRODUCT_TIME_ZONE, getZonedParts, localMidnightInstant } from "./timezone.utils";

/**
 * Ponto único de entrada da "data do produto": além do dia (`toDateKey`),
 * reexporta o MÊS (`toMonthKey`, de `month_key.ts`) e os componentes de
 * calendário (`getZonedParts`, de `timezone.utils.ts`).
 *
 * Existe porque dia, mês, semana e ano precisam ser o MESMO fuso: enquanto o
 * dia e a semana já eram `America/Sao_Paulo` e o mês do sumário ainda vinha de
 * `getFullYear()/getMonth()` (UTC no servidor), um pagamento às 23h30 de 31/10
 * caía no dia certo e no mês errado.
 */
export { getZonedParts } from "./timezone.utils";
export type { ZonedParts } from "./timezone.utils";
export { toMonthKey, monthKeyParts } from "./month_key";

const DATE_KEY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

const pad2 = (value: number) => String(value).padStart(2, "0");

/** Chave `YYYY-MM-DD` do dia em que o instante cai no fuso do produto. */
export function toDateKey(date: Date, timeZone: string = PRODUCT_TIME_ZONE): string {
    const p = getZonedParts(date, timeZone);
    return `${p.year}-${pad2(p.month)}-${pad2(p.day)}`;
}

/** `true` se a string tem o formato de uma chave de dia. */
export function isDateKey(value: unknown): value is string {
    return typeof value === "string" && DATE_KEY_PATTERN.test(value);
}

/**
 * Instante do início (meia-noite local) do dia representado pela chave.
 * Útil para converter a chave de volta em `Date` sem passar por UTC.
 */
export function dateKeyToStartInstant(dateKey: string, timeZone: string = PRODUCT_TIME_ZONE): Date {
    if (!isDateKey(dateKey)) {
        throw new Error(`dateKey inválido: ${dateKey}`);
    }
    const [year, month, day] = dateKey.split("-").map(Number);
    return localMidnightInstant(year, month, day, timeZone);
}

/**
 * Chave do dia seguinte/anterior (`offset` em dias de calendário).
 * Trabalha sobre a chave, então não sofre com horário de verão.
 */
export function shiftDateKey(dateKey: string, offsetDays: number): string {
    if (!isDateKey(dateKey)) {
        throw new Error(`dateKey inválido: ${dateKey}`);
    }
    const [year, month, day] = dateKey.split("-").map(Number);
    const shifted = new Date(Date.UTC(year, month - 1, day + offsetDays));
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}-${pad2(shifted.getUTCDate())}`;
}
