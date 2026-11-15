/**
 * Migração do app antigo para o Funances 2, entre dois projetos Firebase.
 *
 * Lê os workspaces do projeto de ORIGEM, transforma no modelo novo, confere
 * os números ao centavo e escreve um relatório por workspace. Por padrão só
 * simula: nada é gravado em lugar nenhum. Com `--aplicar`, carrega o resultado
 * em `espacos/{id}` do projeto de DESTINO e reconstrói os derivados.
 *
 * O projeto de origem nunca é gravado: este script só chama leituras nele.
 * O projeto antigo (`funance-cef1b`) é recusado como destino.
 *
 * Uso:
 *   cd functions && npm run build
 *   node lib/scripts/migrar_funances2.js --origem=funance-cef1b \
 *     --destino=funances2-testes (--workspace=<id> | --todos) [--aplicar]
 *
 * Flags:
 *   --origem=<projeto>       projeto do app antigo (só leitura)
 *   --destino=<projeto>      projeto do Funances 2 (só usado com --aplicar)
 *   --workspace=<id>         um workspace; pode repetir
 *   --todos                  todos os workspaces da origem
 *   --relatorios=<pasta>     onde gravar os relatórios (padrão: relatorios-migracao)
 *   --hoje=<YYYY-MM-DD>      data de referência (padrão: hoje no fuso do produto)
 *   --aplicar                grava no destino
 *   --espera=<segundos>      com --aplicar num projeto com os gatilhos do motor
 *                            publicados, espera e confere de novo (use 30)
 *   --mesmo-com-diferencas   com --aplicar, carrega mesmo havendo diferença
 *                            sem explicação ou problema (para inspecionar)
 *
 * Credenciais: Application Default Credentials com acesso de leitura à origem
 * e de escrita ao destino.
 *
 * Os relatórios contêm dados financeiros reais e não devem ser versionados.
 */

import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import { commitInChunks, BatchOperation } from "../core/utils/batch.utils";
import { isDateKey, toDateKey } from "../core/utils/date_key";
import { stripUndefined } from "../core/utils/firestore.utils";
import { RAIZ } from "../features/nucleo/domain/models/modelo";
import { ReconstrucaoService } from "../features/nucleo/domain/services/reconstrucao.service";
import { conferir, relatorio } from "../features/nucleo/migracao/conferir";
import { lerWorkspace, listarWorkspaces } from "../features/nucleo/migracao/ler_antigo";
import { documentos, transformar } from "../features/nucleo/migracao/transformar";

/** Projetos que nunca podem receber escrita deste script. */
export const DESTINOS_PROIBIDOS = ["funance-cef1b"];

export interface Opcoes {
    origem: string;
    destino: string | null;
    workspaces: string[];
    todos: boolean;
    relatorios: string;
    hoje: string;
    aplicar: boolean;
    mesmoComDiferencas: boolean;
    /** Espera entre verificações depois da carga, para os gatilhos assentarem. */
    esperaSegundos: number;
}

export function parseArgs(argv: string[], agora: Date = new Date()): Opcoes {
    const valor = (nome: string): string[] =>
        argv.filter((a) => a.startsWith(`--${nome}=`)).map((a) => a.slice(nome.length + 3));

    const opcoes: Opcoes = {
        origem: valor("origem")[0] ?? "",
        destino: valor("destino")[0] ?? null,
        workspaces: valor("workspace"),
        todos: argv.includes("--todos"),
        relatorios: valor("relatorios")[0] ?? "relatorios-migracao",
        hoje: valor("hoje")[0] ?? toDateKey(agora),
        aplicar: argv.includes("--aplicar"),
        mesmoComDiferencas: argv.includes("--mesmo-com-diferencas"),
        esperaSegundos: Number(valor("espera")[0] ?? 0) || 0,
    };

    if (!opcoes.origem) throw new Error("informe --origem=<projeto>");
    if (!isDateKey(opcoes.hoje)) throw new Error("--hoje deve ser YYYY-MM-DD");
    if (opcoes.todos === (opcoes.workspaces.length > 0)) {
        throw new Error("informe --workspace=<id> ou --todos (um dos dois)");
    }
    if (opcoes.aplicar) {
        if (!opcoes.destino) throw new Error("--aplicar exige --destino=<projeto>");
        if (opcoes.destino === opcoes.origem) throw new Error("origem e destino não podem ser o mesmo projeto");
        if (DESTINOS_PROIBIDOS.includes(opcoes.destino)) {
            throw new Error(`${opcoes.destino} é o projeto antigo e não pode ser destino`);
        }
    }
    return opcoes;
}

export interface ResumoWorkspace {
    workspaceId: string;
    nome: string;
    lancamentos: number;
    problemas: number;
    avisos: number;
    semExplicacao: number;
    carregado: boolean;
}

