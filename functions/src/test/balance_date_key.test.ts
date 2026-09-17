/**
 * F1.4 — saldo diário sem corrida e sem estouro de transação.
 *
 * F1.10 — o movimento entra em CENTAVOS INTEIROS (`updateAccountBalance` já
 * não recebe reais) e o documento passou a guardar o par
 * `deltaCents`/`balanceCents` (verdade) + `delta`/`balance` (espelho round2).
 *
 * Cobre a transação pequena (dia + último dia anterior) e a propagação em
 * lotes, com um Firestore falso em memória rico o bastante para observar o que
 * de fato foi consultado e escrito:
 *  - nenhuma consulta pode usar `orderBy(documentId(), "desc")` (o emulador
 *    rejeita e produção depende de um índice `__name__ DESC`);
 *  - a transação escreve UM documento, nunca os saldos futuros;
 *  - a propagação commita em lotes de no máximo 400 operações.
 */

interface FakeDoc {
    id: string;
    data: Record<string, any>;
}

/** Coleções em memória: caminho -> (id -> dados). */
const store = new Map<string, Map<string, Record<string, any>>>();
/** Toda chamada de `orderBy` feita por qualquer consulta. */
let orderByCalls: Array<{ field: string, direction: string }> = [];
/** Tamanho de cada batch commitado. */
let committedBatchSizes: number[] = [];
/** Documentos escritos dentro de transações. */
let transactionWrites: string[] = [];
/** Leituras (consultas e documentos) feitas dentro de transações. */
let transactionReads: number;

const DOCUMENT_ID = "__name__";

function collectionOf(path: string): Map<string, Record<string, any>> {
    let coll = store.get(path);
    if (!coll) {
        coll = new Map();
        store.set(path, coll);
    }
    return coll;
}

function resolveValue(current: any, next: any): any {
    if (next && typeof next === "object" && "__increment" in next) {
        return (typeof current === "number" ? current : 0) + next.__increment;
    }
    return next;
}

function applyWrite(path: string, id: string, data: Record<string, any>, merge: boolean): void {
    const coll = collectionOf(path);
    const current = coll.get(id);
    const base = merge && current ? { ...current } : {};

    for (const [key, value] of Object.entries(data)) {
        base[key] = resolveValue(current?.[key], value);
    }
    coll.set(id, base);
}

function snapshotOf(id: string, data: Record<string, any>) {
    return { id, exists: true, data: () => ({ ...data }), ref: { __path: "", id } };
}

class FakeQuery {
    private filters: Array<{ field: string, op: string, value: any }> = [];
    private orders: Array<{ field: string, direction: string }> = [];
    private limitCount: number | null = null;
    private startAfterId: string | null = null;

    constructor(private path: string) {}

    private clone(): FakeQuery {
        const next = new FakeQuery(this.path);
        next.filters = [...this.filters];
        next.orders = [...this.orders];
        next.limitCount = this.limitCount;
        next.startAfterId = this.startAfterId;
        return next;
    }

    where(field: any, op: string, value: any): FakeQuery {
        const next = this.clone();
        next.filters.push({ field: typeof field === "string" ? field : DOCUMENT_ID, op, value });
        return next;
    }

    orderBy(field: any, direction = "asc"): FakeQuery {
        const name = typeof field === "string" ? field : DOCUMENT_ID;
        orderByCalls.push({ field: name, direction });
        const next = this.clone();
        next.orders.push({ field: name, direction });
        return next;
    }

    limit(count: number): FakeQuery {
        const next = this.clone();
        next.limitCount = count;
        return next;
    }

    startAfter(doc: any): FakeQuery {
        const next = this.clone();
        next.startAfterId = typeof doc === "string" ? doc : doc.id;
        return next;
    }

    async get() {
        const coll = collectionOf(this.path);
        let docs: FakeDoc[] = [...coll.entries()].map(([id, data]) => ({ id, data }));

        for (const filter of this.filters) {
            docs = docs.filter((doc) => {
                const value = filter.field === DOCUMENT_ID ? doc.id : doc.data[filter.field];
                // Campo ausente NÃO casa com nenhum filtro (igual ao Firestore).
                if (value === undefined) return false;
                if (filter.op === "<") return value < filter.value;
                if (filter.op === ">") return value > filter.value;
                if (filter.op === "<=") return value <= filter.value;
                if (filter.op === ">=") return value >= filter.value;
                return value === filter.value;
            });
        }

        const order = this.orders[0] ?? { field: DOCUMENT_ID, direction: "asc" };
        const keyOf = (doc: FakeDoc) => (order.field === DOCUMENT_ID ? doc.id : doc.data[order.field]);
        docs.sort((a, b) => (keyOf(a) < keyOf(b) ? -1 : keyOf(a) > keyOf(b) ? 1 : 0));
        if (order.direction === "desc") docs.reverse();

        if (this.startAfterId !== null) {
            const index = docs.findIndex((doc) => doc.id === this.startAfterId);
            docs = index >= 0 ? docs.slice(index + 1) : docs;
        }
        if (this.limitCount !== null) docs = docs.slice(0, this.limitCount);

        const snapshots = docs.map((doc) => ({
            ...snapshotOf(doc.id, doc.data),
            ref: { __path: this.path, id: doc.id },
        }));

        return { docs: snapshots, empty: snapshots.length === 0, size: snapshots.length };
    }
}

