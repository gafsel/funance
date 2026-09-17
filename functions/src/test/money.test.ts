import {
    addMoney,
    fromCents,
    MAX_SAFE_CENTS,
    moneyEquals,
    readCents,
    resolveCents,
    round2,
    splitCents,
    subtractMoney,
    sumCents,
    sumMoney,
    toCents,
} from "../core/utils/money";

describe("money — os casos clássicos de ponto flutuante", () => {
    it("0.1 + 0.2 soma exatamente 0.3", () => {
        // O `+` do JavaScript devolve 0.30000000000000004; era assim que o
        // saldo e os sumários vinham sendo somados.
        expect(0.1 + 0.2).not.toBe(0.3);
        expect(addMoney(0.1, 0.2)).toBe(0.3);
        expect(toCents(0.1 + 0.2)).toBe(30);
    });

    it("1.005 arredonda para 1.01 (Math.round(v*100) devolveria 1.00)", () => {
        expect(Math.round(1.005 * 100)).toBe(100); // o defeito que saiu
        expect(toCents(1.005)).toBe(101);
        expect(round2(1.005)).toBe(1.01);
    });

    it("arredonda meio AFASTANDO DE ZERO, para o estorno cancelar o lançamento", () => {
        expect(toCents(1.005)).toBe(101);
        expect(toCents(-1.005)).toBe(-101);
        expect(toCents(0.005)).toBe(1);
        expect(toCents(-0.005)).toBe(-1);

        // Math.round nativo arredonda meio para +infinito e quebraria a simetria.
        expect(Math.round(-0.5)).toBe(-0);

        for (const value of [1.005, 0.125, 2.675, 8.165, 1.115]) {
            expect(toCents(value) + toCents(-value)).toBe(0);
        }
    });

    it("não devolve -0", () => {
        expect(Object.is(toCents(-0), 0)).toBe(true);
        expect(Object.is(toCents(-0.001), 0)).toBe(true);
        expect(Object.is(fromCents(-0), 0)).toBe(true);
        expect(Object.is(round2(-0.0004), 0)).toBe(true);
    });

    it("valor não finito vira zero", () => {
        expect(toCents(NaN)).toBe(0);
        expect(toCents(Infinity)).toBe(0);
        expect(toCents(null)).toBe(0);
        expect(toCents(undefined)).toBe(0);
        expect(fromCents(NaN)).toBe(0);
    });

    it("preserva precisão em valores grandes (o teto das rules é 1e12)", () => {
        expect(toCents(12345678901.23)).toBe(1234567890123);
        expect(fromCents(1234567890123)).toBe(12345678901.23);
        expect(round2(12345678901.23)).toBe(12345678901.23);
    });

    it("2.675 — o exemplo de manual do arredondamento binário", () => {
        // 2.675 é guardado como 2.67499999999999982236431605997495353221893310546875
        expect(toCents(2.675)).toBe(268);
        expect(round2(2.675)).toBe(2.68);
    });

    it("8.165 * 100 cai do lado de baixo do meio e ainda assim arredonda certo", () => {
        expect(8.165 * 100).toBe(816.4999999999999);
        expect(Math.round(8.165 * 100)).toBe(816); // o defeito
        expect(toCents(8.165)).toBe(817);
    });
});

describe("money — soma", () => {
    it("um milhão de parcelas de 1 centavo somam exatamente R$ 10.000,00", () => {
        const parcels = new Array<number>(1_000_000).fill(0.01);

        // Somando os doubles o resultado escorrega.
        let naive = 0;
        for (const value of parcels) naive += value;
        expect(naive).not.toBe(10000);

        expect(sumCents(parcels)).toBe(1_000_000);
        expect(sumMoney(parcels)).toBe(10000);
    });

    it("soma e subtração de valores negativos", () => {
        expect(addMoney(-0.1, -0.2)).toBe(-0.3);
        expect(subtractMoney(0.3, 0.1)).toBe(0.2);
        expect(subtractMoney(0.1, 0.3)).toBe(-0.2);
        expect(sumMoney([10.1, -10.1])).toBe(0);
        expect(sumMoney([1.1, 2.2, -3.3])).toBe(0);
    });

    it("lista vazia e valores sujos", () => {
        expect(sumMoney([])).toBe(0);
        expect(sumMoney([1.5, NaN, null, undefined, 2.5])).toBe(4);
    });

    it("a ordem da soma não muda o resultado", () => {
        const values = [0.07, 1.13, 99.99, -3.33, 0.01, 12.5];
        const reversed = [...values].reverse();
        expect(sumCents(values)).toBe(sumCents(reversed));
    });
});

