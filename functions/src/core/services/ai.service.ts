import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { AIConfig, DEFAULT_CONFIG } from "../config/ai.config";
import { OrderModel } from "../../features/finance/domain/models/finance.models";

const geminiApiKey = defineString("GEMINI_API_KEY");

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
}

export class GeminiAIRepositoryImpl implements IAIRepository {
    private genAI: GoogleGenerativeAI;

    constructor() {
        this.genAI = new GoogleGenerativeAI(geminiApiKey.value());
    }

    private async getConfig(): Promise<AIConfig> {
        try {
            const doc = await admin.firestore().collection("config").doc("ai").get();
            if (doc.exists) {
                const data = doc.data() as any;
                return {
                    models: {
                        goals: data?.models?.goals || DEFAULT_CONFIG.models.goals,
                        document: data?.models?.document || DEFAULT_CONFIG.models.document,
                    },
                    prompts: {
                        goals: data?.prompts?.goals || DEFAULT_CONFIG.prompts.goals,
                        document: data?.prompts?.document || DEFAULT_CONFIG.prompts.document,
                    },
                };
            }
        }
        catch (error) {
            console.error("Erro ao buscar config de IA no Firestore, usando padrão:", error);
        }
        return DEFAULT_CONFIG;
    }

    async analyzePlanningAndSuggestGoals(
        workspaceId: string,
        workspaceType: string, 
        categories: string[], 
        orders: OrderModel[],
    ): Promise<any> {
        const config = await this.getConfig();
        const model = this.genAI.getGenerativeModel({ model: config.models.goals });

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

    async analyzeAccountDocument(
        workspaceId: string,
        fileBuffer: Buffer, 
        mimeType: string, 
        fileName: string, 
        existingCategories: string[],
        storagePath?: string,
    ): Promise<any> {
        const config = await this.getConfig();
        const model = this.genAI.getGenerativeModel({ model: config.models.document });

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

        // Log no Firestore
        await admin.firestore().collection("ai_logs").add({
            workspaceId,
            prompt,
            response: text,
            type: "document_analysis",
            fileName,
            storagePath,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
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
}
