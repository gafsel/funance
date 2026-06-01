import { GoogleGenerativeAI } from "@google/generative-ai";
import { defineString } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { AIConfig, DEFAULT_CONFIG } from "../config/ai.config";
import { InstallmentType, OrderModel, OrderStatus, OrderType } from "../../features/finance/domain/models/finance.models";
import * as ofx from "ofx-js";

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
                        documentOfx: data?.prompts?.documentOfx || DEFAULT_CONFIG.prompts.documentOfx,
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
                .replace("{{transactions}}", JSON.stringify(transactions))
                .replace("{{accountName}}", accountInfo.name || fileName.split(".")[0])
                .replace("{{runtimeType}}", accountInfo.runtimeType || "checking")
                .replace("{{currentBalance}}", (accountInfo.currentBalance || 0.0).toString());

            const aiResult = await model.generateContent(prompt);
            const response = await aiResult.response;
            const text = response.text();
            const jsonMatch = text.match(/\{[\s\S]*\}/);
            resultData = jsonMatch ? JSON.parse(jsonMatch[0]) : null;

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

        } else {
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

            // Log no Firestore para PDF
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

    private extractOfxData(parsedOfx: any): { account: any, transactions: any[] } {
        const transactions: any[] = [];
        let account: any = {};
        try {
            const ofxData = parsedOfx.OFX;
            
            // Tentar extrair de BANKMSGSRSV1 (Conta Corrente) ou CREDITCARDMSGSRSV1 (Cartão de Crédito)
            let stmtTrnRs;
            let isCreditCard = false;

            if (ofxData.BANKMSGSRSV1) {
                stmtTrnRs = ofxData.BANKMSGSRSV1.STMTTRNRS;
            } else if (ofxData.CREDITCARDMSGSRSV1) {
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
                account.runtimeType = isCreditCard ? "credit_card" : (bankAcctFrom.ACCTTYPE === "CHECKING" ? "checking" : "investment");
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
        } catch (e) {
            console.error("Erro ao extrair dados OFX:", e);
        }
        return { account, transactions };
    }
}