class FakeCollection extends FakeQuery {
    constructor(private readonly collectionPath: string) {
        super(collectionPath);
    }

    doc(id: string) {
        const path = this.collectionPath;
        return {
            id,
            __path: path,
            async get() {
                const data = collectionOf(path).get(id);
                return data
                    ? { id, exists: true, data: () => ({ ...data }) }
                    : { id, exists: false, data: () => undefined };
            },
        };
    }
}

const fakeFirestore = {
    collection: (path: string) => new FakeCollection(path),
    batch: () => {
        const operations: Array<() => void> = [];
        return {
            set: (ref: any, data: any, options?: any) =>
                operations.push(() => applyWrite(ref.__path, ref.id, data, options?.merge === true)),
            update: (ref: any, data: any) =>
                operations.push(() => applyWrite(ref.__path, ref.id, data, true)),
            delete: (ref: any) => operations.push(() => collectionOf(ref.__path).delete(ref.id)),
            async commit() {
                committedBatchSizes.push(operations.length);
                operations.forEach((operation) => operation());
            },
        };
    },
    runTransaction: async (handler: any) => {
        const pending: Array<() => void> = [];
        const transaction = {
            async get(target: any) {
                transactionReads++;
                return target.get();
            },
            set(ref: any, data: any, options?: any) {
                transactionWrites.push(`${ref.__path}/${ref.id}`);
                pending.push(() => applyWrite(ref.__path, ref.id, data, options?.merge === true));
            },
            update(ref: any, data: any) {
                transactionWrites.push(`${ref.__path}/${ref.id}`);
                pending.push(() => applyWrite(ref.__path, ref.id, data, true));
            },
        };
        const result = await handler(transaction);
        pending.forEach((write) => write());
        return result;
    },
};

jest.mock("firebase-admin", () => {
    const firestore: any = () => fakeFirestore;
    firestore.Timestamp = { fromDate: (date: Date) => date };
    firestore.FieldValue = {
        increment: (value: number) => ({ __increment: value }),
        serverTimestamp: () => ({ __serverTimestamp: true }),
    };
    class FakeFieldPath {
        segments: string[];
        constructor(...segments: string[]) {
            this.segments = segments;
        }
    }
    firestore.FieldPath = FakeFieldPath;
    firestore.FieldPath.documentId = () => DOCUMENT_ID;
    return { firestore };
});

import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { toDateKey } from "../core/utils/date_key";

const WORKSPACE = "ws1";
const ACCOUNT = "acc1";
const BALANCE_PATH = `workspaces/${WORKSPACE}/accounts/${ACCOUNT}/balance`;

function seed(dateKey: string, data: Record<string, any>): void {
    collectionOf(BALANCE_PATH).set(dateKey, data);
}

function read(dateKey: string): Record<string, any> | undefined {
    return collectionOf(BALANCE_PATH).get(dateKey);
}

/** Meio-dia em São Paulo do dia informado (evita ambiguidade de fuso). */
function noonInSaoPaulo(dateKey: string): Date {
    return new Date(`${dateKey}T15:00:00.000Z`);
}

