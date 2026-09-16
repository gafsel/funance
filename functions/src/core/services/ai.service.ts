import { GoogleGenerativeAI, ResponseSchema, SchemaType } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";
import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { AIConfig, DEFAULT_CONFIG } from "../config/ai.config";
import { InstallmentType, OrderModel, OrderStatus, OrderType } from "../../features/finance/domain/models/finance.models";
import * as ofx from "ofx-js";
import * as crypto from "crypto";
import { renderTemplate } from "../utils/prompt_template";

const geminiApiKey = defineString("GEMINI_API_KEY");

// Cache em memória do config de IA (evita uma leitura no Firestore a cada chamada)
const CONFIG_CACHE_TTL_MS = 5 * 60 * 1000; // ~5 minutos
let configCache: { config: AIConfig; fetchedAt: number } | null = null;

// Retenção dos logs de IA (campo expiresAt, consumido pela política de TTL do
// Firestore — ver functions/README.md). O modo debug guarda prompt e resposta
// crus, que são dados financeiros do usuário, então expira muito antes.
const AI_LOG_RETENTION_DAYS = 90;
const AI_LOG_DEBUG_RETENTION_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;

interface AiLogEntry {
    workspaceId: string;
    /** Identifica a chamada (ex.: "coaching_analysis"). */
    functionName: string;
    /** Modelo que efetivamente respondeu (pode ser um fallback). */
    model: string;
    latencyMs: number;
    prompt: string;
    status: "ok" | "erro";
    responseText?: string;
    usage?: any;
    errorCode?: string;
    /** Campos extras gravados SOMENTE em modo debug (ex.: fileName). */
    debugExtra?: Record<string, any>;
}

// Schema estruturado da resposta de coaching (força JSON válido no Gemini)
const COACHING_RESPONSE_SCHEMA: ResponseSchema = {
    type: SchemaType.OBJECT,
    properties: {
        message: { type: SchemaType.STRING },
        summary: { type: SchemaType.STRING },
        type: { type: SchemaType.STRING, format: "enum", enum: ["insight", "warning", "tip"] },
        slides: {
            type: SchemaType.ARRAY,
            items: {
                type: SchemaType.OBJECT,
                properties: {
                    title: { type: SchemaType.STRING },
                    message: { type: SchemaType.STRING },
                    icon: { type: SchemaType.STRING },
                    icons: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
                    color: { type: SchemaType.STRING },
                    secondaryColor: { type: SchemaType.STRING },
                    animationType: {
                        type: SchemaType.STRING,
                        format: "enum",
                        enum: ["zoom", "slide", "bounce", "fade", "pulse"],
                    },
                    actionLabel: { type: SchemaType.STRING, nullable: true },
                    actionPath: { type: SchemaType.STRING, nullable: true },
                },
                required: ["title", "message", "icon", "color"],
            },
        },
    },
    required: ["message", "summary", "type", "slides"],
};

// Schema estruturado da classificação de categorias em grupos macro
const CATEGORY_GROUPS_RESPONSE_SCHEMA: ResponseSchema = {
    type: SchemaType.OBJECT,
    properties: {
        assignments: {
            type: SchemaType.ARRAY,
            items: {
                type: SchemaType.OBJECT,
                properties: {
                    id: { type: SchemaType.STRING },
                    group: {
                        type: SchemaType.STRING,
                        format: "enum",
                        enum: [
                            "housing", "groceries", "dining_out", "transport", "health_pharmacy",
                            "education", "leisure", "subscriptions_services", "pets",
                            "clothing_shopping", "personal_care", "debt_financial",
                            "savings_investments", "income", "other",
                        ],
                    },
                },
                required: ["id", "group"],
            },
        },
    },
    required: ["assignments"],
};

// Schema estruturado da resposta de viabilidade de meta
const GOAL_FEASIBILITY_RESPONSE_SCHEMA: ResponseSchema = {
    type: SchemaType.OBJECT,
    properties: {
        status: { type: SchemaType.STRING, format: "enum", enum: ["feasible", "challenging", "unrealistic"] },
        reason: { type: SchemaType.STRING },
        suggestion: { type: SchemaType.STRING },
    },
    required: ["status", "reason", "suggestion"],
};