export async function migrarWorkspace(
    origem: admin.firestore.Firestore,
    destino: admin.firestore.Firestore | null,
    workspaceId: string,
    opcoes: Opcoes,
    log: (linha: string) => void
): Promise<ResumoWorkspace> {
    const dados = await lerWorkspace(origem, opcoes.origem, workspaceId);
    const novo = transformar(dados, { hoje: opcoes.hoje });
    const conferencia = conferir(dados, novo, { hoje: opcoes.hoje });

    fs.mkdirSync(opcoes.relatorios, { recursive: true });
    const arquivo = path.join(opcoes.relatorios, `${workspaceId}.md`);
    fs.writeFileSync(arquivo, relatorio(conferencia, novo));

    const resumo: ResumoWorkspace = {
        workspaceId,
        nome: novo.espaco.nome,
        lancamentos: Object.keys(novo.lancamentos).length,
        problemas: novo.problemas.length,
        avisos: novo.avisos.length,
        semExplicacao: conferencia.semExplicacao,
        carregado: false,
    };
    log(`[${workspaceId}] ${resumo.lancamentos} lançamentos, ${resumo.problemas} problemas, ` +
        `${resumo.avisos} avisos, ${resumo.semExplicacao} diferenças sem explicação → ${arquivo}`);

    if (!opcoes.aplicar || !destino) return resumo;

    const limpo = resumo.problemas === 0 && resumo.semExplicacao === 0;
    if (!limpo && !opcoes.mesmoComDiferencas) {
        log(`[${workspaceId}] NÃO carregado: há problemas ou diferenças sem explicação.`);
        return resumo;
    }

    const espaco = destino.collection(RAIZ).doc(workspaceId);
    const existente = await espaco.get();
    if (existente.exists && existente.data()?.migradoDe?.workspaceId !== workspaceId) {
        throw new Error(`${espaco.path} já existe no destino e não veio desta migração; nada foi gravado`);
    }

    // Repetível: o espaço migrado é apagado e recriado a cada carga.
    await destino.recursiveDelete(espaco);

    const ops: BatchOperation[] = [{ op: "set", ref: espaco, data: stripUndefined({ ...novo.espaco }) }];
    for (const [caminho, doc] of Object.entries(documentos(novo))) {
        ops.push({ op: "set", ref: destino.doc(`${espaco.path}/${caminho}`), data: stripUndefined(doc) });
    }
    await commitInChunks(destino, ops);

    // Com os gatilhos do motor publicados, cada documento carregado dispara
    // um evento. A reconstrução é repetida até uma verificação, feita depois
    // da espera, não achar mais nada: aí os gatilhos já assentaram.
    const reconstrucao = new ReconstrucaoService(destino);
    await reconstrucao.reconstruir(workspaceId, { aplicar: true });
    let verificacao = await reconstrucao.reconstruir(workspaceId, { aplicar: false });
    for (let tentativa = 0; tentativa < 6 && opcoes.esperaSegundos > 0; tentativa++) {
        await new Promise((resolve) => setTimeout(resolve, opcoes.esperaSegundos * 1000));
        verificacao = await reconstrucao.reconstruir(workspaceId, { aplicar: false });
        if (verificacao.divergencias.length === 0) break;
        log(`[${workspaceId}] gatilhos ainda assentando (${verificacao.divergencias.length} divergências); reconstruindo de novo.`);
        await reconstrucao.reconstruir(workspaceId, { aplicar: true });
        verificacao = await reconstrucao.reconstruir(workspaceId, { aplicar: false });
    }
    if (verificacao.divergencias.length > 0 || verificacao.ilegiveis.length > 0) {
        throw new Error(`[${workspaceId}] derivados não fecharam após a carga: ` +
            `${verificacao.divergencias.length} divergências, ${verificacao.ilegiveis.length} lançamentos ilegíveis`);
    }

    resumo.carregado = true;
    log(`[${workspaceId}] carregado em ${opcoes.destino}: ${ops.length} documentos, derivados reconstruídos e conferidos.`);
    return resumo;
}

async function main(): Promise<void> {
    const opcoes = parseArgs(process.argv.slice(2));
    const credential = admin.credential.applicationDefault();

    const origem = admin.initializeApp({ credential, projectId: opcoes.origem }, "origem").firestore();
    let destino: admin.firestore.Firestore | null = null;
    if (opcoes.aplicar && opcoes.destino) {
        destino = admin.initializeApp({ credential, projectId: opcoes.destino }, "destino").firestore();
        destino.settings({ ignoreUndefinedProperties: false });
    }

    console.log(opcoes.aplicar ?
        `MIGRAÇÃO ${opcoes.origem} → ${opcoes.destino} (GRAVANDO no destino)` :
        `SIMULAÇÃO a partir de ${opcoes.origem} (nada é gravado)`);

    const ids = opcoes.todos ? await listarWorkspaces(origem) : opcoes.workspaces;
    const resumos: ResumoWorkspace[] = [];
    for (const id of ids) {
        resumos.push(await migrarWorkspace(origem, destino, id, opcoes, console.log));
    }

    const pendentes = resumos.filter((r) => r.problemas > 0 || r.semExplicacao > 0);
    console.log(`\n${resumos.length} workspaces; ${pendentes.length} com problema ou diferença sem explicação.`);
    if (pendentes.length > 0) process.exitCode = 1;
}

if (require.main === module) {
    main().catch((error) => {
        console.error(error);
        process.exit(1);
    });
}
