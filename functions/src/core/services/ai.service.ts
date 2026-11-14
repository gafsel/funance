import { GenerateContentConfig, GenerateContentResponse, GoogleGenAI, Schema, Type } from "@google/genai";
import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { AIConfig, DEFAULT_CONFIG, PINNED_FLASH_MODEL, PINNED_PRO_MODEL } from "../config/ai.config";
import { GEMINI_API_KEY } from "../config/secrets";
import { InstallmentType, OrderModel, OrderStatus, OrderType } from "../../features/finance/domain/models/finance.models";
import * as ofx from "ofx-js";
import * as crypto from "crypto";
import { renderTemplate } from "../utils/prompt_template";
import {
    INLINE_DOCUMENT_MAX_BYTES,
    assertDocumentWithinLimit,
} from "../utils/document_limits";
import {
    ValidatedDocumentAnalysis,
    validateAutomaticTransaction,
    validateDocumentAnalysis,
    validateGoalSuggestions,
    validateOfxClassification,
    validateReconciliation,
    validateWeeklyMissionNames,
    ValidatedWeeklyMissions,
    WeeklyMissionExpectation,
} from "./ai_validation";

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
const COACHING_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        message: { type: Type.STRING },
        summary: { type: Type.STRING },
        type: { type: Type.STRING, format: "enum", enum: ["insight", "warning", "tip"] },
        slides: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    title: { type: Type.STRING },
                    message: { type: Type.STRING },
                    icon: { type: Type.STRING },
                    icons: { type: Type.ARRAY, items: { type: Type.STRING } },
                    color: { type: Type.STRING },
                    secondaryColor: { type: Type.STRING },
                    animationType: {
                        type: Type.STRING,
                        format: "enum",
                        enum: ["zoom", "slide", "bounce", "fade", "pulse"],
                    },
                    actionLabel: { type: Type.STRING, nullable: true },
                    actionPath: { type: Type.STRING, nullable: true },
                },
                required: ["title", "message", "icon", "color"],
            },
        },
    },
    required: ["message", "summary", "type", "slides"],
};

// Schema estruturado da classificação de categorias em grupos macro
const CATEGORY_GROUPS_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        assignments: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    id: { type: Type.STRING },
                    group: {
                        type: Type.STRING,
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
const GOAL_FEASIBILITY_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        status: { type: Type.STRING, format: "enum", enum: ["feasible", "challenging", "unrealistic"] },
        reason: { type: Type.STRING },
        suggestion: { type: Type.STRING },
    },
    required: ["status", "reason", "suggestion"],
};

// Schema estruturado da análise ideal 50-30-20 (força JSON válido no Gemini)
const PLANNING_503020_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        summary: { type: Type.STRING },
        groups: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    allocation: {
                        type: Type.STRING,
                        format: "enum",
                        enum: ["essential", "comfort", "investment"],
                    },
                    currentPct: { type: Type.NUMBER },
                    targetPct: { type: Type.NUMBER },
                    deltaBRL: { type: Type.NUMBER },
                },
                required: ["allocation", "currentPct", "targetPct", "deltaBRL"],
            },
        },
        categories: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    categoryId: { type: Type.STRING },
                    idealMonthlyAmount: { type: Type.NUMBER },
                    idealPctOfIncome: { type: Type.NUMBER },
                    status: { type: Type.STRING, format: "enum", enum: ["ok", "above", "below"] },
                    suggestedAllocation: {
                        type: Type.STRING,
                        format: "enum",
                        enum: ["essential", "comfort", "investment"],
                    },
                    shouldReclassify: { type: Type.BOOLEAN },
                    reason: { type: Type.STRING },
                    savingTip: { type: Type.STRING, nullable: true },
                },
                required: [
                    "categoryId", "idealMonthlyAmount", "idealPctOfIncome", "status",
                    "suggestedAllocation", "shouldReclassify", "reason",
                ],
            },
        },
        insights: { type: Type.ARRAY, items: { type: Type.STRING } },
    },
    required: ["summary", "groups", "categories", "insights"],
};

// Categoria sugerida pela IA. Sem "id": os prompts de documento/OFX/conciliação
// mandam só os NOMES das categorias existentes, então qualquer id que o modelo
// devolvesse seria invenção (ver ai_validation.ts).
const CATEGORY_SUGGESTION_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        name: { type: Type.STRING },
        icon: { type: Type.STRING },
        color: { type: Type.STRING },
        type: { type: Type.STRING, format: "enum", enum: ["income", "expense"] },
    },
    required: ["name", "icon", "color", "type"],
};

