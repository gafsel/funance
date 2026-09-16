/**
 * Cobre o formato do log de IA (F5.3): metadados em
 * workspaces/{id}/ai_logs, sem prompt/resposta, com hash e expiresAt.
 */

const mockFs = {
    /** conteúdo do documento config/ai (undefined = não existe) */
    configDoc: undefined as any,
    added: [] as { path: string; data: any }[],
    addThrows: false,
};

const mockGemini = {
    text: "{}",
    usageMetadata: undefined as any,
    error: undefined as any,
    /** modelos que devem falhar; os demais respondem normalmente */
    failingModels: [] as string[],
    modelsTried: [] as string[],
};

jest.mock("firebase-admin", () => {
    const makeCollection = (path: string[]): any => ({
        doc: (id: string) => makeDoc([...path, id]),
        add: async (data: any) => {
            if (mockFs.addThrows) {
                throw new Error("firestore indisponível");
            }
            mockFs.added.push({ path: path.join("/"), data });
            return { id: "log-1" };
        },
    });
    const makeDoc = (path: string[]): any => ({
        collection: (name: string) => makeCollection([...path, name]),
        get: async () => {
            if (path.join("/") === "config/ai") {
                return {
                    exists: mockFs.configDoc !== undefined,
                    data: () => mockFs.configDoc,
                };
            }
            return { exists: false, data: () => undefined };
        },
    });

    const firestore: any = () => ({ collection: (name: string) => makeCollection([name]) });
    firestore.FieldValue = { serverTimestamp: () => ({ __serverTimestamp: true }) };
    firestore.Timestamp = { fromDate: (d: Date) => ({ __millis: d.getTime() }) };
    return { firestore };
});

// ofx-js é ESM e não passa pelo transform do ts-jest; nenhum teste aqui usa OFX.
jest.mock("ofx-js", () => ({ parse: async () => ({}) }));

jest.mock("@google/genai", () => ({
    Type: {
        OBJECT: "OBJECT",
        ARRAY: "ARRAY",
        STRING: "STRING",
        NUMBER: "NUMBER",
        INTEGER: "INTEGER",
        BOOLEAN: "BOOLEAN",
    },
    // SDK novo: `ai.models.generateContent({model, contents, config})` e
    // `response.text` como GETTER (antes era `response.text()`).
    GoogleGenAI: class {
        models = {
            generateContent: async (params: any) => {
                mockGemini.modelsTried.push(params.model);
                if (mockGemini.failingModels.includes(params.model)) {
                    throw Object.assign(new Error(`${params.model} indisponível`), { status: 503 });
                }
                if (mockGemini.error) {
                    throw mockGemini.error;
                }
                return {
                    text: mockGemini.text,
                    usageMetadata: mockGemini.usageMetadata,
                };
            },
        };
    },
}));

// eslint-disable-next-line import/first
import { HttpsError } from "firebase-functions/v2/https";

const DAY_MS = 24 * 60 * 60 * 1000;

/** Recarrega o módulo para zerar o cache de config (TTL de 5 min em memória). */
function loadRepository(): any {
    let repository: any;
    jest.isolateModules(() => {
        // require é necessário: o módulo precisa ser reavaliado a cada teste.
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const mod = require("../core/services/ai.service");
        repository = new mod.GeminiAIRepositoryImpl();
    });
    return repository;
}

const CATEGORIES = [{ id: "c1", name: "Mercado", type: "expense" }];

