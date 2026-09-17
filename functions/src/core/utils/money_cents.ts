/**
 * F1.10, etapa B — O PASSO DERIVADO: completar os `*Cents` do que o CLIENTE
 * escreve.
 *
 * O servidor grava sempre o par (inteiro + espelho `round2`) em tudo que ele
 * escreve. Mas `orders`, `installments`, `accounts`, `goals` e
 * `category_planning` também são escritos pelo APP, que nesta etapa ainda só
 * conhece o `double`. Uma order criada pelo app nasceria com `amount` e sem
 * `amountCents`, e o inteiro — que é a fonte da verdade — ficaria em branco
 * justamente no documento mais novo.
 *
 * A solução é um passo derivado no gatilho de cada coleção: depois de tudo o
 * mais, o handler compara os `*Cents` com o que o `double` diz e completa o que
 * faltar. Três propriedades, todas obrigatórias:
 *
 *  1. **Idempotente**: calcular duas vezes dá o mesmo patch;
 *  2. **Só escreve se MUDAR**: um documento já correto não gera escrita — e sem
 *     isso o gatilho se realimentaria para sempre;
 *  3. **Não dispara o gatilho de novo**: os campos `*Cents` estão nas guardas
 *     por conteúdo (`INSTALLMENT_DERIVED_FIELDS`, `ORDER_DERIVED_FIELDS`,
 *     `GOAL_DERIVED_FIELDS`, `CATEGORY_PLANNING_DERIVED_FIELDS`), então o
 *     evento que esta escrita produz sai cedo.
 *
 * Fora da idempotência por `eventId_action` de propósito: reexecutar o passo é
 * inofensivo (é uma função do conteúdo do documento, não um incremento), e ele
 * não pode ser pulado porque o marcador daquele evento já existia.
 *
 * O que ele NÃO faz: nunca corrige o `double` a partir do inteiro. Nesta etapa
 * o app ainda escreve o `double`, e sobrescrevê-lo seria o servidor discordando
 * do usuário. Quem reconcilia os dois é o `rebuild_workspace`.
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { readCents, toCents } from "./money";

/** Mapa `campo double` -> `campo inteiro` de uma coleção. */
export type CentsFieldMap = Readonly<Record<string, string>>;

/**
 * Patch com os `*Cents` que faltam ou divergem — ou `null` quando o documento
 * já está correto.
 *
 * Regras de cada campo:
 *  - `double` ausente/`null`/não numérico: o inteiro correspondente também não
 *    deve existir. Ausente continua significando ausente, nunca zero — um
 *    `paidAmountCents: 0` numa parcela não paga mentiria dizendo que ela foi
 *    paga com valor zero. Se o inteiro existir sozinho, ele é APAGADO;
 *  - `double` presente: o inteiro tem de ser `toCents(double)`. Diferente,
 *    fracionário, sujo ou ausente — é reescrito.
 */
export function buildCentsPatch(
    data: Record<string, unknown> | null | undefined,
    fields: CentsFieldMap
): Record<string, unknown> | null {
    if (!data) return null;

    const patch: Record<string, unknown> = {};

    for (const [valueField, centsField] of Object.entries(fields)) {
        const raw = data[valueField];
        const current = data[centsField];

        if (typeof raw !== "number" || !Number.isFinite(raw)) {
            // O `double` não existe: o inteiro pendurado é resíduo.
            if (current !== undefined && current !== null) {
                patch[centsField] = admin.firestore.FieldValue.delete();
            }
            continue;
        }

        const expected = toCents(raw);
        if (readCents(current) !== expected) {
            patch[centsField] = expected;
        }
    }

    return Object.keys(patch).length > 0 ? patch : null;
}

