/**
 * F5.5 — varredura paginada de workspaces nos crons.
 *
 * Cobre paginação, concorrência limitada, checkpoint (gravação, retomada e
 * limpeza no fim), parada por deadline e isolamento de falha de um workspace.
 */

interface MockState {
    /** ids de workspace na coleção, em ordem crescente de documentId. */
    workspaceIds: string[];
    /** conteúdo do documento config/cron_checkpoints */
    checkpointDoc: any;
    /** escritas recebidas pelo documento de checkpoint */
    checkpointWrites: any[];
    /** páginas pedidas: {startAfter, limit} */
    pages: { startAfter: string | null; limit: number }[];
    checkpointReadThrows: boolean;
}

const mockFs: MockState = {
    workspaceIds: [],
    checkpointDoc: undefined,
    checkpointWrites: [],
    pages: [],
    checkpointReadThrows: false,
};

const DELETE_SENTINEL = { __delete: true };

jest.mock("firebase-admin", () => {
    function makeQuery(startAfter: string | null, limit: number): any {
        return {
            orderBy: () => makeQuery(startAfter, limit),
            limit: (value: number) => makeQuery(startAfter, value),
            startAfter: (value: string) => makeQuery(value, limit),
            get: async () => {
                mockFs.pages.push({ startAfter, limit });
                const from = startAfter
                    ? mockFs.workspaceIds.indexOf(startAfter) + 1
                    : 0;
                const ids = mockFs.workspaceIds.slice(from, from + limit);
                return {
                    empty: ids.length === 0,
                    docs: ids.map((id) => ({ id })),
                };
            },
        };
    }

    const checkpointRef = {
        get: async () => {
            if (mockFs.checkpointReadThrows) throw new Error("firestore indisponível");
            return {
                exists: mockFs.checkpointDoc !== undefined,
                data: () => mockFs.checkpointDoc,
            };
        },
        set: async (data: any, options: any) => {
            mockFs.checkpointWrites.push({ data, options });
            const base = mockFs.checkpointDoc ?? {};
            const next = { ...base };
            for (const [key, value] of Object.entries(data)) {
                if (value === DELETE_SENTINEL) delete next[key];
                else next[key] = value;
            }
            mockFs.checkpointDoc = next;
        },
    };

    const firestore: any = () => ({
        collection: (name: string) => {
            if (name === "config") {
                return { doc: () => checkpointRef };
            }
            return makeQuery(null, 50);
        },
    });
    firestore.FieldPath = { documentId: () => "__name__" };
    firestore.FieldValue = {
        serverTimestamp: () => ({ __serverTimestamp: true }),
        delete: () => DELETE_SENTINEL,
    };
    return { firestore };
});

// eslint-disable-next-line import/first
import { forEachWorkspacePaged } from "../core/utils/cron_runner";

function ids(count: number, prefix = "w"): string[] {
    return Array.from({ length: count }, (_, i) => `${prefix}${String(i).padStart(3, "0")}`);
}

/** Último valor gravado no checkpoint para a chave. */
function checkpointOf(key: string): string | undefined {
    return mockFs.checkpointDoc?.[key]?.lastWorkspaceId;
}

beforeEach(() => {
    mockFs.workspaceIds = [];
    mockFs.checkpointDoc = undefined;
    mockFs.checkpointWrites = [];
    mockFs.pages = [];
    mockFs.checkpointReadThrows = false;
    jest.spyOn(console, "log").mockImplementation(() => undefined);
    jest.spyOn(console, "warn").mockImplementation(() => undefined);
    jest.spyOn(console, "error").mockImplementation(() => undefined);
});

