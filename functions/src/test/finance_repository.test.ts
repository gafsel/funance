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
    firestore.FieldPath = { documentId: () => "__name__" };
    return { firestore };
});

import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { InstallmentStatus } from "../features/finance/domain/models/finance.models";

describe("FinanceRepositoryImpl.deleteOrdersByAccountId", () => {
    let whereCalls: Array<[string, string, any]>;
    let deletedIds: string[];
    let pages: any[][];

    beforeEach(() => {
        whereCalls = [];
        deletedIds = [];
        pages = [];

        const query: any = {
            where(field: string, operator: string, value: any) {
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

    it("filtra pelo campo espelho accountIds (array), não pelo mapa accounts", async () => {
        pages = [[]];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc1");

        expect(mockFirestoreState.collection).toHaveBeenCalledWith("workspaces/w1/orders");
        expect(whereCalls).toEqual([["accountIds", "array-contains", "acc1"]]);
    });

    it("apaga todas as orders da conta, paginando quando há mais de um lote", async () => {
        const docs = (prefix: string, count: number) =>
            Array.from({ length: count }, (_, i) => ({ ref: { id: `${prefix}-${i}` } }));

        pages = [docs("a", 400), docs("b", 3)];
        const repository = new FinanceRepositoryImpl();

        await repository.deleteOrdersByAccountId("w1", "acc1");

        expect(deletedIds).toHaveLength(403);
        expect(deletedIds[0]).toBe("a-0");
        expect(deletedIds[402]).toBe("b-2");
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
