import { backfillNextInvoice, parseArgs } from "../scripts/backfill_next_invoice";
import { toDateKey } from "../core/utils/date_key";

/** Instante do meio-dia de São Paulo (UTC-3 o ano inteiro desde 2019). */
function spNoon(dateKey: string): Date {
    const [year, month, day] = dateKey.split("-").map(Number);
    return new Date(Date.UTC(year, month - 1, day, 15, 0, 0));
}

interface FakeCard {
    id: string;
    data: Record<string, any>;
}

interface FakeInvoice {
    id: string;
    accountId: string;
    amount: number;
    dueDate: Date;
    orderId: string;
    status?: string;
}

/**
 * Firestore falso: um workspace por chave, com os cartões e as faturas em
 * aberto. `writes` guarda o que o script tentou gravar.
 */
function createFakeFirestore(
    workspaces: Record<string, { cards: FakeCard[]; invoices?: FakeInvoice[] }>,
    failures: { listCards?: string } = {}
) {
    const writes: Array<{ accountId: string; data: any }> = [];

    // `commitInChunks` é o real: o fake precisa de um `batch()` de verdade.
    const firestore: any = {
        batch() {
            const operations: Array<{ ref: any; data: any }> = [];
            return {
                set(ref: any, data: any) {
                    operations.push({ ref, data });
                },
                update(ref: any, data: any) {
                    operations.push({ ref, data });
                },
                delete() { /* não usado */ },
                async commit() {
                    for (const operation of operations) {
                        writes.push({ accountId: operation.ref.__id, data: operation.data });
                    }
                },
            };
        },
        collection(path: string) {
            if (path !== "workspaces") throw new Error(`coleção inesperada: ${path}`);

            return {
                select: () => ({
                    async get() {
                        return { docs: Object.keys(workspaces).map((id) => ({ id })) };
                    },
                }),
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => {
                        const workspace = workspaces[workspaceId] ?? { cards: [] };

                        if (sub === "accounts") {
                            return {
                                where: () => ({
                                    where: () => ({
                                        async get() {
                                            if (failures.listCards === workspaceId) {
                                                throw new Error("índice ausente");
                                            }
                                            return {
                                                docs: workspace.cards.map((card) => ({
                                                    id: card.id,
                                                    data: () => card.data,
                                                    ref: { __id: card.id },
                                                })),
                                            };
                                        },
                                    }),
                                }),
                            };
                        }

                        if (sub === "installments") {
                            let accountId = "";
                            const query: any = {
                                where(field: string, _op: string, value: any) {
                                    if (field === "accountIds") accountId = value;
                                    return query;
                                },
                                orderBy: () => query,
                                limit: () => query,
                                async get() {
                                    const found = (workspace.invoices ?? [])
                                        .filter((i) => i.accountId === accountId)
                                        .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime())[0];

                                    if (!found) return { docs: [] };

                                    return {
                                        docs: [{
                                            id: found.id,
                                            data: () => ({
                                                amount: found.amount,
                                                orderId: found.orderId,
                                                status: found.status ?? "pending",
                                                dueDate: { toDate: () => found.dueDate },
                                            }),
                                        }],
                                    };
                                },
                            };
                            return query;
                        }

                        throw new Error(`subcoleção inesperada: ${sub}`);
                    },
                }),
            };
        },
    };

    return { firestore, writes };
}

const silent = () => undefined;

const card = (id: string, extra: Record<string, any> = {}): FakeCard => ({
    id,
    data: {
        name: "Cartão",
        runtimeType: "creditCard",
        isDeleted: false,
        closingDay: 5,
        dueDay: 10,
        ...extra,
    },
});

