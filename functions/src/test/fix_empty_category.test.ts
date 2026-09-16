/**
 * `scripts/fix_empty_category.ts`: conserta `category.id` vazio em parcelas e
 * orders — e só quando o nome embutido bate com o da categoria de destino.
 *
 * O script é a metade operacional do hotfix: o código já ignora categoria sem
 * id nos sumários (ver `empty_category.test.ts` e `rebuild.test.ts`), mas esses
 * documentos continuam fora dos `period_summaries` até serem corrigidos aqui.
 */

import {
    fixEmptyCategory,
    parseArgs,
    sameCategoryName,
    validateOptions,
} from "../scripts/fix_empty_category";

const silent = () => undefined;

interface FakeDoc {
    workspaceId: string;
    id: string;
    category: Record<string, any> | undefined;
}

interface Write {
    workspaceId: string;
    collection: string;
    id: string;
    data: any;
    options: any;
}

/**
 * Firestore falso: parcelas/orders por workspace e as categorias de destino.
 * O `set` MUTA o documento, para que a segunda execução exercite de verdade a
 * idempotência (o documento corrigido deixa de casar com o filtro).
 */
function createFakeFirestore(
    docs: { installments?: FakeDoc[], orders?: FakeDoc[] },
    categories: Record<string, Record<string, any>> = {}
) {
    const writes: Write[] = [];
    const whereCalls: Array<[string, string, any]> = [];
    const scopes: string[] = [];

    const source: Record<string, FakeDoc[]> = {
        installments: docs.installments ?? [],
        orders: docs.orders ?? [],
    };

    const snapshotDoc = (collection: string, doc: FakeDoc) => ({
        id: doc.id,
        data: () => ({ category: doc.category }),
        ref: {
            parent: { parent: { id: doc.workspaceId } },
            async set(data: any, options: any) {
                writes.push({ workspaceId: doc.workspaceId, collection, id: doc.id, data, options });
                doc.category = { ...doc.category, ...data.category };
            },
        },
    });

    const buildQuery = (collection: string, workspaceId?: string) => {
        let rows = source[collection].filter((d) => !workspaceId || d.workspaceId === workspaceId);

        const query: any = {
            where(field: string, operator: string, value: any) {
                whereCalls.push([field, operator, value]);
                if (field !== "category.id" || operator !== "==") {
                    throw new Error(`filtro inesperado: ${field} ${operator}`);
                }
                rows = rows.filter((d) => d.category?.id === value);
                return query;
            },
            async get() {
                return { docs: rows.map((d) => snapshotDoc(collection, d)) };
            },
        };
        return query;
    };

    const firestore: any = {
        collectionGroup(collection: string) {
            scopes.push(`group:${collection}`);
            return buildQuery(collection);
        },
        collection(name: string) {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return {
                doc: (workspaceId: string) => ({
                    collection: (sub: string) => {
                        if (sub === "categories") {
                            return {
                                doc: (categoryId: string) => ({
                                    async get() {
                                        const data = categories[workspaceId]?.[categoryId];
                                        return { exists: data !== undefined, data: () => data };
                                    },
                                }),
                            };
                        }
                        scopes.push(`workspace:${workspaceId}/${sub}`);
                        return buildQuery(sub, workspaceId);
                    },
                }),
            };
        },
    };

    return { firestore, writes, whereCalls, scopes, source };
}

const broken = (workspaceId: string, id: string, name = "Supermercado"): FakeDoc => ({
    workspaceId,
    id,
    category: { id: "", name, icon: "shopping_cart", color: "#42A5F5", type: "expense" },
});

const healthy = (workspaceId: string, id: string): FakeDoc => ({
    workspaceId,
    id,
    category: { id: "cat-mercado", name: "Supermercado" },
});

const CATEGORIES = { w1: { "cat-mercado": { name: "Supermercado" } } };

describe("fix_empty_category — flags", () => {
    it("dry-run é o padrão e só --apply escreve", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--project=funance-cef1b"]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
    });

    it("lê workspace, categoria de destino e projeto", () => {
        const options = parseArgs(["--workspace=w1", "--category-id=cat-mercado", "--project=p1"]);

        expect(options.workspaceId).toBe("w1");
        expect(options.categoryId).toBe("cat-mercado");
        expect(options.projectId).toBe("p1");
    });

    it("--apply sem --category-id é recusado (o script não adivinha categoria)", () => {
        expect(validateOptions({ dryRun: false })).toMatch(/--category-id/);
        expect(validateOptions({ dryRun: false, categoryId: "cat-mercado" })).toBeNull();
        // Sem --apply, listar sem categoria de destino é o uso normal.
        expect(validateOptions({ dryRun: true })).toBeNull();
    });
});

describe("fix_empty_category — comparação de nome", () => {
    it("ignora caixa e espaços nas pontas", () => {
        expect(sameCategoryName("Supermercado", "supermercado")).toBe(true);
        expect(sameCategoryName("  SUPERMERCADO ", "Supermercado")).toBe(true);
        expect(sameCategoryName("Mercado", "Supermercado")).toBe(false);
        expect(sameCategoryName("", "")).toBe(false);
        expect(sameCategoryName(undefined, "Supermercado")).toBe(false);
    });
});