describe("forEachWorkspacePaged — paginação", () => {
    it("processa todos os workspaces em páginas do tamanho pedido", async () => {
        mockFs.workspaceIds = ids(12);
        const seen: string[] = [];

        const result = await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 5, concurrency: 2, deadlineMs: 60_000 },
            async (id) => {
                seen.push(id);
            }
        );

        expect(seen.sort()).toEqual(mockFs.workspaceIds);
        expect(result).toMatchObject({ processed: 12, failed: 0, completed: true, lastWorkspaceId: null });
        // 5 + 5 + 2: a terceira página vem incompleta e encerra a varredura.
        expect(mockFs.pages.map((p) => p.startAfter)).toEqual([null, "w004", "w009"]);
    });

    it("pede outra página quando a última veio cheia, e para no vazio", async () => {
        mockFs.workspaceIds = ids(10);

        const result = await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 5, concurrency: 5, deadlineMs: 60_000 },
            async () => undefined
        );

        expect(result.completed).toBe(true);
        expect(mockFs.pages).toHaveLength(3);
        expect(mockFs.pages[2].startAfter).toBe("w009");
    });

    it("coleção vazia completa sem processar nada", async () => {
        const result = await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 5, concurrency: 5, deadlineMs: 60_000 },
            async () => undefined
        );
        expect(result).toMatchObject({ processed: 0, completed: true });
    });
});

describe("forEachWorkspacePaged — concorrência", () => {
    it("não passa do limite de execuções simultâneas", async () => {
        mockFs.workspaceIds = ids(10);
        let running = 0;
        let maxRunning = 0;

        await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 10, concurrency: 3, deadlineMs: 60_000 },
            async () => {
                running++;
                maxRunning = Math.max(maxRunning, running);
                await new Promise((resolve) => setTimeout(resolve, 5));
                running--;
            }
        );

        expect(maxRunning).toBe(3);
    });

    it("de fato roda em paralelo dentro do lote", async () => {
        mockFs.workspaceIds = ids(4);
        const startedTogether: string[] = [];

        await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 4, concurrency: 4, deadlineMs: 60_000 },
            async (id) => {
                startedTogether.push(id);
                await new Promise((resolve) => setTimeout(resolve, 5));
            }
        );

        // Os 4 entraram antes de qualquer um terminar.
        expect(startedTogether).toEqual(ids(4));
    });
});

describe("forEachWorkspacePaged — checkpoint", () => {
    it("grava o checkpoint a cada lote", async () => {
        mockFs.workspaceIds = ids(6);

        await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 6, concurrency: 2, deadlineMs: 60_000 },
            async () => undefined
        );

        const written = mockFs.checkpointWrites
            .map((w) => w.data.weekly?.lastWorkspaceId)
            .filter(Boolean);
        expect(written).toEqual(["w001", "w003", "w005"]);
        expect(mockFs.checkpointWrites.every((w) => w.options.merge === true)).toBe(true);
    });

    it("zera o checkpoint quando a varredura completa", async () => {
        mockFs.workspaceIds = ids(3);

        await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 5, concurrency: 5, deadlineMs: 60_000 },
            async () => undefined
        );

        expect(checkpointOf("weekly")).toBeUndefined();
        expect(mockFs.checkpointWrites.at(-1)!.data.weekly).toBe(DELETE_SENTINEL);
    });

    it("retoma do checkpoint gravado, sem reprocessar o começo", async () => {
        mockFs.workspaceIds = ids(6);
        mockFs.checkpointDoc = { weekly: { lastWorkspaceId: "w003" } };
        const seen: string[] = [];

        const result = await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 10, concurrency: 5, deadlineMs: 60_000 },
            async (id) => {
                seen.push(id);
            }
        );

        expect(seen).toEqual(["w004", "w005"]);
        expect(result.resumedFrom).toBe("w003");
        expect(result.completed).toBe(true);
    });

    it("não mistura as chaves de crons diferentes", async () => {
        mockFs.workspaceIds = ids(4);
        mockFs.checkpointDoc = { gamification_monthly: { lastWorkspaceId: "w002" } };
        const seen: string[] = [];

        await forEachWorkspacePaged(
            { checkpointKey: "gamification_weekly", pageSize: 10, concurrency: 5, deadlineMs: 60_000 },
            async (id) => {
                seen.push(id);
            }
        );

        expect(seen).toEqual(ids(4));
        expect(mockFs.checkpointDoc.gamification_monthly.lastWorkspaceId).toBe("w002");
    });

    it("falha ao LER o checkpoint não impede a varredura (começa do início)", async () => {
        mockFs.workspaceIds = ids(3);
        mockFs.checkpointReadThrows = true;
        const seen: string[] = [];

        const result = await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 10, concurrency: 5, deadlineMs: 60_000 },
            async (id) => {
                seen.push(id);
            }
        );

        expect(seen).toEqual(ids(3));
        expect(result.resumedFrom).toBeNull();
    });
});

