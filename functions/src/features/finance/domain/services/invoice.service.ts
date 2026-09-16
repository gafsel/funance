/**
 * F1.8 — a ÚNICA fonte de vencimento, fechamento e janela de fatura.
 *
 * Antes existiam DUAS implementações da mesma regra: esta e a Dart
 * (`lib/features/finance/domain/services/invoice_service.dart`). Elas já
 * divergiam em dois pontos — a Dart não clampava o dia em
 * `calculateInvoiceDueDate`, e só a Dart tinha `calculateInvoiceCycleRange` —
 * e, como o id da order de fatura deriva da data
 * (`invoice-{accountId}-{YYYY-MM-DD}`), cliente e servidor podiam apontar para
 * faturas DIFERENTES. A cópia Dart foi removida; o cliente lê
 * `accounts/{id}.nextInvoice`, escrito por este serviço.
 *
 * Três correções vieram junto:
 *
 * 1. **feriados móveis**. A lista tinha só as 8 datas fixas, com um comentário
 *    dizendo que Carnaval, Sexta-feira Santa e Corpus Christi "exigiriam
 *    cálculo mais complexo". Eles são calculados a partir da Páscoa
 *    (Meeus/Gauss) e entram aqui;
 * 2. **fuso do produto**. Dia da semana, dia do mês e a chave da fatura saem
 *    de `getZonedParts`/`toDateKey` (`America/Sao_Paulo`), não de
 *    `getDate()`/`toISOString()` (que no servidor é UTC);
 * 3. **clamp do dia nos dois lados**. Fechamento 31 em fevereiro fecha no dia
 *    28/29, e o vencimento 31 em abril vence no dia 30 — nenhum dos dois
 *    "estoura" para o mês seguinte criando uma fatura duplicada.
 */

import { AccountModel } from "../models/finance.models";
import { PRODUCT_TIME_ZONE, getZonedParts, localMidnightInstant } from "../../../../core/utils/timezone.utils";
import { toDateKey } from "../../../../core/utils/date_key";

/** Janela de compras que pertence a uma fatura, mais o fechamento que a gerou. */
export interface InvoiceCycleRange {
    /** 00:00 (fuso do produto) do dia do fechamento ANTERIOR — inclusive. */
    start: Date;
    /** 23:59:59.999 da véspera do fechamento atual — inclusive. */
    end: Date;
    /** 00:00 do dia do fechamento que gerou esta fatura. */
    closingDate: Date;
}

const MS_PER_HOUR = 60 * 60 * 1000;
const NOON_OFFSET_MS = 12 * MS_PER_HOUR;

/** Padrões usados quando a conta de cartão não tem os dias configurados. */
const DEFAULT_CLOSING_DAY = 5;
const DEFAULT_DUE_DAY = 10;

export class InvoiceService {
    /** Feriados nacionais de data FIXA, no formato `MM-DD`. */
    private static readonly FIXED_HOLIDAYS = new Set([
        "01-01", // Ano Novo
        "04-21", // Tiradentes
        "05-01", // Dia do Trabalho
        "09-07", // Independência
        "10-12", // Nossa Senhora Aparecida
        "11-02", // Finados
        "11-15", // Proclamação da República
        "12-25", // Natal
    ]);

    /**
     * Feriados móveis por ano, memoizados. São três e todos derivam da Páscoa:
     * Carnaval (terça, −47), Sexta-feira Santa (−2) e Corpus Christi (+60).
     */
    private static readonly movableCache = new Map<number, Set<string>>();

    /**
     * Domingo de Páscoa do ano, pelo algoritmo de Meeus/Gauss (calendário
     * gregoriano). Devolve o mês 1-12 e o dia.
     */
    static easterSunday(year: number): { month: number; day: number } {
        const a = year % 19;
        const b = Math.floor(year / 100);
        const c = year % 100;
        const d = Math.floor(b / 4);
        const e = b % 4;
        const f = Math.floor((b + 8) / 25);
        const g = Math.floor((b - f + 1) / 3);
        const h = (19 * a + b - d - g + 15) % 30;
        const i = Math.floor(c / 4);
        const k = c % 4;
        const l = (32 + 2 * e + 2 * i - h - k) % 7;
        const m = Math.floor((a + 11 * h + 22 * l) / 451);
        const month = Math.floor((h + l - 7 * m + 114) / 31);
        const day = ((h + l - 7 * m + 114) % 31) + 1;
        return { month, day };
    }

    /** Conjunto `MM-DD` dos feriados móveis do ano. */
    static movableHolidays(year: number): Set<string> {
        const cached = this.movableCache.get(year);
        if (cached) return cached;

        const easter = this.easterSunday(year);
        // Aritmética de calendário em UTC puro: são deslocamentos de DIAS sobre
        // uma data civil, sem hora e sem fuso — o resultado é só o par mês/dia.
        const easterUtc = Date.UTC(year, easter.month - 1, easter.day);
        const shift = (days: number) => {
            const date = new Date(easterUtc + days * 24 * MS_PER_HOUR);
            return `${pad2(date.getUTCMonth() + 1)}-${pad2(date.getUTCDate())}`;
        };

        const holidays = new Set([
            shift(-47), // Carnaval (terça-feira)
            shift(-2),  // Sexta-feira Santa
            shift(60),  // Corpus Christi
        ]);

        this.movableCache.set(year, holidays);
        return holidays;
    }