describe("fix_empty_category — varredura", () => {
    it("só consulta documentos com category.id vazio, em parcelas e orders", async () => {
        const { firestore, whereCalls, scopes } = createFakeFirestore({
            installments: [broken("w1", "i1"), healthy("w1", "i2")],
            orders: [broken("w1", "o1")],
        });

        const summary = await fixEmptyCategory(firestore, { dryRun: true }, silent);

        expect(whereCalls).toEqual([
            ["category.id", "==", ""],
            ["category.id", "==", ""],
        ]);
        // Sem --workspace a busca é no grupo de coleções (base inteira).
        expect(scopes).toEqual(["group:installments", "group:orders"]);
        expect(summary).toMatchObject({ scanned: 2, installments: 1, orders: 1 });
    });

    it("com --workspace usa a subcoleção daquele workspace", async () => {
        const { firestore, scopes } = createFakeFirestore({
            installments: [broken("w1", "i1"), broken("w2", "i2")],
        });

        const summary = await fixEmptyCategory(firestore, { dryRun: true, workspaceId: "w1" }, silent);

        expect(scopes).toEqual(["workspace:w1/installments", "workspace:w1/orders"]);
        expect(summary.scanned).toBe(1);
    });

    it("sem --category-id apenas lista, sem escrever nada", async () => {
        const { firestore, writes } = createFakeFirestore(
            { installments: [broken("w1", "i1")] },
            CATEGORIES
        );

        const summary = await fixEmptyCategory(firestore, { dryRun: true }, silent);

        expect(writes).toHaveLength(0);
        expect(summary).toMatchObject({ scanned: 1, fixed: 0, skippedNoTarget: 1 });
    });
});

describe("fix_empty_category — correção", () => {
    it("no dry-run relata o que corrigiria, sem escrever", async () => {
        const { firestore, writes } = createFakeFirestore(
            { installments: [broken("w1", "i1", "supermercado")] },
            CATEGORIES
        );

        const summary = await fixEmptyCategory(
            firestore,
            { dryRun: true, workspaceId: "w1", categoryId: "cat-mercado" },
            silent
        );

        expect(writes).toHaveLength(0);
        expect(summary).toMatchObject({ scanned: 1, fixed: 1, skippedNameMismatch: 0 });
    });

    it("grava só o id, preservando os demais campos da categoria embutida", async () => {
        const { firestore, writes } = createFakeFirestore(
            { installments: [broken("w1", "i1")], orders: [broken("w1", "o1")] },
            CATEGORIES
        );

        const summary = await fixEmptyCategory(
            firestore,
            { dryRun: false, workspaceId: "w1", categoryId: "cat-mercado" },
            silent
        );

        expect(summary).toMatchObject({ scanned: 2, installments: 1, orders: 1, fixed: 2, failed: 0 });
        expect(writes.map((w) => `${w.collection}/${w.id}`)).toEqual(["installments/i1", "orders/o1"]);
        for (const write of writes) {
            expect(write.data.category).toEqual({
                id: "cat-mercado",
                name: "Supermercado",
                icon: "shopping_cart",
                color: "#42A5F5",
                type: "expense",
            });
            expect(write.options).toEqual({ merge: true });
        }
    });

    it("NÃO corrige quando o nome não bate — apenas lista", async () => {
        const { firestore, writes } = createFakeFirestore(
            { installments: [broken("w1", "i1", "Farmácia"), broken("w1", "i2", "Supermercado")] },
            CATEGORIES
        );

        const summary = await fixEmptyCategory(
            firestore,
            { dryRun: false, workspaceId: "w1", categoryId: "cat-mercado" },
            silent
        );

        expect(summary).toMatchObject({ scanned: 2, fixed: 1, skippedNameMismatch: 1 });
        expect(writes.map((w) => w.id)).toEqual(["i2"]);
    });

    it("NÃO corrige quando a categoria de destino não existe no workspace", async () => {
        const { firestore, writes } = createFakeFirestore(
            { installments: [broken("w2", "i1")] },
            CATEGORIES
        );

        const summary = await fixEmptyCategory(
            firestore,
            { dryRun: false, categoryId: "cat-mercado" },
            silent
        );

        expect(writes).toHaveLength(0);
        expect(summary).toMatchObject({ scanned: 1, fixed: 0, skippedNoTarget: 1 });
    });

    it("é idempotente: a segunda execução não encontra mais nada", async () => {
        const fake = createFakeFirestore({ installments: [broken("w1", "i1")] }, CATEGORIES);
        const options = { dryRun: false, workspaceId: "w1", categoryId: "cat-mercado" };

        const first = await fixEmptyCategory(fake.firestore, options, silent);
        const second = await fixEmptyCategory(fake.firestore, options, silent);

        expect(first.fixed).toBe(1);
        expect(second).toMatchObject({ scanned: 0, fixed: 0 });
        expect(fake.writes).toHaveLength(1);
        expect(fake.source.installments[0].category).toMatchObject({ id: "cat-mercado", name: "Supermercado" });
    });
});
