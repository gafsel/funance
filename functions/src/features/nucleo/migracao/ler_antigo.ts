/**
 * Lê um workspace inteiro do banco antigo. Só faz leituras.
 */

import * as admin from "firebase-admin";
import { DadosAntigos, Docs } from "./dados_antigos";

type Firestore = admin.firestore.Firestore;

async function colecao(ref: admin.firestore.CollectionReference): Promise<Docs> {
    const docs: Docs = {};
    for (const doc of (await ref.get()).docs) docs[doc.id] = doc.data();
    return docs;
}

export async function lerWorkspace(origem: Firestore, projeto: string, workspaceId: string): Promise<DadosAntigos> {
    const ws = origem.collection("workspaces").doc(workspaceId);
    const snapshot = await ws.get();
    if (!snapshot.exists) {
        throw new Error(`workspace ${workspaceId} não existe em ${projeto}`);
    }

    const accounts = await colecao(ws.collection("accounts"));
    const saldos: Record<string, Docs> = {};
    for (const id of Object.keys(accounts)) {
        saldos[id] = await colecao(ws.collection("accounts").doc(id).collection("balance"));
    }

    return {
        projeto,
        workspaceId,
        workspace: snapshot.data() ?? {},
        accounts,
        orders: await colecao(ws.collection("orders")),
        installments: await colecao(ws.collection("installments")),
        categories: await colecao(ws.collection("categories")),
        plannings: await colecao(ws.collection("category_planning")),
        goals: await colecao(ws.collection("goals")),
        automaticas: await colecao(ws.collection("automatic_transactions")),
        reconciliations: await colecao(ws.collection("reconciliations")),
        saldos,
        resumos: await colecao(ws.collection("period_summaries")),
    };
}

export async function listarWorkspaces(origem: Firestore): Promise<string[]> {
    return (await origem.collection("workspaces").select().get()).docs.map((d) => d.id);
}