describe("forEachWorkspacePaged — deadline", () => {
    /** Relógio que avança `stepMs` a cada consulta. */
    function fakeClock(stepMs: number) {
        let current = 0;
        return () => {
            const value = current;
            current += stepMs;
            return value;
        };
    }

    it("para antes do deadline e deixa o checkpoint no ponto exato", async () => {
        mockFs.workspaceIds = ids(20);
        const seen: string[] = [];

        // O relógio anda 30s por consulta; com 100s de orçamento só cabem os
        // primeiros lotes.
        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "weekly",
                pageSize: 20,
                concurrency: 2,
                deadlineMs: 100_000,
                now: fakeClock(30_000),
            },
            async (id) => {
                seen.push(id);
            }
        );

        expect(result.completed).toBe(false);
        expect(seen.length).toBeGreaterThan(0);
        expect(seen.length).toBeLessThan(20);
        expect(result.lastWorkspaceId).toBe(seen[seen.length - 1]);
        expect(checkpointOf("weekly")).toBe(seen[seen.length - 1]);
    });

    it("a execução seguinte continua de onde parou e conclui", async () => {
        mockFs.workspaceIds = ids(8);
        const first: string[] = [];

        await forEachWorkspacePaged(
            {
                checkpointKey: "weekly",
                pageSize: 8,
                concurrency: 2,
                deadlineMs: 60_000,
                now: fakeClock(25_000),
            },
            async (id) => {
                first.push(id);
            }
        );

        expect(first.length).toBeLessThan(8);

        const second: string[] = [];
        const result = await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 8, concurrency: 2, deadlineMs: 60_000 },
            async (id) => {
                second.push(id);
            }
        );

        expect([...first, ...second]).toEqual(ids(8));
        expect(result.completed).toBe(true);
        expect(checkpointOf("weekly")).toBeUndefined();
    });

    it("deadline já vencido não processa nada e não perde o checkpoint", async () => {
        mockFs.workspaceIds = ids(5);
        mockFs.checkpointDoc = { weekly: { lastWorkspaceId: "w001" } };
        const seen: string[] = [];

        const result = await forEachWorkspacePaged(
            { checkpointKey: "weekly", pageSize: 5, concurrency: 5, deadlineMs: 0, now: () => 1000 },
            async (id) => {
                seen.push(id);
            }
        );

        expect(seen).toEqual([]);
        expect(result.completed).toBe(false);
        expect(checkpointOf("weekly")).toBe("w001");
    });
});

describe("forEachWorkspacePaged — isolamento de falha", () => {
    it("um workspace que lança não derruba os demais", async () => {
        mockFs.workspaceIds = ids(6);
        const seen: string[] = [];

        const result = await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 6, concurrency: 2, deadlineMs: 60_000 },
            async (id) => {
                if (id === "w002") throw new Error("dado corrompido");
                seen.push(id);
            }
        );

        expect(seen).toEqual(["w000", "w001", "w003", "w004", "w005"]);
        expect(result).toMatchObject({ processed: 5, failed: 1, completed: true });
    });

    it("workspace que falha é consumido: o checkpoint avança e ele não trava o cron", async () => {
        mockFs.workspaceIds = ids(4);

        await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 4, concurrency: 1, deadlineMs: 60_000 },
            async (id) => {
                if (id === "w000") throw new Error("sempre falha");
            }
        );

        expect(mockFs.checkpointWrites.map((w) => w.data.k?.lastWorkspaceId).filter(Boolean))
            .toEqual(["w000", "w001", "w002", "w003"]);
    });

    it("todos falhando ainda assim completa a varredura", async () => {
        mockFs.workspaceIds = ids(3);

        const result = await forEachWorkspacePaged(
            { checkpointKey: "k", pageSize: 3, concurrency: 3, deadlineMs: 60_000 },
            async () => {
                throw new Error("boom");
            }
        );

        expect(result).toMatchObject({ processed: 0, failed: 3, completed: true });
        expect(checkpointOf("k")).toBeUndefined();
    });
});
