/**
 * Migração F1.4 (`migrate_balance_date_key.ts`): dry-run, idempotência, cálculo
 * do `delta` a partir do dia anterior, paginação e escopo por workspace.
 */

import { migrateBalanceDateKey, parseArgs } from "../scripts/migrate_balance_date_key";

type Docs = Record<string, Record<string, any>>;

/** `workspaceId -> accountId -> (dateKey -> dados)`. */
type Fixture = Record<string, Record<string, Docs>>;

let committedBatchSizes: number[];

/** Firestore falso: só o que o script usa (listDocuments, paginação e batch). */
function buildFirestore(fixture: Fixture): any {
    const balanceQuery = (docs: Docs, pageSize: number | null, startAfterId: string | null) => {
        const entries = Object.entries(docs).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
        const started = startAfterId === null
            ? entries
            : entries.filter(([id]) => id > startAfterId);
        const page = pageSize === null ? started : started.slice(0, pageSize);

        return {
            empty: page.length === 0,
            size: page.length,
            docs: page.map(([id, data]) => ({
                id,
                data: () => ({ ...data }),
                ref: { __accountDocs: docs, id },
            })),
        };
    };

    const balanceCollection = (docs: Docs) => {
        const query: any = {
            __pageSize: null as number | null,
            __startAfter: null as string | null,
            orderBy() {
                return query;
            },
            limit(size: number) {
                query.__pageSize = size;
                return query;
            },
            startAfter(id: string) {
                query.__startAfter = id;
                return query;
            },
            async get() {
                return balanceQuery(docs, query.__pageSize, query.__startAfter);
            },
        };
        return query;
    };

    return {
        collection: (name: string) => {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return {
                async listDocuments() {
                    return Object.keys(fixture).map((id) => ({ id }));
                },
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => {
                        if (sub !== "accounts") throw new Error(`subcoleção inesperada: ${sub}`);
                        return {
                            async listDocuments() {
                                return Object.keys(fixture[workspaceId] || {}).map((accountId) => ({
                                    id: accountId,
                                    collection: (name2: string) => {
                                        if (name2 !== "balance") throw new Error(`subcoleção inesperada: ${name2}`);
                                        return balanceCollection(fixture[workspaceId][accountId]);
                                    },
                                }));
                            },
                        };
                    },
                }),
            };
        },
        batch: () => {
            const operations: Array<() => void> = [];
            return {
                update(ref: any, data: Record<string, any>) {
                    operations.push(() => {
                        ref.__accountDocs[ref.id] = { ...ref.__accountDocs[ref.id], ...data };
                    });
                },
                set: jest.fn(),
                delete: jest.fn(),
                async commit() {
                    committedBatchSizes.push(operations.length);
                    operations.forEach((operation) => operation());
                },
            };
        },
    };
}

const silent = () => undefined;