/**
 * O MESMO documento, com todos os `*Cents` recalculados a partir do `double`.
 *
 * **O defeito que esta função conserta.** O payload de um evento do Firestore é
 * o documento como ele estava NAQUELE instante. Quando o app edita um valor
 * (`amount: 500 → 1000`) sem tocar no espelho, o `afterData` chega com
 * `amount: 1000` e `amountCents: 50000` — o inteiro ANTIGO. O passo derivado
 * conserta o BANCO (`applyCentsPatch`), mas o objeto em memória continua
 * mentindo, e toda a regra de negócio abaixo dele usa `resolveCents`, que
 * **prefere o inteiro**. O resultado é o gatilho processar o valor velho: o
 * planejamento aplicava 500 nos sumários e gravava `appliedAmount: 500` para
 * uma edição de 1000, e o segundo evento (só o espelho) saía pela guarda por
 * conteúdo sem corrigir nada.
 *
 * A normalização é EM MEMÓRIA e vale para os dois lados do evento: o `before`
 * também pode carregar um espelho defasado, se o evento anterior àquele ainda
 * não tinha sido patchado. Quem estorna precisa do valor que de fato valia.
 *
 * Por que não relaxar o `resolveCents` para só preferir o inteiro quando ele
 * bate com o `double`: isso apagaria o sinal. A divergência entre os dois é
 * exatamente o que o `--verify` da migração existe para denunciar, e um
 * `resolveCents` tolerante faria toda divergência virar "o double ganha", em
 * silêncio, em todo lugar. Aqui o escopo é outro e é explícito: o payload de um
 * evento, onde a divergência tem uma causa conhecida e inofensiva.
 *
 * Devolve uma CÓPIA — o payload do evento não é alterado — ou `null`/`undefined`
 * quando a entrada é `null`/`undefined`, para o chamador não precisar
 * distinguir "documento apagado" de "documento sem dinheiro".
 */
export function withFreshCents<T extends Record<string, any> | null | undefined>(
    data: T,
    fields: CentsFieldMap
): T {
    if (!data) return data;

    const fresh: Record<string, unknown> = { ...data };

    for (const [valueField, centsField] of Object.entries(fields)) {
        const raw = fresh[valueField];

        if (typeof raw !== "number" || !Number.isFinite(raw)) {
            // Ausente continua ausente: um inteiro pendurado sem o `double`
            // correspondente é resíduo e não pode responder por ninguém.
            delete fresh[centsField];
            continue;
        }

        fresh[centsField] = toCents(raw);
    }

    return fresh as T;
}

/**
 * Aplica o patch derivado no documento, quando há o que aplicar.
 *
 * `update` (e não `set(..., {merge: true})`): o passo derivado NUNCA cria um
 * documento. Se o documento for apagado entre o evento e esta escrita, ele
 * lança `NOT_FOUND` (gRPC 5) e nós saímos calados — ressuscitar uma order
 * apagada com um único campo seria pior do que não completar o inteiro.
 *
 * Devolve `true` quando algo foi escrito.
 */
export async function applyCentsPatch(
    ref: admin.firestore.DocumentReference,
    data: Record<string, unknown> | null | undefined,
    fields: CentsFieldMap,
    label: string
): Promise<boolean> {
    const patch = buildCentsPatch(data, fields);
    if (!patch) return false;

    try {
        await ref.update(patch);
        logger.debug(`[${label}] espelhos inteiros completados em ${ref.path}: ${Object.keys(patch).join(", ")}.`);
        return true;
    }
    catch (error: unknown) {
        // gRPC 5 = NOT_FOUND: o documento sumiu entre o evento e a escrita.
        if ((error as { code?: number } | null)?.code === 5) {
            logger.debug(`[${label}] ${ref.path} não existe mais; espelhos inteiros descartados.`);
            return false;
        }
        // Falhar aqui não pode derrubar o gatilho: o resto do evento (sumário,
        // saldo, meta, XP) já rodou, e a `migrate_money_cents` é a segunda rede.
        logger.warn(`[${label}] falha ao completar os espelhos inteiros de ${ref.path}: ${error}`);
        return false;
    }
}
