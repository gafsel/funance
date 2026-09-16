import { migrateSystemCategories, parseArgs } from "../scripts/migrate_system_categories";
import { SYSTEM_CATEGORIES } from "../features/workspace/domain/models/category.model";

const SYSTEM_IDS = SYSTEM_CATEGORIES.map((c) => c.id);

type Existing = Record<string, Record<string, any>>;

/**
 * Firestore falso: `existing` mapeia workspaceId -> {categoryId: data} para os
 * documentos que já existem; `writes` registra o que o script tentou escrever.
 */
function createFakeFirestore(workspaceIds: string[], existing: Existing) {
    const writes: Array<{ workspaceId: string; categoryId: string; data: any; options?: any }> = [];

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
                    collection: (sub: string) => {
                        if (sub !== "categories") {
                            throw new Error(`subcoleção inesperada: ${sub}`);
                        }
                        return {
                            doc: (categoryId: string) => ({
                                async get() {
                                    const data = existing[workspaceId]?.[categoryId];
                                    return { exists: data !== undefined, data: () => data };
                                },
                                async set(data: any, options?: any) {
                                    writes.push({ workspaceId, categoryId, data, options });
                                },
                            }),
                        };
                    },
                }),
            };
        },
    };

    return { firestore, writes };
}

const silent = () => undefined;

describe("migrate_system_categories", () => {
    it("cobre as cinco categorias de sistema (saldo inicial + virtuais)", () => {
        expect(SYSTEM_IDS).toEqual([
            "initial-balance",
            "virtual_debt_expense",
            "virtual_debt_income",
            "virtual_investment_expense",
            "virtual_investment_income",
        ]);
        expect(SYSTEM_CATEGORIES.every((c) => c.isSystem === true)).toBe(true);
    });

    it("é dry-run por padrão e só aplica com --apply", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--project=funance-cef1b"]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
        expect(parseArgs(["--workspace=w9"]).workspaceId).toBe("w9");
        expect(parseArgs(["--project=p1"]).projectId).toBe("p1");
    });

    it("no dry-run relata o que faria sem escrever nada", async () => {
        const { firestore, writes } = createFakeFirestore(["w1"], {
            w1: { virtual_debt_expense: { name: "Empréstimo/Dívidas" } },
        });

        const summary = await migrateSystemCategories(firestore, { dryRun: true }, silent);

        expect(writes).toHaveLength(0);
        // 4 criações + 1 marcação da virtual já existente sem a flag.
        expect(summary).toEqual({ scanned: 1, created: 4, flagged: 1, skipped: 0, failed: 0 });
    });

    it("cria as categorias ausentes com isSystem: true", async () => {
        const { firestore, writes } = createFakeFirestore(["w1"], {});

        const summary = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(summary).toEqual({ scanned: 1, created: 5, flagged: 0, skipped: 0, failed: 0 });
        expect(writes.map((w) => w.categoryId)).toEqual(SYSTEM_IDS);
        for (const write of writes) {
            expect(write.data.isSystem).toBe(true);
            expect(write.data.isDeleted).toBe(false);
            // O id vira o id do documento, não um campo do payload.
            expect(write.data.id).toBeUndefined();
        }
    });

    it("apenas acrescenta isSystem nas categorias virtuais já existentes, sem sobrescrever o resto", async () => {
        const { firestore, writes } = createFakeFirestore(["w1"], {
            w1: {
                "initial-balance": { name: "Saldo Inicial", isSystem: true },
                virtual_debt_expense: { name: "Nome customizado", color: "#000000" },
                virtual_debt_income: { name: "Empréstimo/Dívidas" },
                virtual_investment_expense: { name: "Investimentos" },
                virtual_investment_income: { name: "Investimentos" },
            },
        });

        const summary = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(summary).toEqual({ scanned: 1, created: 0, flagged: 4, skipped: 1, failed: 0 });
        expect(writes).toHaveLength(4);
        for (const write of writes) {
            expect(write.data).toEqual({ isSystem: true });
            expect(write.options).toEqual({ merge: true });
        }
    });

    it("é idempotente: uma segunda execução não escreve nada", async () => {
        const existing: Existing = { w1: {}, w2: {} };
        const { firestore, writes } = createFakeFirestore(["w1", "w2"], existing);

        await migrateSystemCategories(firestore, { dryRun: false }, silent);
        expect(writes).toHaveLength(10);

        for (const workspaceId of ["w1", "w2"]) {
            for (const id of SYSTEM_IDS) {
                existing[workspaceId][id] = { isSystem: true };
            }
        }
        const second = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(writes).toHaveLength(10);
        expect(second).toEqual({ scanned: 2, created: 0, flagged: 0, skipped: 10, failed: 0 });
    });

    it("limita a execução a um workspace quando --workspace é informado", async () => {
        const { firestore, writes } = createFakeFirestore(["w1", "w2", "w3"], {});

        const summary = await migrateSystemCategories(firestore, { dryRun: false, workspaceId: "w2" }, silent);

        expect(summary.scanned).toBe(1);
        expect(new Set(writes.map((w) => w.workspaceId))).toEqual(new Set(["w2"]));
    });

    it("contabiliza falhas sem abortar as demais categorias", async () => {
        const { firestore } = createFakeFirestore(["w1"], {});
        const original = firestore.collection;
        firestore.collection = (path: string) => {
            const collection = original(path);
            return {
                ...collection,
                doc: (workspaceId: string) => ({
                    collection: () => ({
                        doc: (categoryId: string) => {
                            if (categoryId === "initial-balance") {
                                return {
                                    get: async () => {
                                        throw new Error("permission denied");
                                    },
                                };
                            }
                            return collection.doc(workspaceId).collection("categories").doc(categoryId);
                        },
                    }),
                }),
            };
        };

        const summary = await migrateSystemCategories(firestore, { dryRun: false }, silent);

        expect(summary).toEqual({ scanned: 1, created: 4, flagged: 0, skipped: 0, failed: 1 });
    });
});
