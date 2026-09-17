/**
 * Remoção EXPLÍCITA de `undefined` antes de gravar no Firestore.
 *
 * O projeto rodava com `ignoreUndefinedProperties: true`, que faz o SDK
 * descartar em silêncio qualquer chave com valor `undefined`. Era conveniente e
 * perigoso ao mesmo tempo: um campo que o servidor deveria escrever e que veio
 * `undefined` por um erro de tipagem simplesmente NÃO IA para o documento, sem
 * erro, sem log e sem teste quebrando — o defeito só aparecia semanas depois,
 * como um campo ausente no app.
 *
 * Desligada a opção (F1.11), gravar `undefined` passa a lançar. Onde o
 * `undefined` é LEGÍTIMO — um `Partial<Model>` com campos opcionais ausentes,
 * um modelo cujo campo só existe em fatura —, o descarte continua valendo, mas
 * agora é uma decisão escrita no código: `stripUndefined`.
 *
 * O que a função NÃO faz, de propósito:
 *
 * - não transforma `undefined` em `null` (isso mudaria o documento: `null` é um
 *   valor gravado, `undefined` é a ausência da chave);
 * - não entra em objetos que não sejam literais: `Timestamp`, `Date`,
 *   `FieldValue` (`increment`, `serverTimestamp`, `delete`, `arrayUnion`),
 *   `DocumentReference`, `GeoPoint` e `Buffer` são sentinelas/valores do SDK e
 *   precisam chegar INTACTOS — recriá-los como objeto literal os destruiria.
 */

/** Objeto literal (`{...}`), e não uma instância de classe do SDK. */
function isPlainObject(value: unknown): value is Record<string, unknown> {
    if (value === null || typeof value !== "object") return false;
    const prototype = Object.getPrototypeOf(value);
    return prototype === Object.prototype || prototype === null;
}

/**
 * Devolve uma cópia sem as chaves cujo valor é `undefined`, recursivamente
 * (inclusive dentro de arrays de objetos literais).
 *
 * O valor devolvido é uma cópia: o objeto recebido não é alterado, porque ele
 * costuma ser o modelo que o chamador ainda vai usar depois da escrita.
 */
export function stripUndefined<T>(value: T): T {
    if (Array.isArray(value)) {
        return value.map((item) => stripUndefined(item)) as unknown as T;
    }

    if (!isPlainObject(value)) {
        return value;
    }

    const result: Record<string, unknown> = {};
    for (const [key, item] of Object.entries(value)) {
        if (item === undefined) continue;
        result[key] = stripUndefined(item);
    }
    return result as T;
}

/**
 * Um `Timestamp` do Firestore, visto pela única coisa que interessa a quem lê:
 * `toDate()`. Estrutural de propósito — os mocks dos testes unitários fingem um
 * Timestamp com `{ toDate: () => new Date(...) }` e precisam continuar servindo.
 */
export interface TimestampLike {
    toDate(): Date;
}

/**
 * Uma data como ela CHEGA de um documento cru.
 *
 * O mesmo campo pode ser `Timestamp` (escrito pelo servidor), `Date` (escrito
 * pelo Admin SDK sem conversão), string ISO (escrito pelo cliente antigo) ou
 * um epoch em milissegundos. Declarar a união é o que impede o código de
 * assumir uma das formas e quebrar nas outras — que foi exatamente o defeito
 * que `toGoalDate` e seus irmãos existem para tratar.
 */
export type RawFirestoreDate = TimestampLike | Date | string | number;
