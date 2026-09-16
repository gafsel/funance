import * as admin from "firebase-admin";

/**
 * O Firestore aceita no máximo 500 operações por `WriteBatch`. Usamos 400 como
 * padrão para deixar folga e nunca esbarrar no limite duro.
 */
export const DEFAULT_CHUNK_SIZE = 400;

/**
 * Operação de escrita a ser aplicada em lote. Uma `DocumentReference` "pelada"
 * é interpretada como `delete` (caso mais comum nos repositórios).
 */
export type BatchOperation =
    | { op: "delete"; ref: admin.firestore.DocumentReference }
    | { op: "update"; ref: admin.firestore.DocumentReference; data: Record<string, any> }
    | { op: "set"; ref: admin.firestore.DocumentReference; data: Record<string, any>; options?: admin.firestore.SetOptions };

export type BatchInput = admin.firestore.DocumentReference | BatchOperation;

function toOperation(input: BatchInput): BatchOperation {
    if ("op" in input) {
        return input;
    }
    return { op: "delete", ref: input };
}

/**
 * Aplica as operações em batches de no máximo `chunkSize` writes, commitando
 * um batch de cada vez. Sem isso, coleções grandes estouram o limite de 500
 * operações e o commit falha por inteiro (nada é escrito).
 *
 * Retorna a quantidade de operações efetivamente commitadas.
 */
export async function commitInChunks(
    firestore: admin.firestore.Firestore,
    refsOrOps: BatchInput[],
    chunkSize: number = DEFAULT_CHUNK_SIZE
): Promise<number> {
    if (refsOrOps.length === 0) {
        return 0;
    }

    const size = Math.max(1, Math.min(chunkSize, 500));
    let committed = 0;

    for (let i = 0; i < refsOrOps.length; i += size) {
        const chunk = refsOrOps.slice(i, i + size);
        const batch = firestore.batch();

        for (const input of chunk) {
            const operation = toOperation(input);
            if (operation.op === "delete") {
                batch.delete(operation.ref);
            }
            else if (operation.op === "update") {
                batch.update(operation.ref, operation.data);
            }
            else {
                if (operation.options) {
                    batch.set(operation.ref, operation.data, operation.options);
                }
                else {
                    batch.set(operation.ref, operation.data);
                }
            }
        }

        await batch.commit();
        committed += chunk.length;
    }

    return committed;
}

/**
 * Apaga todos os documentos que casam com a query, paginando de `chunkSize` em
 * `chunkSize`. Como os documentos lidos são apagados a cada volta, a própria
 * query serve de cursor e o laço termina quando a página vem vazia.
 *
 * Retorna a quantidade de documentos apagados.
 */
export async function deleteByQueryInChunks(
    firestore: admin.firestore.Firestore,
    query: admin.firestore.Query,
    chunkSize: number = DEFAULT_CHUNK_SIZE
): Promise<number> {
    const size = Math.max(1, Math.min(chunkSize, 500));
    let deleted = 0;

    for (;;) {
        const snapshot = await query.limit(size).get();
        if (snapshot.empty) {
            break;
        }

        await commitInChunks(firestore, snapshot.docs.map((doc) => doc.ref), size);
        deleted += snapshot.size;

        if (snapshot.size < size) {
            break;
        }
    }

    return deleted;
}
