import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { AI_QUOTA_LABELS } from "../config/quota.config";

/**
 * Fuso oficial do produto. O "dia" da quota vira à meia-noite de Brasília,
 * não à meia-noite UTC (que aqui é 21h do dia anterior).
 */
export const QUOTA_TIME_ZONE = "America/Sao_Paulo";

/** Retenção dos documentos de quota (mesmo campo/TTL usado em ai_logs). */
export const QUOTA_RETENTION_DAYS = 90;

const DAY_MS = 24 * 60 * 60 * 1000;

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

/**
 * Cota já resolvida para um par (workspace, função).
 *
 * Existe para que o serviço de domínio possa consumir a cota NO PONTO EXATO em
 * que a IA é invocada, sem conhecer o quotaService nem os limites: o handler
 * monta o guard, o serviço chama `consume()` logo antes de `aiRepository.*` e
 * `refund()` quando a chamada falha por infraestrutura. Assim, uma resposta
 * servida pelo cache do serviço não gasta cota nenhuma.
 */
export interface QuotaGuard {
    consume(): Promise<void>;
    refund(): Promise<void>;
}

export interface IQuotaService {
    /**
     * Consome uma unidade da quota diária de `functionName` no workspace.
     * Lança HttpsError("resource-exhausted") quando o limite já foi atingido.
     */
    assertQuota(workspaceId: string, functionName: string, dailyLimit: number): Promise<void>;

    /**
     * Devolve uma unidade da quota. Best-effort: nunca lança, para não
     * mascarar o erro original que motivou o estorno.
     */
    refundQuota(workspaceId: string, functionName: string): Promise<void>;

    /** Empacota assertQuota/refundQuota para passar ao serviço de domínio. */
    guardFor(workspaceId: string, functionName: string, dailyLimit: number): QuotaGuard;
}

/**
 * Rate limit diário por workspace para as funções de IA.
 *
 * Contador em `workspaces/{workspaceId}/quotas/{YYYY-MM-DD}`: um campo por
 * função, incrementado com FieldValue.increment DENTRO de uma transação — a
 * leitura e o incremento precisam ser atômicos, senão duas chamadas
 * simultâneas passam as duas pelo limite.
 *
 * O documento leva `expiresAt` (criação + 90 dias) para ser recolhido pela
 * política de TTL do Firestore, igual aos ai_logs (ver functions/README.md).
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
        const docRef = this.quotaDocRef(workspaceId);

        await db.runTransaction(async (transaction) => {
            const snapshot = await transaction.get(docRef);
            const raw = Number(snapshot.data()?.[functionName] ?? 0);
            // Campo corrompido (NaN/Infinity) não pode LIBERAR a chamada:
            // qualquer comparação com NaN é falsa, então falhamos fechado.
            const used = Number.isFinite(raw) ? raw : dailyLimit;

            if (used >= dailyLimit) {
                throw new HttpsError("resource-exhausted", this.buildMessage(functionName, dailyLimit));
            }

            const payload: Record<string, any> = {
                [functionName]: admin.firestore.FieldValue.increment(1),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            // createdAt/expiresAt só na criação do documento do dia, para que o
            // TTL seja criação + 90 dias e não deslize a cada incremento.
            if (!snapshot.exists) {
                payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
                payload.expiresAt = admin.firestore.Timestamp.fromDate(
                    new Date(Date.now() + QUOTA_RETENTION_DAYS * DAY_MS)
                );
            }

            transaction.set(docRef, payload, { merge: true });
        });
    }

    /**
     * Estorno de uma unidade, usado quando a chamada à IA falhou por
     * infraestrutura (5xx/429/timeout do Gemini) — o usuário não deve pagar
     * cota por indisponibilidade nossa. Não estorna erro de payload/validação.
     */
    async refundQuota(workspaceId: string, functionName: string): Promise<void> {
        if (!workspaceId) return;

        try {
            const db = admin.firestore();
            // Usa o dia corrente: se a chamada atravessou a meia-noite, o
            // documento novo não tem o campo e o estorno vira no-op — melhor
            // isso do que deixar o contador negativo.
            const docRef = this.quotaDocRef(workspaceId);

            await db.runTransaction(async (transaction) => {
                const snapshot = await transaction.get(docRef);
                if (!snapshot.exists) return;

                const used = Number(snapshot.data()?.[functionName]);
                if (!Number.isFinite(used) || used <= 0) return;

                transaction.set(
                    docRef,
                    {
                        [functionName]: admin.firestore.FieldValue.increment(-1),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true }
                );
            });
        }
        catch (error) {
            // Best-effort: o erro original da IA é o que interessa ao usuário.
            console.error(`Falha ao estornar cota de ${functionName} em ${workspaceId}:`, error);
        }
    }

    guardFor(workspaceId: string, functionName: string, dailyLimit: number): QuotaGuard {
        return {
            consume: () => this.assertQuota(workspaceId, functionName, dailyLimit),
            refund: () => this.refundQuota(workspaceId, functionName),
        };
    }

    private quotaDocRef(workspaceId: string): admin.firestore.DocumentReference {
        return admin.firestore()
            .collection("workspaces").doc(workspaceId)
            .collection("quotas").doc(quotaDayKey());
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
