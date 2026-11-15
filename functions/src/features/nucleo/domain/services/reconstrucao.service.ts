/**
 * Reconstrução dos derivados de um espaço.
 *
 * Recalcula do zero, com a mesma função que o motor usa, o movimento por dia
 * de cada conta, os resumos mensais e os totais das faturas, e compara com o
 * que está gravado. Sem `aplicar`, só relata as diferenças: é o teste do
 * motor. Com `aplicar`, grava o estado calculado.
 *
 * Deve rodar com o espaço parado: um lançamento gravado no meio da execução
 * pode ser contado duas vezes ou nenhuma.
 */

import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { BatchOperation, commitInChunks } from "../../../../core/utils/batch.utils";
import { COLECOES, Conta, Lancamento, RAIZ } from "../models/modelo";
import { Celula, ContasPorId, contribuicoes, contribuicoesDaConta, somar } from "./contribuicoes";
import { lerConta, lerLancamento } from "./leitura";
import { chaveDaConta, chaveDoLancamento, paraGuardar } from "./motor.service";

type Firestore = admin.firestore.Firestore;

export interface Divergencia {
    doc: string;
    campo: string;
    gravado: number;
    calculado: number;
}

export interface ResultadoReconstrucao {
    lancamentos: number;
    ilegiveis: string[];
    divergencias: Divergencia[];
    aplicado: boolean;
}

/** Estado derivado calculado em memória. */
export interface Derivados {
    /** Soma por célula: chave `doc#campo`. */
    celulas: Map<string, Celula>;
    /** Células por fonte (`l_<id>`, `c_<id>`), como o motor guarda. */
    porFonte: Map<string, Celula[]>;
}

/** Calcula os derivados sem tocar no banco. */
export function calcularDerivados(
    contas: Record<string, Conta>,
    lancamentos: Record<string, Lancamento>
): Derivados {
    const porId: ContasPorId = contas;
    const porFonte = new Map<string, Celula[]>();
    const todas: Celula[] = [];

    for (const [id, conta] of Object.entries(contas)) {
        const celulas = contribuicoesDaConta(id, conta);
        if (celulas.length > 0) porFonte.set(chaveDaConta(id), celulas);
        todas.push(...celulas);
    }
    for (const [id, lancamento] of Object.entries(lancamentos)) {
        const celulas = contribuicoes(lancamento, porId);
        if (celulas.length > 0) porFonte.set(chaveDoLancamento(id), celulas);
        todas.push(...celulas);
    }

    const celulas = somar(todas);
    for (const [chave, celula] of celulas) {
        if (celula.centavos === 0) celulas.delete(chave);
    }
    return { celulas, porFonte };
}

/** Folhas numéricas de um documento, como `caminho/do/campo → valor`. */
export function folhasNumericas(dados: Record<string, unknown>, prefixo: string[] = []): Map<string, number> {
    const folhas = new Map<string, number>();
    for (const [chave, valor] of Object.entries(dados)) {
        const caminho = [...prefixo, chave];
        if (typeof valor === "number") {
            folhas.set(caminho.join("/"), valor);
        }
        else if (valor && typeof valor === "object" && Object.getPrototypeOf(valor) === Object.prototype) {
            for (const [k, v] of folhasNumericas(valor as Record<string, unknown>, caminho)) folhas.set(k, v);
        }
    }
    return folhas;
}

export class ReconstrucaoService {
    constructor(private readonly firestore: Firestore) {}

