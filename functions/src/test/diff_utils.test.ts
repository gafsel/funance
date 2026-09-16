import { deepEquals, getChangedFields } from "../core/utils/diff.utils";

/** Timestamp do Firestore, reduzido ao que a comparação usa. */
function timestamp(date: Date) {
    return {
        _seconds: Math.floor(date.getTime() / 1000),
        _nanoseconds: (date.getTime() % 1000) * 1e6,
        toDate: () => new Date(date.getTime()),
    };
}

describe("getChangedFields", () => {
    it("considera Timestamp e Date equivalentes quando apontam para o mesmo instante", () => {
        const date = new Date(2025, 2, 31, 12);

        expect(getChangedFields(
            { dueDate: timestamp(date) },
            { dueDate: new Date(date.getTime()) }
        )).toEqual([]);
    });

    it("detecta mudança de data", () => {
        const before = { dueDate: timestamp(new Date(2025, 2, 31, 12)) };
        const after = { dueDate: timestamp(new Date(2025, 2, 28, 12)) };

        expect(getChangedFields(before, after)).toEqual(["dueDate"]);
    });

    it("trata campo ausente e campo nulo como iguais", () => {
        expect(getChangedFields({ paidDate: null }, {})).toEqual([]);
        expect(getChangedFields({ paidDate: undefined }, { paidDate: null })).toEqual([]);
    });

    it("compara mapas aninhados independentemente da ordem das chaves", () => {
        const before = { category: { id: "c1", name: "Casa", type: "expense" } };
        const after = { category: { type: "expense", name: "Casa", id: "c1" } };

        expect(getChangedFields(before, after)).toEqual([]);
    });

    it("detecta mudança dentro de um mapa aninhado", () => {
        expect(getChangedFields(
            { accounts: { a: "debt" } },
            { accounts: { a: "credit" } }
        )).toEqual(["accounts"]);
    });

    it("compara arrays por posição", () => {
        expect(getChangedFields({ accountIds: ["a", "b"] }, { accountIds: ["a", "b"] })).toEqual([]);
        expect(getChangedFields({ accountIds: ["a", "b"] }, { accountIds: ["b", "a"] })).toEqual(["accountIds"]);
    });

    it("lista campos novos e removidos", () => {
        expect(getChangedFields({ a: 1 }, { b: 2 })).toEqual(["a", "b"]);
    });

    it("isola a escrita derivada de xp + cascata", () => {
        const dueDate = timestamp(new Date(2025, 2, 31, 12));
        const before = {
            amount: 0,
            dueDate,
            status: "paid",
            paidAmount: 100,
            replicationCascade: "all",
        };
        const after = { ...before, xp: 15, replicationCascade: "none" };

        expect(getChangedFields(before, after)).toEqual(["replicationCascade", "xp"]);
    });

    it("deepEquals ignora diferenças de ordem e de representação de data", () => {
        const date = new Date(2025, 0, 1, 12);
        expect(deepEquals({ a: 1, d: timestamp(date) }, { d: date, a: 1 })).toBe(true);
        expect(deepEquals({ a: 1 }, { a: "1" })).toBe(false);
    });
});
