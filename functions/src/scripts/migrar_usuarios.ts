/**
 * Copia os usuários do login do projeto antigo para o do Funances 2, com os
 * mesmos ids, senhas (hash) e vínculos com o Google.
 *
 * Por padrão só lista quantos seriam copiados. Com `--aplicar`, importa no
 * destino. Quem já existe no destino com o mesmo id é atualizado; a origem
 * nunca é alterada. Também copia o perfil `users/{uid}` para `usuarios/{uid}`.
 *
 * Uso:
 *   cd functions && npm run build
 *   node lib/scripts/migrar_usuarios.js --origem=funance-cef1b \
 *     --destino=funances2-testes [--aplicar]
 *
 * A chave do hash das senhas é lida da configuração do projeto de origem em
 * memória e nunca é impressa nem gravada em disco.
 */

import * as admin from "firebase-admin";
import { DESTINOS_PROIBIDOS } from "./migrar_funances2";

export interface Opcoes {
    origem: string;
    destino: string;
    aplicar: boolean;
}

export function parseArgs(argv: string[]): Opcoes {
    const valor = (nome: string): string =>
        argv.find((a) => a.startsWith(`--${nome}=`))?.slice(nome.length + 3) ?? "";
    const opcoes = { origem: valor("origem"), destino: valor("destino"), aplicar: argv.includes("--aplicar") };
    if (!opcoes.origem || !opcoes.destino) throw new Error("informe --origem=<projeto> e --destino=<projeto>");
    if (opcoes.origem === opcoes.destino) throw new Error("origem e destino não podem ser o mesmo projeto");
    if (DESTINOS_PROIBIDOS.includes(opcoes.destino)) throw new Error(`${opcoes.destino} é o projeto antigo e não pode ser destino`);
    return opcoes;
}

interface HashConfig {
    algorithm?: string;
    signerKey?: string;
    saltSeparator?: string;
    rounds?: number;
    memoryCost?: number;
}

/** Usuário como a API do Identity Toolkit devolve e aceita. */
export type UsuarioBruto = Record<string, unknown> & { localId: string };

const CAMPOS_COPIADOS = [
    "localId", "email", "emailVerified", "displayName", "photoUrl", "passwordHash", "salt",
    "providerUserInfo", "createdAt", "lastLoginAt", "disabled", "phoneNumber",
];

/** Só os campos que identificam a pessoa e o login; nada de sessão ou token. */
export function paraImportar(usuario: UsuarioBruto): UsuarioBruto {
    const copia: Record<string, unknown> = {};
    for (const campo of CAMPOS_COPIADOS) {
        if (usuario[campo] !== undefined) copia[campo] = usuario[campo];
    }
    // O vínculo com o provedor vai só com o id cru: o `federatedId` que a
    // leitura devolve não é aceito de volta na importação.
    const provedores = (usuario.providerUserInfo ?? []) as Record<string, unknown>[];
    copia.providerUserInfo = provedores
        .filter((p) => p.providerId !== "password")
        .map((p) => ({
            providerId: p.providerId,
            rawId: p.rawId,
            ...(p.email ? { email: p.email } : {}),
            ...(p.displayName ? { displayName: p.displayName } : {}),
            ...(p.photoUrl ? { photoUrl: p.photoUrl } : {}),
        }));
    return copia as UsuarioBruto;
}

/**
 * Chamada à API do Identity Toolkit. Usa REST em vez do Admin SDK porque,
 * com credencial de usuário, a API exige o projeto de cota no cabeçalho.
 */
async function chamar<T>(app: admin.app.App, projeto: string, caminho: string, corpo?: unknown): Promise<T> {
    const token = await app.options.credential?.getAccessToken();
    const resposta = await fetch(`https://identitytoolkit.googleapis.com/${caminho}`, {
        method: corpo ? "POST" : "GET",
        headers: {
            "Authorization": `Bearer ${token?.access_token}`,
            "x-goog-user-project": projeto,
            "Content-Type": "application/json",
        },
        body: corpo ? JSON.stringify(corpo) : undefined,
    });
    if (!resposta.ok) throw new Error(`${caminho.split("?")[0]} respondeu ${resposta.status}`);
    return await resposta.json() as T;
}

async function main(): Promise<void> {
    const opcoes = parseArgs(process.argv.slice(2));
    const credential = admin.credential.applicationDefault();
    const origem = admin.initializeApp({ credential, projectId: opcoes.origem }, "origem");
    const destino = admin.initializeApp({ credential, projectId: opcoes.destino }, "destino");

    const usuarios: UsuarioBruto[] = [];
    let pagina: string | undefined;
    do {
        const lote = await chamar<{ users?: UsuarioBruto[]; nextPageToken?: string }>(origem, opcoes.origem,
            `v1/projects/${opcoes.origem}/accounts:batchGet?maxResults=500${pagina ? `&nextPageToken=${pagina}` : ""}`);
        usuarios.push(...(lote.users ?? []));
        pagina = lote.nextPageToken;
    } while (pagina);

    const comSenha = usuarios.filter((u) => u.passwordHash).length;
    const comGoogle = usuarios.filter((u) =>
        (u.providerUserInfo as { providerId?: string }[] | undefined)?.some((p) => p.providerId === "google.com")).length;
    console.log(`${usuarios.length} usuários em ${opcoes.origem}: ${comSenha} com senha, ${comGoogle} com Google.`);

    if (!opcoes.aplicar) {
        console.log("Simulação: nada foi gravado.");
        return;
    }

    const config = await chamar<{ signIn?: { hashConfig?: HashConfig } }>(
        origem, opcoes.origem, `admin/v2/projects/${opcoes.origem}/config`);
    const hash = config.signIn?.hashConfig ?? {};
    if (comSenha > 0 && (hash.algorithm !== "SCRYPT" || !hash.signerKey)) {
        throw new Error("a origem tem usuários com senha, mas a configuração do hash não pôde ser lida");
    }

    const resultado = await chamar<{ error?: { index: number; message: string }[] }>(
        destino, opcoes.destino, `v1/projects/${opcoes.destino}/accounts:batchCreate`, {
            users: usuarios.map(paraImportar),
            allowOverwrite: true,
            hashAlgorithm: "SCRYPT",
            signerKey: hash.signerKey,
            saltSeparator: hash.saltSeparator,
            rounds: hash.rounds,
            memoryCost: hash.memoryCost,
        });
    const falhas = resultado.error ?? [];
    console.log(`Importados: ${usuarios.length - falhas.length}. Falhas: ${falhas.length}.`);
    for (const falha of falhas) console.log(`  usuário ${falha.index}: ${falha.message}`);

    // Perfis.
    const perfis = await origem.firestore().collection("users").get();
    const batch = destino.firestore().batch();
    for (const doc of perfis.docs) {
        const d = doc.data();
        batch.set(destino.firestore().collection("usuarios").doc(doc.id), {
            email: d.email ?? null,
            nome: d.displayName ?? null,
            foto: d.photoUrl ?? null,
            criadoEm: d.createdAt ?? null,
        });
    }
    await batch.commit();
    console.log(`Perfis copiados: ${perfis.size}.`);
    if (falhas.length > 0) process.exitCode = 1;
}

if (require.main === module) {
    main().catch((error) => {
        console.error(error instanceof Error ? error.message : error);
        process.exit(1);
    });
}
