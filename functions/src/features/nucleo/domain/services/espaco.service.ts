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

type Padrao = [id: string, nome: string, tipo: Categoria["tipo"], grupo: Categoria["grupo"], icone: string, cor: string];

export const CATEGORIAS_PADRAO: Record<TipoEspaco, Padrao[]> = {
    pessoal: [
        ["salario", "Salário", "entrada", null, "payments", "#23804A"],
        ["outras-entradas", "Outras entradas", "entrada", null, "attach_money", "#4A8C9C"],
        ["moradia", "Moradia", "saida", "essencial", "home", "#42A5F5"],
        ["mercado", "Mercado", "saida", "essencial", "shopping_cart", "#FF9800"],
        ["transporte", "Transporte", "saida", "essencial", "directions_car", "#7E57C2"],
        ["saude", "Saúde", "saida", "essencial", "local_hospital", "#EF5350"],
        ["contas-da-casa", "Contas da casa", "saida", "essencial", "lightbulb", "#FFB300"],
        ["educacao", "Educação", "saida", "essencial", "school", "#5C6BC0"],
        ["lazer", "Lazer", "saida", "conforto", "sports_esports", "#EC407A"],
        ["restaurantes", "Restaurantes", "saida", "conforto", "restaurant", "#FF7043"],
        ["compras", "Compras", "saida", "conforto", "shopping_bag", "#26A69A"],
        ["assinaturas", "Assinaturas", "saida", "conforto", "subscriptions", "#8D6E63"],
        ["outros", "Outros", "saida", "conforto", "category", "#78909C"],
    ],
    empresa: [
        ["vendas", "Vendas", "entrada", null, "trending_up", "#23804A"],
        ["servicos", "Serviços", "entrada", null, "work", "#00BCD4"],
        ["outras-receitas", "Outras receitas", "entrada", null, "attach_money", "#4A8C9C"],
        ["fornecedores", "Fornecedores", "saida", "essencial", "local_shipping", "#FF9800"],
        ["pessoal", "Pessoal", "saida", "essencial", "people", "#5C6BC0"],
        ["pro-labore", "Pró-labore", "saida", "essencial", "payments", "#7E57C2"],
        ["aluguel-e-estrutura", "Aluguel e estrutura", "saida", "essencial", "home", "#42A5F5"],
        ["impostos-e-taxas", "Impostos e taxas", "saida", "essencial", "account_balance", "#EF5350"],
        ["marketing", "Marketing", "saida", "conforto", "campaign", "#EC407A"],
        ["ferramentas", "Ferramentas e sistemas", "saida", "conforto", "build", "#26A69A"],
        ["outras-despesas", "Outras despesas", "saida", "conforto", "category", "#78909C"],
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

export interface Perfil {
    nome?: string | null;
    foto?: string | null;
}

export async function criarEspaco(
    firestore: admin.firestore.Firestore,
    uid: string,
    pedido: PedidoDeEspaco,
    perfil: Perfil = {}
): Promise<string> {
    const meus = await firestore.collectionGroup(COLECOES.membros).where("uid", "==", uid).get();
    if (meus.docs.filter((d) => d.data().papel === "dono").length >= LIMITE_DE_ESPACOS) {
        throw new Error(`Cada pessoa pode ser dona de até ${LIMITE_DE_ESPACOS} espaços.`);
    }

    const espaco = firestore.collection(RAIZ).doc();
    const batch = firestore.batch();
    batch.set(espaco, { nome: pedido.nome, tipo: pedido.tipo, criadoEm: FieldValue.serverTimestamp() });
    batch.set(espaco.collection(COLECOES.membros).doc(uid), {
        uid, papel: "dono", entrada: FieldValue.serverTimestamp(), nome: perfil.nome ?? null, foto: perfil.foto ?? null,
    });
    for (const [id, nome, tipo, grupo, icone, cor] of CATEGORIAS_PADRAO[pedido.tipo]) {
        batch.set(espaco.collection(COLECOES.categorias).doc(id), {
            nome, tipo, icone, cor, grupo, limiteMensalCentavos: null, arquivada: false,
        });
    }
    await batch.commit();
    return espaco.id;
}

/**
 * Copia nome e foto de `usuarios/{uid}` para o vínculo de cada membro de um
 * espaço. Serve para os espaços migrados, cujos vínculos nasceram sem isso.
 */
export async function sincronizarMembros(firestore: admin.firestore.Firestore, espacoId: string): Promise<number> {
    const membros = await firestore.collection(RAIZ).doc(espacoId).collection(COLECOES.membros).get();
    let atualizados = 0;
    for (const membro of membros.docs) {
        const perfil = (await firestore.collection("usuarios").doc(membro.id).get()).data();
        if (!perfil) continue;
        await membro.ref.set({ nome: perfil.nome ?? null, foto: perfil.foto ?? null }, { merge: true });
        atualizados++;
    }
    return atualizados;
}
