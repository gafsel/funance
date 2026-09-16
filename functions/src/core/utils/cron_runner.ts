/**
 * Varredura paginada de workspaces para os crons (F5.5).
 *
 * Os três crons que tocam TODOS os workspaces (coaching semanal, gamificação
 * semanal e mensal) liam a coleção de workspaces INTEIRA para a memória e
 * depois faziam um `for` sequencial com `await` por workspace, tudo dentro de
 * um timeout de função. Isso tem três problemas que só pioram
 * com a base crescendo:
 *
 * 1. a lista inteira na memória da instância;
 * 2. o tempo total é a SOMA de todos os workspaces, em série;
 * 3. quando o timeout estoura, a execução morre no meio e a próxima começa
 *    **do zero** — os workspaces do fim da coleção nunca são processados.
 *
 * `forEachWorkspacePaged` resolve os três: pagina por `documentId()`
 * ascendente, processa com concorrência limitada, grava checkpoint a cada
 * lote e PARA antes do deadline, retomando do ponto exato na execução
 * seguinte. Ao terminar a varredura, o checkpoint é zerado e a próxima
 * execução recomeça do início.
 */

import * as admin from "firebase-admin";

/**
 * Documento ÚNICO com o checkpoint de cada cron, um campo por chave
 * (`config/cron_checkpoints`, campo `{checkpointKey}`). Um documento por cron
 * seria uma subcoleção sob um documento que não existe; um mapa de campos dá o
 * mesmo endereço lógico com uma leitura só.
 *
 * Fechado para o cliente pelo `match /{document=**} { allow read, write: if false }`
 * das security rules — nada em `config/` é exposto.
 */
export const CRON_CHECKPOINT_COLLECTION = "config";
export const CRON_CHECKPOINT_DOC_ID = "cron_checkpoints";

export interface CronCheckpoint {
    /** Último workspace processado com sucesso (ou com falha registrada). */
    lastWorkspaceId: string;
    updatedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface ForEachWorkspacePagedOptions {
    /** Identifica o cron no documento de checkpoint. Deve ser estável. */
    checkpointKey: string;
    /** Workspaces lidos por página (uma query do Firestore). */
    pageSize?: number;
    /** Quantos workspaces são processados em paralelo dentro de uma página. */
    concurrency?: number;
    /**
     * Orçamento de tempo em ms, contado a partir da chamada. Deve ser o
     * timeout da function MENOS uma margem que caiba o último lote.
     */
    deadlineMs: number;
    /** Injeção de relógio (testes). */
    now?: () => number;
}

export interface WorkspaceScanResult {
    /** Workspaces em que `fn` rodou até o fim sem lançar. */
    processed: number;
    /** Workspaces em que `fn` lançou (o erro foi logado e isolado). */
    failed: number;
    /** true quando a coleção acabou; false quando parou pelo deadline. */
    completed: boolean;
    /** Onde a varredura parou (null quando completou e zerou o checkpoint). */
    lastWorkspaceId: string | null;
    /** Checkpoint de onde esta execução retomou (null = começou do início). */
    resumedFrom: string | null;
}

const DEFAULT_PAGE_SIZE = 50;
const DEFAULT_CONCURRENCY = 5;

/**
 * Executa `fn` para cada workspace, em páginas, com concorrência limitada,
 * checkpoint e parada por deadline.
 *
 * `fn` que lança NÃO derruba a varredura: o erro é logado, contado em `failed`
 * e o workspace é considerado consumido (o checkpoint avança). Um workspace
 * com dado corrompido não pode travar o cron para todos os outros, execução
 * após execução.
 */
export async function forEachWorkspacePaged(
    options: ForEachWorkspacePagedOptions,
    fn: (workspaceId: string) => Promise<void>
): Promise<WorkspaceScanResult> {
    const pageSize = Math.max(1, options.pageSize ?? DEFAULT_PAGE_SIZE);
    const concurrency = Math.max(1, options.concurrency ?? DEFAULT_CONCURRENCY);
    const now = options.now ?? Date.now;
    const deadlineAt = now() + options.deadlineMs;

    const resumedFrom = await readCheckpoint(options.checkpointKey);
    let cursor = resumedFrom;
    let processed = 0;
    let failed = 0;
    let completed = false;

    if (resumedFrom) {
        console.log(`[cron_runner:${options.checkpointKey}] retomando depois de ${resumedFrom}.`);
    }

    while (now() < deadlineAt) {
        let query = admin.firestore()
            .collection("workspaces")
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pageSize);

        if (cursor) {
            query = query.startAfter(cursor);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
            completed = true;
            break;
        }

        const ids = snapshot.docs.map((doc) => doc.id);
        let consumedInPage = 0;

        // Limitador de concorrência sem dependência nova: lotes de tamanho
        // `concurrency`, com o deadline verificado antes de cada lote. O
        // checkpoint avança por lote, então um timeout no meio da página
        // reprocessa no máximo `concurrency` workspaces.
        for (let start = 0; start < ids.length; start += concurrency) {
            if (now() >= deadlineAt) break;

            const batch = ids.slice(start, start + concurrency);
            const results = await Promise.allSettled(batch.map((id) => fn(id)));

            results.forEach((result, index) => {
                if (result.status === "fulfilled") {
                    processed++;
                }
                else {
                    failed++;
                    console.error(
                        `[cron_runner:${options.checkpointKey}] falha no workspace ${batch[index]}:`,
                        result.reason
                    );
                }
            });

            consumedInPage += batch.length;
            cursor = batch[batch.length - 1];
            await writeCheckpoint(options.checkpointKey, cursor);
        }

        // Página interrompida pelo deadline: o resto dela fica para a próxima.
        if (consumedInPage < ids.length) break;

        // Página incompleta significa fim da coleção.
        if (ids.length < pageSize) {
            completed = true;
            break;
        }
    }

