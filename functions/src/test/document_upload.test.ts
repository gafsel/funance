/**
 * F5.4 — documento grande sem base64 inline.
 *
 * Três caminhos: inline até 4 MB, Files API acima disso e recusa acima de
 * 10 MB. O SDK do Gemini é mockado; nenhuma chamada real é feita.
 */

const mockGemini = {
    text: "{}",
    /** `contents` recebido pelo generateContent (é onde a parte do arquivo vai). */
    lastContents: undefined as any,
    generateCalls: 0,
    uploadCalls: [] as any[],
    deleteCalls: [] as any[],
    getCalls: 0,
    /** estados devolvidos por files.get, em ordem */
    getStates: [] as string[],
    /** estado devolvido pelo upload */
    uploadState: "ACTIVE",
};

jest.mock("firebase-admin", () => {
    const makeCollection = (): any => ({
        doc: () => makeDoc(),
        add: async () => ({ id: "log-1" }),
    });
    const makeDoc = (): any => ({
        id: "gen-id",
        collection: () => makeCollection(),
        get: async () => ({ exists: false, data: () => undefined }),
    });
    const firestore: any = () => ({ collection: () => makeCollection() });
    firestore.FieldValue = { serverTimestamp: () => ({ __serverTimestamp: true }) };
    firestore.Timestamp = { fromDate: (d: Date) => ({ __millis: d.getTime() }) };
    return { firestore };
});

jest.mock("ofx-js", () => ({ parse: async () => ({}) }));

jest.mock("@google/genai", () => ({
    Type: {
        OBJECT: "OBJECT", ARRAY: "ARRAY", STRING: "STRING",
        NUMBER: "NUMBER", INTEGER: "INTEGER", BOOLEAN: "BOOLEAN",
    },
    GoogleGenAI: class {
        models = {
            generateContent: async (params: any) => {
                mockGemini.generateCalls++;
                mockGemini.lastContents = params.contents;
                return { text: mockGemini.text, usageMetadata: undefined };
            },
        };

        files = {
            upload: async (params: any) => {
                mockGemini.uploadCalls.push(params);
                return {
                    name: "files/abc123",
                    uri: "https://generativelanguage.googleapis.com/v1beta/files/abc123",
                    mimeType: params?.config?.mimeType,
                    state: mockGemini.uploadState,
                };
            },
            get: async (params: any) => {
                const state = mockGemini.getStates[mockGemini.getCalls] ?? "ACTIVE";
                mockGemini.getCalls++;
                return {
                    name: params.name,
                    uri: "https://generativelanguage.googleapis.com/v1beta/files/abc123",
                    mimeType: "application/pdf",
                    state,
                };
            },
            delete: async (params: any) => {
                mockGemini.deleteCalls.push(params);
            },
        };
    },
}));

// eslint-disable-next-line import/first
import { HttpsError } from "firebase-functions/v2/https";
// eslint-disable-next-line import/first
import {
    INLINE_DOCUMENT_MAX_BYTES,
    MAX_DOCUMENT_BYTES,
    assertDocumentWithinLimit,
    documentTooLargeMessage,
    formatMegabytes,
} from "../core/utils/document_limits";

function loadRepository(): any {
    let repository: any;
    jest.isolateModules(() => {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const mod = require("../core/services/ai.service");
        repository = new mod.GeminiAIRepositoryImpl();
    });
    return repository;
}

/** Parte de arquivo dentro do `contents` montado para o prompt. */
function filePart(): any {
    const contents = mockGemini.lastContents;
    return Array.isArray(contents) ? contents.find((c: any) => c?.inlineData || c?.fileData) : undefined;
}

const ANALYSIS_JSON = JSON.stringify({
    account: { name: "Nubank", runtimeType: "creditCard", color: "#820AD1", icon: "credit_card", currentBalance: 100 },
    orders: [],
});

beforeEach(() => {
    mockGemini.text = ANALYSIS_JSON;
    mockGemini.lastContents = undefined;
    mockGemini.generateCalls = 0;
    mockGemini.uploadCalls = [];
    mockGemini.deleteCalls = [];
    mockGemini.getCalls = 0;
    mockGemini.getStates = [];
    mockGemini.uploadState = "ACTIVE";
    jest.spyOn(console, "log").mockImplementation(() => undefined);
    jest.spyOn(console, "warn").mockImplementation(() => undefined);
});

describe("limites de tamanho", () => {
    it("formata megabytes em português", () => {
        expect(formatMegabytes(10 * 1024 * 1024)).toBe("10,0 MB");
        expect(formatMegabytes(12.5 * 1024 * 1024)).toBe("12,5 MB");
    });

    it("aceita o arquivo no limite e recusa acima dele", () => {
        expect(() => assertDocumentWithinLimit(MAX_DOCUMENT_BYTES)).not.toThrow();
        expect(() => assertDocumentWithinLimit(MAX_DOCUMENT_BYTES + 1)).toThrow(HttpsError);
    });

    it("recusa arquivo vazio", () => {
        expect(() => assertDocumentWithinLimit(0)).toThrow(/vazio/);
    });

    it("a mensagem diz o tamanho, o limite e a saída", () => {
        const message = documentTooLargeMessage(12.5 * 1024 * 1024);
        expect(message).toContain("12,5 MB");
        expect(message).toContain("10,0 MB");
        expect(message).toContain("OFX");
    });
});

