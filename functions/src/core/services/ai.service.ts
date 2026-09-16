import { GoogleGenerativeAI, ResponseSchema, SchemaType } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { AIConfig, DEFAULT_CONFIG } from "../config/ai.config";
import { InstallmentType, OrderModel, OrderStatus, OrderType } from "../../features/finance/domain/models/finance.models";
import * as ofx from "ofx-js";

const geminiApiKey = defineString("GEMINI_API_KEY");

// Cache em memória do config de IA (evita uma leitura no Firestore a cada chamada)
const CONFIG_CACHE_TTL_MS = 5 * 60 * 1000; // ~5 minutos
let configCache: { config: AIConfig; fetchedAt: number } | null = null;

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
     * Mesma interface de getGenerativeModel().generateContent, com retry +
     * backoff para erros transitórios e fallback de modelo. Sem isso, um 503
     * temporário do Gemini vira erro na cara do usuário.
     */
    private getResilientModel(
        params: Parameters<GoogleGenerativeAI["getGenerativeModel"]>[0]
    ): { generateContent: (request: any) => Promise<any> } {
        return {
            generateContent: async (request: any) => {
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
                            return await model.generateContent(request);
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
            },
        };
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
        const model = this.getResilientModel({ model: config.models.goals });

        const prompt = config.prompts.goals
            .replace("{{workspaceType}}", workspaceType)
            .replace("{{categories}}", categories.join(" | "))
            .replace("{{orders}}", JSON.stringify(orders));

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "planning_analysis",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({ model: config.models.automaticTransaction });

        const prompt = config.prompts.automaticTransaction
            .replace("{{description}}", description)
            .replace("{{packageName}}", packageName || "N/A")
            .replace("{{type}}", type)
            .replace("{{existingCategories}}", existingCategories.map(c => `${c.name} (${c.id})`).join(" | "))
            .replace("{{existingAccounts}}", existingAccounts.map(a => `${a.name} (${a.id})`).join(" | "));

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "automatic_transaction_enrichment",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({ model: config.models.document });

        let resultData: any;

        if (fileName.toLowerCase().endsWith(".ofx")) {
            const ofxString = fileBuffer.toString("utf-8");
            const parsedOfx = await ofx.parse(ofxString);
            
            const extractionResult = this.extractOfxData(parsedOfx);
            const transactions = extractionResult.transactions;
            const accountInfo = extractionResult.account;
            
            // Usar IA apenas para classificação das transações identificadas
            const prompt = config.prompts.documentOfx
                .replace("{{existingCategories}}", existingCategories.join(" | "))
                .replace("{{transactions}}", JSON.stringify(transactions));

            const aiResult = await model.generateContent(prompt);
            const response = await aiResult.response;
            const text = response.text();
            const jsonMatch = text.match(/\{[\s\S]*\}/);
            resultData = jsonMatch ? JSON.parse(jsonMatch[0]) : null;

            resultData = {
                account: accountInfo,
                orders: resultData.orders,
            };

            // Log no Firestore para OFX
            await admin.firestore().collection("ai_logs").add({
                workspaceId,
                prompt,
                response: text,
                type: "document_analysis_ofx",
                fileName,
                storagePath,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        }
        else {
            const isImage = mimeType.startsWith("image/");
            const prompt = config.prompts.document
                .replace("{{fileName}}", fileName)
                .replace("{{existingCategories}}", existingCategories.join(" | "));

            const result = await model.generateContent([
                prompt,
                {
                    inlineData: {
                        data: fileBuffer.toString("base64"),
                        mimeType: mimeType,
                    },
                },
            ]);
            const response = await result.response;
            const text = response.text();

            // Log no Firestore para PDF/Imagem
            await admin.firestore().collection("ai_logs").add({
                workspaceId,
                prompt,
                response: text,
                type: isImage ? "document_analysis_image" : "document_analysis_pdf",
                fileName,
                storagePath,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

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
        const model = this.getResilientModel({ model: config.models.document });

        let prompt = config.prompts.reconciliation
            .replace("{{fileName}}", fileName)
            .replace("{{existingCategories}}", existingCategories.join(", "));

        let aiResult;

        if (mimeType === "application/x-ofx" || fileName.toLowerCase().endsWith(".ofx")) {
            const ofxData = fileBuffer.toString("utf-8");
            const parsedOfx = await ofx.parse(ofxData);
            const ofxExtracted = this.extractOfxData(parsedOfx);
            
            prompt = config.prompts.documentOfx
                .replace("{{existingCategories}}", existingCategories.join(", "))
                .replace("{{transactions}}", JSON.stringify(ofxExtracted.transactions));
            
            aiResult = await model.generateContent(prompt);
        }
        else {
            aiResult = await model.generateContent([
                prompt,
                {
                    inlineData: {
                        data: fileBuffer.toString("base64"),
                        mimeType: mimeType,
                    },
                },
            ]);
        }

        const text = aiResult.response.text();
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
        const model = this.getResilientModel({
            model: config.models.coaching,
            generationConfig: {
                responseMimeType: "application/json",
                responseSchema: COACHING_RESPONSE_SCHEMA,
            },
        });

        const prompt = config.prompts.coaching
            .replace("{{workspaceType}}", workspaceType)
            .replace("{{financialData}}", JSON.stringify(financialData))
            .replace("{{forecastData}}", JSON.stringify(forecastData))
            .replace("{{goalsData}}", JSON.stringify(goalsData))
            .replace("{{previousContext}}", previousContext ? JSON.stringify(previousContext) : "Nenhuma interação anterior.");

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "coaching_analysis",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({ model: config.models.weeklyMissions });

        const prompt = config.prompts.weeklyMissions
            .replace("{{workspaceType}}", workspaceType)
            .replace("{{categories}}", categories.join(" | ") || "Nenhuma categoria")
            .replace("{{goals}}", goals.join(" | ") || "Nenhuma meta")
            .replace("{{maxCategory}}", maxCategory);

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "weekly_missions_generation",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({
            model: config.models.categoryGroups,
            generationConfig: {
                responseMimeType: "application/json",
                responseSchema: CATEGORY_GROUPS_RESPONSE_SCHEMA,
                temperature: 0,
            },
        });

        const prompt = config.prompts.categoryGroups
            .replace("{{categories}}", JSON.stringify(categories));

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "category_group_classification",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({
            model: config.models.planning503020,
            generationConfig: {
                responseMimeType: "application/json",
                responseSchema: PLANNING_503020_RESPONSE_SCHEMA,
            },
        });

        const prompt = config.prompts.planning503020
            .replace("{{context}}", JSON.stringify(context));

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "planning_503020_ideal_analysis",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
        const model = this.getResilientModel({
            model: config.models.goalFeasibility,
            generationConfig: {
                responseMimeType: "application/json",
                responseSchema: GOAL_FEASIBILITY_RESPONSE_SCHEMA,
            },
        });

        const prompt = config.prompts.goalFeasibility
            .replace("{{goalPayload}}", JSON.stringify(goalPayload))
            .replace("{{monthlyBreakdown}}", JSON.stringify(monthlyBreakdown));

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "goal_feasibility_analysis",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
