/**
 * Reconstrói os derivados de um espaço do Funances 2 (movimento por dia,
 * resumos mensais e totais das faturas) a partir dos lançamentos.
 *
 * Sem `--aplicar`, só compara o que está gravado com o que deveria estar:
 * serve de teste do motor. Rode com o espaço parado.
 *
 * Uso:
 *   cd functions && npm run build
 *   node lib/scripts/reconstruir_espaco.js --project=<projeto> \
 *     (--espaco=<id> | --todos) [--aplicar]
 */

import * as admin from "firebase-admin";
import { RAIZ } from "../features/nucleo/domain/models/modelo";
import { ReconstrucaoService } from "../features/nucleo/domain/services/reconstrucao.service";

export interface Opcoes {
    projeto: string;
    espacos: string[];
    todos: boolean;
    aplicar: boolean;
}

export function parseArgs(argv: string[], env: NodeJS.ProcessEnv = process.env): Opcoes {
    const valor = (nome: string): string[] =>
        argv.filter((a) => a.startsWith(`--${nome}=`)).map((a) => a.slice(nome.length + 3));
    const opcoes: Opcoes = {
        projeto: valor("project")[0] ?? env.GOOGLE_CLOUD_PROJECT ?? "",
        espacos: valor("espaco"),
        todos: argv.includes("--todos"),
        aplicar: argv.includes("--aplicar"),
    };
    if (!opcoes.projeto) throw new Error("informe --project=<projeto>");
    if (opcoes.todos === (opcoes.espacos.length > 0)) throw new Error("informe --espaco=<id> ou --todos (um dos dois)");
    return opcoes;
}

async function main(): Promise<void> {
    const opcoes = parseArgs(process.argv.slice(2));
    if (!admin.apps.length) {
        admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: opcoes.projeto });
    }
    const firestore = admin.firestore();
    firestore.settings({ ignoreUndefinedProperties: false });

    const ids = opcoes.todos ?
        (await firestore.collection(RAIZ).select().get()).docs.map((d) => d.id) :
        opcoes.espacos;
    const servico = new ReconstrucaoService(firestore);

    let comDivergencia = 0;
    for (const id of ids) {
        const r = await servico.reconstruir(id, { aplicar: opcoes.aplicar });
        console.log(`[${id}] ${r.lancamentos} lançamentos, ${r.ilegiveis.length} ilegíveis, ` +
            `${r.divergencias.length} divergências${r.aplicado ? " (corrigidas)" : ""}`);
        for (const d of r.divergencias.slice(0, 20)) {
            console.log(`    ${d.doc} ${d.campo}: gravado ${d.gravado}, calculado ${d.calculado}`);
        }
        if (r.divergencias.length > 0) comDivergencia++;
    }
    if (comDivergencia > 0 && !opcoes.aplicar) process.exitCode = 1;
}

if (require.main === module) {
    main().catch((error) => {
        console.error(error);
        process.exit(1);
    });
}
