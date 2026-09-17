/**
 * Cobre a regra F1.7: o soft delete de conta precisa realmente apagar as
 * orders. O bug original consultava `where("accounts", "array-contains", id)`,
 * mas `accounts` é um MAPA {accountId: 'debt'|'credit'} — a query nunca casava
 * e nada era removido (apesar do log dizendo o contrário).
 */
const mockFirestoreState: any = {
    collection: null,
    batch: null,
};

jest.mock("firebase-admin", () => {
    const firestore: any = () => ({
        collection: (...args: any[]) => mockFirestoreState.collection(...args),
        batch: () => mockFirestoreState.batch(),
    });
    firestore.Timestamp = { fromDate: (date: Date) => date };
    firestore.FieldValue = {
        increment: (value: number) => ({ __increment: value }),
        serverTimestamp: () => ({ __serverTimestamp: true }),
    };
    // FieldPath real o bastante para o teste inspecionar os segmentos.
    class FakeFieldPath {
        segments: string[];
        constructor(...segments: string[]) {
            this.segments = segments;
        }
    }
    firestore.FieldPath = FakeFieldPath;
    firestore.FieldPath.documentId = () => "__name__";
    return { firestore };
});

import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { InstallmentStatus } from "../features/finance/domain/models/finance.models";

describe("FinanceRepositoryImpl.deleteOrdersByAccountId", () => {
    let whereCalls: Array<[any, string, any]>;
    let deletedIds: string[];
    let pages: any[][];
    /** Documentos de history por order, consumidos página a página. */
    let historyByOrder: Record<string, any[][]>;

    /** Order com a subcoleção `history` ligada ao mock. */
    const orderDoc = (id: string) => ({
        ref: {
            id,
            collection: (name: string) => {
                if (name !== "history") throw new Error(`subcoleção inesperada: ${name}`);
                const historyQuery: any = {
                    limit: () => historyQuery,
                    async get() {
                        const docs = (historyByOrder[id] || []).shift() || [];
                        return { docs, empty: docs.length === 0, size: docs.length };
                    },
                };
                return historyQuery;
            },
        },
    });

    beforeEach(() => {
        whereCalls = [];
        deletedIds = [];
        pages = [];
        historyByOrder = {};

        const query: any = {
            where(field: any, operator: string, value: any) {
                whereCalls.push([field, operator, value]);
                return query;
            },
            limit() {
                return query;
            },
            async get() {
                const docs = pages.shift() || [];
                return { docs, empty: docs.length === 0, size: docs.length };
            },
        };

        mockFirestoreState.collection = jest.fn(() => query);
        mockFirestoreState.batch = () => ({
            delete(ref: any) {
                deletedIds.push(ref.id);
            },
            update: jest.fn(),
            set: jest.fn(),
            async commit() {
                return undefined;
            },
        });
    });

    it("consulta a chave do mapa via FieldPath('accounts', accountId) com o operador 'in'", async () => {
        pages = [[]];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc1");

        expect(mockFirestoreState.collection).toHaveBeenCalledWith("workspaces/w1/orders");
        expect(whereCalls).toHaveLength(1);

        const [field, operator, value] = whereCalls[0];
        // FieldPath, não string interpolada: ids com ponto/crase não viram caminho.
        expect(typeof field).not.toBe("string");
        expect(field.segments).toEqual(["accounts", "acc1"]);
        expect(operator).toBe("in");
        expect(value).toEqual(["debt", "credit"]);
    });

    it("preserva ids de conta com ponto nos segmentos do FieldPath", async () => {
        pages = [[]];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc.1");

        expect(whereCalls[0][0].segments).toEqual(["accounts", "acc.1"]);
    });

    it("NÃO usa o campo espelho accountIds (as orders do cliente não o possuem)", async () => {
        pages = [[]];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc1");

        // order_model.g.dart não serializa accountIds: só faturas e saldo
        // inicial (criados pelo servidor) têm o campo.
        expect(whereCalls.map(([field]) => field)).not.toContain("accountIds");
        expect(whereCalls.map(([, operator]) => operator)).not.toContain("array-contains");
    });

    it("apaga todas as orders da conta, paginando quando há mais de um lote", async () => {
        const docs = (prefix: string, count: number) =>
            Array.from({ length: count }, (_, i) => orderDoc(`${prefix}-${i}`));

        pages = [docs("a", 400), docs("b", 3)];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc1");

        expect(deletedIds).toHaveLength(403);
        expect(deletedIds[0]).toBe("a-0");
        expect(deletedIds[402]).toBe("b-2");
        // Toda página usa o mesmo filtro por chave de mapa.
        expect(whereCalls).toHaveLength(1);
    });

    it("apaga a subcoleção history de cada order removida", async () => {
        pages = [[orderDoc("o1"), orderDoc("o2")]];
        historyByOrder = {
            o1: [[{ ref: { id: "o1-h1" } }, { ref: { id: "o1-h2" } }]],
            o2: [[{ ref: { id: "o2-h1" } }]],
        };

        await new FinanceRepositoryImpl().deleteOrdersByAccountId("w1", "acc1");

        // Histórico primeiro (subcoleções não caem em cascata), orders depois.
        expect(deletedIds).toEqual(["o1-h1", "o1-h2", "o2-h1", "o1", "o2"]);
    });

    it("apaga as orders normalmente quando não há histórico", async () => {
        pages = [[orderDoc("o1")]];

        await new FinanceRepositoryImpl().deleteOrdersByAccountId("w1", "acc1");

        expect(deletedIds).toEqual(["o1"]);
    });
});

