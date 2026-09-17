/**
 * DINHEIRO SEM PONTO FLUTUANTE (F1.10) — a aritmética monetária do servidor.
 *
 * O problema não é teórico. `0.1 + 0.2` vale `0.30000000000000004` em IEEE 754,
 * e o backend somava dinheiro exatamente assim: saldo diário por
 * `FieldValue.increment` de `double`, `period_summaries` por incremento de
 * `double`, total da order por `reduce(+)`. O erro não some — ele ACUMULA, e a
 * única defesa espalhada pelo código eram comparações com épsilon
 * (`Math.abs(diff) > 0.01`, `1e-9`, `0.005`), que escondem o sintoma sem tocar
 * na causa.
 *
 * A REGRA deste pacote: **todo cálculo monetário do servidor soma CENTAVOS
 * INTEIROS**; o `double` gravado é sempre o espelho `round2` do inteiro. Quem
 * precisa comparar dois valores compara os centavos, que são exatos — e por
 * isso as comparações com épsilon saem.
 *
 * ## Por que `toCents` não é `Math.round(v * 100)`
 *
 * `1.005 * 100` vale `100.49999999999999`: `Math.round` devolveria 100 centavos
 * para o que o usuário digitou como R$ 1,005. O literal decimal é a intenção;
 * o `double` é só a representação mais próxima dela. Antes de arredondar,
 * `toCents` recorta o valor escalado em 15 dígitos significativos — o bastante
 * para apagar o ruído de representação (que vive no 16º/17º dígito) e pouco o
 * bastante para não perder precisão real em valores grandes (as security rules
 * já limitam qualquer valor a ±1e12, e 1e12 × 100 = 1e14 cabe em 15 dígitos).
 *
 * `Math.round` do JavaScript arredonda meio para CIMA (`-0.5` vira `-0`), o que
 * quebraria a simetria entre um lançamento e o seu estorno: R$ -1,005 tem de
 * virar -101 centavos, não -100. Por isso o arredondamento aqui é
 * **half-away-from-zero**: o módulo é arredondado e o sinal é reposto depois.
 *
 * Tudo aqui é função PURA e sem dependência de Firestore: é a mesma aritmética
 * usada pelo gatilho, pelo cron, pelo rebuild e pelos scripts de migração.
 */

/** Centavos por unidade monetária. */
const SCALE = 100;

/**
 * Dígitos significativos preservados ao normalizar o valor escalado.
 *
 * 15 é o maior número de dígitos decimais que TODO `double` representa sem
 * ambiguidade. Acima disso o ruído de representação volta; abaixo, valores
 * grandes (R$ 12.345.678.901,23) perderiam precisão de verdade.
 */
const SIGNIFICANT_DIGITS = 15;

/**
 * Maior valor em centavos que ainda é um inteiro exato em `double`.
 * Acima disso a soma de centavos deixaria de ser confiável — e é melhor o
 * chamador saber disso do que gravar um número já corrompido.
 */
export const MAX_SAFE_CENTS = Number.MAX_SAFE_INTEGER;

/**
 * Valor monetário (reais) -> centavos INTEIROS, com arredondamento
 * half-away-from-zero e imune ao ruído de ponto flutuante.
 *
 * Valor não finito (`NaN`, `Infinity`, `undefined` já convertido) vira `0`: é a
 * mesma postura que o resto do backend adota para campo sujo em documento
 * legado (`toNumber`, `summaryNumber`) — um valor que não é número não é
 * dinheiro.
 *
 * ```
 * toCents(0.1 + 0.2) === 30      // e não 30.000000000000004
 * toCents(1.005)     === 101     // o literal decimal é a intenção
 * toCents(-1.005)    === -101    // simétrico: o estorno cancela o lançamento
 * toCents(502.40)    === 50240
 * ```
 */
export function toCents(value: number | null | undefined): number {
    if (typeof value !== "number" || !Number.isFinite(value)) return 0;

    // `toPrecision` devolve string (eventualmente em notação exponencial, que
    // `Number` reinterpreta sem perda). É o passo que transforma
    // 100.49999999999999 em 100.5 ANTES do arredondamento.
    const scaled = Number((value * SCALE).toPrecision(SIGNIFICANT_DIGITS));

    // Half-away-from-zero: `Math.round` sozinho arredonda meio para +∞, e o
    // estorno de um valor deixaria de ser o simétrico do lançamento.
    const rounded = scaled < 0 ? -Math.round(-scaled) : Math.round(scaled);

    // Normaliza `-0` para `0`: são iguais em `===`, mas o Firestore guarda os
    // dois e um diff de documento acusaria mudança onde não houve nenhuma.
    return rounded === 0 ? 0 : rounded;
}