describe("logAiCall", () => {
    beforeEach(() => {
        mockFs.configDoc = undefined;
        mockFs.added = [];
        mockFs.addThrows = false;
        mockGemini.text = JSON.stringify({ assignments: [{ id: "c1", group: "groceries" }] });
        mockGemini.usageMetadata = undefined;
        mockGemini.error = undefined;
        mockGemini.failingModels = [];
        mockGemini.modelsTried = [];
    });

    it("grava em workspaces/{workspaceId}/ai_logs, não na coleção raiz", async () => {
        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        expect(mockFs.added).toHaveLength(1);
        expect(mockFs.added[0].path).toBe("workspaces/w1/ai_logs");
    });

    it("não grava prompt nem resposta por padrão", async () => {
        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        const doc = mockFs.added[0].data;
        expect(doc.prompt).toBeUndefined();
        expect(doc.response).toBeUndefined();
        expect(doc.debugPrompt).toBeUndefined();
        expect(doc.debugResponse).toBeUndefined();
        // Nenhum campo pode conter o conteúdo do prompt.
        expect(JSON.stringify(doc)).not.toContain("Mercado");
    });

    it("grava os metadados esperados, incluindo hash SHA-256 do prompt", async () => {
        mockGemini.usageMetadata = { promptTokenCount: 120, candidatesTokenCount: 40, totalTokenCount: 160 };

        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        const doc = mockFs.added[0].data;
        expect(doc.functionName).toBe("category_group_classification");
        expect(doc.model).toBe("gemini-2.5-flash");
        expect(doc.status).toBe("ok");
        expect(doc.latencyMs).toBeGreaterThanOrEqual(0);
        expect(doc.promptSha256).toMatch(/^[0-9a-f]{64}$/);
        expect(doc.inputTokens).toBe(120);
        expect(doc.outputTokens).toBe(40);
        expect(doc.totalTokens).toBe(160);
        expect(doc.createdAt).toEqual({ __serverTimestamp: true });
    });

    it("define expiresAt em ~90 dias quando debugLogging está desligado", async () => {
        const before = Date.now();
        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        const expires = mockFs.added[0].data.expiresAt.__millis;
        expect(expires - before).toBeGreaterThanOrEqual(90 * DAY_MS - 5000);
        expect(expires - before).toBeLessThanOrEqual(90 * DAY_MS + 5000);
    });

    it("com debugLogging=true grava prompt/resposta e reduz o TTL para ~7 dias", async () => {
        mockFs.configDoc = { debugLogging: true };
        const before = Date.now();

        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        const doc = mockFs.added[0].data;
        expect(doc.debugPrompt).toContain("Mercado");
        expect(doc.debugResponse).toBe(mockGemini.text);
        const expires = doc.expiresAt.__millis;
        expect(expires - before).toBeGreaterThanOrEqual(7 * DAY_MS - 5000);
        expect(expires - before).toBeLessThanOrEqual(7 * DAY_MS + 5000);
    });

    it("registra status erro e errorCode quando o Gemini falha, e repropaga", async () => {
        // 400 não é retryable: falha na primeira tentativa, sem backoff.
        mockGemini.error = Object.assign(new Error("bad request"), { status: 400 });

        await expect(loadRepository().classifyCategoryGroups("w1", CATEGORIES)).rejects.toThrow("bad request");

        expect(mockFs.added).toHaveLength(1);
        expect(mockFs.added[0].data.status).toBe("erro");
        expect(mockFs.added[0].data.errorCode).toBe("400");
        expect(mockFs.added[0].data.promptSha256).toMatch(/^[0-9a-f]{64}$/);
    });

    it("loga o modelo que de fato respondeu quando há fallback", async () => {
        // O primário (gemini-2.5-flash, pinado) responde 503 nas 2 tentativas;
        // o fallback (gemini-2.5-flash-lite) responde.
        mockGemini.failingModels = ["gemini-2.5-flash"];

        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        expect(mockGemini.modelsTried).toEqual([
            "gemini-2.5-flash",
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite",
        ]);
        expect(mockFs.added).toHaveLength(1);
        expect(mockFs.added[0].data.model).toBe("gemini-2.5-flash-lite");
        expect(mockFs.added[0].data.status).toBe("ok");
    });

    it("no erro final, loga o modelo primário e o código do último erro", async () => {
        mockGemini.failingModels = ["gemini-2.5-flash", "gemini-2.5-flash-lite"];

        await expect(loadRepository().classifyCategoryGroups("w1", CATEGORIES)).rejects.toThrow(/indispon/);

        expect(mockFs.added).toHaveLength(1);
        expect(mockFs.added[0].data.model).toBe("gemini-2.5-flash");
        expect(mockFs.added[0].data.status).toBe("erro");
        expect(mockFs.added[0].data.errorCode).toBe("503");
    });

    it("falha ao gravar o log não derruba a chamada de IA", async () => {
        mockFs.addThrows = true;

        const result = await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        expect(result).toEqual({ c1: "groceries" });
        expect(mockFs.added).toHaveLength(0);
    });
});