/**
 * Cobre a regra F1.13: `getInstallments` não excluía parcelas com
 * status 'removed' (exclusão lógica) quando nenhum filtro de status era
 * informado, contaminando relatórios e agregações.
 */
describe("FinanceRepositoryImpl.getInstallments", () => {
    let whereCalls: Array<[string, string, any]>;

    beforeEach(() => {
        whereCalls = [];

        const query: any = {
            where(field: string, operator: string, value: any) {
                whereCalls.push([field, operator, value]);
                return query;
            },
            async get() {
                return { docs: [], empty: true, size: 0 };
            },
        };

        mockFirestoreState.collection = jest.fn(() => query);
        mockFirestoreState.batch = () => ({
            delete: jest.fn(), update: jest.fn(), set: jest.fn(), commit: jest.fn(),
        });
    });

    it("exclui 'removed' por padrão quando nenhum status é informado", async () => {
        const repository = new FinanceRepositoryImpl();

        await repository.getInstallments("w1", {});

        expect(whereCalls).toEqual([
            ["status", "in", [InstallmentStatus.pending, InstallmentStatus.paid, InstallmentStatus.settled]],
        ]);
    });

    it("mantém o filtro explícito de status, removendo 'removed' do conjunto", async () => {
        const repository = new FinanceRepositoryImpl();

        await repository.getInstallments("w1", {
            status: [InstallmentStatus.paid, InstallmentStatus.removed],
        });

        expect(whereCalls).toEqual([["status", "in", [InstallmentStatus.paid]]]);
    });

    it("inclui 'removed' apenas com includeRemoved", async () => {
        const repository = new FinanceRepositoryImpl();

        await repository.getInstallments("w1", { includeRemoved: true });
        expect(whereCalls).toEqual([]);

        whereCalls = [];
        await repository.getInstallments("w1", {
            status: [InstallmentStatus.removed],
            includeRemoved: true,
        });
        expect(whereCalls).toEqual([["status", "in", [InstallmentStatus.removed]]]);
    });

    it("retorna vazio (sem consultar) quando o filtro pede apenas 'removed' sem includeRemoved", async () => {
        const repository = new FinanceRepositoryImpl();

        const result = await repository.getInstallments("w1", { status: [InstallmentStatus.removed] });

        expect(result).toEqual([]);
        expect(whereCalls).toEqual([]);
    });
});

/**
 * O Firestore não apaga subcoleções em cascata: ao remover uma order é preciso
 * limpar `orders/{orderId}/history` explicitamente.
 */
