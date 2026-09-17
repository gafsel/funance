/**
 * `GoalRepositoryImpl.getBalancesForGoal` — o marco zero de uma meta `payDebt`.
 *
 * O documento diário guarda o saldo ACUMULADO ao fim do dia. Ler o saldo
 * inicial com limite inclusivo (`dateKey <= startKey`) engolia o pagamento
 * feito no PRÓPRIO dia de início: ele já estava dentro do marco zero e sumia
 * do progresso. O limite correto é exclusivo — "o saldo no fim do dia anterior
 * ao início".
 *
 * O caso dos testes é o de produção: meta "Pagar dívida Itaú" com `startDate`
 * 2026-06-22 e saldos `2026-06-08 = -19058,90` e `2026-06-22 = -15247,16`.
 */
/** Documento de saldo do fake: `dateKey` ausente = documento legado. */
type BalanceDoc = { id: string; balance: number; dateKey?: string };

type Filter = { field: string; op: string; value: string };

const state: {
    docs: BalanceDoc[];
    filters: Filter[][];
    path: string[];
} = { docs: [], filters: [], path: [] };

jest.mock("firebase-admin", () => {
    const firestore: any = () => makeDb();
    firestore.FieldPath = { documentId: () => "__name__" };
    firestore.Timestamp = { fromDate: (date: Date) => date };
    firestore.FieldValue = { serverTimestamp: () => ({ __serverTimestamp: true }) };
    return { firestore };
});

/**
 * Fake do Firestore com a semântica que importa aqui: filtros por id
 * (`__name__`) e por `dateKey`, ordenação, `limit` e `startAfter`. Um
 * documento SEM `dateKey` (legado) não casa com nenhum filtro nesse campo —
 * é exatamente por isso que o repositório tem o caminho duplo.
 */
function makeDb(): any {
    const buildQuery = (filters: Filter[], order: { field: string; dir: string } | null, max: number | null, startAfterId: string | null): any => {
        const self: any = {
            where(field: any, op: string, value: string) {
                const name = typeof field === "string" ? field : String(field);
                return buildQuery([...filters, { field: name, op, value }], order, max, startAfterId);
            },
            orderBy(field: any, dir = "asc") {
                const name = typeof field === "string" ? field : String(field);
                return buildQuery(filters, { field: name, dir }, max, startAfterId);
            },
            limit(n: number) {
                return buildQuery(filters, order, n, startAfterId);
            },
            select() {
                return self;
            },
            startAfter(doc: { id: string }) {
                return buildQuery(filters, order, max, doc.id);
            },
            async get() {
                state.filters.push(filters);

                let list = state.docs.filter((doc) => filters.every((filter) => {
                    const value = filter.field === "__name__" ? doc.id : doc.dateKey;
                    if (value === undefined) return false;
                    if (filter.op === "<") return value < filter.value;
                    if (filter.op === "<=") return value <= filter.value;
                    if (filter.op === ">") return value > filter.value;
                    throw new Error(`operador não suportado no fake: ${filter.op}`);
                }));

                const key = (doc: BalanceDoc) => (order?.field === "dateKey" ? doc.dateKey ?? "" : doc.id);
                list.sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0));
                if (order?.dir === "desc") list.reverse();

                if (startAfterId !== null) {
                    const from = list.findIndex((doc) => doc.id === startAfterId);
                    list = from >= 0 ? list.slice(from + 1) : list;
                }
                if (max !== null) list = list.slice(0, max);

                return {
                    empty: list.length === 0,
                    size: list.length,
                    docs: list.map((doc) => ({
                        id: doc.id,
                        data: () => ({ balance: doc.balance, dateKey: doc.dateKey }),
                    })),
                };
            },
        };
        return self;
    };

    const collection = (name: string): any => {
        state.path.push(name);
        const query = buildQuery([], null, null, null);
        query.doc = (id: string) => {
            state.path.push(id);
            return { collection, id };
        };
        return query;
    };

    return { collection };
}

import { GoalRepositoryImpl } from "../features/goal/data/repositories/goal.repository.impl";

/** Saldos do caso real, em reais. */
const ANTES = -19058.90;
const NO_DIA = -15247.16;
const START_DATE = new Date("2026-06-22T00:00:00.000Z");

/** Filtros da query indexada do saldo INICIAL (a que usa `dateKey` e não `9999-12-31`). */
function indexedStartFilters(): Filter[] | undefined {
    return state.filters.find((filters) =>
        filters.length === 1 &&
        filters[0].field === "dateKey" &&
        filters[0].value !== "9999-12-31");
}

describe("GoalRepositoryImpl.getBalancesForGoal — saldo inicial exclusivo", () => {
    let repository: GoalRepositoryImpl;

    beforeEach(() => {
        state.docs = [];
        state.filters = [];
        state.path = [];
        repository = new GoalRepositoryImpl();
    });

    it("lê a subcoleção de saldos da conta da meta", async () => {
        await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);
        expect(state.path).toEqual(expect.arrayContaining(["workspaces", "w1", "accounts", "acc-itau", "balance"]));
    });

    it("base legada: ignora o saldo do próprio dia de início e usa o do dia anterior", async () => {
        state.docs = [
            { id: "2026-06-08", balance: ANTES },
            { id: "2026-06-22", balance: NO_DIA },
        ];

        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);

        // Marco zero = fim do dia 21 (o documento de 08/06). O pagamento do dia
        // 22 volta a contar: 19058,90 - 15247,16 = 3811,74 só nesse dia.
        expect(balances.startBalance).toBe(ANTES);
        expect(balances.currentBalance).toBe(NO_DIA);
    });

    it("base migrada: a query indexada do saldo inicial usa `<`, não `<=`", async () => {
        state.docs = [
            { id: "2026-06-08", balance: ANTES, dateKey: "2026-06-08" },
            { id: "2026-06-22", balance: NO_DIA, dateKey: "2026-06-22" },
        ];

        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);

        expect(indexedStartFilters()).toEqual([{ field: "dateKey", op: "<", value: "2026-06-22" }]);
        expect(balances.startBalance).toBe(ANTES);
        expect(balances.currentBalance).toBe(NO_DIA);
    });

    it("o saldo ATUAL continua inclusivo: o documento de hoje entra", async () => {
        state.docs = [
            { id: "2026-06-08", balance: ANTES, dateKey: "2026-06-08" },
            { id: "2026-06-22", balance: NO_DIA, dateKey: "2026-06-22" },
        ];

        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);

        expect(balances.currentBalance).toBe(NO_DIA);
    });

    it("meta que começa num dia SEM documento de saldo não muda de comportamento", async () => {
        state.docs = [
            { id: "2026-06-08", balance: ANTES, dateKey: "2026-06-08" },
            { id: "2026-07-01", balance: -12000, dateKey: "2026-07-01" },
        ];

        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);

        expect(balances.startBalance).toBe(ANTES);
        expect(balances.currentBalance).toBe(-12000);
    });

    it("sem nenhum saldo ANTES do início, o marco zero é nulo", async () => {
        state.docs = [{ id: "2026-06-22", balance: NO_DIA, dateKey: "2026-06-22" }];

        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);

        expect(balances.startBalance).toBeNull();
        expect(balances.currentBalance).toBe(NO_DIA);
    });

    it("conta sem saldo nenhum devolve os dois nulos", async () => {
        const balances = await repository.getBalancesForGoal("w1", "acc-itau", START_DATE);
        expect(balances).toEqual({ startBalance: null, currentBalance: null });
    });
});