    /** `true` se o instante cai num feriado nacional no fuso do produto. */
    static isHoliday(date: Date, timeZone: string = PRODUCT_TIME_ZONE): boolean {
        const p = getZonedParts(date, timeZone);
        const key = `${pad2(p.month)}-${pad2(p.day)}`;
        return this.FIXED_HOLIDAYS.has(key) || this.movableHolidays(p.year).has(key);
    }

    /** `true` se o instante cai num sábado ou domingo no fuso do produto. */
    static isWeekend(date: Date, timeZone: string = PRODUCT_TIME_ZONE): boolean {
        const weekday = getZonedParts(date, timeZone).weekday;
        return weekday === 0 || weekday === 6;
    }

    /**
     * Primeiro dia útil a partir de `date` (inclusive), como o MEIO-DIA local
     * desse dia. Devolver meio-dia é de propósito: o resultado alimenta uma
     * conta de calendário, e uma borda de 00:00 é o que faz o dia escorregar
     * quando alguém reinterpreta o instante em outro fuso.
     */
    static getNextBusinessDay(date: Date, timeZone: string = PRODUCT_TIME_ZONE): Date {
        const p = getZonedParts(date, timeZone);
        let candidate = zonedNoon(p.year, p.month, p.day, timeZone);

        // Teto defensivo: no pior caso real são 4 dias (sexta + feriadão), mas
        // um laço sem limite numa lista de feriados corrompida trava a function.
        for (let guard = 0; guard < 15; guard++) {
            if (!this.isWeekend(candidate, timeZone) && !this.isHoliday(candidate, timeZone)) {
                return candidate;
            }
            const c = getZonedParts(candidate, timeZone);
            const next = normalizeDay(c.year, c.month, c.day + 1);
            candidate = zonedNoon(next.year, next.month, next.day, timeZone);
        }

        return candidate;
    }

    /**
     * Vencimento da fatura que recebe uma compra feita em `paymentDate`.
     *
     * Regra: a compra ATÉ a véspera do fechamento entra na fatura do
     * fechamento deste mês; do dia do fechamento em diante, na do mês seguinte.
     * Quando o dia de vencimento é MENOR que o de fechamento, o vencimento de
     * um fechamento cai sempre no mês seguinte ao dele.
     */
    static calculateInvoiceDueDate(
        paymentDate: Date,
        account: Pick<AccountModel, "closingDay" | "dueDay">,
        timeZone: string = PRODUCT_TIME_ZONE
    ): Date {
        const closingDay = account.closingDay || DEFAULT_CLOSING_DAY;
        const dueDay = account.dueDay || DEFAULT_DUE_DAY;

        const reference = this.getNextBusinessDay(paymentDate, timeZone);
        const p = getZonedParts(reference, timeZone);

        // O fechamento EFETIVO do mês de referência: com fechamento 31, em
        // fevereiro a fatura fecha no dia 28 (ou 29). Sem este clamp, `refDay <
        // closingDay` era sempre verdadeiro em fevereiro e a compra do dia 28
        // caía na fatura errada.
        const effectiveClosingDay = Math.min(closingDay, lastDayOfMonth(p.year, p.month));
        const dueInNextMonth = dueDay < closingDay;

        const monthOffset = p.day < effectiveClosingDay
            ? (dueInNextMonth ? 1 : 0)
            : (dueInNextMonth ? 2 : 1);

        return clampedZonedNoon(p.year, p.month + monthOffset, dueDay, timeZone);
    }

    /**
     * Janela de compras (inclusive nas duas pontas) da fatura que vence em
     * `invoiceDueDate`, mais o fechamento que a gerou.
     *
     * Espelha `calculateInvoiceDueDate`: uma compra NO dia do fechamento já
     * pertence à fatura seguinte, então o ciclo vai do fechamento anterior
     * (00:00, inclusive) até a véspera do fechamento atual (23:59:59.999).
     *
     * As bordas usam meia-noite/fim do dia de propósito: as parcelas são
     * normalizadas para 12:00, mas em fusos diferentes conforme a origem
     * (12:00 local no app, 12:00 UTC no servidor). Bordas ao meio-dia faziam o
     * dia do fechamento entrar ou sair da fatura dependendo de quem gravou.
     */
    static calculateInvoiceCycleRange(
        invoiceDueDate: Date,
        account: Pick<AccountModel, "closingDay" | "dueDay">,
        timeZone: string = PRODUCT_TIME_ZONE
    ): InvoiceCycleRange {
        const closingDay = account.closingDay || DEFAULT_CLOSING_DAY;
        const dueDay = account.dueDay || DEFAULT_DUE_DAY;
        const dueInNextMonth = dueDay < closingDay;

        const p = getZonedParts(invoiceDueDate, timeZone);
        const closingMonth = p.month - (dueInNextMonth ? 1 : 0);

        const closingDate = clampedZonedMidnight(p.year, closingMonth, closingDay, timeZone);
        const previousClosing = clampedZonedMidnight(p.year, closingMonth - 1, closingDay, timeZone);

        return {
            start: previousClosing,
            end: new Date(closingDate.getTime() - 1),
            closingDate,
        };
    }