describe("backfill_next_invoice", () => {
    it("é dry-run por padrão e só aplica com --apply", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--project=funance-cef1b"]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
        expect(parseArgs(["--force"]).force).toBe(true);
        expect(parseArgs(["--workspace=w9"]).workspaceId).toBe("w9");
        expect(parseArgs(["--project=p1"]).projectId).toBe("p1");
    });

    it("no dry-run relata o que faria sem escrever nada", async () => {
        const { firestore, writes } = createFakeFirestore({ w1: { cards: [card("c1")] } });

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: true, now: spNoon("2025-03-01") },
            silent
        );

        expect(writes).toHaveLength(0);
        expect(summary).toEqual({ workspaces: 1, cards: 1, filled: 1, skipped: 0, failed: 0 });
    });

    it("preenche a partir da fatura em aberto", async () => {
        const { firestore, writes } = createFakeFirestore({
            w1: {
                cards: [card("c1")],
                invoices: [{
                    id: "inst-1",
                    accountId: "c1",
                    amount: 420.75,
                    dueDate: spNoon("2025-03-10"),
                    orderId: "invoice-c1-2025-03-10",
                }],
            },
        });

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: false, now: spNoon("2025-02-20") },
            silent
        );

        expect(summary.filled).toBe(1);
        expect(writes).toHaveLength(1);

        const next = writes[0].data.nextInvoice;
        expect(next.amount).toBe(420.75);
        expect(next.installmentId).toBe("inst-1");
        expect(next.orderId).toBe("invoice-c1-2025-03-10");
        expect(toDateKey(next.dueDate.toDate())).toBe("2025-03-10");
        expect(toDateKey(next.cycleStart.toDate())).toBe("2025-02-05");
        expect(toDateKey(next.cycleEnd.toDate())).toBe("2025-03-04");
        expect(toDateKey(next.closingDate.toDate())).toBe("2025-03-05");
    });

    it("sem fatura em aberto, grava o ciclo corrente com valor zero", async () => {
        const { firestore, writes } = createFakeFirestore({ w1: { cards: [card("c1")] } });

        await backfillNextInvoice(firestore, { dryRun: false, now: spNoon("2025-03-20") }, silent);

        const next = writes[0].data.nextInvoice;
        expect(next.amount).toBe(0);
        expect(next.installmentId).toBeNull();
        expect(toDateKey(next.dueDate.toDate())).toBe("2025-04-10");
        expect(next.orderId).toBe("invoice-c1-2025-04-10");
    });

    it("é idempotente: pula quem já tem nextInvoice", async () => {
        const { firestore, writes } = createFakeFirestore({
            w1: { cards: [card("c1", { nextInvoice: { amount: 1 } }), card("c2")] },
        });

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: false, now: spNoon("2025-03-01") },
            silent
        );

        expect(summary).toEqual({ workspaces: 1, cards: 2, filled: 1, skipped: 1, failed: 0 });
        expect(writes.map((w) => w.accountId)).toEqual(["c2"]);
    });

    it("--force recalcula quem já tem o campo", async () => {
        const { firestore, writes } = createFakeFirestore({
            w1: { cards: [card("c1", { nextInvoice: { amount: 1 } })] },
        });

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: false, force: true, now: spNoon("2025-03-01") },
            silent
        );

        expect(summary.skipped).toBe(0);
        expect(writes.map((w) => w.accountId)).toEqual(["c1"]);
    });

    it("respeita o escopo por workspace", async () => {
        const { firestore, writes } = createFakeFirestore({
            w1: { cards: [card("c1")] },
            w2: { cards: [card("c2")] },
        });

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: false, workspaceId: "w2", now: spNoon("2025-03-01") },
            silent
        );

        expect(summary.workspaces).toBe(1);
        expect(writes.map((w) => w.accountId)).toEqual(["c2"]);
    });

    it("contabiliza falha de um workspace sem interromper os outros", async () => {
        const { firestore, writes } = createFakeFirestore(
            { w1: { cards: [card("c1")] }, w2: { cards: [card("c2")] } },
            { listCards: "w1" }
        );

        const summary = await backfillNextInvoice(
            firestore,
            { dryRun: false, now: spNoon("2025-03-01") },
            silent
        );

        expect(summary.failed).toBe(1);
        expect(summary.filled).toBe(1);
        expect(writes.map((w) => w.accountId)).toEqual(["c2"]);
    });

    it("aplica o clamp de fechamento 31 em fevereiro", async () => {
        const { firestore, writes } = createFakeFirestore({
            w1: {
                cards: [card("c1", { closingDay: 31, dueDay: 10 })],
                invoices: [{
                    id: "inst-1",
                    accountId: "c1",
                    amount: 90,
                    dueDate: spNoon("2025-04-10"),
                    orderId: "invoice-c1-2025-04-10",
                }],
            },
        });

        await backfillNextInvoice(firestore, { dryRun: false, now: spNoon("2025-03-15") }, silent);

        const next = writes[0].data.nextInvoice;
        expect(toDateKey(next.cycleStart.toDate())).toBe("2025-02-28");
        expect(toDateKey(next.closingDate.toDate())).toBe("2025-03-31");
    });
});