describe("FinanceRepositoryImpl.deleteOrder", () => {
    let deletedRefs: string[];
    let historyPages: any[][];
    let orderDeleted: boolean;

    beforeEach(() => {
        deletedRefs = [];
        historyPages = [];
        orderDeleted = false;

        const historyQuery: any = {
            limit: () => historyQuery,
            async get() {
                const docs = historyPages.shift() || [];
                return { docs, empty: docs.length === 0, size: docs.length };
            },
        };

        const docRef: any = {
            id: "o1",
            collection: (name: string) => {
                if (name !== "history") throw new Error(`subcoleção inesperada: ${name}`);
                return historyQuery;
            },
            async delete() {
                orderDeleted = true;
            },
        };

        mockFirestoreState.collection = jest.fn(() => ({ doc: () => docRef }));
        mockFirestoreState.batch = () => ({
            delete(ref: any) {
                deletedRefs.push(ref.id);
            },
            update: jest.fn(),
            set: jest.fn(),
            async commit() {
                return undefined;
            },
        });
    });

    it("apaga a subcoleção history antes de apagar a order", async () => {
        historyPages = [[{ ref: { id: "h1" } }, { ref: { id: "h2" } }]];

        await new FinanceRepositoryImpl().deleteOrder("w1", "o1");

        expect(deletedRefs).toEqual(["h1", "h2"]);
        expect(orderDeleted).toBe(true);
    });

    it("apaga a order normalmente quando não há histórico", async () => {
        historyPages = [[]];

        await new FinanceRepositoryImpl().deleteOrder("w1", "o1");

        expect(deletedRefs).toEqual([]);
        expect(orderDeleted).toBe(true);
    });
});

describe("FinanceRepositoryImpl.deleteInstallmentsByOrderId", () => {
    it("apaga em lotes, paginando", async () => {
        const whereCalls: Array<[string, string, any]> = [];
        const deletedIds: string[] = [];
        const pages: any[][] = [
            Array.from({ length: 400 }, (_, i) => ({ ref: { id: `a-${i}` } })),
            [{ ref: { id: "b-0" } }],
        ];

        const query: any = {
            where(field: string, operator: string, value: any) {
                whereCalls.push([field, operator, value]);
                return query;
            },
            limit: () => query,
            async get() {
                const docs = pages.shift() || [];
                return { docs, empty: docs.length === 0, size: docs.length };
            },
        };

        mockFirestoreState.collection = jest.fn(() => query);
        mockFirestoreState.batch = () => ({
            delete(ref: any) {
                deletedIds.push(ref.id);
            },
            update: jest.fn(),
            set: jest.fn(),
            async commit() {
                return undefined;
            },
        });

        await new FinanceRepositoryImpl().deleteInstallmentsByOrderId("w1", "o1");

        expect(whereCalls).toEqual([["orderId", "==", "o1"]]);
        expect(deletedIds).toHaveLength(401);
    });
});

/**
 * HOTFIX — categoria sem id. `categories.<id>` com id vazio vira um segmento
 * vazio de FieldPath e o SDK rejeita o documento inteiro com "Element at index
 * 0 should not be an empty string", sem dizer qual workspace nem qual período.
 * O repositório é a DEFESA FINAL: quem chama já trata categoria sem id como
 * "sem categoria" (ver `empty_category.test.ts`), então chegar aqui é bug de
 * chamador — e o erro precisa apontar para ele.
 */
describe("FinanceRepositoryImpl.updatePeriodSummary", () => {
    const CATEGORY: any = { id: "cat-mercado", name: "Supermercado" };

    beforeEach(() => {
        mockFirestoreState.collection = jest.fn(() => {
            throw new Error("o Firestore não deveria ser tocado com categoria sem id");
        });
        mockFirestoreState.batch = () => ({
            delete: jest.fn(), update: jest.fn(), set: jest.fn(), commit: jest.fn(),
        });
    });

    it("rejeita categoria com id vazio antes de tocar no Firestore", async () => {
        const repository = new FinanceRepositoryImpl();

        await expect(
            repository.updatePeriodSummary("w1", 2026, 3, { ...CATEGORY, id: "" }, { actualDelta: 10 })
        ).rejects.toThrow(/categoria sem id/);

        expect(mockFirestoreState.collection).not.toHaveBeenCalled();
    });

    it("o erro cita workspace, período e nome da categoria", async () => {
        const repository = new FinanceRepositoryImpl();

        await expect(
            repository.updatePeriodSummary("w1", 2026, undefined, { ...CATEGORY, id: "" }, { actualDelta: 10 }, 10)
        ).rejects.toThrow(/workspace=w1.*2026.*W10.*Supermercado/);
    });

    it("rejeita também categoria ausente", async () => {
        const repository = new FinanceRepositoryImpl();

        await expect(
            repository.updatePeriodSummary("w1", 2026, 3, undefined as any, { actualDelta: 10 })
        ).rejects.toThrow(/categoria sem id/);
    });
});