// Schema estruturado da análise ideal 50-30-20 (força JSON válido no Gemini)
const PLANNING_503020_RESPONSE_SCHEMA: ResponseSchema = {
    type: SchemaType.OBJECT,
    properties: {
        summary: { type: SchemaType.STRING },
        groups: {
            type: SchemaType.ARRAY,
            items: {
                type: SchemaType.OBJECT,
                properties: {
                    allocation: {
                        type: SchemaType.STRING,
                        format: "enum",
                        enum: ["essential", "comfort", "investment"],
                    },
                    currentPct: { type: SchemaType.NUMBER },
                    targetPct: { type: SchemaType.NUMBER },
                    deltaBRL: { type: SchemaType.NUMBER },
                },
                required: ["allocation", "currentPct", "targetPct", "deltaBRL"],
            },
        },
        categories: {
            type: SchemaType.ARRAY,
            items: {
                type: SchemaType.OBJECT,
                properties: {
                    categoryId: { type: SchemaType.STRING },
                    idealMonthlyAmount: { type: SchemaType.NUMBER },
                    idealPctOfIncome: { type: SchemaType.NUMBER },
                    status: { type: SchemaType.STRING, format: "enum", enum: ["ok", "above", "below"] },
                    suggestedAllocation: {
                        type: SchemaType.STRING,
                        format: "enum",
                        enum: ["essential", "comfort", "investment"],
                    },
                    shouldReclassify: { type: SchemaType.BOOLEAN },
                    reason: { type: SchemaType.STRING },
                    savingTip: { type: SchemaType.STRING, nullable: true },
                },
                required: [
                    "categoryId", "idealMonthlyAmount", "idealPctOfIncome", "status",
                    "suggestedAllocation", "shouldReclassify", "reason",
                ],
            },
        },
        insights: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
    },
    required: ["summary", "groups", "categories", "insights"],
};

/**
 * Faz o parse do texto retornado pela IA. Com responseMimeType "application/json"
 * o texto já é JSON puro; mantemos o fallback por regex para robustez.
 */
function parseAIJson(text: string): any {
    try {
        return JSON.parse(text);
    }
    catch {
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        throw new Error("A resposta da IA não contém JSON válido.");
    }
}

// Falhas de INFRAESTRUTURA do Gemini: indisponibilidade, throttling e rede.
// Não incluem 4xx de payload (400/403/404), que são erro nosso ou do dado.
const TRANSIENT_AI_STATUS = [408, 429, 500, 502, 503, 504];
const TRANSIENT_AI_CODES = ["ECONNRESET", "ETIMEDOUT", "ECONNREFUSED", "EAI_AGAIN", "ENOTFOUND", "EPIPE"];
const TRANSIENT_AI_MESSAGE = /timeout|timed out|socket hang up|network error|fetch failed/i;

/**
 * Indica se o erro veio de indisponibilidade do Gemini (e não de uma resposta
 * inválida ou de um payload ruim). Usado para decidir se a cota do usuário
 * deve ser estornada: ele não pode pagar por um 503 nosso.
 */
export function isTransientAiError(error: any): boolean {
    if (!error) return false;
    // Erros de negócio/validação já viraram HttpsError — nunca são infra.
    if (error instanceof HttpsError) return false;

    const status = Number(error?.status);
    if (Number.isFinite(status) && TRANSIENT_AI_STATUS.includes(status)) return true;

    if (typeof error?.code === "string" && TRANSIENT_AI_CODES.includes(error.code)) return true;

    return TRANSIENT_AI_MESSAGE.test(String(error?.message || ""));
}

export interface IAIRepository {
    analyzePlanningAndSuggestGoals(
        workspaceId: string,
        workspaceType: string, 
        categories: string[], 
        orders: OrderModel[],
    ): Promise<any>;
    analyzeAccountDocument(
        workspaceId: string,
        fileBuffer: Buffer, 
        mimeType: string, 
        fileName: string, 
        existingCategories: string[],
        storagePath?: string,
    ): Promise<any>;

