import { commitInChunks, deleteByQueryInChunks } from "../core/utils/batch.utils";

/**
 * Firestore falso: cada `batch()` grava as operações recebidas e o commit
 * empurra o lote para `commits`, permitindo assertar o tamanho de cada batch.
 */
function createFakeFirestore() {
    const commits: any[][] = [];

    const firestore = {
        batch() {
            const operations: any[] = [];
            return {
                delete(ref: any) {
                    operations.push({ op: "delete", ref });
                },
                update(ref: any, data: any) {
                    operations.push({ op: "update", ref, data });
                },
                set(ref: any, data: any, options?: any) {
                    operations.push({ op: "set", ref, data, options });
                },
                async commit() {
                    commits.push(operations);
                },
            };
        },
    };

    return { firestore: firestore as any, commits };
}

const ref = (id: string) => ({ id } as any);

describe("commitInChunks", () => {
    it("não commita nada quando não há operações", async () => {
        const { firestore, commits } = createFakeFirestore();
        const total = await commitInChunks(firestore, []);

        expect(total).toBe(0);
        expect(commits).toHaveLength(0);
    });

    it("quebra em lotes de no máximo 400 (padrão) e nunca ultrapassa 500", async () => {
        const { firestore, commits } = createFakeFirestore();
        const refs = Array.from({ length: 1001 }, (_, i) => ref(`doc-${i}`));

        const total = await commitInChunks(firestore, refs);

        expect(total).toBe(1001);
        expect(commits.map((c) => c.length)).toEqual([400, 400, 201]);
        for (const commit of commits) {
            expect(commit.length).toBeLessThanOrEqual(500);
        }
    });

    it("trata DocumentReference pelada como delete", async () => {
        const { firestore, commits } = createFakeFirestore();

        await commitInChunks(firestore, [ref("a"), ref("b")]);

        expect(commits[0].map((o) => o.op)).toEqual(["delete", "delete"]);
        expect(commits[0].map((o) => o.ref.id)).toEqual(["a", "b"]);
    });

    it("aplica operações de update e set", async () => {
        const { firestore, commits } = createFakeFirestore();

        await commitInChunks(firestore, [
            { op: "update", ref: ref("a"), data: { x: 1 } },
            { op: "set", ref: ref("b"), data: { y: 2 }, options: { merge: true } },
            { op: "set", ref: ref("c"), data: { z: 3 } },
        ]);

        expect(commits[0]).toEqual([
            { op: "update", ref: { id: "a" }, data: { x: 1 } },
            { op: "set", ref: { id: "b" }, data: { y: 2 }, options: { merge: true } },
            { op: "set", ref: { id: "c" }, data: { z: 3 }, options: undefined },
        ]);
    });

    it("limita o chunkSize pedido ao teto físico de 500", async () => {
        const { firestore, commits } = createFakeFirestore();
        const refs = Array.from({ length: 600 }, (_, i) => ref(`doc-${i}`));

        await commitInChunks(firestore, refs, 900);

        expect(commits.map((c) => c.length)).toEqual([500, 100]);
    });
});

describe("deleteByQueryInChunks", () => {
    /** Query falsa que devolve páginas sucessivas a cada `get()`. */
    function createFakeQuery(pages: any[][]) {
        const calls: number[] = [];
        let index = 0;

        const query: any = {
            limit(size: number) {
                calls.push(size);
                return query;
            },
            async get() {
                const docs = pages[index] || [];
                index++;
                return { docs, empty: docs.length === 0, size: docs.length };
            },
        };

        return { query, calls };
    }

    it("pagina até esgotar os documentos", async () => {
        const { firestore, commits } = createFakeFirestore();
        const page = (n: number) => Array.from({ length: n }, (_, i) => ({ ref: ref(`d${i}`) }));
        const { query, calls } = createFakeQuery([page(400), page(400), page(10)]);

        const deleted = await deleteByQueryInChunks(firestore, query);

        expect(deleted).toBe(810);
        expect(calls).toEqual([400, 400, 400]);
        expect(commits.map((c) => c.length)).toEqual([400, 400, 10]);
    });

    it("encerra imediatamente quando a query não casa com nada", async () => {
        const { firestore, commits } = createFakeFirestore();
        const { query } = createFakeQuery([[]]);

        const deleted = await deleteByQueryInChunks(firestore, query);

        expect(deleted).toBe(0);
        expect(commits).toHaveLength(0);
    });
});