describe("pinning e sanitização de modelo", () => {
    beforeEach(() => {
        mockFs.configDoc = undefined;
        mockFs.added = [];
        mockFs.addThrows = false;
        mockGemini.text = JSON.stringify({ assignments: [] });
        mockGemini.usageMetadata = undefined;
        mockGemini.error = undefined;
        mockGemini.failingModels = [];
        mockGemini.modelsTried = [];
    });

    /**
     * `sanitizeModel` é privado; o que importa é qual modelo foi de fato
     * chamado, e isso o ai_log registra. `modelsTried[0]` é o primário, antes
     * de qualquer fallback.
     */
    async function modelFor(models?: any): Promise<string> {
        // `modelsTried` acumula entre chamadas; cada asserção quer o primário
        // da SUA chamada. loadRepository() já zera o cache de config em memória.
        mockGemini.modelsTried = [];
        mockFs.configDoc = models === undefined ? undefined : { models };
        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);
        return mockGemini.modelsTried[0];
    }

    it("sem override em config/ai, usa o flash PINADO", async () => {
        expect(await modelFor()).toBe("gemini-2.5-flash");
    });

    it("alias rolante -latest é remapeado para a versão pinada", async () => {
        expect(await modelFor({ categoryGroups: "gemini-flash-latest" })).toBe("gemini-2.5-flash");
        expect(await modelFor({ categoryGroups: "gemini-pro-latest" })).toBe("gemini-2.5-pro");
    });

    it("família aposentada gemini-1.5-* é remapeada para a versão pinada", async () => {
        expect(await modelFor({ categoryGroups: "gemini-1.5-flash" })).toBe("gemini-2.5-flash");
        expect(await modelFor({ categoryGroups: "gemini-1.5-pro-002" })).toBe("gemini-2.5-pro");
    });

    it("override para um modelo pinado válido é honrado", async () => {
        expect(await modelFor({ categoryGroups: "gemini-2.5-pro" })).toBe("gemini-2.5-pro");
        expect(await modelFor({ categoryGroups: "gemini-3.0-flash" })).toBe("gemini-3.0-flash");
    });

    it("override inválido cai no padrão do código em vez de ir para a API", async () => {
        for (const lixo of ["", "   ", "modelo inválido!", "../../etc/passwd", "a".repeat(100), 42, null, {}]) {
            expect(await modelFor({ categoryGroups: lixo })).toBe("gemini-2.5-flash");
        }
    });

    it("config/ai sem a chave models não quebra a sanitização", async () => {
        mockFs.configDoc = { debugLogging: false };
        await loadRepository().classifyCategoryGroups("w1", CATEGORIES);
        expect(mockGemini.modelsTried[0]).toBe("gemini-2.5-flash");
    });

    it("análise de documento usa o PRO pinado por padrão", async () => {
        mockGemini.text = JSON.stringify({ orders: [] });

        await loadRepository().analyzeAccountDocument(
            "w1", Buffer.from("%PDF-1.4"), "application/pdf", "fatura.pdf", []
        );

        expect(mockGemini.modelsTried[0]).toBe("gemini-2.5-pro");
        expect(mockFs.added[0].data.model).toBe("gemini-2.5-pro");
    });

    it("os fallbacks também são versões pinadas, nunca alias", async () => {
        mockGemini.failingModels = ["gemini-2.5-pro"];
        mockGemini.text = JSON.stringify({ orders: [] });

        await loadRepository().analyzeAccountDocument(
            "w1", Buffer.from("%PDF-1.4"), "application/pdf", "fatura.pdf", []
        );

        expect(mockGemini.modelsTried).toEqual([
            "gemini-2.5-pro",
            "gemini-2.5-pro",
            "gemini-2.5-flash",
        ]);
        expect(mockGemini.modelsTried.every((m) => !m.endsWith("-latest"))).toBe(true);
    });
});

describe("isTransientAiError", () => {
    function classify(error: any): boolean {
        let result = false;
        jest.isolateModules(() => {
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            const mod = require("../core/services/ai.service");
            result = mod.isTransientAiError(error);
        });
        return result;
    }

    it("considera transitório 5xx, 429 e 408 do Gemini", () => {
        for (const status of [408, 429, 500, 502, 503, 504]) {
            expect(classify(Object.assign(new Error("x"), { status }))).toBe(true);
        }
    });

    it("NÃO considera transitório 400/403/404 (payload ou permissão)", () => {
        for (const status of [400, 403, 404]) {
            expect(classify(Object.assign(new Error("x"), { status }))).toBe(false);
        }
    });

    it("considera transitório erro de rede/timeout", () => {
        expect(classify(Object.assign(new Error("x"), { code: "ECONNRESET" }))).toBe(true);
        expect(classify(new Error("request timed out"))).toBe(true);
        expect(classify(new Error("fetch failed"))).toBe(true);
    });

    it("NÃO considera transitório HttpsError nem erro de parse", () => {
        expect(classify(new HttpsError("internal", "resposta inválida"))).toBe(false);
        expect(classify(new Error("A resposta da IA não contém JSON válido."))).toBe(false);
        expect(classify(undefined)).toBe(false);
    });
});