describe("migrate_balance_date_key", () => {
    beforeEach(() => {
        committedBatchSizes = [];
    });

    it("dry-run não escreve nada", async () => {
        const fixture: Fixture = {
            w1: { acc1: { "2026-03-01": { balance: 1000 }, "2026-03-10": { balance: 800 } } },
        };
        const firestore = buildFirestore(fixture);

        const summary = await migrateBalanceDateKey(firestore, { dryRun: true }, silent);

        expect(summary).toMatchObject({ workspaces: 1, accounts: 1, scanned: 2, migrated: 2, failed: 0 });
        expect(fixture.w1.acc1["2026-03-01"]).toEqual({ balance: 1000 });
        expect(committedBatchSizes).toEqual([]);
    });

    it("grava dateKey = id e delta = balance - balance do dia anterior", async () => {
        const fixture: Fixture = {
            w1: {
                acc1: {
                    "2026-03-01": { balance: 1000 },
                    "2026-03-10": { balance: 832.53 },
                    "2026-03-20": { balance: 782.53 },
                },
            },
        };
        const firestore = buildFirestore(fixture);

        await migrateBalanceDateKey(firestore, { dryRun: false }, silent);

        expect(fixture.w1.acc1["2026-03-01"]).toEqual({ balance: 1000, dateKey: "2026-03-01", delta: 1000 });
        expect(fixture.w1.acc1["2026-03-10"]).toEqual({ balance: 832.53, dateKey: "2026-03-10", delta: -167.47 });
        expect(fixture.w1.acc1["2026-03-20"]).toEqual({ balance: 782.53, dateKey: "2026-03-20", delta: -50 });
    });

    it("é idempotente: a segunda execução não muda nada", async () => {
        const fixture: Fixture = {
            w1: { acc1: { "2026-03-01": { balance: 1000 }, "2026-03-10": { balance: 900 } } },
        };
        const firestore = buildFirestore(fixture);

        await migrateBalanceDateKey(firestore, { dryRun: false }, silent);
        committedBatchSizes = [];

        const second = await migrateBalanceDateKey(firestore, { dryRun: false }, silent);

        expect(second).toMatchObject({ scanned: 2, migrated: 0, skippedAlreadyMigrated: 2 });
        expect(committedBatchSizes).toEqual([]);
    });

    it("corrige um delta gravado errado", async () => {
        const fixture: Fixture = {
            w1: {
                acc1: {
                    "2026-03-01": { balance: 1000, dateKey: "2026-03-01", delta: 1000 },
                    "2026-03-10": { balance: 900, dateKey: "2026-03-10", delta: -999 },
                },
            },
        };
        const firestore = buildFirestore(fixture);

        const summary = await migrateBalanceDateKey(firestore, { dryRun: false }, silent);

        expect(summary).toMatchObject({ migrated: 1, skippedAlreadyMigrated: 1 });
        expect(fixture.w1.acc1["2026-03-10"].delta).toBeCloseTo(-100, 2);
    });

    it("ignora documento com id fora do padrão YYYY-MM-DD", async () => {
        const fixture: Fixture = {
            w1: { acc1: { "2026-03-01": { balance: 100 }, "saldo-atual": { balance: 42 } } },
        };
        const firestore = buildFirestore(fixture);

        const summary = await migrateBalanceDateKey(firestore, { dryRun: false }, silent);

        expect(summary).toMatchObject({ migrated: 1, skippedInvalidId: 1 });
        expect(fixture.w1.acc1["saldo-atual"]).toEqual({ balance: 42 });
    });

    it("pagina o histórico e mantém o acumulado entre páginas", async () => {
        const docs: Docs = {};
        for (let i = 0; i < 25; i++) {
            const day = new Date(Date.UTC(2026, 0, 1 + i)).toISOString().split("T")[0];
            docs[day] = { balance: (i + 1) * 10 };
        }
        const fixture: Fixture = { w1: { acc1: docs } };
        const firestore = buildFirestore(fixture);

        await migrateBalanceDateKey(firestore, { dryRun: false, pageSize: 10 }, silent);

        // Cada dia sobe 10: o delta é constante mesmo atravessando páginas.
        expect(Object.values(docs).every((doc) => Math.abs(doc.delta - 10) < 0.005)).toBe(true);
        expect(docs["2026-01-11"]).toMatchObject({ dateKey: "2026-01-11", delta: 10 });
    });

    it("limita o escopo a um workspace", async () => {
        const fixture: Fixture = {
            w1: { acc1: { "2026-03-01": { balance: 10 } } },
            w2: { acc2: { "2026-03-01": { balance: 20 } } },
        };
        const firestore = buildFirestore(fixture);

        const summary = await migrateBalanceDateKey(firestore, { dryRun: false, workspaceId: "w2" }, silent);

        expect(summary).toMatchObject({ workspaces: 1, accounts: 1, scanned: 1 });
        expect(fixture.w1.acc1["2026-03-01"]).toEqual({ balance: 10 });
        expect(fixture.w2.acc2["2026-03-01"]).toMatchObject({ dateKey: "2026-03-01", delta: 20 });
    });

    it("conta falha de conta sem abortar a migração inteira", async () => {
        const fixture: Fixture = {
            w1: { acc1: { "2026-03-01": { balance: 10 } }, acc2: { "2026-03-01": { balance: 20 } } },
        };
        const firestore = buildFirestore(fixture);
        const original = firestore.collection;
        firestore.collection = (name: string) => {
            const collection = original(name);
            const originalDoc = collection.doc;
            collection.doc = (workspaceId: string) => {
                const workspace = originalDoc(workspaceId);
                const originalSub = workspace.collection;
                workspace.collection = (sub: string) => {
                    const accounts = originalSub(sub);
                    const originalList = accounts.listDocuments;
                    accounts.listDocuments = async () => {
                        const refs = await originalList();
                        const explode = () => {
                            throw new Error("boom");
                        };
                        return refs.map((ref: any) => (ref.id === "acc1"
                            ? { id: ref.id, collection: explode }
                            : ref));
                    };
                    return accounts;
                };
                return workspace;
            };
            return collection;
        };

        const summary = await migrateBalanceDateKey(firestore, { dryRun: false }, silent);

        expect(summary.failed).toBe(1);
        expect(fixture.w1.acc2["2026-03-01"]).toMatchObject({ dateKey: "2026-03-01", delta: 20 });
    });

    it("parseArgs: dry-run por padrão e flags reconhecidas", () => {
        expect(parseArgs([])).toMatchObject({ dryRun: true });
        expect(parseArgs(["--apply", "--workspace=w1", "--project=p1", "--page-size=50"])).toMatchObject({
            dryRun: false,
            workspaceId: "w1",
            projectId: "p1",
            pageSize: 50,
        });
    });
});