    if (completed) {
        await clearCheckpoint(options.checkpointKey);
    }
    else if (cursor) {
        console.warn(
            `[cron_runner:${options.checkpointKey}] deadline atingido em ${cursor}; ` +
            "a próxima execução retoma daí."
        );
    }

    return {
        processed,
        failed,
        completed,
        lastWorkspaceId: completed ? null : cursor,
        resumedFrom,
    };
}

function checkpointDoc(): FirebaseFirestore.DocumentReference {
    return admin.firestore()
        .collection(CRON_CHECKPOINT_COLLECTION)
        .doc(CRON_CHECKPOINT_DOC_ID);
}

/**
 * Lê o checkpoint. Falha de leitura não pode impedir o cron de rodar: nesse
 * caso a varredura começa do início, que é correto — só custa reprocessar.
 */
async function readCheckpoint(checkpointKey: string): Promise<string | null> {
    try {
        const snapshot = await checkpointDoc().get();
        const last = snapshot.data()?.[checkpointKey]?.lastWorkspaceId;
        return typeof last === "string" && last.length > 0 ? last : null;
    }
    catch (error) {
        console.error(`[cron_runner:${checkpointKey}] falha ao ler o checkpoint; começando do início:`, error);
        return null;
    }
}

/**
 * Grava o checkpoint. Best-effort: se falhar, a varredura segue — o pior caso
 * é a próxima execução recomeçar do início.
 */
async function writeCheckpoint(checkpointKey: string, lastWorkspaceId: string): Promise<void> {
    try {
        await checkpointDoc().set(
            {
                [checkpointKey]: {
                    lastWorkspaceId,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            },
            { merge: true }
        );
    }
    catch (error) {
        console.error(`[cron_runner:${checkpointKey}] falha ao gravar o checkpoint:`, error);
    }
}

/** Zera o checkpoint ao completar a varredura (a próxima começa do início). */
async function clearCheckpoint(checkpointKey: string): Promise<void> {
    try {
        await checkpointDoc().set(
            { [checkpointKey]: admin.firestore.FieldValue.delete() },
            { merge: true }
        );
    }
    catch (error) {
        console.error(`[cron_runner:${checkpointKey}] falha ao zerar o checkpoint:`, error);
    }
}