/**
 * Centavos inteiros -> valor monetário (reais) com no máximo 2 casas.
 *
 * O resultado é sempre o `double` MAIS PRÓXIMO do decimal com duas casas — que
 * é exatamente o que `round2` devolveria. Não existe `0.30000000000000004` do
 * outro lado desta função.
 */
export function fromCents(cents: number | null | undefined): number {
    if (typeof cents !== "number" || !Number.isFinite(cents)) return 0;
    const whole = cents < 0 ? -Math.round(-cents) : Math.round(cents);
    const value = whole / SCALE;
    return value === 0 ? 0 : value;
}

/**
 * Valor monetário normalizado em 2 casas — o ESPELHO que vai para o campo
 * `double` do documento.
 *
 * Substitui as três cópias de `Math.round(value * 100) / 100` que existiam no
 * repositório de finanças, na validação de IA e nos utilitários de análise.
 * A diferença não é cosmética: `Math.round(1.005 * 100) / 100` devolve `1`, e
 * `round2(1.005)` devolve `1.01`.
 */
export function round2(value: number | null | undefined): number {
    return fromCents(toCents(value));
}

/** Soma de dois valores monetários, exata: `round2(a + b)` sem o erro do `+`. */
export function addMoney(a: number | null | undefined, b: number | null | undefined): number {
    return fromCents(toCents(a) + toCents(b));
}

/** Diferença de dois valores monetários, exata. */
export function subtractMoney(a: number | null | undefined, b: number | null | undefined): number {
    return fromCents(toCents(a) - toCents(b));
}

/**
 * Soma de uma lista de valores monetários, em centavos inteiros.
 *
 * Um milhão de parcelas de R$ 0,01 somam exatamente R$ 10.000,00 — somando os
 * `double` o resultado escorrega.
 */
export function sumMoney(values: ReadonlyArray<number | null | undefined>): number {
    return fromCents(sumCents(values));
}

/** Soma de uma lista de valores monetários, já em centavos inteiros. */
export function sumCents(values: ReadonlyArray<number | null | undefined>): number {
    let total = 0;
    for (const value of values) {
        total += toCents(value);
    }
    return total;
}

/**
 * Os dois valores representam a MESMA quantia?
 *
 * É o substituto das comparações com épsilon: em centavos inteiros não há
 * "quase igual", e `0.1 + 0.2` é igual a `0.3`.
 */
export function moneyEquals(a: number | null | undefined, b: number | null | undefined): boolean {
    return toCents(a) === toCents(b);
}

/**
 * O campo `*Cents` já gravado, quando ele é um INTEIRO confiável; `null`
 * quando está ausente, sujo ou fracionário.
 *
 * Usado por quem prefere o inteiro ao `double` (o rebuild, o verificador da
 * migração): enquanto a base não estiver migrada o campo não existe, e o
 * chamador cai no `toCents(double)`.
 */
export function readCents(value: unknown): number | null {
    if (typeof value !== "number" || !Number.isInteger(value)) return null;
    if (Math.abs(value) > MAX_SAFE_CENTS) return null;
    return value;
}

/**
 * Centavos de um par (`double` gravado, `*Cents` gravado): o inteiro é a FONTE
 * DA VERDADE quando existe; o `double` é o espelho e só responde enquanto a
 * migração não passou por aquele documento.
 */
export function resolveCents(value: number | null | undefined, cents: unknown): number {
    return readCents(cents) ?? toCents(value);
}

/**
 * Reparte `totalCents` em `count` partes inteiras, distribuindo o resto 1
 * centavo por parte nas primeiras.
 *
 * R$ 502,40 em 10x dá 10 × R$ 50,24 — e não 9 × R$ 50,24 + R$ 50,24000000001.
 * Devolve `[]` para entrada inválida, como o chamador espera.
 */
export function splitCents(totalCents: number, count: number): number[] {
    if (!Number.isFinite(totalCents) || !Number.isInteger(count) || count <= 0) {
        return [];
    }

    const total = Math.trunc(totalCents);
    // `Math.trunc` (e não `Math.floor`) para que um total NEGATIVO reparta
    // simétrico ao positivo: -100 em 3 vira [-34, -33, -33], e não
    // [-34, -33, -33] com o resto no lugar errado.
    const base = Math.trunc(total / count);
    const remainder = total - base * count;
    const step = remainder < 0 ? -1 : 1;
    const extras = Math.abs(remainder);

    return Array.from({ length: count }, (_, i) => base + (i < extras ? step : 0));
}
