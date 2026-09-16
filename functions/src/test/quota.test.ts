import { HttpsError } from "firebase-functions/v2/https";

/**
 * Estado compartilhado com o mock do firebase-admin. Precisa começar com
 * "mock" para o jest permitir a referência dentro da factory hoisteada, e só
 * é desreferenciado dentro de funções (a factory roda antes deste const ser
 * inicializado, mas os closures só executam durante os testes).
 */
const mockDb = {
    /** undefined = documento de quota do dia ainda não existe */
    docData: undefined as Record<string, any> | undefined,
    path: [] as string[],
    setCalls: [] as { data: any; options: any }[],
    transactions: 0,
};

jest.mock("firebase-admin", () => {
    const ref: any = {};
    ref.collection = (name: string) => {
        mockDb.path.push(name);
        return ref;
    };
    ref.doc = (id: string) => {
        mockDb.path.push(id);
        return ref;
    };

    const firestore: any = () => ({
        collection: ref.collection,
        runTransaction: async (fn: any) => {
            mockDb.transactions++;
            return fn({
                get: async () => ({
                    exists: mockDb.docData !== undefined,
                    data: () => mockDb.docData,
                }),
                set: (_ref: any, data: any, options: any) => {
                    mockDb.setCalls.push({ data, options });
                },
            });
        },
    });
    firestore.FieldValue = {
        increment: (n: number) => ({ __increment: n }),
        serverTimestamp: () => ({ __serverTimestamp: true }),
    };

    return { firestore };
});

// Importado depois do jest.mock para pegar o admin mockado.
// eslint-disable-next-line import/first
import { QuotaServiceImpl, quotaDayKey } from "../core/services/quota.service";

function resetDb() {
    mockDb.docData = undefined;
    mockDb.path = [];
    mockDb.setCalls = [];
    mockDb.transactions = 0;
}

describe("quotaDayKey", () => {
    it("formata YYYY-MM-DD no fuso America/Sao_Paulo", () => {
        // 2026-09-16T12:00:00Z => 09:00 em São Paulo, mesmo dia.
        expect(quotaDayKey(new Date("2026-09-16T12:00:00Z"))).toBe("2026-09-16");
    });

    it("usa o dia LOCAL de Brasília, não o dia UTC", () => {
        // 2026-09-17T02:00:00Z ainda é 16/09 23:00 em São Paulo (UTC-3).
        expect(quotaDayKey(new Date("2026-09-17T02:00:00Z"))).toBe("2026-09-16");
        // 2026-09-17T03:00:00Z já é 17/09 00:00 em São Paulo.
        expect(quotaDayKey(new Date("2026-09-17T03:00:00Z"))).toBe("2026-09-17");
    });
});

describe("QuotaServiceImpl.assertQuota", () => {
    const service = new QuotaServiceImpl();

    beforeEach(() => {
        resetDb();
    });

    it("grava o contador em workspaces/{id}/quotas/{YYYY-MM-DD}", async () => {
        await service.assertQuota("w1", "generateCoaching", 3);

        expect(mockDb.path).toEqual(["workspaces", "w1", "quotas", quotaDayKey()]);
    });

    it("incrementa o campo da função com merge quando ainda há saldo", async () => {
        mockDb.docData = { generateCoaching: 1 };

        await service.assertQuota("w1", "generateCoaching", 3);

        expect(mockDb.setCalls).toHaveLength(1);
        expect(mockDb.setCalls[0].options).toEqual({ merge: true });
        expect(mockDb.setCalls[0].data.generateCoaching).toEqual({ __increment: 1 });
        expect(mockDb.setCalls[0].data.updatedAt).toEqual({ __serverTimestamp: true });
    });

    it("cria o documento do dia quando ele ainda não existe", async () => {
        await service.assertQuota("w1", "analyze503020Ideal", 3);

        expect(mockDb.setCalls).toHaveLength(1);
        expect(mockDb.setCalls[0].data.analyze503020Ideal).toEqual({ __increment: 1 });
    });

    it("roda leitura e incremento dentro de uma transação", async () => {
        await service.assertQuota("w1", "generateCoaching", 3);

        expect(mockDb.transactions).toBe(1);
    });

    it("lança resource-exhausted quando o limite foi atingido", async () => {
        mockDb.docData = { generateCoaching: 3 };

        await expect(service.assertQuota("w1", "generateCoaching", 3)).rejects.toMatchObject({
            code: "resource-exhausted",
        });
        // Nada é gravado quando o limite estoura.
        expect(mockDb.setCalls).toHaveLength(0);
    });

    it("usa mensagem em português citando o limite e a renovação", async () => {
        mockDb.docData = { analyze503020Ideal: 3 };

        await expect(service.assertQuota("w1", "analyze503020Ideal", 3)).rejects.toThrow(
            /limite de 3 análises da regra 50-30-20 por dia/
        );
        await expect(service.assertQuota("w1", "analyze503020Ideal", 3)).rejects.toThrow(
            /horário de Brasília/
        );
    });

    it("conta cada função separadamente no mesmo documento do dia", async () => {
        // Coaching estourado, mas 50-30-20 ainda tem saldo.
        mockDb.docData = { generateCoaching: 3, analyze503020Ideal: 0 };

        await expect(service.assertQuota("w1", "generateCoaching", 3)).rejects.toBeInstanceOf(HttpsError);
        await expect(service.assertQuota("w1", "analyze503020Ideal", 3)).resolves.toBeUndefined();
        expect(mockDb.setCalls).toHaveLength(1);
    });

    it("permite exatamente o número de chamadas do limite", async () => {
        for (let used = 0; used < 5; used++) {
            mockDb.docData = { analysePlanning: used };
            await expect(service.assertQuota("w1", "analysePlanning", 5)).resolves.toBeUndefined();
        }
        mockDb.docData = { analysePlanning: 5 };
        await expect(service.assertQuota("w1", "analysePlanning", 5)).rejects.toBeInstanceOf(HttpsError);
    });

    it("trata valor não numérico gravado no campo como zero", async () => {
        mockDb.docData = { generateCoaching: null };

        await expect(service.assertQuota("w1", "generateCoaching", 3)).resolves.toBeUndefined();
    });

    it("bloqueia sem gravar quando o limite configurado é zero", async () => {
        await expect(service.assertQuota("w1", "generateCoaching", 0)).rejects.toMatchObject({
            code: "resource-exhausted",
        });
        expect(mockDb.setCalls).toHaveLength(0);
        expect(mockDb.transactions).toBe(0);
    });

    it("exige workspaceId", async () => {
        await expect(service.assertQuota("", "generateCoaching", 3)).rejects.toMatchObject({
            code: "invalid-argument",
        });
    });
});