describe("money — comparação sem epsilon", () => {
    it("0.1 + 0.2 é igual a 0.3", () => {
        expect(0.1 + 0.2 === 0.3).toBe(false);
        expect(moneyEquals(0.1 + 0.2, 0.3)).toBe(true);
    });

    it("um centavo de diferença NÃO é igual", () => {
        expect(moneyEquals(10, 10.01)).toBe(false);
        expect(moneyEquals(10, 10.004)).toBe(true); // abaixo de meio centavo
    });
});

describe("money — leitura do campo *Cents", () => {
    it("aceita apenas inteiro dentro do intervalo seguro", () => {
        expect(readCents(1234)).toBe(1234);
        expect(readCents(0)).toBe(0);
        expect(readCents(-99)).toBe(-99);
        expect(readCents(12.5)).toBeNull();
        expect(readCents("1234")).toBeNull();
        expect(readCents(undefined)).toBeNull();
        expect(readCents(NaN)).toBeNull();
        expect(readCents(MAX_SAFE_CENTS + 10)).toBeNull();
    });

    it("o INTEIRO é a fonte da verdade; o double só responde na base não migrada", () => {
        // Documento já migrado: vale o inteiro, mesmo divergindo do espelho.
        expect(resolveCents(12.34, 1234)).toBe(1234);
        expect(resolveCents(12.34, 1235)).toBe(1235);
        // Documento legado (sem o campo): cai no double.
        expect(resolveCents(12.34, undefined)).toBe(1234);
        expect(resolveCents(0.1 + 0.2, null)).toBe(30);
    });
});

describe("money — divisão em parcelas", () => {
    it("R$ 502,40 em 10x dá 10 parcelas de R$ 50,24", () => {
        const parts = splitCents(toCents(502.4), 10);
        expect(parts).toEqual(new Array(10).fill(5024));
        expect(sumCents(parts.map(fromCents))).toBe(50240);
    });

    it("distribui o resto 1 centavo por parcela, e a soma fecha", () => {
        const parts = splitCents(toCents(100), 3);
        expect(parts).toEqual([3334, 3333, 3333]);
        expect(parts.reduce((a, b) => a + b, 0)).toBe(10000);
    });

    it("total negativo reparte simétrico ao positivo", () => {
        const positive = splitCents(10000, 3);
        const negative = splitCents(-10000, 3);
        expect(negative).toEqual(positive.map((part) => -part));
        expect(negative.reduce((a, b) => a + b, 0)).toBe(-10000);
    });

    it("entrada inválida devolve lista vazia", () => {
        expect(splitCents(100, 0)).toEqual([]);
        expect(splitCents(100, -1)).toEqual([]);
        expect(splitCents(100, 1.5)).toEqual([]);
        expect(splitCents(NaN, 3)).toEqual([]);
    });

    it("qualquer repartição fecha exatamente no total", () => {
        for (let total = -500; total <= 500; total += 7) {
            for (let count = 1; count <= 13; count++) {
                const parts = splitCents(total, count);
                expect(parts).toHaveLength(count);
                expect(parts.reduce((a, b) => a + b, 0)).toBe(total);
            }
        }
    });
});

describe("money — round-trip", () => {
    it("fromCents(toCents(v)) é estável e idempotente", () => {
        const values = [0, 0.01, 0.1, 0.3, 1.005, -1.005, 99.999, 1234.567, -0.004, 1e6 + 0.005];
        for (const value of values) {
            const once = round2(value);
            expect(round2(once)).toBe(once);
            expect(toCents(once)).toBe(toCents(value));
        }
    });
});
