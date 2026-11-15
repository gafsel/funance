/**
 * Funções de apoio ao lançamento: leitura de frase pela IA e extensão mensal
 * das séries recorrentes.
 */

import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { AI_CALLABLE_OPTIONS_SHORT, AI_SCHEDULE_OPTIONS } from "../../../../core/config/functions.config";
import { GEMINI_API_KEY } from "../../../../core/config/secrets";
import { BatchOperation, commitInChunks } from "../../../../core/utils/batch.utils";
import { isDateKey, toDateKey } from "../../../../core/utils/date_key";
import { shiftMonthKey } from "../../../../core/utils/month_key";
import { COLECOES, RAIZ, Serie } from "../../domain/models/modelo";
import { criarEspaco as criarEspacoNoBanco, validarPedido } from "../../domain/services/espaco.service";
import { ContextoDaFrase, FraseService, LIMITE_DE_CARACTERES } from "../../domain/services/frase.service";
import { proximosDaSerie } from "../../domain/services/series";

/** Leituras pela IA por espaço e por dia. */
export const LIMITE_DIARIO_DE_FRASES = 200;
/** Até quantos meses à frente uma série recorrente fica gerada. */
export const MESES_A_FRENTE = 12;

let frases: FraseService | null = null;

const lista = (v: unknown, max: number): { id: string; nome: string; tipo: string }[] =>
    (Array.isArray(v) ? v : []).slice(0, max)
        .filter((i) => typeof i?.id === "string" && typeof i?.nome === "string" && typeof i?.tipo === "string")
        .map((i) => ({ id: i.id.slice(0, 200), nome: i.nome.slice(0, 100), tipo: i.tipo.slice(0, 30) }));

export const interpretarFrase = onCall(AI_CALLABLE_OPTIONS_SHORT, async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");

    const { espacoId, texto, hoje } = request.data ?? {};
    if (typeof espacoId !== "string" || !espacoId) throw new HttpsError("invalid-argument", "Espaço é obrigatório.");
    if (typeof texto !== "string" || !texto.trim() || texto.length > LIMITE_DE_CARACTERES) {
        throw new HttpsError("invalid-argument", `O texto deve ter de 1 a ${LIMITE_DE_CARACTERES} caracteres.`);
    }

    const firestore = admin.firestore();
    const espaco = firestore.collection(RAIZ).doc(espacoId);
    const membro = await espaco.collection(COLECOES.membros).doc(request.auth.uid).get();
    if (!membro.exists) throw new HttpsError("permission-denied", "Você não participa deste espaço.");

    // Limite diário: conta antes de chamar a IA, para que tentativas em
    // paralelo não passem juntas.
    const dia = toDateKey(new Date());
    const uso = espaco.collection("uso").doc(dia);
    const permitido = await firestore.runTransaction(async (txn) => {
        const atual = ((await txn.get(uso)).data()?.frases ?? 0) as number;
        if (atual >= LIMITE_DIARIO_DE_FRASES) return false;
        txn.set(uso, { frases: atual + 1 }, { merge: true });
        return true;
    });
    if (!permitido) throw new HttpsError("resource-exhausted", "Limite diário de leituras atingido. Use o modo avançado.");

    const contexto: ContextoDaFrase = {
        hoje: isDateKey(hoje) ? hoje : dia,
        contas: lista(request.data.contas, 50),
        categorias: lista(request.data.categorias, 200),
    };

    frases = frases ?? new FraseService(() => GEMINI_API_KEY.value());
    try {
        return { leituras: await frases.interpretar(texto, contexto) };
    }
    catch (error) {
        console.error("[interpretarFrase] falha na IA", error instanceof Error ? error.message : error);
        throw new HttpsError("unavailable", "Não consegui ler agora. Tente de novo ou use o modo avançado.");
    }
});

/** Cria um espaço novo; quem chama vira dono. */
export const criarEspaco = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    let pedido;
    try {
        pedido = validarPedido(request.data);
    }
    catch (error) {
        throw new HttpsError("invalid-argument", error instanceof Error ? error.message : "Pedido inválido.");
    }
    try {
        return { espacoId: await criarEspacoNoBanco(admin.firestore(), request.auth.uid, pedido) };
    }
    catch (error) {
        throw new HttpsError("failed-precondition", error instanceof Error ? error.message : "Não foi possível criar o espaço.");
    }
});

/** Gera os lançamentos que faltam das séries recorrentes de um espaço. */
export async function estenderSeriesDoEspaco(
    firestore: admin.firestore.Firestore,
    espacoId: string,
    hoje: string
): Promise<number> {
    const espaco = firestore.collection(RAIZ).doc(espacoId);
    const horizonte = shiftMonthKey(hoje.slice(0, 7), MESES_A_FRENTE);
    const series = await espaco.collection(COLECOES.series)
        .where("ativa", "==", true).where("forma", "==", "recorrente").get();

    const ops: BatchOperation[] = [];
    for (const doc of series.docs) {
        const novos = proximosDaSerie(doc.id, doc.data() as Serie, horizonte);
        const ids = Object.keys(novos).sort();
        if (ids.length === 0) continue;
        for (const id of ids) {
            ops.push({ op: "set", ref: espaco.collection(COLECOES.lancamentos).doc(id), data: novos[id] });
        }
        ops.push({ op: "update", ref: doc.ref, data: { geradoAte: novos[ids[ids.length - 1]].data } });
    }
    await commitInChunks(firestore, ops);
    return ops.length;
}

export const estenderSeries = onSchedule(
    { ...AI_SCHEDULE_OPTIONS, schedule: "0 4 1 * *", timeZone: "America/Sao_Paulo" },
    async () => {
        const firestore = admin.firestore();
        const hoje = toDateKey(new Date());
        const espacos = await firestore.collection(RAIZ).select().get();
        for (const espaco of espacos.docs) {
            try {
                await estenderSeriesDoEspaco(firestore, espaco.id, hoje);
            }
            catch (error) {
                console.error(`[estenderSeries] ${espaco.id}`, error instanceof Error ? error.message : error);
            }
        }
    }
);