describe("FinanceRepositoryImpl.updateAccountBalance (F1.4)", () => {
    let repository: FinanceRepositoryImpl;

    beforeEach(() => {
        store.clear();
        orderByCalls = [];
        committedBatchSizes = [];
        transactionWrites = [];
        transactionReads = 0;
        repository = new FinanceRepositoryImpl();
    });

    it("cria o documento do dia com dateKey, delta e balance", async () => {
        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -16747);

        expect(read("2026-03-10")).toMatchObject({
            dateKey: "2026-03-10",
            delta: -167.47,
            balance: -167.47,
            deltaCents: -16747,
            balanceCents: -16747,
        });
    });

    it("nunca ordena por documentId descendente", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });
        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        const descendingByKey = orderByCalls.filter((call) => call.field === "__name__" && call.direction === "desc");
        expect(descendingByKey).toEqual([]);
        // A única ordenação descendente permitida é por um CAMPO indexado.
        expect(orderByCalls).toContainEqual({ field: "dateKey", direction: "desc" });
    });

    it("parte do saldo do último dia anterior", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });
        seed("2026-03-05", { dateKey: "2026-03-05", delta: -200, balance: 800 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-10")).toMatchObject({
            dateKey: "2026-03-10", delta: -50, balance: 750, deltaCents: -5000, balanceCents: 75000,
        });
    });

    it("soma vários movimentos no mesmo dia", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);
        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -3025);

        expect(read("2026-03-10")).toMatchObject({
            delta: -80.25, balance: 919.75, deltaCents: -8025, balanceCents: 91975,
        });
    });

    it("escreve UM documento na transação e propaga o resto em lotes de 400", async () => {
        seed("2023-01-01", { dateKey: "2023-01-01", delta: 5000, balance: 5000 });
        // 1000 dias de saldo futuro: no modelo antigo, tudo isso entrava na
        // mesma transação e estourava o limite de 500 escritas.
        for (let i = 0; i < 1000; i++) {
            const day = new Date(Date.UTC(2023, 0, 2 + i));
            const key = day.toISOString().split("T")[0];
            seed(key, { dateKey: key, delta: 0, balance: 5000 });
        }

        transactionWrites = [];
        committedBatchSizes = [];

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2023-01-01"), -10000);

        expect(transactionWrites).toEqual([`${BALANCE_PATH}/2023-01-01`]);
        expect(committedBatchSizes).toEqual([400, 400, 200]);
        expect(committedBatchSizes.every((size) => size <= 400)).toBe(true);

        expect(read("2023-01-01")).toMatchObject({
            delta: 4900, balance: 4900, deltaCents: 490000, balanceCents: 490000,
        });
        expect(read("2023-01-02")!.balance).toBeCloseTo(4900, 2);
        expect(read("2025-09-27")!.balance).toBeCloseTo(4900, 2);
    });

    it("propaga apenas para os dias POSTERIORES", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });
        seed("2026-03-20", { dateKey: "2026-03-20", delta: -100, balance: 900 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-01")!.balance).toBeCloseTo(1000, 2);
        expect(read("2026-03-10")!.balance).toBeCloseTo(950, 2);
        expect(read("2026-03-20")!.balance).toBeCloseTo(850, 2);
    });

    it("encontra o dia anterior mesmo em documentos legados (sem dateKey)", async () => {
        // Formato anterior a F1.4: só `balance`, id = YYYY-MM-DD.
        seed("2026-03-01", { balance: 1000 });
        seed("2026-03-05", { balance: 800 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-10")).toMatchObject({ dateKey: "2026-03-10", delta: -50, balance: 750 });
    });

    it("prefere o documento legado mais recente ao candidato indexado", async () => {
        // Base em migração: um documento já com dateKey e outro, mais recente,
        // ainda sem o campo. A query indexada sozinha devolveria o antigo.
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });
        seed("2026-03-05", { balance: 800 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-10")!.balance).toBeCloseTo(750, 2);
    });

    it("infere o delta de um documento legado do próprio dia", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000 });
        seed("2026-03-10", { balance: 900 }); // movimento de -100 implícito

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-10")).toMatchObject({
            dateKey: "2026-03-10", delta: -150, balance: 850, deltaCents: -15000, balanceCents: 85000,
        });
    });

    it("preenche o dateKey dos documentos legados durante a propagação", async () => {
        seed("2026-03-20", { balance: 500 });

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"), -5000);

        expect(read("2026-03-20")).toMatchObject({
            dateKey: "2026-03-20", balance: 450, balanceCents: 45000,
        });
    });

    it("usa o dia de calendário de São Paulo, não o de UTC", async () => {
        // 23h30 de 10/03 em São Paulo = 02h30 de 11/03 em UTC.
        const lateNightInSaoPaulo = new Date("2026-03-11T02:30:00.000Z");
        expect(lateNightInSaoPaulo.toISOString().split("T")[0]).toBe("2026-03-11");
        expect(toDateKey(lateNightInSaoPaulo)).toBe("2026-03-10");

        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, lateNightInSaoPaulo, -2500);

        expect(read("2026-03-10")).toMatchObject({ dateKey: "2026-03-10", delta: -25, deltaCents: -2500 });
        expect(read("2026-03-11")).toBeUndefined();
    });

    it("a transação faz poucas leituras (dia + anterior), independentemente do histórico", async () => {
        for (let i = 0; i < 50; i++) {
            const day = new Date(Date.UTC(2026, 0, 1 + i));
            const key = day.toISOString().split("T")[0];
            seed(key, { dateKey: key, delta: 0, balance: 100 });
        }

        transactionReads = 0;
        await repository.updateAccountBalance(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-06-01"), -1000);

        // 1 documento do dia + 1 consulta indexada + 1 sonda de legado.
        expect(transactionReads).toBe(3);
    });
});

describe("FinanceRepositoryImpl.getLastBalanceBefore (F1.4)", () => {
    beforeEach(() => {
        store.clear();
        orderByCalls = [];
    });

    it("devolve o último saldo anterior sem varredura descendente por chave", async () => {
        seed("2026-03-01", { dateKey: "2026-03-01", delta: 1000, balance: 1000, updatedAt: new Date() });
        seed("2026-03-05", { dateKey: "2026-03-05", delta: -200, balance: 800, updatedAt: new Date() });

        const repository = new FinanceRepositoryImpl();
        const result = await repository.getLastBalanceBefore(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"));

        expect(result).toMatchObject({ id: "2026-03-05", dateKey: "2026-03-05", balance: 800 });
        expect(orderByCalls.filter((call) => call.field === "__name__" && call.direction === "desc")).toEqual([]);
    });

    it("devolve null quando não há saldo anterior", async () => {
        const repository = new FinanceRepositoryImpl();
        expect(await repository.getLastBalanceBefore(WORKSPACE, ACCOUNT, noonInSaoPaulo("2026-03-10"))).toBeNull();
    });
});