    analyzeReconciliationDocument(
        workspaceId: string,
        fileBuffer: Buffer,
        mimeType: string,
        fileName: string,
        existingCategories: string[],
    ): Promise<any>;
    generateCoachingSlides(
        workspaceId: string,
        workspaceType: string,
        financialData: any,
        forecastData: any,
        goalsData: any,
        previousContext?: any[]
    ): Promise<any>;
    enrichAutomaticTransaction(
        workspaceId: string,
        description: string,
        packageName: string | undefined,
        type: string,
        existingCategories: any[],
        existingAccounts: any[]
    ): Promise<any>;
    generateWeeklyMissions(
        workspaceId: string,
        workspaceType: string,
        categories: string[],
        goals: string[],
        maxCategory: string,
    ): Promise<any>;
    analyzeGoalFeasibility(
        workspaceId: string,
        goalPayload: object,
        monthlyBreakdown: object[]
    ): Promise<any>;
    classifyCategoryGroups(
        workspaceId: string,
        categories: { id: string; name: string; type: string }[]
    ): Promise<Record<string, string>>;
    analyze503020Ideal(
        workspaceId: string,
        context: object
    ): Promise<any>;
}

export class GeminiAIRepositoryImpl implements IAIRepository {
    private genAI: GoogleGenerativeAI;

    // Modelos estáveis usados quando o primário falha por indisponibilidade
    // (503 "high demand" no alias -latest, 404 de modelo aposentado etc.).
    private static readonly FALLBACK_MODELS = ["gemini-2.5-flash", "gemini-2.5-flash-lite"];
    private static readonly RETRYABLE_STATUS = [429, 500, 503];

    constructor() {
        this.genAI = new GoogleGenerativeAI(geminiApiKey.value());
    }

    /**
     * generateContent com retry + backoff para erros transitórios e fallback
     * de modelo. Sem isso, um 503 temporário do Gemini vira erro na cara do
     * usuário. Devolve também qual modelo respondeu de fato, para o log de
     * metadados registrar quando houve fallback.
     */
    private async generateResilient(
        params: Parameters<GoogleGenerativeAI["getGenerativeModel"]>[0],
        request: any
    ): Promise<{ result: any; modelUsed: string }> {
        const candidates = [
            params.model,
            ...GeminiAIRepositoryImpl.FALLBACK_MODELS.filter((m) => m !== params.model),
        ];
        let lastError: any;
        for (let c = 0; c < candidates.length; c++) {
            const modelName = candidates[c];
            // 2 tentativas no modelo primário; 1 nos fallbacks para
            // não estourar o timeout da function.
            const attempts = c === 0 ? 2 : 1;
            for (let attempt = 0; attempt < attempts; attempt++) {
                try {
                    const model = this.genAI.getGenerativeModel({
                        ...params,
                        model: modelName,
                    });
                    const result = await model.generateContent(request);
                    return { result, modelUsed: modelName };
                }
                catch (error: any) {
                    lastError = error;
                    const status = error?.status;
                    // Modelo inexistente/aposentado: pula direto para o próximo.
                    if (status === 404) break;
                    if (!GeminiAIRepositoryImpl.RETRYABLE_STATUS.includes(status)) {
                        throw error;
                    }
                    await new Promise((r) => setTimeout(r, 500 * (attempt + 1)));
                }
            }
            if (c < candidates.length - 1) {
                console.warn(
                    `Modelo ${modelName} indisponível (${lastError?.status}); tentando ${candidates[c + 1]}...`
                );
            }
        }
        throw lastError;
    }

