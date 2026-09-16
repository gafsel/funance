/**
 * Comparação profunda de payloads do Firestore.
 *
 * Um documento lido de um evento pode trazer `Timestamp`, `Date`, mapas
 * aninhados e arrays. `JSON.stringify` cru não serve: dois `Timestamp` iguais
 * serializam para objetos `{_seconds, _nanoseconds}` que às vezes diferem de um
 * `Date` equivalente, e a ordem das chaves de um mapa não é estável.
 *
 * `normalizeForComparison` reduz tudo a uma forma canônica:
 *  - `Timestamp`/`Date` viram `@date:<millis>`;
 *  - chaves de objeto são ordenadas;
 *  - `undefined` e `null` são equivalentes (campo ausente == campo nulo), e
 *    chaves nulas somem — é assim que o Firestore se comporta com
 *    `ignoreUndefinedProperties`.
 */
export function normalizeForComparison(value: any): any {
    if (value === null || value === undefined) return null;

    if (typeof value === "object") {
        // Timestamp do Firestore (e qualquer coisa com toDate()).
        if (typeof value.toDate === "function") {
            const date = value.toDate();
            return date instanceof Date && !Number.isNaN(date.getTime()) ? `@date:${date.getTime()}` : null;
        }

        if (value instanceof Date) {
            return Number.isNaN(value.getTime()) ? null : `@date:${value.getTime()}`;
        }

        if (Array.isArray(value)) {
            return value.map(normalizeForComparison);
        }

        const normalized: Record<string, any> = {};
        for (const key of Object.keys(value).sort()) {
            const entry = normalizeForComparison(value[key]);
            if (entry === null) continue;
            normalized[key] = entry;
        }
        return normalized;
    }

    return value;
}

/** Igualdade profunda usando a forma canônica acima. */
export function deepEquals(a: any, b: any): boolean {
    return JSON.stringify(normalizeForComparison(a)) === JSON.stringify(normalizeForComparison(b));
}

/**
 * Campos de primeiro nível cujo valor mudou entre `before` e `after`.
 * Campos presentes em apenas um dos lados contam como mudança (a menos que o
 * valor seja nulo dos dois lados).
 */
export function getChangedFields(
    before: Record<string, any> | null | undefined,
    after: Record<string, any> | null | undefined
): string[] {
    const beforeData = before || {};
    const afterData = after || {};

    const keys = new Set([...Object.keys(beforeData), ...Object.keys(afterData)]);
    const changed: string[] = [];

    for (const key of keys) {
        if (!deepEquals(beforeData[key], afterData[key])) {
            changed.push(key);
        }
    }

    return changed.sort();
}