/**
 * `applyPlanningImpacts` monta `categories[<id>]` direto. Sem guarda, UM
 * `category_planning` com `category.id` vazio fazia o SDK rejeitar o lote
 * inteiro ("Element at index 0 should not be an empty string") e derrubar com
 * ele o gatilho de planejamento e o cron mensal — todos os outros meses e
 * categorias junto. Mesma regra do resto do hotfix: pula com aviso.
 */
describe("FinanceRepositoryImpl.applyPlanningImpacts — categoria sem id", () => {
    const CATEGORY: any = { id: "cat-mercado", name: "Mercado" };
    const BROKEN: any = { id: "", name: "Supermercado" };

    let sets: Array<{ id: string, data: any }>;
    let warn: jest.SpyInstance;

    const update = (category: any, generalPlannedDelta: number, month = 3): any =>
        ({ year: 2026, month, category, generalPlannedDelta });

    beforeEach(() => {
        sets = [];
        warn = jest.spyOn(console, "warn").mockImplementation(() => undefined);

        mockFirestoreState.collection = jest.fn(() => ({ doc: (id: string) => ({ id }) }));
        mockFirestoreState.batch = () => ({
            delete: jest.fn(),
            update: jest.fn(),
            set(ref: any, data: any) {
                sets.push({ id: ref.id, data });
            },
            async commit() {
                return undefined;
            },
        });
    });

    afterEach(() => {
        warn.mockRestore();
    });

    it("pula a categoria sem id com aviso, em vez de montar `categories['']`", async () => {
        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [update(BROKEN, 150)]);

        // Nenhuma escrita: era o único impacto do documento.
        expect(sets).toEqual([]);
        expect(warn).toHaveBeenCalledTimes(1);
        const message = warn.mock.calls[0][0] as string;
        expect(message).toContain("workspace=w1");
        expect(message).toContain("documento=2026-03");
        expect(message).toContain("Supermercado");
    });

    it("as outras categorias do MESMO documento continuam sendo gravadas", async () => {
        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [
            update(BROKEN, 150),
            update(CATEGORY, 200),
        ]);

        expect(sets).toHaveLength(1);
        expect(Object.keys(sets[0].data.categories)).toEqual(["cat-mercado"]);
        expect(sets[0].data.categories["cat-mercado"].generalPlannedAmount).toEqual({ __increment: 200 });
        expect(warn).toHaveBeenCalledTimes(1);
    });

    it("os outros MESES continuam sendo gravados", async () => {
        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [
            update(BROKEN, 150, 3),
            update(CATEGORY, 200, 4),
            update(CATEGORY, 300, 5),
        ]);

        expect(sets.map((s) => s.id)).toEqual(["2026-04", "2026-05"]);
    });

    it("categoria AUSENTE cai na mesma guarda, sem estourar no agrupamento", async () => {
        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [
            update(undefined, 150),
            update(CATEGORY, 200),
        ]);

        expect(sets).toHaveLength(1);
        expect(Object.keys(sets[0].data.categories)).toEqual(["cat-mercado"]);
        expect(warn).toHaveBeenCalledTimes(1);
    });

    it("os marcadores do planejamento continuam sendo gravados mesmo quando tudo é pulado", async () => {
        const marks = { ref: { id: "planning-1" }, data: { lastSummaryMonth: "2026-03" } };

        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [update(BROKEN, 150)], marks as any);

        expect(sets.map((s) => s.id)).toEqual(["planning-1"]);
    });

    it("sem categoria quebrada, nada é avisado", async () => {
        await new FinanceRepositoryImpl().applyPlanningImpacts("w1", [update(CATEGORY, 200)]);

        expect(sets).toHaveLength(1);
        expect(warn).not.toHaveBeenCalled();
    });
});