    /**
     * Chama o Gemini e grava UM log de metadados, tanto no sucesso quanto no
     * erro. Retorna o texto cru da resposta.
     */
    private async generateWithLogging(
        workspaceId: string,
        functionName: string,
        params: Parameters<GoogleGenerativeAI["getGenerativeModel"]>[0],
        request: any,
        prompt: string,
        debugExtra?: Record<string, any>
    ): Promise<string> {
        const startedAt = Date.now();
        try {
            const { result, modelUsed } = await this.generateResilient(params, request);
            const response = await result.response;
            const text = response.text();

            await this.logAiCall({
                workspaceId,
                functionName,
                model: modelUsed,
                latencyMs: Date.now() - startedAt,
                prompt,
                status: "ok",
                responseText: text,
                usage: response?.usageMetadata,
                debugExtra,
            });

            return text;
        }
        catch (error: any) {
            await this.logAiCall({
                workspaceId,
                functionName,
                model: params.model || "desconhecido",
                latencyMs: Date.now() - startedAt,
                prompt,
                status: "erro",
                errorCode: String(error?.status ?? error?.code ?? error?.name ?? "unknown"),
                debugExtra,
            });
            throw error;
        }
    }

    /**
     * Log de uma chamada de IA em `workspaces/{workspaceId}/ai_logs/{id}`.
     *
     * Apenas METADADOS: o prompt e a resposta contêm dados financeiros do
     * usuário (descrições de transações, saldos, metas) e não têm por que ficar
     * guardados para sempre numa coleção raiz. O prompt entra só como hash
     * SHA-256, que ainda permite agrupar chamadas idênticas e detectar
     * repetição sem guardar o conteúdo.
     *
     * Com `config/ai.debugLogging === true`, prompt e resposta crus são
     * gravados e o documento expira em 7 dias em vez de 90.
     *
     * `expiresAt` é o campo lido pela política de TTL do Firestore (o comando
     * para ativá-la está em functions/README.md). Enquanto a política não
     * estiver ativa, o campo é inofensivo: nada é apagado.
     */
    private async logAiCall(entry: AiLogEntry): Promise<void> {
        try {
            const config = await this.getConfig();
            const debug = config.debugLogging === true;
            const retentionDays = debug ? AI_LOG_DEBUG_RETENTION_DAYS : AI_LOG_RETENTION_DAYS;

            const doc: Record<string, any> = {
                functionName: entry.functionName,
                model: entry.model,
                latencyMs: entry.latencyMs,
                promptSha256: crypto.createHash("sha256").update(entry.prompt).digest("hex"),
                promptLength: entry.prompt.length,
                status: entry.status,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: admin.firestore.Timestamp.fromDate(
                    new Date(Date.now() + retentionDays * DAY_MS)
                ),
            };

            // usageMetadata nem sempre vem preenchido (depende do modelo).
            if (entry.usage) {
                doc.inputTokens = entry.usage.promptTokenCount ?? null;
                doc.outputTokens = entry.usage.candidatesTokenCount ?? null;
                doc.totalTokens = entry.usage.totalTokenCount ?? null;
            }

            if (entry.errorCode) {
                doc.errorCode = entry.errorCode;
            }

            if (debug) {
                doc.debugPrompt = entry.prompt;
                doc.debugResponse = entry.responseText ?? null;
                if (entry.debugExtra) {
                    doc.debugExtra = entry.debugExtra;
                }
            }

            await admin.firestore()
                .collection("workspaces").doc(entry.workspaceId)
                .collection("ai_logs").add(doc);
        }
        catch (error) {
            // O log é acessório: nunca pode derrubar a chamada de IA.
            console.error("Falha ao gravar ai_log:", error);
        }
    }