    /**
     * Próximo vencimento de fatura em ou após `reference` — a fatura que o
     * cartão está acumulando ou prestes a cobrar. Usado quando a conta ainda
     * não tem NENHUMA fatura em aberto (cartão novo, ou fatura zerada e
     * apagada): o app precisa da janela e da data mesmo com valor zero.
     */
    static resolveUpcomingDueDate(
        reference: Date,
        account: Pick<AccountModel, "closingDay" | "dueDay">,
        timeZone: string = PRODUCT_TIME_ZONE
    ): Date {
        const dueDay = account.dueDay || DEFAULT_DUE_DAY;
        const p = getZonedParts(reference, timeZone);
        const todayKey = toDateKey(reference, timeZone);

        // Dois meses bastam: o vencimento deste mês já passou ou não.
        for (let offset = 0; offset <= 2; offset++) {
            const candidate = clampedZonedNoon(p.year, p.month + offset, dueDay, timeZone);
            if (toDateKey(candidate, timeZone) >= todayKey) {
                return candidate;
            }
        }

        return clampedZonedNoon(p.year, p.month + 1, dueDay, timeZone);
    }

    /**
     * Id canônico da order de fatura. A chave é o dia do vencimento no FUSO DO
     * PRODUTO — antes era `toISOString()` (UTC) sobre uma data construída como
     * meio-dia local, que num servidor a leste de Greenwich dava o dia errado.
     */
    static invoiceOrderId(accountId: string, dueDate: Date, timeZone: string = PRODUCT_TIME_ZONE): string {
        return `invoice-${accountId}-${toDateKey(dueDate, timeZone)}`;
    }

    /**
     * Id no formato ANTIGO (dia em UTC). Continua válido: as orders de fatura
     * já gravadas mantêm esse id, e quem procura uma fatura existente precisa
     * reconhecer os dois formatos. Nada novo é criado com ele.
     */
    static legacyInvoiceOrderId(accountId: string, dueDate: Date): string {
        return `invoice-${accountId}-${dueDate.toISOString().split("T")[0]}`;
    }

    /**
     * Mantido por compatibilidade com o código e os testes que já chamavam
     * assim: `month` é 0-based e pode estourar (12 = janeiro do ano seguinte).
     * Devolve o meio-dia local do dia clampado ao último dia do mês.
     */
    static buildClampedDate(year: number, month: number, day: number, timeZone: string = PRODUCT_TIME_ZONE): Date {
        return clampedZonedNoon(year, month + 1, day, timeZone);
    }
}

const pad2 = (value: number) => String(value).padStart(2, "0");

/** Último dia do mês (mês 1-based). */
function lastDayOfMonth(year: number, month: number): number {
    return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Normaliza (ano, mês 1-based fora de 1..12) para um par válido. */
function normalizeMonth(year: number, month: number): { year: number; month: number } {
    const cal = new Date(Date.UTC(year, month - 1, 1));
    return { year: cal.getUTCFullYear(), month: cal.getUTCMonth() + 1 };
}

/** Normaliza (ano, mês 1-based, dia) permitindo dia fora de 1..últimoDia. */
function normalizeDay(year: number, month: number, day: number): { year: number; month: number; day: number } {
    const cal = new Date(Date.UTC(year, month - 1, day));
    return { year: cal.getUTCFullYear(), month: cal.getUTCMonth() + 1, day: cal.getUTCDate() };
}

/**
 * Meio-dia local do dia informado.
 *
 * `localMidnightInstant` já resolve as bordas de horário de verão; somar 12h a
 * partir da meia-noite nunca atravessa o dia (nenhum fuso desloca 12 horas).
 */
function zonedNoon(year: number, month: number, day: number, timeZone: string): Date {
    return new Date(localMidnightInstant(year, month, day, timeZone).getTime() + NOON_OFFSET_MS);
}

/** Meio-dia local, com mês normalizado e dia limitado ao último do mês. */
function clampedZonedNoon(year: number, month: number, day: number, timeZone: string): Date {
    const m = normalizeMonth(year, month);
    return zonedNoon(m.year, m.month, Math.min(day, lastDayOfMonth(m.year, m.month)), timeZone);
}

/** Meia-noite local, com mês normalizado e dia limitado ao último do mês. */
function clampedZonedMidnight(year: number, month: number, day: number, timeZone: string): Date {
    const m = normalizeMonth(year, month);
    return localMidnightInstant(m.year, m.month, Math.min(day, lastDayOfMonth(m.year, m.month)), timeZone);
}
