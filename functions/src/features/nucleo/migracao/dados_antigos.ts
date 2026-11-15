/**
 * O workspace do app antigo, como ele sai do banco, e os auxiliares para ler
 * os seus campos. Nada aqui grava.
 */

import { toDateKey } from "../../../core/utils/date_key";
import { resolveCents } from "../../../core/utils/money";

// Os documentos antigos são lidos crus: o formato variou ao longo do tempo.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Bruto = Record<string, any>;
export type Docs = Record<string, Bruto>;

export interface DadosAntigos {
    projeto: string;
    workspaceId: string;
    workspace: Bruto;
    accounts: Docs;
    orders: Docs;
    installments: Docs;
    categories: Docs;
    plannings: Docs;
    goals: Docs;
    automaticas: Docs;
    reconciliations: Docs;
    /** `accounts/{id}/balance/{dia}`, por conta. */
    saldos: Record<string, Docs>;
    /** `period_summaries/{chave}`. */
    resumos: Docs;
}

/** Instante de um campo de data cru, ou `null`. */
export function instante(raw: unknown): Date | null {
    if (raw === null || raw === undefined) return null;
    let data: Date;
    if (raw instanceof Date) data = raw;
    else if (typeof (raw as { toDate?: unknown }).toDate === "function") data = (raw as { toDate(): Date }).toDate();
    else if (typeof raw === "string" || typeof raw === "number") data = new Date(raw);
    else return null;
    return Number.isNaN(data.getTime()) ? null : data;
}

/**
 * Dia de calendário de um campo de data cru.
 *
 * Texto ISO sem fuso (`2026-09-04T12:00:00.000`) já é hora local de quem
 * gravou: vale o dia escrito. O resto é instante, lido no fuso do produto.
 */
export function diaDe(raw: unknown): string | null {
    if (typeof raw === "string") {
        const semFuso = /^(\d{4}-\d{2}-\d{2})(T[\d:.]+)?$/.exec(raw);
        if (semFuso) return semFuso[1];
    }
    const data = instante(raw);
    return data ? toDateKey(data) : null;
}

export const centavos = (doc: Bruto, campo: string): number => resolveCents(doc[campo], doc[`${campo}Cents`]);

export const temValor = (doc: Bruto, campo: string): boolean =>
    typeof doc[campo] === "number" || typeof doc[`${campo}Cents`] === "number";

export const estaPaga = (inst: Bruto): boolean => inst.status === "paid" || inst.status === "settled";

export const ehSaldoInicial = (inst: Bruto): boolean =>
    (typeof inst.orderId === "string" && inst.orderId.startsWith("initial-balance-")) ||
    inst.category?.id === "initial-balance";

export const ehCategoriaDeSistema = (id: unknown, categoria?: Bruto): boolean =>
    id === "initial-balance" || (typeof id === "string" && id.startsWith("virtual_")) || categoria?.isSystem === true;

/** Contas de uma parcela separadas por lado. */
export function lados(inst: Bruto): { debito: string[]; credito: string[] } {
    const debito: string[] = [];
    const credito: string[] = [];
    for (const [id, lado] of Object.entries(inst.accounts ?? {})) {
        if (lado === "debt") debito.push(id);
        else if (lado === "credit") credito.push(id);
    }
    return { debito, credito };
}
