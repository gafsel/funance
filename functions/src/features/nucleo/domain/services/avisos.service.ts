/**
 * Publica os avisos de um espaço: grava em `avisos/{id}` (a lista que o app
 * mostra) e manda a notificação para os aparelhos de cada membro que não
 * desligou aquele tipo.
 *
 * O documento do aviso é criado com `create`: se já existe, o aviso daquele
 * dia já saiu e nada é enviado de novo.
 */

import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { shiftMonthKey } from "../../../../core/utils/month_key";
import { Categoria, COLECOES, Conta, DiaChave, Fatura, Lancamento, RAIZ, ResumoMes } from "../models/modelo";
import { Aviso, avisoDeFimDeSemana, avisoDeVencimentos, avisoSemLancar, tetoDoEstiloDeVida } from "./avisos";

/** Manda para os aparelhos e devolve os tokens que não existem mais. */
export type Enviar = (tokens: string[], titulo: string, texto: string) => Promise<string[]>;

interface Usuario {
    avisos?: Record<string, boolean>;
    aparelhos?: Record<string, { token?: string }>;
}

export class AvisosService {
    constructor(private readonly firestore: admin.firestore.Firestore, private readonly enviar: Enviar) {}

    private espaco(espacoId: string) {
        return this.firestore.collection(RAIZ).doc(espacoId);
    }

    /** Avisos da manhã: tempo sem lançar e o que vence hoje. */
    async manha(espacoId: string, hoje: DiaChave): Promise<Aviso[]> {
        const espaco = this.espaco(espacoId);
        const [ultimo, previstos, faturas, contas] = await Promise.all([
            espaco.collection(COLECOES.lancamentos).where("dataEfetiva", "<=", hoje).orderBy("dataEfetiva", "desc").limit(1).get(),
            espaco.collection(COLECOES.lancamentos).where("situacao", "==", "previsto").where("data", "==", hoje).get(),
            espaco.collection(COLECOES.faturas).where("vencimento", "==", hoje).get(),
            espaco.collection(COLECOES.contas).get(),
        ]);
        const porId = Object.fromEntries(contas.docs.map((d) => [d.id, d.data() as Conta]));
        const avisos = [
            avisoSemLancar((ultimo.docs[0]?.get("dataEfetiva") as string | undefined) ?? null, hoje),
            avisoDeVencimentos(
                previstos.docs.map((d) => d.data() as Lancamento), faturas.docs.map((d) => d.data() as Fatura), porId, hoje),
        ].filter((a): a is Aviso => a !== null);
        return this.publicar(espacoId, avisos);
    }

    /** Aviso do começo do fim de semana: limites do estilo de vida. */
    async fimDeSemana(espacoId: string, hoje: DiaChave): Promise<Aviso[]> {
        const espaco = this.espaco(espacoId);
        const mes = hoje.slice(0, 7);
        const resumos = espaco.collection(COLECOES.resumos);
        const [resumo, categorias, distribuicao, ...anteriores] = await Promise.all([
            resumos.doc(mes).get(),
            espaco.collection(COLECOES.categorias).get(),
            espaco.collection(COLECOES.caminho).doc("distribuicao").get(),
            ...[1, 2, 3].map((n) => resumos.doc(shiftMonthKey(mes, -n)).get()),
        ]);
        const teto = tetoDoEstiloDeVida(
            anteriores.map((r) => (r.data() as ResumoMes | undefined)?.entradas?.realizadoCentavos ?? 0),
            distribuicao.get("referencia") as string | undefined,
        );
        const aviso = avisoDeFimDeSemana(
            (resumo.data() as ResumoMes | undefined) ?? null,
            Object.fromEntries(categorias.docs.map((d) => [d.id, d.data() as Categoria])),
            teto,
            hoje,
        );
        return this.publicar(espacoId, aviso ? [aviso] : []);
    }

    /** Grava e envia os avisos que ainda não saíram. Devolve os que saíram agora. */
    private async publicar(espacoId: string, avisos: Aviso[]): Promise<Aviso[]> {
        if (avisos.length === 0) return [];
        const espaco = this.espaco(espacoId);
        const novos: Aviso[] = [];
        for (const aviso of avisos) {
            try {
                await espaco.collection(COLECOES.avisos).doc(aviso.id).create({ ...aviso, criadoEm: FieldValue.serverTimestamp() });
                novos.push(aviso);
            }
            catch (error) {
                // 6 = ALREADY_EXISTS: o aviso de hoje já saiu.
                if ((error as { code?: number }).code !== 6) throw error;
            }
        }
        if (novos.length === 0) return [];

        const [dados, membros] = await Promise.all([espaco.get(), espaco.collection(COLECOES.membros).get()]);
        const nome = (dados.get("nome") as string | undefined) ?? "Funances";
        for (const membro of membros.docs) {
            const ref = this.firestore.collection("usuarios").doc(membro.id);
            const usuario = ((await ref.get()).data() ?? {}) as Usuario;
            const aparelhos = Object.entries(usuario.aparelhos ?? {}).filter(([, a]) => typeof a?.token === "string" && a.token);
            if (aparelhos.length === 0) continue;
            for (const aviso of novos) {
                if (usuario.avisos?.[aviso.tipo] === false) continue;
                const mortos = await this.enviar(aparelhos.map(([, a]) => a.token as string), `${aviso.titulo} · ${nome}`, aviso.texto);
                const apagar = Object.fromEntries(
                    aparelhos.filter(([, a]) => mortos.includes(a.token as string)).map(([id]) => [`aparelhos.${id}`, FieldValue.delete()]));
                if (Object.keys(apagar).length > 0) await ref.update(apagar);
            }
        }
        return novos;
    }
}

/** Envio de verdade, pelo Firebase Cloud Messaging. */
export const enviarPorFcm: Enviar = async (tokens, titulo, texto) => {
    const resposta = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title: titulo, body: texto },
        webpush: {
            notification: { icon: "/icons/Icon-192.png", badge: "/icons/aviso.png", tag: titulo },
            fcmOptions: { link: "/" },
        },
    });
    const mortos: string[] = [];
    resposta.responses.forEach((r, i) => {
        if (r.success) return;
        const codigo = r.error?.code ?? "";
        if (codigo.includes("registration-token-not-registered") || codigo.includes("invalid-argument") || codigo.includes("invalid-registration-token")) {
            mortos.push(tokens[i]);
        }
        else {
            console.error("[avisos] falha no envio", codigo);
        }
    });
    return mortos;
};
