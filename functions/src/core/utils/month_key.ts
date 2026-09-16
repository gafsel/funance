/**
 * F1.5 — aritmética das chaves de mês `YYYY-MM`.
 *
 * `startMonth`, `endMonth`, `summarizedUntil`, `appliedFrom` e `appliedUntil`
 * são todos strings `YYYY-MM`, escolhidas de propósito: comparação de string é
 * comparação cronológica, e é assim que o Firestore consegue filtrar
 * (`where("summarizedUntil", "<", horizonte)`).
 */

import { PRODUCT_TIME_ZONE, getZonedParts } from "./timezone.utils";

const MONTH_KEY_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;

const pad2 = (value: number) => String(value).padStart(2, "0");

/** `true` se a string é uma chave de mês válida. */
export function isMonthKey(value: unknown): value is string {
    return typeof value === "string" && MONTH_KEY_PATTERN.test(value);
}

/** Chave `YYYY-MM` do mês em que o instante cai no fuso do produto. */
export function toMonthKey(date: Date, timeZone: string = PRODUCT_TIME_ZONE): string {
    const p = getZonedParts(date, timeZone);
    return `${p.year}-${pad2(p.month)}`;
}

/** Componentes numéricos da chave. */
export function monthKeyParts(monthKey: string): { year: number, month: number } {
    if (!isMonthKey(monthKey)) {
        throw new Error(`monthKey inválido: ${monthKey}`);
    }
    const [year, month] = monthKey.split("-").map(Number);
    return { year, month };
}

/** Chave deslocada em `offset` meses (aceita negativo). */
export function shiftMonthKey(monthKey: string, offset: number): string {
    const { year, month } = monthKeyParts(monthKey);
    const shifted = new Date(Date.UTC(year, month - 1 + offset, 1));
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}`;
}

/** Lista (inclusiva) das chaves de `from` até `until`; vazia se `from > until`. */
export function monthKeyRange(from: string, until: string): string[] {
    if (!isMonthKey(from) || !isMonthKey(until) || from > until) return [];

    const keys: string[] = [];
    let current = from;
    while (current <= until) {
        keys.push(current);
        current = shiftMonthKey(current, 1);
    }
    return keys;
}

/** Quantidade de dias do mês. */
export function daysInMonthKey(monthKey: string): number {
    const { year, month } = monthKeyParts(monthKey);
    return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** A menor das duas chaves. */
export function minMonthKey(a: string, b: string): string {
    return a <= b ? a : b;
}

/** A maior das duas chaves. */
export function maxMonthKey(a: string, b: string): string {
    return a >= b ? a : b;
}
