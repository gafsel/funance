/**
 * Criação de um espaço novo. É do servidor porque o espaço e o vínculo de
 * dono não podem ser escritos pelo app (as rules negam): quem cria vira dono,
 * e só o servidor diz quem é dono.
 */

import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { COLECOES, Categoria, RAIZ, TipoEspaco } from "../models/modelo";

/** Quantos espaços uma pessoa pode ter como dona. */
export const LIMITE_DE_ESPACOS = 10;

type Padrao = [id: string, nome: string, tipo: Categoria["tipo"], grupo: Categoria["grupo"]];

export const CATEGORIAS_PADRAO: Record<TipoEspaco, Padrao[]> = {
    pessoal: [
        ["salario", "Salário", "entrada", null],
        ["outras-entradas", "Outras entradas", "entrada", null],
        ["moradia", "Moradia", "saida", "essencial"],
        ["mercado", "Mercado", "saida", "essencial"],
        ["transporte", "Transporte", "saida", "essencial"],
        ["saude", "Saúde", "saida", "essencial"],
        ["contas-da-casa", "Contas da casa", "saida", "essencial"],
        ["educacao", "Educação", "saida", "essencial"],
        ["lazer", "Lazer", "saida", "conforto"],
        ["restaurantes", "Restaurantes", "saida", "conforto"],
        ["compras", "Compras", "saida", "conforto"],
        ["assinaturas", "Assinaturas", "saida", "conforto"],
        ["outros", "Outros", "saida", "conforto"],
    ],
    empresa: [
        ["vendas", "Vendas", "entrada", null],
        ["servicos", "Serviços", "entrada", null],
        ["outras-receitas", "Outras receitas", "entrada", null],
        ["fornecedores", "Fornecedores", "saida", "essencial"],
        ["pessoal", "Pessoal", "saida", "essencial"],
        ["pro-labore", "Pró-labore", "saida", "essencial"],
        ["aluguel-e-estrutura", "Aluguel e estrutura", "saida", "essencial"],
        ["impostos-e-taxas", "Impostos e taxas", "saida", "essencial"],
        ["marketing", "Marketing", "saida", "conforto"],
        ["ferramentas", "Ferramentas e sistemas", "saida", "conforto"],
        ["outras-despesas", "Outras despesas", "saida", "conforto"],
    ],
};

export interface PedidoDeEspaco {
    nome: string;
    tipo: TipoEspaco;
}

export function validarPedido(dados: unknown): PedidoDeEspaco {
    const d = (dados ?? {}) as Record<string, unknown>;
    const nome = typeof d.nome === "string" ? d.nome.trim() : "";
    if (nome.length < 1 || nome.length > 60) throw new Error("O nome deve ter de 1 a 60 caracteres.");
    if (d.tipo !== "pessoal" && d.tipo !== "empresa") throw new Error("O tipo deve ser pessoal ou empresa.");
    return { nome, tipo: d.tipo };
}

export async function criarEspaco(firestore: admin.firestore.Firestore, uid: string, pedido: PedidoDeEspaco): Promise<string> {
    const meus = await firestore.collectionGroup(COLECOES.membros).where("uid", "==", uid).get();
    if (meus.docs.filter((d) => d.data().papel === "dono").length >= LIMITE_DE_ESPACOS) {
        throw new Error(`Cada pessoa pode ser dona de até ${LIMITE_DE_ESPACOS} espaços.`);
    }

    const espaco = firestore.collection(RAIZ).doc();
    const batch = firestore.batch();
    batch.set(espaco, { nome: pedido.nome, tipo: pedido.tipo, criadoEm: FieldValue.serverTimestamp() });
    batch.set(espaco.collection(COLECOES.membros).doc(uid), { uid, papel: "dono", entrada: FieldValue.serverTimestamp() });
    for (const [id, nome, tipo, grupo] of CATEGORIAS_PADRAO[pedido.tipo]) {
        batch.set(espaco.collection(COLECOES.categorias).doc(id), {
            nome, tipo, icone: null, cor: null, grupo, limiteMensalCentavos: null, arquivada: false,
        });
    }
    await batch.commit();
    return espaco.id;
}