describe("analyzeAccountDocument — escolha do transporte do arquivo", () => {
    it("manda inline (base64) um PDF de 1 MB", async () => {
        const buffer = Buffer.alloc(1024 * 1024, 1);

        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "fatura.pdf", []);

        expect(mockGemini.uploadCalls).toHaveLength(0);
        expect(filePart().inlineData).toBeDefined();
        expect(filePart().inlineData.mimeType).toBe("application/pdf");
        expect(filePart().fileData).toBeUndefined();
    });

    it("manda inline exatamente no limite de 4 MB", async () => {
        const buffer = Buffer.alloc(INLINE_DOCUMENT_MAX_BYTES, 1);

        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "fatura.pdf", []);

        expect(mockGemini.uploadCalls).toHaveLength(0);
        expect(filePart().inlineData).toBeDefined();
    });

    it("usa a Files API acima de 4 MB e referencia a URI, sem base64 no prompt", async () => {
        const buffer = Buffer.alloc(INLINE_DOCUMENT_MAX_BYTES + 1, 1);

        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "extrato.pdf", []);

        expect(mockGemini.uploadCalls).toHaveLength(1);
        expect(mockGemini.uploadCalls[0].config.mimeType).toBe("application/pdf");
        expect(mockGemini.uploadCalls[0].config.displayName).toBe("extrato.pdf");
        expect(filePart().inlineData).toBeUndefined();
        expect(filePart().fileData.fileUri).toContain("files/abc123");
        expect(filePart().fileData.mimeType).toBe("application/pdf");
    });

    it("apaga o arquivo remoto depois da análise", async () => {
        const buffer = Buffer.alloc(5 * 1024 * 1024, 1);

        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "extrato.pdf", []);

        expect(mockGemini.deleteCalls).toEqual([{ name: "files/abc123" }]);
    });

    it("apaga o arquivo remoto mesmo quando a análise falha", async () => {
        mockGemini.text = "isto não é json";
        const buffer = Buffer.alloc(5 * 1024 * 1024, 1);

        // parse ruim degrada para análise vazia — o cleanup precisa rodar igual.
        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "extrato.pdf", []);

        expect(mockGemini.deleteCalls).toEqual([{ name: "files/abc123" }]);
    });

    it("espera o upload sair de PROCESSING antes de usar a URI", async () => {
        mockGemini.uploadState = "PROCESSING";
        mockGemini.getStates = ["PROCESSING", "ACTIVE"];
        const buffer = Buffer.alloc(5 * 1024 * 1024, 1);

        await loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "extrato.pdf", []);

        expect(mockGemini.getCalls).toBe(2);
        expect(filePart().fileData).toBeDefined();
    }, 15000);

    it("recusa acima de 10 MB sem chamar o Gemini", async () => {
        const buffer = Buffer.alloc(MAX_DOCUMENT_BYTES + 1, 1);

        await expect(
            loadRepository().analyzeAccountDocument("w1", buffer, "application/pdf", "gigante.pdf", [])
        ).rejects.toThrow(/limite para análise/);

        expect(mockGemini.generateCalls).toBe(0);
        expect(mockGemini.uploadCalls).toHaveLength(0);
    });
});

describe("analyzeReconciliationDocument — mesmo transporte", () => {
    beforeEach(() => {
        mockGemini.text = JSON.stringify({
            transactions: [{ description: "Uber", amount: 20, date: "2026-01-02", type: "expense" }],
        });
    });

    it("manda inline um arquivo pequeno", async () => {
        const buffer = Buffer.alloc(512 * 1024, 1);

        const result = await loadRepository()
            .analyzeReconciliationDocument("w1", buffer, "image/png", "print.png", []);

        expect(mockGemini.uploadCalls).toHaveLength(0);
        expect(filePart().inlineData).toBeDefined();
        expect(result.transactions).toHaveLength(1);
    });

    it("usa a Files API acima de 4 MB e limpa depois", async () => {
        const buffer = Buffer.alloc(6 * 1024 * 1024, 1);

        await loadRepository().analyzeReconciliationDocument("w1", buffer, "application/pdf", "extrato.pdf", []);

        expect(mockGemini.uploadCalls).toHaveLength(1);
        expect(filePart().fileData).toBeDefined();
        expect(mockGemini.deleteCalls).toEqual([{ name: "files/abc123" }]);
    });

    it("recusa acima de 10 MB sem chamar o Gemini", async () => {
        const buffer = Buffer.alloc(MAX_DOCUMENT_BYTES + 1, 1);

        await expect(
            loadRepository().analyzeReconciliationDocument("w1", buffer, "application/pdf", "gigante.pdf", [])
        ).rejects.toThrow(/limite para análise/);

        expect(mockGemini.generateCalls).toBe(0);
    });
});
