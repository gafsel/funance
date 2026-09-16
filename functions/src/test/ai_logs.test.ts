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

jest.mock("@google/generative-ai", () => ({
    SchemaType: {
        OBJECT: "object",
        ARRAY: "array",
        STRING: "string",
        NUMBER: "number",
        BOOLEAN: "boolean",
    },
    GoogleGenerativeAI: class {
        getGenerativeModel(params: any) {
            return {
                generateContent: async () => {
                    mockGemini.modelsTried.push(params.model);
                    if (mockGemini.error) {
                        throw mockGemini.error;
                    }
                    return {
                        response: {
                            text: () => mockGemini.text,
                            usageMetadata: mockGemini.usageMetadata,
                        },
                    };
                },
            };
        }
    },
}));

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
        expect(doc.model).toBe("gemini-flash-latest");
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

    it("falha ao gravar o log não derruba a chamada de IA", async () => {
        mockFs.addThrows = true;

        const result = await loadRepository().classifyCategoryGroups("w1", CATEGORIES);

        expect(result).toEqual({ c1: "groceries" });
        expect(mockFs.added).toHaveLength(0);
    });
});