// Lançamento extraído de documento (extrato/fatura/OFX).
const DOCUMENT_ORDER_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        type: { type: Type.STRING, format: "enum", enum: ["expense", "income"] },
        description: { type: Type.STRING },
        amount: { type: Type.NUMBER },
        dueDate: { type: Type.STRING, description: "Data no formato YYYY-MM-DD" },
        installmentType: {
            type: Type.STRING,
            format: "enum",
            enum: ["single", "installment", "recurring"],
        },
        installmentCount: { type: Type.INTEGER },
        category: CATEGORY_SUGGESTION_SCHEMA,
    },
    required: ["type", "description", "amount", "dueDate", "category"],
};

// Schema da sugestão de metas e planejamentos do onboarding
const GOAL_SUGGESTIONS_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        goals: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    name: { type: Type.STRING },
                    targetAmount: { type: Type.NUMBER },
                    type: {
                        type: Type.STRING,
                        format: "enum",
                        enum: ["save_money", "reduce_expense", "reduce_credit_card"],
                    },
                    deadlineMonths: { type: Type.INTEGER },
                    icon: { type: Type.STRING },
                },
                required: ["name", "targetAmount", "type", "deadlineMonths", "icon"],
            },
        },
        plannings: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    category: CATEGORY_SUGGESTION_SCHEMA,
                    amount: { type: Type.NUMBER },
                },
                required: ["category", "amount"],
            },
        },
    },
    required: ["goals", "plannings"],
};

// Schema da análise de documento (PDF/imagem). "error" NÃO é obrigatório: é a
// saída de recusa quando o arquivo não é um documento financeiro, e o prompt
// depende de poder devolver só ela.
const DOCUMENT_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        error: { type: Type.STRING, nullable: true },
        account: {
            type: Type.OBJECT,
            nullable: true,
            properties: {
                name: { type: Type.STRING },
                runtimeType: {
                    type: Type.STRING,
                    format: "enum",
                    enum: ["checking", "investment", "creditCard", "debt"],
                },
                color: { type: Type.STRING },
                icon: { type: Type.STRING },
                currentBalance: { type: Type.NUMBER },
                interestRate: { type: Type.NUMBER, nullable: true },
                limit: { type: Type.NUMBER, nullable: true },
                dueDay: { type: Type.INTEGER, nullable: true },
                closingDay: { type: Type.INTEGER, nullable: true },
            },
            required: ["name", "runtimeType", "color", "icon", "currentBalance"],
        },
        orders: { type: Type.ARRAY, items: DOCUMENT_ORDER_SCHEMA },
    },
};

// Schema da classificação das transações de um arquivo OFX
const DOCUMENT_OFX_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        orders: { type: Type.ARRAY, items: DOCUMENT_ORDER_SCHEMA },
    },
    required: ["orders"],
};

// Schema da extração de transações para conciliação bancária
const RECONCILIATION_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        error: { type: Type.STRING, nullable: true },
        transactions: {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    description: { type: Type.STRING },
                    amount: { type: Type.NUMBER },
                    date: { type: Type.STRING, description: "Data no formato YYYY-MM-DD" },
                    type: { type: Type.STRING, format: "enum", enum: ["expense", "income"] },
                    category: CATEGORY_SUGGESTION_SCHEMA,
                },
                required: ["description", "amount", "date", "type", "category"],
            },
        },
    },
};

// Schema do enriquecimento de transação automática. Aqui a categoria PODE ter
// id: o prompt envia as categorias e contas do workspace com id.
const AUTOMATIC_TRANSACTION_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        category: {
            type: Type.OBJECT,
            properties: {
                id: { type: Type.STRING, nullable: true },
                name: { type: Type.STRING },
                icon: { type: Type.STRING },
                color: { type: Type.STRING },
                type: { type: Type.STRING, format: "enum", enum: ["income", "expense"] },
            },
            required: ["name", "icon", "color", "type"],
        },
        accountId: { type: Type.STRING, nullable: true },
    },
    required: ["category"],
};

// Schema das três missões semanais.
//
// `templateKey` é obrigatório desde wp/missions-by-type: a IA não escolhe mais
// o objetivo da missão, ela reescreve o texto de um template que o prompt
// mandou, e ecoar a chave é como o validador confere a qual objetivo aquele
// texto se refere. Uma resposta sem a chave (ou com a chave errada) é
// descartada e o texto do catálogo prevalece.
const WEEKLY_MISSION_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        templateKey: { type: Type.STRING },
        name: { type: Type.STRING },
        target: { type: Type.INTEGER },
    },
    required: ["templateKey", "name", "target"],
};

