/**
 * Motor de lançamentos.
 *
 * Reage à gravação de um lançamento (ou de uma conta) e atualiza, numa única
 * transação, tudo o que deriva dele: movimento do dia na conta, resumo do mês
 * e fatura do cartão.
 *
 * O motor não confia no "antes e depois" do evento. Ele lê o documento como
 * está agora, lê o que já tinha aplicado dele (`aplicados/{chave}`) e aplica a
 * diferença. Consequências:
 * - o mesmo evento entregue duas vezes não soma duas vezes;
 * - eventos fora de ordem convergem para o estado final;
 * - um gatilho que falhou é corrigido pelo próximo que rodar.
 */

import * as admin from "firebase-admin";
import { COLECOES, RAIZ } from "../models/modelo";
import { Celula, ContasPorId, aninhar, contribuicoes, contribuicoesDaConta, diferenca } from "./contribuicoes";
import { lerConta, lerLancamento } from "./leitura";

type Firestore = admin.firestore.Firestore;
type Transaction = admin.firestore.Transaction;

export interface ResultadoMotor {
    /** Quantas células mudaram. Zero = nada a fazer (repetição ou eco). */
    alteradas: number;
}

export const chaveDoLancamento = (id: string): string => `l_${id}`;
export const chaveDaConta = (id: string): string => `c_${id}`;

export class MotorService {
    constructor(private readonly firestore: Firestore) {}

    private espaco(espacoId: string) {
        return this.firestore.collection(RAIZ).doc(espacoId);
    }

    async processarLancamento(espacoId: string, lancamentoId: string): Promise<ResultadoMotor> {
        const espaco = this.espaco(espacoId);
        return this.sincronizar(espacoId, chaveDoLancamento(lancamentoId), async (txn) => {
            const doc = await txn.get(espaco.collection(COLECOES.lancamentos).doc(lancamentoId));
            const lancamento = lerLancamento(doc.data());
            if (!lancamento) return [];

            const ids = [lancamento.contaId, lancamento.contaDestinoId].filter((id): id is string => !!id);
            const contas: ContasPorId = {};
            for (const id of new Set(ids)) {
                const conta = await txn.get(espaco.collection(COLECOES.contas).doc(id));
                contas[id] = lerConta(conta.data()) ?? undefined;
            }
            return contribuicoes(lancamento, contas);
        });
    }

    async processarConta(espacoId: string, contaId: string): Promise<ResultadoMotor> {
        const espaco = this.espaco(espacoId);
        return this.sincronizar(espacoId, chaveDaConta(contaId), async (txn) => {
            const doc = await txn.get(espaco.collection(COLECOES.contas).doc(contaId));
            return contribuicoesDaConta(contaId, lerConta(doc.data()));
        });
    }

    private async sincronizar(
        espacoId: string,
        chave: string,
        calcular: (txn: Transaction) => Promise<Celula[]>
    ): Promise<ResultadoMotor> {
        const espaco = this.espaco(espacoId);
        const aplicadoRef = espaco.collection(COLECOES.aplicados).doc(chave);

        return this.firestore.runTransaction(async (txn) => {
            const aplicadoDoc = await txn.get(aplicadoRef);
            const aplicadas = (aplicadoDoc.data()?.celulas ?? []) as Celula[];
            const novas = await calcular(txn);
            const delta = diferenca(novas, aplicadas);

            if (delta.length === 0) {
                return { alteradas: 0 };
            }

            for (const [doc, dados] of agruparPorDocumento(delta)) {
                txn.set(this.firestore.doc(`${espaco.path}/${doc}`), dados, { merge: true });
            }

            if (novas.length === 0) {
                txn.delete(aplicadoRef);
            }
            else {
                txn.set(aplicadoRef, {
                    celulas: novas.map(paraGuardar),
                    em: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            return { alteradas: delta.length };
        });
    }
}

/** O que fica guardado de cada célula aplicada (sem a `base`). */
export const paraGuardar = (c: Celula): Celula => ({ doc: c.doc, campo: c.campo, centavos: c.centavos });

/** Um `set` com `merge` por documento, somando cada campo com `increment`. */
function agruparPorDocumento(celulas: Celula[]): Map<string, Record<string, unknown>> {
    const porDoc = new Map<string, Record<string, unknown>>();
    for (const c of celulas) {
        const atual = porDoc.get(c.doc) ?? {};
        mesclar(atual, c.base ?? {});
        mesclar(atual, aninhar(c.campo, admin.firestore.FieldValue.increment(c.centavos)));
        porDoc.set(c.doc, atual);
    }
    return porDoc;
}

const ehObjetoSimples = (v: unknown): v is Record<string, unknown> =>
    typeof v === "object" && v !== null && Object.getPrototypeOf(v) === Object.prototype;

function mesclar(alvo: Record<string, unknown>, origem: Record<string, unknown>): void {
    for (const [chave, valor] of Object.entries(origem)) {
        const existente = alvo[chave];
        if (ehObjetoSimples(valor) && ehObjetoSimples(existente)) {
            mesclar(existente, valor);
        }
        else {
            alvo[chave] = ehObjetoSimples(valor) ? { ...valor } : valor;
        }
    }
}
