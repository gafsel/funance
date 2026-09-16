import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { AI_QUOTA_LABELS } from "../config/quota.config";

/**
 * Fuso oficial do produto. O "dia" da quota vira à meia-noite de Brasília,
 * não à meia-noite UTC (que aqui é 21h do dia anterior).
 */
export const QUOTA_TIME_ZONE = "America/Sao_Paulo";

/** Formata um instante como YYYY-MM-DD no fuso do produto. */
export function quotaDayKey(date: Date = new Date(), timeZone: string = QUOTA_TIME_ZONE): string {
    // "en-CA" já produz exatamente YYYY-MM-DD.
    return new Intl.DateTimeFormat("en-CA", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
    }).format(date);
}

export interface IQuotaService {
    /**
     * Consome uma unidade da quota diária de `functionName` no workspace.
     * Lança HttpsError("resource-exhausted") quando o limite já foi atingido.
     */
    assertQuota(workspaceId: string, functionName: string, dailyLimit: number): Promise<void>;
}

/**
 * Rate limit diário por workspace para as funções de IA.
 *
 * Contador em `workspaces/{workspaceId}/quotas/{YYYY-MM-DD}`: um campo por
 * função, incrementado com FieldValue.increment DENTRO de uma transação — a
 * leitura e o incremento precisam ser atômicos, senão duas chamadas
 * simultâneas passam as duas pelo limite.
 *
 * A quota é consumida ANTES da chamada ao Gemini (inclusive quando a resposta
 * acaba vindo do cache do serviço): é ela que protege o custo da API, então
 * não pode depender do sucesso da geração.
 */
export class QuotaServiceImpl implements IQuotaService {
    async assertQuota(workspaceId: string, functionName: string, dailyLimit: number): Promise<void> {
        if (!workspaceId) {
            throw new HttpsError("invalid-argument", "Workspace ID é obrigatório.");
        }
        // Limite não positivo significa recurso desligado — bloqueia sem gravar nada.
        if (!(dailyLimit > 0)) {
            throw new HttpsError("resource-exhausted", this.buildMessage(functionName, dailyLimit));
        }

        const db = admin.firestore();
        const docRef = db
            .collection("workspaces").doc(workspaceId)
            .collection("quotas").doc(quotaDayKey());

        await db.runTransaction(async (transaction) => {
            const snapshot = await transaction.get(docRef);
            const used = Number(snapshot.data()?.[functionName] ?? 0);

            if (used >= dailyLimit) {
                throw new HttpsError("resource-exhausted", this.buildMessage(functionName, dailyLimit));
            }

            transaction.set(
                docRef,
                {
                    [functionName]: admin.firestore.FieldValue.increment(1),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
            );
        });
    }

    private buildMessage(functionName: string, dailyLimit: number): string {
        const label = AI_QUOTA_LABELS[functionName as keyof typeof AI_QUOTA_LABELS] || "análises com inteligência artificial";
        if (!(dailyLimit > 0)) {
            return `As ${label} estão indisponíveis no momento. Tente novamente mais tarde.`;
        }
        return `Você atingiu o limite de ${dailyLimit} ${label} por dia neste workspace. ` +
            "O limite é renovado à meia-noite (horário de Brasília).";
    }
}
