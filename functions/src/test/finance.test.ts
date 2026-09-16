// ofx-js é ESM puro e não é transformado pelo ts-jest; mockamos pois não é usado nestes testes
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import { splitAmountIntoInstallments } from "../features/finance/domain/services/finance.service";

describe("splitAmountIntoInstallments", () => {
    const sum = (values: number[]) => Math.round(values.reduce((acc, v) => acc + v * 100, 0)) / 100;

    it("should split 502.40 / 10 into 10 equal installments of 50.24", () => {
        const result = splitAmountIntoInstallments(502.40, 10);
        expect(result).toHaveLength(10);
        expect(result.every(v => v === 50.24)).toBe(true);
        expect(sum(result)).toBe(502.40);
    });

    it("should split 512.04 / 12 into 12 equal installments of 42.67", () => {
        const result = splitAmountIntoInstallments(512.04, 12);
        expect(result).toHaveLength(12);
        expect(result.every(v => v === 42.67)).toBe(true);
        expect(sum(result)).toBe(512.04);
    });

    it("should split 100 / 3 distributing the remainder cent to the first installment", () => {
        const result = splitAmountIntoInstallments(100, 3);
        expect(result).toEqual([33.34, 33.33, 33.33]);
        expect(sum(result)).toBe(100);
    });

    it("should distribute remainder cents one per installment on the first installments", () => {
        const result = splitAmountIntoInstallments(100.05, 4);
        // 10005 centavos / 4 = 2501 base, resto 1 => primeira parcela +1 centavo
        expect(result).toEqual([25.02, 25.01, 25.01, 25.01]);
        expect(sum(result)).toBe(100.05);
    });

    it("should handle single installment", () => {
        expect(splitAmountIntoInstallments(99.99, 1)).toEqual([99.99]);
    });

    it("should return empty array for invalid count", () => {
        expect(splitAmountIntoInstallments(100, 0)).toEqual([]);
        expect(splitAmountIntoInstallments(100, -2)).toEqual([]);
        expect(splitAmountIntoInstallments(100, 2.5)).toEqual([]);
    });

    it("should always preserve the total for arbitrary values", () => {
        const cases: [number, number][] = [[502.40, 10], [512.04, 12], [100, 3], [0.01, 3], [999.97, 7], [1234.56, 11]];
        for (const [total, count] of cases) {
            const result = splitAmountIntoInstallments(total, count);
            expect(result).toHaveLength(count);
            expect(sum(result)).toBe(total);
            // Diferença máxima de 1 centavo entre parcelas
            const max = Math.max(...result);
            const min = Math.min(...result);
            expect(Math.round((max - min) * 100)).toBeLessThanOrEqual(1);
        }
    });
});
