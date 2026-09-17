/**
 * Cache de resposta de IA por HASH DA ENTRADA (F5.6).
 *
 * Duas funções — `analysePlanning` (sugestão de metas no onboarding) e
 * `analyzeGoalFeasibility` (viabilidade de meta) — eram chamadas várias vezes
 * com exatamente a mesma entrada: o usuário volta uma tela e avança de novo,
 * ajusta um campo e desfaz, o app reabre a sugestão. Cada repetição era uma
 * chamada paga ao Gemini e uma unidade de cota do usuário.
 *
 * O cache vive em `workspaces/{workspaceId}/ai_cache/{functionName}_{sha256}`,
 * onde o sha256 é da entrada NORMALIZADA (chaves ordenadas, datas em ISO).
 * Mudou qualquer coisa na entrada, muda o hash e a IA é chamada de novo — não
 * existe o risco de servir uma análise velha para um dado novo.
 *
 * Só resposta JÁ VALIDADA entra no cache: nada que o validador descartaria
 * pode ser servido depois como se fosse bom.
 *
 * **Cache-hit não consome cota.** O consumo segue o mesmo padrão de
 * `generateCoaching`/`analyze503020Ideal`: `QuotaGuard.consume()` imediatamente
 * antes da chamada real ao Gemini, nunca no handler.
 */

import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { stripUndefined } from "../utils/firestore.utils";

/** Validade do cache. Documentado no README junto com a política de TTL. */
export const AI_CACHE_TTL_DAYS = 7;

const DAY_MS = 24 * 60 * 60 * 1000;

/** Nomes ESTÁVEIS usados no id do documento. Mudar um invalida o cache dele. */
export const AI_CACHE_FUNCTIONS = {
    analysePlanning: "analysePlanning",
    analyzeGoalFeasibility: "analyzeGoalFeasibility",
} as const;

export type AiCacheFunction = typeof AI_CACHE_FUNCTIONS[keyof typeof AI_CACHE_FUNCTIONS];

/**
 * JSON determinístico: chaves de objeto em ordem alfabética, `Date` e
 * `Timestamp` do Firestore em ISO. Sem isso, dois objetos idênticos montados em
 * ordens diferentes gerariam hashes diferentes e o cache nunca acertaria.
 */
export function stableStringify(value: unknown): string {
    const normalize = (input: any): any => {
        if (input === null || input === undefined) return null;
        if (input instanceof Date) return input.toISOString();
        // Timestamp do Firestore (e qualquer coisa com toDate()).
        if (typeof input?.toDate === "function") return input.toDate().toISOString();
        if (Array.isArray(input)) return input.map(normalize);
        if (typeof input === "object") {
            const out: Record<string, any> = {};
            for (const key of Object.keys(input).sort()) {
                const normalized = normalize(input[key]);
                // `undefined` some do JSON; normalizar para null mantém a
                // chave e o hash estável.
                out[key] = normalized;
            }
            return out;
        }
        if (typeof input === "number" && !Number.isFinite(input)) return null;
        return input;
    };
    return JSON.stringify(normalize(value));
}

/** `{functionName}_{sha256(entrada normalizada)}` — o id do documento. */
export function aiCacheKey(functionName: string, input: unknown): string {
    const hash = crypto.createHash("sha256").update(stableStringify(input)).digest("hex");
    return `${functionName}_${hash}`;
}

export interface IAiCacheService {
    /** Resposta em cache e ainda válida, ou null. Nunca lança. */
    get<T = any>(workspaceId: string, functionName: AiCacheFunction, input: unknown): Promise<T | null>;
    /** Grava a resposta VALIDADA. Best-effort: nunca lança. */
    set(workspaceId: string, functionName: AiCacheFunction, input: unknown, payload: any): Promise<void>;
}

export class AiCacheServiceImpl implements IAiCacheService {
    async get<T = any>(workspaceId: string, functionName: AiCacheFunction, input: unknown): Promise<T | null> {
        if (!workspaceId) return null;

        try {
            const snapshot = await this.docRef(workspaceId, aiCacheKey(functionName, input)).get();
            if (!snapshot.exists) return null;

            const data = snapshot.data();
            // A política de TTL do Firestore apaga em background e pode nem
            // estar ativa: a validade é conferida na leitura.
            const expiresAt = data?.expiresAt?.toDate ? data.expiresAt.toDate() : null;
            if (!expiresAt || expiresAt.getTime() <= Date.now()) return null;

            const payload = data?.payload;
            if (payload === undefined || payload === null) return null;

            console.log(`AiCache: hit de ${functionName} em ${workspaceId} (sem consumo de cota).`);
            return payload as T;
        }
        catch (error) {
            // Cache é acessório: qualquer problema vira cache-miss.
            console.error(`AiCache: falha ao ler o cache de ${functionName}:`, error);
            return null;
        }
    }

    async set(workspaceId: string, functionName: AiCacheFunction, input: unknown, payload: any): Promise<void> {
        if (!workspaceId || payload === undefined || payload === null) return;

        try {
            await this.docRef(workspaceId, aiCacheKey(functionName, input)).set({
                functionName,
                // A resposta validada pode ter campos opcionais ausentes; o
                // cache guarda o que existe, sem `undefined` no documento.
                payload: stripUndefined(payload),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: admin.firestore.Timestamp.fromDate(
                    new Date(Date.now() + AI_CACHE_TTL_DAYS * DAY_MS)
                ),
            });
        }
        catch (error) {
            console.error(`AiCache: falha ao gravar o cache de ${functionName}:`, error);
        }
    }

    private docRef(workspaceId: string, cacheKey: string): admin.firestore.DocumentReference {
        return admin.firestore()
            .collection("workspaces").doc(workspaceId)
            .collection("ai_cache").doc(cacheKey);
    }
}