const WEEKLY_MISSIONS_RESPONSE_SCHEMA: Schema = {
    type: Type.OBJECT,
    properties: {
        consistency: WEEKLY_MISSION_SCHEMA,
        discipline: WEEKLY_MISSION_SCHEMA,
        organization: WEEKLY_MISSION_SCHEMA,
    },
    required: ["consistency", "discipline", "organization"],
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

/**
 * Igual a `parseAIJson`, mas devolve null em vez de lançar. Usado onde uma
 * resposta ilegível deve degradar (lista vazia, sugestão ausente) em vez de
 * virar erro na cara do usuário.
 */
/** Conjunto dos ids que o prompt de fato enviou (para barrar id inventado). */
function toIdSet(items: any[]): Set<string> {
    const ids = new Set<string>();
    for (const item of Array.isArray(items) ? items : []) {
        if (typeof item?.id === "string" && item.id.length > 0) ids.add(item.id);
    }
    return ids;
}

function parseAIJsonSafe(text: string): any | null {
    try {
        return parseAIJson(text);
    }
    catch (error) {
        console.error("Resposta da IA sem JSON válido:", error);
        return null;
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
    /**
     * TEMPERA o texto das missões da semana — não as escolhe.
     *
     * `expectations` traz os templates que o catálogo já selecionou (chave,
     * texto base, alvo e os termos obrigatórios). A resposta passa por
     * `validateWeeklyMissionNames`, e a missão cujo texto não referenciar o
     * template (ou mexer no alvo, ou usar vocabulário da outra audiência) volta
     * `null`, para o serviço usar o texto do catálogo.
     */
    generateWeeklyMissions(
        workspaceId: string,
        workspaceType: string,
        categories: string[],
        goals: string[],
        expectations: WeeklyMissionExpectation[],
    ): Promise<ValidatedWeeklyMissions>;
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

/**
 * Par (modelo, config) de uma chamada ao Gemini no SDK `@google/genai`.
 * Substitui o `getGenerativeModel({model, generationConfig})` do SDK legado:
 * modelo e configuração agora viajam no mesmo objeto de `generateContent`.
 */
interface GenerateParams {
    model: string;
    config?: GenerateContentConfig;
}

export class GeminiAIRepositoryImpl implements IAIRepository {
    private _genAI?: GoogleGenAI;

    // Modelos estáveis usados quando o primário falha por indisponibilidade
    // (503 "high demand", 404 de modelo aposentado etc.).
    private static readonly FALLBACK_MODELS = ["gemini-2.5-flash", "gemini-2.5-flash-lite"];
    private static readonly RETRYABLE_STATUS = [429, 500, 503];

    // Espera do upload na Files API (arquivo grande fica PROCESSING antes de
    // poder ser referenciado num prompt).
    private static readonly FILE_PROCESSING_TIMEOUT_MS = 60_000;
    private static readonly FILE_POLL_INTERVAL_MS = 1_000;

    /**
     * Cliente criado na PRIMEIRA chamada, e não no construtor: o valor de um
     * segredo só existe em execução, e `.value()` lança se for lido enquanto o
     * CLI carrega o módulo para descobrir as funções no deploy.
     */
    private get genAI(): GoogleGenAI {
        if (!this._genAI) {
            this._genAI = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
        }
        return this._genAI;
    }

    /**
     * generateContent com retry + backoff para erros transitórios e fallback
     * de modelo. Sem isso, um 503 temporário do Gemini vira erro na cara do
     * usuário. Devolve também qual modelo respondeu de fato, para o log de
     * metadados registrar quando houve fallback.
     */
    private async generateResilient(
        params: GenerateParams,
        contents: any
    ): Promise<{ result: GenerateContentResponse; modelUsed: string }> {
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
                    const result = await this.genAI.models.generateContent({
                        model: modelName,
                        contents,
                        config: params.config,
                    });
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
     * Monta a parte do prompt que carrega o documento (PDF/imagem).
     *
     * Até 4 MB vai **inline** em base64: um round-trip a menos e nada para
     * limpar depois. Acima disso o base64 inflaria o payload em ~33% e
     * estouraria o limite de request do Gemini, então o arquivo sobe pela
     * **Files API** e o prompt referencia só a URI (`fileData`).
     *
     * Devolve também um `cleanup`: o arquivo remoto é apagado assim que a
     * resposta chega. O Gemini já expira o upload em 48h sozinho, mas deixar
     * extrato do usuário parado lá é dado financeiro sem motivo.
     */
    private async buildDocumentPart(
        fileBuffer: Buffer,
        mimeType: string,
        fileName: string
    ): Promise<{ part: any; cleanup: () => Promise<void> }> {
        // Segunda linha de defesa: o handler já recusou pelo metadado do
        // Storage, mas o serviço não pode confiar em quem o chama.
        assertDocumentWithinLimit(fileBuffer.length);

        const noop = async () => undefined;

        if (fileBuffer.length <= INLINE_DOCUMENT_MAX_BYTES) {
            return {
                part: { inlineData: { data: fileBuffer.toString("base64"), mimeType } },
                cleanup: noop,
            };
        }

        console.log(
            `Documento ${fileName} com ${fileBuffer.length} bytes: enviando pela Files API do Gemini.`
        );

        const uploaded = await this.genAI.files.upload({
            file: new Blob([new Uint8Array(fileBuffer)], { type: mimeType }),
            config: { mimeType, displayName: fileName },
        });

        const ready = await this.waitForFileActive(uploaded);

        return {
            part: { fileData: { fileUri: ready.uri, mimeType: ready.mimeType || mimeType } },
            cleanup: async () => {
                if (!ready.name) return;
                try {
                    await this.genAI.files.delete({ name: ready.name });
                }
                catch (error) {
                    // Expira sozinho em 48h; não vale derrubar a análise.
                    console.warn(`Falha ao apagar o arquivo ${ready.name} da Files API:`, error);
                }
            },
        };
    }

    /**
     * Espera o upload sair de PROCESSING. Um PDF grande não fica utilizável
     * no mesmo instante do upload; usar a URI antes disso devolve 400.
     */
    private async waitForFileActive(file: any): Promise<any> {
        const deadline = Date.now() + GeminiAIRepositoryImpl.FILE_PROCESSING_TIMEOUT_MS;
        let current = file;

        while (current?.state === "PROCESSING" && Date.now() < deadline) {
            await new Promise((resolve) => setTimeout(resolve, GeminiAIRepositoryImpl.FILE_POLL_INTERVAL_MS));
            current = await this.genAI.files.get({ name: current.name });
        }

        if (current?.state === "FAILED") {
            throw new Error(`O Gemini não conseguiu processar o arquivo enviado: ${current?.error?.message ?? "motivo desconhecido"}.`);
        }
        if (current?.state === "PROCESSING") {
            throw new Error("O processamento do arquivo pelo Gemini demorou demais. Tente novamente.");
        }
        return current;
    }

    /**
     * Chama o Gemini e grava UM log de metadados, tanto no sucesso quanto no
     * erro. Retorna o texto cru da resposta.
     */
    private async generateWithLogging(
        workspaceId: string,
        functionName: string,
        params: GenerateParams,
        contents: any,
        prompt: string,
        debugExtra?: Record<string, any>
    ): Promise<string> {
        const startedAt = Date.now();
        try {
            const { result, modelUsed } = await this.generateResilient(params, contents);
            // No SDK novo `text` é um getter (antes era `response.text()`).
            const text = result.text ?? "";

            await this.logAiCall({
                workspaceId,
                functionName,
                model: modelUsed,
                latencyMs: Date.now() - startedAt,
                prompt,
                status: "ok",
                responseText: text,
                usage: result.usageMetadata,
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

    /**
     * Normaliza o nome de modelo vindo do override em `config/ai`.
     *
     * Três casos, todos terminando numa versão PINADA (F5.6):
     * - nome vazio/inválido (não é string, ou tem caractere fora de
     *   [A-Za-z0-9._-]): cai no padrão do código;
     * - família `gemini-1.5-*`: aposentada pelo Google, responde 404 — o
     *   override antigo quebraria todas as features de IA;
     * - alias rolante (`*-latest`): muda de modelo sem deploy, que é
     *   exatamente o que o pinning existe para evitar.
     *
     * Um override para um modelo pinado válido (ex.: `gemini-2.5-pro`)
     * continua valendo — é assim que se troca de modelo sem deploy.
     */
    private sanitizeModel(name: unknown, fallback: string): string {
        if (typeof name !== "string" || !/^[A-Za-z0-9._-]{1,64}$/.test(name)) {
            return fallback;
        }
        const isPro = name.includes("pro");
        if (name.startsWith("gemini-1.5")) {
            return isPro ? PINNED_PRO_MODEL : PINNED_FLASH_MODEL;
        }
        if (name.endsWith("-latest")) {
            return isPro ? PINNED_PRO_MODEL : PINNED_FLASH_MODEL;
        }
        return name;
    }

    private async getConfig(): Promise<AIConfig> {
        if (configCache && (Date.now() - configCache.fetchedAt) < CONFIG_CACHE_TTL_MS) {
            return configCache.config;
        }

        try {
            const doc = await admin.firestore().collection("config").doc("ai").get();
            if (doc.exists) {
                const data = doc.data() as any;

                const config: AIConfig = {
                    debugLogging: data?.debugLogging === true,
                    models: {
                        goals: this.sanitizeModel(data?.models?.goals, DEFAULT_CONFIG.models.goals),
                        document: this.sanitizeModel(data?.models?.document, DEFAULT_CONFIG.models.document),
                        coaching: this.sanitizeModel(data?.models?.coaching, DEFAULT_CONFIG.models.coaching),
                        automaticTransaction: this.sanitizeModel(data?.models?.automaticTransaction, DEFAULT_CONFIG.models.automaticTransaction),
                        weeklyMissions: this.sanitizeModel(data?.models?.weeklyMissions, DEFAULT_CONFIG.models.weeklyMissions),
                        goalFeasibility: this.sanitizeModel(data?.models?.goalFeasibility, DEFAULT_CONFIG.models.goalFeasibility),
                        categoryGroups: this.sanitizeModel(data?.models?.categoryGroups, DEFAULT_CONFIG.models.categoryGroups),
                        planning503020: this.sanitizeModel(data?.models?.planning503020, DEFAULT_CONFIG.models.planning503020),
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
            {
                model: config.models.goals,
                config: {
                    responseMimeType: "application/json",
                    responseSchema: GOAL_SUGGESTIONS_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        // Resposta ilegível vira {goals: [], plannings: []} — o onboarding
        // segue sem sugestão em vez de quebrar.
        return validateGoalSuggestions(parseAIJsonSafe(text));
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
            {
                model: config.models.automaticTransaction,
                config: {
                    responseMimeType: "application/json",
                    responseSchema: AUTOMATIC_TRANSACTION_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        // Único prompt que recebe IDS no contexto: o resultado é gravado em
        // categoryId/accountId da transação, então um id inventado apontaria
        // para nada. O validador só aceita id que veio no prompt.
        return validateAutomaticTransaction(
            parseAIJsonSafe(text),
            toIdSet(existingCategories),
            toIdSet(existingAccounts),
        );
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

        let analysis: ValidatedDocumentAnalysis;
        // Conta lida do próprio OFX (não da IA): nome, tipo e saldo vêm do
        // arquivo, que é estruturado e confiável.
        let ofxAccount: any = null;

        if (fileName.toLowerCase().endsWith(".ofx")) {
            const ofxString = fileBuffer.toString("utf-8");
            const parsedOfx = await ofx.parse(ofxString);

            const extractionResult = this.extractOfxData(parsedOfx);
            const transactions = extractionResult.transactions;
            ofxAccount = extractionResult.account;

            // Usar IA apenas para classificação das transações identificadas
            const prompt = renderTemplate(config.prompts.documentOfx, {
                existingCategories: existingCategories.join(" | "),
                transactions: JSON.stringify(transactions),
            });

            const text = await this.generateWithLogging(
                workspaceId,
                "document_analysis_ofx",
                {
                    model: config.models.document,
                    config: {
                        responseMimeType: "application/json",
                        responseSchema: DOCUMENT_OFX_RESPONSE_SCHEMA,
                    },
                },
                prompt,
                prompt,
                { fileName, storagePath },
            );

            analysis = {
                error: null,
                account: null,
                orders: validateOfxClassification(parseAIJsonSafe(text)).orders,
            };
        }
        else {
            const isImage = mimeType.startsWith("image/");
            const prompt = renderTemplate(config.prompts.document, {
                fileName,
                existingCategories: existingCategories.join(" | "),
            });

            const document = await this.buildDocumentPart(fileBuffer, mimeType, fileName);
            let text: string;
            try {
                text = await this.generateWithLogging(
                    workspaceId,
                    isImage ? "document_analysis_image" : "document_analysis_pdf",
                    {
                        model: config.models.document,
                        config: {
                            responseMimeType: "application/json",
                            responseSchema: DOCUMENT_RESPONSE_SCHEMA,
                        },
                    },
                    [prompt, document.part],
                    prompt,
                    { fileName, storagePath },
                );
            }
            finally {
                await document.cleanup();
            }

            analysis = validateDocumentAnalysis(parseAIJsonSafe(text));
        }

        // Recusa explícita do modelo ("não é um extrato/fatura válido").
        if (analysis.error) {
            throw new Error(analysis.error);
        }

        const account = ofxAccount ?? analysis.account ?? {};

        return {
            account: {
                id: "temp-id",
                name: account.name || fileName.split(".")[0],
                runtimeType: account.runtimeType || "checking",
                color: account.color || "#4A8C9C",
                icon: account.icon || "account_balance",
                initialBalance: account.currentBalance || 0.0,
                initialBalanceDate: new Date().toISOString().split("T")[0],
                metadata: {},
                limit: account.limit,
                dueDay: account.dueDay,
                closingDay: account.closingDay,
                interestRate: account.interestRate,
            },
            // Toda order aqui já passou pelo validador: dueDate é YYYY-MM-DD
            // válido e amount é positivo e finito.
            orders: analysis.orders.map((o) => ({
                ...o,
                id: admin.firestore().collection("temp").doc().id,
                status: OrderStatus.active,
                installmentType: o.installmentType || InstallmentType.single,
                startMonth: o.dueDate.substring(0, 7),
                dueDay: parseInt(o.dueDate.substring(8, 10)),
            })),
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
                {
                    model: config.models.document,
                    config: {
                        responseMimeType: "application/json",
                        responseSchema: DOCUMENT_OFX_RESPONSE_SCHEMA,
                    },
                },
                prompt,
                prompt,
                { fileName },
            );
        }
        else {
            const document = await this.buildDocumentPart(fileBuffer, mimeType, fileName);
            try {
                text = await this.generateWithLogging(
                    workspaceId,
                    "reconciliation_analysis",
                    {
                        model: config.models.document,
                        config: {
                            responseMimeType: "application/json",
                            responseSchema: RECONCILIATION_RESPONSE_SCHEMA,
                        },
                    },
                    [prompt, document.part],
                    prompt,
                    { fileName },
                );
            }
            finally {
                await document.cleanup();
            }
        }

        const parsed = parseAIJsonSafe(text);
        if (parsed === null) {
            throw new Error("Não foi possível extrair JSON da resposta da IA");
        }

        // No fluxo de OFX o prompt é o de classificação (chaves `orders`); o
        // validador de conciliação já aceita esse alias.
        const validated = validateReconciliation(parsed);
        if (validated.error) {
            return { error: validated.error };
        }

        return { transactions: validated.transactions };
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
                config: {
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
        expectations: WeeklyMissionExpectation[],
    ): Promise<ValidatedWeeklyMissions> {
        const config = await this.getConfig();

        // Só o que a IA precisa para REESCREVER vai no prompt. `forbiddenTerms`
        // é igual para as três missões (é a audiência), então sai da lista e
        // vira uma seção própria — repeti-lo três vezes só gastaria token.
        const missionBriefs = expectations.map((e) => ({
            type: e.type,
            templateKey: e.templateKey,
            baseName: e.baseName,
            target: e.target,
            requiredTerms: e.requiredTerms,
        }));
        const forbidden = expectations[0]?.forbiddenTerms ?? [];

        const prompt = renderTemplate(config.prompts.weeklyMissions, {
            workspaceType,
            categories: categories.join(" | ") || "Nenhuma categoria",
            goals: goals.join(" | ") || "Nenhuma meta",
            missions: JSON.stringify(missionBriefs),
            forbidden: forbidden.join(", ") || "nenhum",
        });

        const text = await this.generateWithLogging(
            workspaceId,
            "weekly_missions_generation",
            {
                model: config.models.weeklyMissions,
                config: {
                    responseMimeType: "application/json",
                    responseSchema: WEEKLY_MISSIONS_RESPONSE_SCHEMA,
                },
            },
            prompt,
            prompt,
        );

        const parsed = parseAIJsonSafe(text);
        if (parsed === null) {
            throw new Error("Não foi possível gerar as missões semanais via IA.");
        }

        // Missão inválida vira null; o GamificationService cai no texto do
        // CATÁLOGO daquele template, então a semana nunca fica sem missão.
        return validateWeeklyMissionNames(parsed, expectations);
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
                config: {
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
                config: {
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
                config: {
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
