jest.mock("firebase-admin", () => ({
    firestore: {
        Timestamp: {
            fromDate: (date: Date) => ({ __ts: date.getTime(), toDate: () => new Date(date.getTime()) }),
        },
    },
}));

import {
    backfillLastGeneratedDueDate,
    parseArgs,
} from "../scripts/backfill_last_generated_due_date";

interface FakeOrder {
    workspaceId: string;
    id: string;
    installmentType: string;
    lastGeneratedDueDate?: Date;
    installments: (Date | null)[];
    failOnInstallments?: boolean;
}

/**
 * Firestore falso: as orders vivem em `workspaces/{wid}/orders` e são
 * devolvidas tanto pela subcoleção quanto pelo collectionGroup, conforme o
 * script escolhe um ou outro.
 */
function createFakeFirestore(orders: FakeOrder[]) {
    const writes: Array<{ workspaceId: string; orderId: string; data: any; options: any }> = [];

    const makeOrderDoc = (order: FakeOrder) => ({
        id: order.id,
        ref: {
            parent: { parent: { id: order.workspaceId } },
            async set(data: any, options: any) {
                writes.push({ workspaceId: order.workspaceId, orderId: order.id, data, options });
            },
        },
        data: () => ({
            installmentType: order.installmentType,
            lastGeneratedDueDate: order.lastGeneratedDueDate
                ? { toDate: () => order.lastGeneratedDueDate }
                : undefined,
        }),
    });

    const installmentsQuery = (workspaceId: string) => ({
        where(field: string, _op: string, orderId: string) {
            expect(field).toBe("orderId");
            return {
                async get() {
                    const order = orders.find((o) => o.workspaceId === workspaceId && o.id === orderId);
                    if (order?.failOnInstallments) throw new Error("falha simulada ao ler parcelas");
                    return {
                        docs: (order?.installments || []).map((dueDate) => ({
                            data: () => ({ dueDate: dueDate ? { toDate: () => dueDate } : null }),
                        })),
                    };
                },
            };
        },
    });

    const firestore: any = {
        collectionGroup(name: string) {
            expect(name).toBe("orders");
            return {
                where(field: string, _op: string, value: string) {
                    expect(field).toBe("installmentType");
                    return {
                        async get() {
                            return { docs: orders.filter((o) => o.installmentType === value).map(makeOrderDoc) };
                        },
                    };
                },
            };
        },
        collection(path: string) {
            expect(path).toBe("workspaces");
            return {
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => {
                        if (sub === "installments") return installmentsQuery(workspaceId);
                        if (sub !== "orders") throw new Error(`subcoleção inesperada: ${sub}`);
                        return {
                            where(field: string, _op: string, value: string) {
                                expect(field).toBe("installmentType");
                                return {
                                    async get() {
                                        return {
                                            docs: orders
                                                .filter((o) => o.workspaceId === workspaceId && o.installmentType === value)
                                                .map(makeOrderDoc),
                                        };
                                    },
                                };
                            },
                        };
                    },
                }),
            };
        },
    };

    return { firestore, writes };
}

const silent = () => undefined;

const RECURRING = "recurring";

describe("backfill_last_generated_due_date", () => {
    it("é dry-run por padrão e só aplica com --apply", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--project=funance-cef1b"]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
        expect(parseArgs(["--workspace=w9"]).workspaceId).toBe("w9");
        expect(parseArgs(["--project=p1"]).projectId).toBe("p1");
    });

    it("no dry-run relata o que preencheria sem escrever nada", async () => {
        const { firestore, writes } = createFakeFirestore([
            {
                workspaceId: "w1",
                id: "o1",
                installmentType: RECURRING,
                installments: [new Date(2025, 0, 10, 12), new Date(2025, 5, 10, 12), new Date(2025, 2, 10, 12)],
            },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: true }, silent);

        expect(summary).toMatchObject({ scanned: 1, filled: 1, failed: 0 });
        expect(writes).toHaveLength(0);
    });

    it("grava o vencimento da ÚLTIMA parcela, ao meio-dia", async () => {
        const { firestore, writes } = createFakeFirestore([
            {
                workspaceId: "w1",
                id: "o1",
                installmentType: RECURRING,
                installments: [new Date(2025, 0, 10, 12), new Date(2025, 5, 10, 8), new Date(2025, 2, 10, 12)],
            },
        ]);

        await backfillLastGeneratedDueDate(firestore, { dryRun: false }, silent);

        expect(writes).toHaveLength(1);
        expect(writes[0].options).toEqual({ merge: true });

        const written: Date = writes[0].data.lastGeneratedDueDate.toDate();
        expect(written.getFullYear()).toBe(2025);
        expect(written.getMonth()).toBe(5);
        expect(written.getDate()).toBe(10);
        expect(written.getHours()).toBe(12);
    });

    it("é idempotente: pula orders que já têm lastGeneratedDueDate", async () => {
        const { firestore, writes } = createFakeFirestore([
            {
                workspaceId: "w1",
                id: "o1",
                installmentType: RECURRING,
                lastGeneratedDueDate: new Date(2025, 5, 10, 12),
                installments: [new Date(2025, 5, 10, 12)],
            },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: false }, silent);

        expect(summary.skippedAlreadySet).toBe(1);
        expect(summary.filled).toBe(0);
        expect(writes).toHaveLength(0);
    });

    it("ignora orders recorrentes sem parcelas (nada a inferir)", async () => {
        const { firestore, writes } = createFakeFirestore([
            { workspaceId: "w1", id: "o1", installmentType: RECURRING, installments: [] },
            { workspaceId: "w1", id: "o2", installmentType: RECURRING, installments: [null] },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: false }, silent);

        expect(summary.skippedNoInstallments).toBe(2);
        expect(writes).toHaveLength(0);
    });

    it("não toca em orders que não são recorrentes", async () => {
        const { firestore, writes } = createFakeFirestore([
            { workspaceId: "w1", id: "o1", installmentType: "installment", installments: [new Date(2025, 0, 1, 12)] },
            { workspaceId: "w1", id: "o2", installmentType: "single", installments: [new Date(2025, 0, 1, 12)] },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: false }, silent);

        expect(summary.scanned).toBe(0);
        expect(writes).toHaveLength(0);
    });

    it("com --workspace limita a migração a um workspace", async () => {
        const { firestore, writes } = createFakeFirestore([
            { workspaceId: "w1", id: "o1", installmentType: RECURRING, installments: [new Date(2025, 0, 1, 12)] },
            { workspaceId: "w2", id: "o2", installmentType: RECURRING, installments: [new Date(2025, 0, 1, 12)] },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: false, workspaceId: "w2" }, silent);

        expect(summary.scanned).toBe(1);
        expect(writes).toHaveLength(1);
        expect(writes[0].workspaceId).toBe("w2");
    });

    it("contabiliza falhas e segue para as próximas orders", async () => {
        const { firestore, writes } = createFakeFirestore([
            { workspaceId: "w1", id: "o1", installmentType: RECURRING, installments: [], failOnInstallments: true },
            { workspaceId: "w1", id: "o2", installmentType: RECURRING, installments: [new Date(2025, 3, 15, 12)] },
        ]);

        const summary = await backfillLastGeneratedDueDate(firestore, { dryRun: false }, silent);

        expect(summary.failed).toBe(1);
        expect(summary.filled).toBe(1);
        expect(writes.map((w) => w.orderId)).toEqual(["o2"]);
    });
});
