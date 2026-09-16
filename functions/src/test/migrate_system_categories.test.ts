import { migrateSystemCategories, parseArgs } from "../scripts/migrate_system_categories";
import { INITIAL_BALANCE_CATEGORY_ID } from "../features/workspace/domain/models/category.model";

/**
 * Firestore falso: `existing` define quais workspaces já têm a categoria de
 * sistema; `writes` registra o que o script tentou escrever.
 */
function createFakeFirestore(workspaceIds: string[], existing: Set<string>) {
    const writes: Array<{ workspaceId: string; data: any }> = [];

    const firestore: any = {
        collection(path: string) {
            if (path !== "workspaces") {
                throw new Error(`coleção inesperada: ${path}`);
            }
            return {
                select: () => ({
                    async get() {
                        return { docs: workspaceIds.map((id) => ({ id })) };
                    },
                }),
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => ({
                        doc: (categoryId: string) => ({
                            async get() {
                                return { exists: existing.has(workspaceId) && categoryId === INITIAL_BALANCE_CATEGORY_ID };
                            },
                            async set(data: any) {
                                if (sub !== "categories") {
                                    throw new Error(`subcoleção inesperada: ${sub}`);
                                }
                                writes.push({ workspaceId, data });
                            },
                        }),
                    }),
                }),
            };
        },
    };

    return { firestore, writes };
}

const silent = () => undefined;

describe("migrate_system_categories", () => {
    it("é dry-run por padrão e só aplica com --apply", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--project=funance-cef1b"]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
        expect(parseArgs(["--workspace=w9"]).workspaceId).toBe("w9");
        expect(parseArgs(["--project=p1"]).projectId).toBe("p1");
    });

    it("no dry-run relata o que criaria sem escrever nada", async () => {
        const { firestore, writes } = createFakeFirestore(["w1", "w2", "w3"], new Set(["w2"]));

        const summary = await migrateSystemCategories(firestore, { dryRun: true }, silent);

        expect(writes).toHaveLength(0);
        expect(summary).toEqual({ scanned: 3, created: 2, skipped: 1, failed: 0 });
    });

    it("cria a categoria apenas nos workspaces que não a possuem", async () => {
        const { firestore, writes } = createFakeFirestore(["w1", "w2", "w3"], new Set(["w2"]));

        const summary = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(summary).toEqual({ scanned: 3, created: 2, skipped: 1, failed: 0 });
        expect(writes.map((w) => w.workspaceId)).toEqual(["w1", "w3"]);
        expect(writes[0].data).toEqual(expect.objectContaining({
            name: "Saldo Inicial",
            icon: "account_balance_wallet",
            isSystem: true,
            isDeleted: false,
        }));
        // O id vira o id do documento, não um campo do payload.
        expect(writes[0].data.id).toBeUndefined();
    });

    it("é idempotente: uma segunda execução não escreve nada", async () => {
        const existing = new Set<string>();
        const { firestore, writes } = createFakeFirestore(["w1", "w2"], existing);

        await migrateSystemCategories(firestore, { dryRun: false }, silent);
        expect(writes).toHaveLength(2);

        existing.add("w1");
        existing.add("w2");
        const second = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(writes).toHaveLength(2);
        expect(second).toEqual({ scanned: 2, created: 0, skipped: 2, failed: 0 });
    });

    it("limita a execução a um workspace quando --workspace é informado", async () => {
        const { firestore, writes } = createFakeFirestore(["w1", "w2", "w3"], new Set());

        const summary = await migrateSystemCategories(firestore, { dryRun: false, workspaceId: "w2" }, silent);

        expect(summary.scanned).toBe(1);
        expect(writes.map((w) => w.workspaceId)).toEqual(["w2"]);
    });

    it("contabiliza falhas sem abortar os demais workspaces", async () => {
        const { firestore } = createFakeFirestore(["w1", "w2"], new Set());
        const original = firestore.collection;
        firestore.collection = (path: string) => {
            const collection = original(path);
            return {
                ...collection,
                doc: (workspaceId: string) => {
                    if (workspaceId === "w1") {
                        return {
                            collection: () => ({
                                doc: () => ({
                                    get: async () => {
                                        throw new Error("permission denied");
                                    },
                                }),
                            }),
                        };
                    }
                    return collection.doc(workspaceId);
                },
            };
        };

        const summary = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(summary).toEqual({ scanned: 2, created: 1, skipped: 0, failed: 1 });
    });
});
