/**
 * Limites de tamanho dos documentos enviados para a IA (F5.4).
 *
 * Um extrato/fatura chega como PDF ou imagem e era embutido no prompt em
 * base64 (`inlineData`). Base64 infla o arquivo em ~33%, e o payload inteiro
 * ainda precisa caber no limite de request do Gemini e na memória da function
 * — um PDF de 15 MB virava ~20 MB de string dentro do processo.
 *
 * Duas fronteiras:
 * - **10 MB**: teto absoluto. Acima disso a callable recusa com
 *   `invalid-argument` e uma mensagem que diz o que fazer.
 * - **4 MB**: até aí o arquivo vai inline (um round-trip a menos). Acima,
 *   sobe pela Files API do Gemini e o prompt referencia só a URI.
 */

import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

const MB = 1024 * 1024;

/** Teto absoluto do arquivo aceito pelas callables de documento. */
export const MAX_DOCUMENT_BYTES = 10 * MB;

/** Até este tamanho o arquivo viaja inline (base64) no próprio prompt. */
export const INLINE_DOCUMENT_MAX_BYTES = 4 * MB;

/** "12,4 MB" — com vírgula, que é o separador decimal em português. */
export function formatMegabytes(bytes: number): string {
    return `${(bytes / MB).toFixed(1).replace(".", ",")} MB`;
}

export function documentTooLargeMessage(bytes: number): string {
    return `O arquivo tem ${formatMegabytes(bytes)} e o limite para análise é de ` +
        `${formatMegabytes(MAX_DOCUMENT_BYTES)}. Envie um período menor (um mês por vez) ` +
        "ou o arquivo OFX do seu banco, que é bem mais leve.";
}

/** Recusa o documento acima do teto. Lança `invalid-argument`. */
export function assertDocumentWithinLimit(bytes: number): void {
    if (!Number.isFinite(bytes) || bytes <= 0) {
        throw new HttpsError("invalid-argument", "O arquivo enviado está vazio ou não pôde ser lido.");
    }
    if (bytes > MAX_DOCUMENT_BYTES) {
        throw new HttpsError("invalid-argument", documentTooLargeMessage(bytes));
    }
}

/**
 * Checa o tamanho do arquivo no Storage lendo APENAS os metadados.
 *
 * Roda no handler, antes de consumir cota e antes de baixar o arquivo: um
 * upload de 40 MB não pode custar uma unidade de cota nem a memória do
 * download. Devolve o tamanho em bytes.
 */
export async function assertStoredDocumentWithinLimit(storagePath: string): Promise<number> {
    const normalizedPath = storagePath.replace(/\/+/g, "/");
    const file = admin.storage().bucket().file(normalizedPath);

    const [exists] = await file.exists();
    if (!exists) {
        throw new HttpsError("not-found", "Arquivo não encontrado no storage. Envie o documento novamente.");
    }

    const [metadata] = await file.getMetadata();
    const size = Number(metadata?.size ?? 0);
    assertDocumentWithinLimit(size);
    return size;
}