    async reconstruir(espacoId: string, opcoes: { aplicar: boolean }): Promise<ResultadoReconstrucao> {
        const espaco = this.firestore.collection(RAIZ).doc(espacoId);

        const contas: Record<string, Conta> = {};
        for (const doc of (await espaco.collection(COLECOES.contas).get()).docs) {
            const conta = lerConta(doc.data());
            if (conta) contas[doc.id] = conta;
        }

        const lancamentos: Record<string, Lancamento> = {};
        const ilegiveis: string[] = [];
        for (const doc of (await espaco.collection(COLECOES.lancamentos).get()).docs) {
            const lancamento = lerLancamento(doc.data());
            if (lancamento) lancamentos[doc.id] = lancamento;
            else ilegiveis.push(doc.id);
        }

        const { celulas, porFonte } = calcularDerivados(contas, lancamentos);

        // Estado gravado hoje: só os campos que o motor mantém.
        const gravados = new Map<string, Map<string, number>>();
        const guardar = (doc: string, dados: Record<string, unknown>, campos?: string[]) => {
            const folhas = folhasNumericas(dados);
            if (campos) {
                for (const chave of [...folhas.keys()]) if (!campos.includes(chave)) folhas.delete(chave);
            }
            gravados.set(doc, folhas);
        };

        for (const doc of (await espaco.collection(COLECOES.resumos).get()).docs) {
            guardar(`${COLECOES.resumos}/${doc.id}`, doc.data());
        }
        for (const doc of (await espaco.collection(COLECOES.faturas).get()).docs) {
            guardar(`${COLECOES.faturas}/${doc.id}`, doc.data(), ["totalCentavos", "pagoCentavos"]);
        }
        const contasGravadas = await espaco.collection(COLECOES.contas).get();
        for (const conta of contasGravadas.docs) {
            for (const doc of (await conta.ref.collection(COLECOES.dias).get()).docs) {
                guardar(`${COLECOES.contas}/${conta.id}/${COLECOES.dias}/${doc.id}`, doc.data());
            }
        }

        // Comparação célula a célula.
        const divergencias: Divergencia[] = [];
        const vistos = new Set<string>();
        for (const [chave, celula] of celulas) {
            vistos.add(chave);
            const gravado = gravados.get(celula.doc)?.get(celula.campo.join("/")) ?? 0;
            if (gravado !== celula.centavos) {
                divergencias.push({ doc: celula.doc, campo: celula.campo.join("/"), gravado, calculado: celula.centavos });
            }
        }
        for (const [doc, folhas] of gravados) {
            for (const [campo, gravado] of folhas) {
                if (gravado !== 0 && !vistos.has(`${doc}#${campo}`)) {
                    divergencias.push({ doc, campo, gravado, calculado: 0 });
                }
            }
        }

        if (opcoes.aplicar) {
            await this.gravar(espaco, celulas, porFonte, [...gravados.keys()]);
        }

        return {
            lancamentos: Object.keys(lancamentos).length,
            ilegiveis,
            divergencias,
            aplicado: opcoes.aplicar,
        };
    }

    private async gravar(
        espaco: admin.firestore.DocumentReference,
        celulas: Map<string, Celula>,
        porFonte: Map<string, Celula[]>,
        docsGravados: string[]
    ): Promise<void> {
        const ops: BatchOperation[] = [];
        const ehFatura = (doc: string) => doc.startsWith(`${COLECOES.faturas}/`);

        // Um documento por vez, com todos os seus campos.
        const porDoc = new Map<string, Record<string, unknown>>();
        for (const celula of celulas.values()) {
            const dados = porDoc.get(celula.doc) ?? { ...(celula.base ?? {}) };
            definir(dados, celula.campo, celula.centavos);
            porDoc.set(celula.doc, dados);
        }

        for (const [doc, dados] of porDoc) {
            if (ehFatura(doc)) {
                // A fatura guarda a janela do ciclo; só os totais são refeitos.
                ops.push({
                    op: "set",
                    ref: espaco.firestore.doc(`${espaco.path}/${doc}`),
                    data: { totalCentavos: 0, pagoCentavos: 0, ...dados },
                    options: { merge: true },
                });
            }
            else {
                ops.push({ op: "set", ref: espaco.firestore.doc(`${espaco.path}/${doc}`), data: dados });
            }
        }

        // O que existia e deixou de ter movimento.
        for (const doc of docsGravados) {
            if (porDoc.has(doc)) continue;
            const ref = espaco.firestore.doc(`${espaco.path}/${doc}`);
            if (ehFatura(doc)) {
                ops.push({ op: "set", ref, data: { totalCentavos: 0, pagoCentavos: 0 }, options: { merge: true } });
            }
            else {
                ops.push({ op: "delete", ref });
            }
        }

        // O registro do que foi aplicado passa a refletir o que foi gravado.
        const aplicados = await espaco.collection(COLECOES.aplicados).get();
        for (const doc of aplicados.docs) {
            if (!porFonte.has(doc.id)) ops.push({ op: "delete", ref: doc.ref });
        }
        for (const [chave, lista] of porFonte) {
            ops.push({
                op: "set",
                ref: espaco.collection(COLECOES.aplicados).doc(chave),
                data: { celulas: lista.map(paraGuardar), em: FieldValue.serverTimestamp() },
            });
        }

        await commitInChunks(espaco.firestore, ops);
    }
}

function definir(alvo: Record<string, unknown>, campo: string[], valor: number): void {
    let atual = alvo;
    for (const chave of campo.slice(0, -1)) {
        atual[chave] = (atual[chave] as Record<string, unknown>) ?? {};
        atual = atual[chave] as Record<string, unknown>;
    }
    atual[campo[campo.length - 1]] = valor;
}