    private async getConfig(): Promise<AIConfig> {
        if (configCache && (Date.now() - configCache.fetchedAt) < CONFIG_CACHE_TTL_MS) {
            return configCache.config;
        }

        try {
            const doc = await admin.firestore().collection("config").doc("ai").get();
            if (doc.exists) {
                const data = doc.data() as any;
                // A família gemini-1.5-* foi aposentada (404). Se o override
                // do Firestore ainda apontar para ela, remapeia para o alias
                // rolante equivalente em vez de quebrar todas as features de IA.
                const sanitizeModel = (name: string | undefined, fallback: string): string => {
                    const model = name || fallback;
                    if (!model.startsWith("gemini-1.5")) return model;
                    return model.includes("pro") ? "gemini-pro-latest" : "gemini-flash-latest";
                };

                const config: AIConfig = {
                    debugLogging: data?.debugLogging === true,
                    models: {
                        goals: sanitizeModel(data?.models?.goals, DEFAULT_CONFIG.models.goals),
                        document: sanitizeModel(data?.models?.document, DEFAULT_CONFIG.models.document),
                        coaching: sanitizeModel(data?.models?.coaching, DEFAULT_CONFIG.models.coaching),
                        automaticTransaction: sanitizeModel(data?.models?.automaticTransaction, DEFAULT_CONFIG.models.automaticTransaction),
                        weeklyMissions: sanitizeModel(data?.models?.weeklyMissions, DEFAULT_CONFIG.models.weeklyMissions),
                        goalFeasibility: sanitizeModel(data?.models?.goalFeasibility, DEFAULT_CONFIG.models.goalFeasibility),
                        categoryGroups: sanitizeModel(data?.models?.categoryGroups, DEFAULT_CONFIG.models.categoryGroups),
                        planning503020: sanitizeModel(data?.models?.planning503020, DEFAULT_CONFIG.models.planning503020),
                    },
                    prompts: {
                        goals: data?.prompts?.goals || DEFAULT_CONFIG.prompts.goals,
                        document: data?.prompts?.document || DEFAULT_CONFIG.prompts.document,
                        documentOfx: data?.prompts?.documentOfx || DEFAULT_CONFIG.prompts.documentOfx,
                        reconciliation: data?.prompts?.reconciliation || DEFAULT_CONFIG.prompts.reconciliation,
                        coaching: data?.prompts?.coaching || DEFAULT_CONFIG.prompts.coaching,
                        automaticTransaction: data?.prompts?.automaticTransaction || DEFAULT_CONFIG.prompts.automaticTransaction,
                        weeklyMissions: data?.prompts?.weeklyMissions || DEFAULT_CONFIG.prompts.weeklyMissions,
                        goalFeasibility: data?.prompts?.goalFeasibility || DEFAULT_CONFIG.prompts.goalFeasibility,
                        categoryGroups: data?.prompts?.categoryGroups || DEFAULT_CONFIG.prompts.categoryGroups,
                        planning503020: data?.prompts?.planning503020 || DEFAULT_CONFIG.prompts.planning503020,
                    },
                };
                configCache = { config, fetchedAt: Date.now() };
                return config;
            }
        }
        catch (error) {
            console.error("Erro ao buscar config de IA no Firestore, usando padrão:", error);
        }
        configCache = { config: DEFAULT_CONFIG, fetchedAt: Date.now() };
        return DEFAULT_CONFIG;
    }

    async analyzePlanningAndSuggestGoals(
        workspaceId: string,
        workspaceType: string, 
        categories: string[], 
        orders: OrderModel[],
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.goals, {
            workspaceType,
            categories: categories.join(" | "),
            orders: JSON.stringify(orders),
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "planning_analysis",
            { model: config.models.goals },
            prompt,
            prompt,
        );

        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }

        return { goals: [], plannings: [] };
    }

    async enrichAutomaticTransaction(
        workspaceId: string,
        description: string,
        packageName: string | undefined,
        type: string,
        existingCategories: any[],
        existingAccounts: any[]
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.automaticTransaction, {
            description,
            packageName: packageName || "N/A",
            type,
            existingCategories: existingCategories.map(c => `${c.name} (${c.id})`).join(" | "),
            existingAccounts: existingAccounts.map(a => `${a.name} (${a.id})`).join(" | "),
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "automatic_transaction_enrichment",
            { model: config.models.automaticTransaction },
            prompt,
            prompt,
        );

        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }

        return null;
    }

    async analyzeAccountDocument(
        workspaceId: string,
        fileBuffer: Buffer, 
        mimeType: string, 
        fileName: string, 
        existingCategories: string[],
        storagePath?: string,
    ): Promise<any> {
        const config = await this.getConfig();

        let resultData: any;

        if (fileName.toLowerCase().endsWith(".ofx")) {
            const ofxString = fileBuffer.toString("utf-8");
            const parsedOfx = await ofx.parse(ofxString);
            
            const extractionResult = this.extractOfxData(parsedOfx);
            const transactions = extractionResult.transactions;
            const accountInfo = extractionResult.account;
            
            // Usar IA apenas para classificação das transações identificadas
            const prompt = renderTemplate(config.prompts.documentOfx, {
                existingCategories: existingCategories.join(" | "),
                transactions: JSON.stringify(transactions),
            });

            const text = await this.generateWithLogging(
                workspaceId,
                "document_analysis_ofx",
                { model: config.models.document },
                prompt,
                prompt,
                { fileName, storagePath },
            );

            const jsonMatch = text.match(/\{[\s\S]*\}/);
            resultData = jsonMatch ? JSON.parse(jsonMatch[0]) : null;

            resultData = {
                account: accountInfo,
                orders: resultData.orders,
            };
        }
        else {
            const isImage = mimeType.startsWith("image/");
            const prompt = renderTemplate(config.prompts.document, {
                fileName,
                existingCategories: existingCategories.join(" | "),
            });

            const text = await this.generateWithLogging(
                workspaceId,
                isImage ? "document_analysis_image" : "document_analysis_pdf",
                { model: config.models.document },
                [
                    prompt,
                    {
                        inlineData: {
                            data: fileBuffer.toString("base64"),
                            mimeType: mimeType,
                        },
                    },
                ],
                prompt,
                { fileName, storagePath },
            );

            const jsonMatch = text.match(/\{[\s\S]*\}/);
            resultData = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
        }

        if (resultData && resultData.error) {
            throw new Error(resultData.error);
        }

        if (resultData) {
            return {
                account: {
                    id: "temp-id",
                    name: resultData.account?.name || fileName.split(".")[0],
                    runtimeType: resultData.account?.runtimeType || "checking",
                    color: resultData.account?.color || "#4A8C9C",
                    icon: resultData.account?.icon || "account_balance",
                    initialBalance: resultData.account?.currentBalance || 0.0,
                    initialBalanceDate: new Date().toISOString().split("T")[0],
                    metadata: {},
                    limit: resultData.account?.limit,
                    dueDay: resultData.account?.dueDay,
                    closingDay: resultData.account?.closingDay,
                    interestRate: resultData.account?.interestRate,
                },
                orders: (resultData.orders || []).map((o: any) => ({
                    ...o,
                    id: admin.firestore().collection("temp").doc().id,
                    status: OrderStatus.active,
                    installmentType: o.installmentType || InstallmentType.single,
                    startMonth: o.dueDate ? o.dueDate.substring(0, 7) : new Date().toISOString().substring(0, 7),
                    dueDay: o.dueDate ? parseInt(o.dueDate.substring(8, 10)) : new Date().getDate(),
                })),
            };
        }

        return {
            account: {
                id: "temp-id",
                name: fileName.split(".")[0],
                runtimeType: "checking",
                color: "#4A8C9C",
                icon: "account_balance",
                initialBalance: 0.0,
                initialBalanceDate: new Date().toISOString().split("T")[0],
                metadata: {},
            },
            orders: [],
        };
    }

    async analyzeReconciliationDocument(
        workspaceId: string,
        fileBuffer: Buffer,
        mimeType: string,
        fileName: string,
        existingCategories: string[],
    ): Promise<any> {
        const config = await this.getConfig();

        let prompt = renderTemplate(config.prompts.reconciliation, {
            fileName,
            existingCategories: existingCategories.join(", "),
        });

        let text: string;

        if (mimeType === "application/x-ofx" || fileName.toLowerCase().endsWith(".ofx")) {
            const ofxData = fileBuffer.toString("utf-8");
            const parsedOfx = await ofx.parse(ofxData);
            const ofxExtracted = this.extractOfxData(parsedOfx);

            prompt = renderTemplate(config.prompts.documentOfx, {
                existingCategories: existingCategories.join(", "),
                transactions: JSON.stringify(ofxExtracted.transactions),
            });

            text = await this.generateWithLogging(
                workspaceId,
                "reconciliation_analysis_ofx",
                { model: config.models.document },
                prompt,
                prompt,
                { fileName },
            );
        }
        else {
            text = await this.generateWithLogging(
                workspaceId,
                "reconciliation_analysis",
                { model: config.models.document },
                [
                    prompt,
                    {
                        inlineData: {
                            data: fileBuffer.toString("base64"),
                            mimeType: mimeType,
                        },
                    },
                ],
                prompt,
                { fileName },
            );
        }

        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
            throw new Error("Não foi possível extrair JSON da resposta da IA");
        }

        const data = JSON.parse(jsonMatch[0]);

        if (data.error) {
            return data;
        }

        // Tentar encontrar transações em diferentes campos possíveis do JSON
        const transactionsRaw = data.transactions || data.orders || data.items || [];
        const transactions = Array.isArray(transactionsRaw) ? transactionsRaw : [];

        return {
            transactions: transactions.map((t: any) => ({
                description: t.description || t.memo || t.text || "Sem descrição",
                amount: t.amount !== undefined ? t.amount : (t.value !== undefined ? t.value : (t.total !== undefined ? t.total : 0)),
                date: t.date || t.dueDate || t.timestamp || new Date().toISOString(),
                type: t.type || (t.amount < 0 ? "expense" : "income"),
                category: t.category,
            })),
        };
    }

    async generateCoachingSlides(
        workspaceId: string,
        workspaceType: string,
        financialData: any,
        forecastData: any,
        goalsData: any,
        previousContext?: any[]
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.coaching, {
            workspaceType,
            financialData: JSON.stringify(financialData),
            forecastData: JSON.stringify(forecastData),
            goalsData: JSON.stringify(goalsData),
            previousContext: previousContext ? JSON.stringify(previousContext) : "Nenhuma interação anterior.",
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "coaching_analysis",
            {
                model: config.models.coaching,
                generationConfig: {
                    responseMimeType: "application/json",
                    responseSchema: COACHING_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        try {
            return parseAIJson(text);
        }
        catch (error) {
            console.error("Falha ao parsear resposta de coaching:", error);
            throw new Error("Não foi possível gerar os slides de coaching.");
        }
    }

    async generateWeeklyMissions(
        workspaceId: string,
        workspaceType: string,
        categories: string[],
        goals: string[],
        maxCategory: string,
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.weeklyMissions, {
            workspaceType,
            categories: categories.join(" | ") || "Nenhuma categoria",
            goals: goals.join(" | ") || "Nenhuma meta",
            maxCategory,
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "weekly_missions_generation",
            { model: config.models.weeklyMissions },
            prompt,
            prompt,
        );

        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }

        throw new Error("Não foi possível gerar as missões semanais via IA.");
    }

    async classifyCategoryGroups(
        workspaceId: string,
        categories: { id: string; name: string; type: string }[]
    ): Promise<Record<string, string>> {
        if (categories.length === 0) return {};

        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.categoryGroups, {
            categories: JSON.stringify(categories),
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "category_group_classification",
            {
                model: config.models.categoryGroups,
                generationConfig: {
                    responseMimeType: "application/json",
                    responseSchema: CATEGORY_GROUPS_RESPONSE_SCHEMA,
                    temperature: 0,
                },
            },
            prompt,
            prompt,
        );

        const parsed = parseAIJson(text);
        const assignments: Record<string, string> = {};
        for (const item of parsed?.assignments || []) {
            if (item && typeof item.id === "string" && typeof item.group === "string") {
                assignments[item.id] = item.group;
            }
        }
        return assignments;
    }

    async analyze503020Ideal(
        workspaceId: string,
        context: object
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.planning503020, {
            context: JSON.stringify(context),
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "planning_503020_ideal_analysis",
            {
                model: config.models.planning503020,
                generationConfig: {
                    responseMimeType: "application/json",
                    responseSchema: PLANNING_503020_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        try {
            return parseAIJson(text);
        }
        catch (error) {
            console.error("Falha ao parsear resposta da análise 50-30-20:", error);
            throw new Error("Não foi possível gerar a análise ideal 50-30-20.");
        }
    }

    async analyzeGoalFeasibility(
        workspaceId: string,
        goalPayload: object,
        monthlyBreakdown: object[]
    ): Promise<any> {
        const config = await this.getConfig();

        const prompt = renderTemplate(config.prompts.goalFeasibility, {
            goalPayload: JSON.stringify(goalPayload),
            monthlyBreakdown: JSON.stringify(monthlyBreakdown),
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "goal_feasibility_analysis",
            {
                model: config.models.goalFeasibility,
                generationConfig: {
                    responseMimeType: "application/json",
                    responseSchema: GOAL_FEASIBILITY_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        try {
            return parseAIJson(text);
        }
        catch (error) {
            console.error("Falha ao parsear resposta de viabilidade de meta:", error);
            throw new Error("Não foi possível analisar a viabilidade da meta.");
        }
    }

    private extractOfxData(parsedOfx: any): { account: any, transactions: any[] } {
        const transactions: any[] = [];
        const account: any = {};
        try {
            const ofxData = parsedOfx.OFX;
            
            // Tentar extrair de BANKMSGSRSV1 (Conta Corrente) ou CREDITCARDMSGSRSV1 (Cartão de Crédito)
            let stmtTrnRs;
            let isCreditCard = false;

            if (ofxData.BANKMSGSRSV1) {
                stmtTrnRs = ofxData.BANKMSGSRSV1.STMTTRNRS;
            }
            else if (ofxData.CREDITCARDMSGSRSV1) {
                stmtTrnRs = ofxData.CREDITCARDMSGSRSV1.CCSTMTTRNRS;
                isCreditCard = true;
            }

            if (!stmtTrnRs) return { account, transactions };

            const stmtRs = Array.isArray(stmtTrnRs) ? stmtTrnRs[0][isCreditCard ? "CCSTMTRS" : "STMTRS"] : stmtTrnRs[isCreditCard ? "CCSTMTRS" : "STMTRS"];
            
            // Extrair informações da conta
            const bankAcctFrom = stmtRs.BANKACCTFROM || stmtRs.CCACCTFROM;
            if (bankAcctFrom) {
                const acctId = bankAcctFrom.ACCTID || "";
                const org = ofxData.SIGNONMSGSRSV1?.SONRS?.FI?.ORG || "";
                
                account.name = `${org} ${acctId}`.trim();
                account.runtimeType = isCreditCard ? "creditCard" : (bankAcctFrom.ACCTTYPE === "CHECKING" ? "checking" : "investment");
            }

            if (stmtRs.LEDGERBAL) {
                account.currentBalance = parseFloat(stmtRs.LEDGERBAL.BALAMT);
            }

            const bankTranList = stmtRs.BANKTRANLIST;
            if (bankTranList) {
                const stmtTrn = Array.isArray(bankTranList.STMTTRN) ? bankTranList.STMTTRN : [bankTranList.STMTTRN];

                for (const trn of stmtTrn) {
                    const dateStr = trn.DTPOSTED; // YYYYMMDDHHMMSS
                    const year = dateStr.substring(0, 4);
                    const month = dateStr.substring(4, 6);
                    const day = dateStr.substring(6, 8);
                    
                    transactions.push({
                        description: trn.MEMO || trn.NAME || "Transação OFX",
                        amount: Math.abs(parseFloat(trn.TRNAMT)),
                        dueDate: `${year}-${month}-${day}`,
                        type: parseFloat(trn.TRNAMT) < 0 ? OrderType.expense : OrderType.income,
                    });
                }
            }
        }
        catch (e) {
            console.error("Erro ao extrair dados OFX:", e);

            throw new Error("Falha ao extrair dados OFX");
        }
        return { account, transactions };
    }
}
