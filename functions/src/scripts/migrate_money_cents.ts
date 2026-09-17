/**
 * Migração (F1.10, etapa B): preenche os espelhos INTEIROS `*Cents` em todos os
 * documentos monetários da base.
 *
 * Contexto: desde a etapa A todo cálculo do servidor soma centavos inteiros, e
 * todo documento que o SERVIDOR escreve já nasce com o par (inteiro + `double`
 * espelho). Falta o acervo: as parcelas, orders, contas, metas, planejamentos,
 * saldos e sumários que já estavam gravados — e que hoje só têm o `double`.
 * Enquanto o `*Cents` não existe, `resolveCents` cai no `double`, então nada
 * quebra; o que não existe é a garantia de exatidão que a etapa promete.
 *
 * O que ele preenche, por coleção:
 *
 * | Coleção | Campos |
 * |---|---|
 * | `orders` | `amountCents` |
 * | `installments` | `amountCents`, `paidAmountCents`, `referenceAmountCents` |
 * | `accounts` | `initialBalanceCents`, `limitCents` |
 * | `accounts/{a}/balance` | `deltaCents`, `balanceCents` |
 * | `goals` | `targetAmountCents`, `currentAmountCents` |
 * | `category_planning` | `amountCents`, `appliedAmountCents` |
 * | `period_summaries` | `generalPlannedAmountCents`, `specificPlannedAmountCents`, `actualAmountCents` (por categoria) |
 * | `accounts.nextInvoice` | `amountCents` |
 *
 * Características:
 *   - **DRY-RUN POR PADRÃO**: só escreve com `--apply`.
 *   - **IDEMPOTENTE**: um documento já correto não gera escrita nenhuma. Rodar
 *     duas vezes seguidas faz a segunda reportar zero.
 *   - **NÃO TOCA NO `double`**: o inteiro é derivado dele, nunca o contrário.
 *     Nesta etapa o app ainda escreve o `double`, e sobrescrevê-lo seria o
 *     servidor discordando do usuário. Quem reconcilia os dois é o
 *     `rebuild_workspace`.
 *   - **Ausente continua ausente**: um `paidAmount` que não existe não vira
 *     `paidAmountCents: 0` — isso diria que a parcela foi paga com valor zero.
 *   - **`--verify`**: não escreve nada; confere `|cents − round(double×100)| > 0`
 *     documento a documento e imprime a SOMA por coleção dos dois lados, para o
 *     dono comparar antes e depois.
 *   - **Checkpoint reiniciável**: guarda onde parou em
 *     `config/cron_checkpoints.moneyCentsMigrationPath`. Uma execução
 *     interrompida retoma do ponto exato; ao terminar, o checkpoint é zerado.
 *   - Escreve em lotes de no máximo 400 operações (`commitInChunks`).
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_money_cents.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces --apply
 *   # 4) Verificação (leitura pura, antes e depois):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces --verify
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --verify             só verifica: divergências + somas por coleção
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a um único workspace
 *   --all-workspaces     percorre TODOS os workspaces (padrão quando não há --workspace)
 *   --page-size=<n>      documentos lidos por página (default 500)
 *   --restart            ignora o checkpoint e recomeça do início
 */

import * as admin from "firebase-admin";
import { BatchOperation, commitInChunks, DEFAULT_CHUNK_SIZE } from "../core/utils/batch.utils";
import { classifyMoney, readCents, toCents } from "../core/utils/money";
import {
    BALANCE_CENTS_FIELDS,
    MONEY_CENTS_FIELDS,
    SUMMARY_CENTS_FIELDS,
} from "../features/finance/domain/models/finance.models";

/**
 * Campo do checkpoint em `config/cron_checkpoints` — ESTÁVEL.
 *
 * Guarda a lista de workspaces AINDA PENDENTES (os que faltam + os que
 * falharam), e não "o último concluído". A diferença não é cosmética: com um
 * marcador de avanço e um filtro `id > marcador`, um workspace que FALHA fica
 * atrás do marcador e nunca mais é visitado — a execução seguinte varre zero
 * documentos, considera a varredura completa, zera o checkpoint e sai com
 * código 0. O defeito ficaria invisível exatamente onde ele importa.
 */
export const MONEY_CENTS_CHECKPOINT_FIELD = "moneyCentsPendingWorkspaces";

const DEFAULT_PAGE_SIZE = 500;

export interface MigrateMoneyCentsOptions {
    dryRun: boolean;
    verify?: boolean;
    workspaceId?: string;
    pageSize?: number;
    restart?: boolean;
}

/** Contagem de uma coleção, com as duas somas que o `--verify` compara. */
export interface CollectionTally {
    /** Documentos lidos. */
    scanned: number;
    /** Documentos que receberiam (ou receberam) algum `*Cents`. */
    migrated: number;
    /** Documentos que já estavam corretos. */
    alreadyOk: number;
    /**
     * Documentos em que o `*Cents` GRAVADO discorda do `double`
     * (`|cents − round(double × 100)| > 0`). Zero é o esperado depois da
     * migração; qualquer outra coisa é um documento que precisa de olho.
     */
    divergent: number;
    /**
     * Campos `*Cents` pendurados sem o `double` correspondente. São resíduo e
     * a migração os APAGA — contados à parte porque não são divergência de
     * valor e, por isso, não entram nas somas.
     */
    orphans: number;
    /**
     * Campos monetários PRESENTES que não são número finito (string, booleano,
     * `NaN`). A migração NÃO grava zero para eles: o documento é denunciado e o
     * `--verify` falha. Gravar `0` porque o `double` era a string `"1000"`
     * apagaria mil reais com um número de cara legítima.
     */
    invalid: number;
    /** Soma de todos os valores monetários, pelo `double` (em centavos). */
    sumFromDoubleCents: number;
    /** A mesma soma, pelo `*Cents` gravado (caindo no `double` quando ausente). */
    sumFromCents: number;
    /** Amostra de caminhos divergentes (no máximo 20). */
    divergentSamples: string[];
    /** Amostra de caminhos com campo monetário inválido (no máximo 20). */
    invalidSamples: string[];
}

export interface MigrateMoneyCentsSummary {
    workspaces: number;
    /** Por coleção (`orders`, `installments`, ...). */
    collections: Record<string, CollectionTally>;
    /** Operações efetivamente commitadas (sempre 0 em dry-run e em --verify). */
    writesCommitted: number;
    failed: number;
    /** Ids dos workspaces que falharam — eles FICAM no checkpoint. */
    failedWorkspaces: string[];
    /**
     * Workspaces que a próxima execução ainda vai visitar (os não processados
     * mais os que falharam). Vazio = a base está migrada.
     */
    pending: string[];
    /** Documentos que ainda precisam de `*Cents` (soma de `migrated`). */
    remaining: number;
    /** Campos monetários presentes que NÃO são número finito. */
    invalid: number;
}

/**
 * Aplica os patches em lotes, degradando para escrita POR DOCUMENTO quando o
 * lote falha.
 *
 * `batch.update` é atômico: se UM documento sumiu entre a leitura e o commit, o
 * lote inteiro é rejeitado com `NOT_FOUND` e os outros 399 não são gravados. Um
 * único documento apagado no meio da migração custaria o lote todo — e a
 * execução seguinte tropeçaria no mesmo lugar.
 *
 * **Por que `update` e não `set(..., {merge: true})`.** O `set` com merge não
 * falharia, mas CRIARIA o documento apagado — uma order fantasma com um único
 * campo `amountCents`, que o app listaria. Um patch de espelho não é motivo
 * para ressuscitar nada. Então mantemos o `update` e resolvemos a fragilidade
 * do lote: no erro, cada documento é gravado sozinho, o `NOT_FOUND` é contado
 * como "sumiu" e qualquer outro erro é propagado — ele é problema de verdade.
 */
export async function commitPatches(
    firestore: admin.firestore.Firestore,
    operations: BatchOperation[],
    log: (message: string) => void
): Promise<number> {
    let committed = 0;

    for (let i = 0; i < operations.length; i += DEFAULT_CHUNK_SIZE) {
        const chunk = operations.slice(i, i + DEFAULT_CHUNK_SIZE);

        try {
            committed += await commitInChunks(firestore, chunk, DEFAULT_CHUNK_SIZE);
            continue;
        }
        catch (error) {
            log(`[migrate_money_cents] lote de ${chunk.length} falhou (${error}); gravando documento a documento.`);
        }

        for (const operation of chunk) {
            try {
                if (operation.op === "set") {
                    await operation.ref.set(operation.data, operation.options ?? {});
                }
                else if (operation.op === "update") {
                    await operation.ref.update(operation.data);
                }
                committed++;
            }
            catch (error: unknown) {
                // gRPC 5 = NOT_FOUND: o documento sumiu entre a leitura e a
                // escrita. Não há espelho a completar em algo que não existe.
                if ((error as { code?: number } | null)?.code === 5) {
                    log(`[migrate_money_cents] ${operation.ref.path}: apagado desde a leitura; patch descartado.`);
                    continue;
                }
                throw error;
            }
        }
    }

    return committed;
}

/**
 * Grava a lista de pendentes (ou a apaga, quando vazia).
 *
 * Lista vazia vira `null` de propósito: um array vazio no documento seria
 * indistinguível de "nunca rodou" na leitura e faria a execução seguinte
 * retomar uma lista que não existe mais.
 */
async function writeCheckpoint(
    ref: admin.firestore.DocumentReference,
    pending: string[]
): Promise<void> {
    await ref.set({
        [MONEY_CENTS_CHECKPOINT_FIELD]: pending.length > 0 ? [...pending].sort() : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}

function emptyTally(): CollectionTally {
    return {
        scanned: 0,
        migrated: 0,
        alreadyOk: 0,
        divergent: 0,
        orphans: 0,
        invalid: 0,
        sumFromDoubleCents: 0,
        sumFromCents: 0,
        divergentSamples: [],
        invalidSamples: [],
    };
}

/** Todas as coleções tocadas, na ordem em que são varridas. */
export const MIGRATED_COLLECTIONS = [
    "orders",
    "installments",
    "accounts",
    "balance",
    "goals",
    "category_planning",
    "period_summaries",
] as const;

/**
 * Espelhos inteiros que faltam num documento SIMPLES (um mapa
 * `campo double -> campo inteiro`), e o que eles dizem sobre as somas.
 *
 * Devolve `null` em `patch` quando o documento já está correto.
 */
export interface CentsInspection {
    /** Campos a gravar, ou `null` quando o documento já está correto. */
    patch: Record<string, unknown> | null;
    /**
     * `true` quando o patch é um mapa ANINHADO e precisa de `set(..., {merge})`
     * em vez de `update` — é o caso de `period_summaries`, cujo dinheiro vive
     * em `categories.{id}`.
     */
    merge: boolean;
    /** O `*Cents` gravado discorda do `double`. */
    divergent: boolean;
    /** Campos `*Cents` sem o `double` correspondente (resíduo a apagar). */
    orphans: number;
    /** Campos monetários presentes e não numéricos. */
    invalid: number;
    /** Soma dos valores monetários do documento, pelo `double` (em centavos). */
    doubleCents: number;
    /** A mesma soma, pelo `*Cents` gravado (caindo no `double` quando ausente). */
    storedCents: number;
}

export function inspectFlatDoc(
    data: Record<string, unknown>,
    fields: Readonly<Record<string, string>>
): CentsInspection {
    const patch: Record<string, unknown> = {};
    let divergent = false;
    let orphans = 0;
    let invalid = 0;
    let doubleCents = 0;
    let storedCents = 0;

    for (const [valueField, centsField] of Object.entries(fields)) {
        const raw = data[valueField];
        const current = data[centsField];
        const classified = classifyMoney(raw);

        if (classified.kind === "invalid") {
            // Campo PRESENTE e não numérico. A migração não inventa um zero
            // para ele — o documento é denunciado e o `--verify` falha.
            invalid++;
            continue;
        }

        if (classified.kind === "absent") {
            // Ausente continua ausente: um inteiro pendurado sem `double` é
            // resíduo e sai. Não é divergência de VALOR, então tem contador
            // próprio e fica fora das somas.
            if (current !== undefined && current !== null) {
                patch[centsField] = admin.firestore.FieldValue.delete();
                orphans++;
            }
            continue;
        }

        const expected = classified.cents!;
        const stored = readCents(current);

        doubleCents += expected;
        storedCents += stored ?? expected;

        if (stored === null) {
            patch[centsField] = expected;
        }
        else if (stored !== expected) {
            // O campo existe e DISCORDA do espelho: é o caso que o `--verify`
            // existe para denunciar. A migração reescreve a partir do `double`,
            // que nesta etapa continua sendo o que o app escreveu.
            patch[centsField] = expected;
            divergent = true;
        }
    }

    return {
        patch: Object.keys(patch).length > 0 ? patch : null,
        merge: false,
        divergent,
        orphans,
        invalid,
        doubleCents,
        storedCents,
    };
}

/**
 * O mesmo para um `period_summaries`, cujo dinheiro vive num mapa
 * `categories.{id}.{total}` — três totais por categoria.
 *
 * O patch é um mapa ANINHADO (`{categories: {id: {...Cents}}}`) gravado com
 * `set(..., {merge: true})`, e não um caminho pontilhado
 * (`"categories.mercado.actualAmountCents"`). O motivo é o mesmo que levou o
 * repositório a usar `FieldPath` nas chaves de mapa: um id de categoria com
 * ponto seria interpretado como caminho aninhado e gravaria no lugar errado. O
 * merge de mapas do Firestore toca só as folhas presentes, então os totais em
 * `double` e as outras categorias ficam intactos.
 */
export function inspectSummaryDoc(data: Record<string, unknown>): CentsInspection {
    const categories = (data.categories ?? {}) as Record<string, Record<string, unknown> | undefined>;
    const patch: Record<string, Record<string, number>> = {};
    let divergent = false;
    let invalid = 0;
    let doubleCents = 0;
    let storedCents = 0;

    for (const [categoryId, totals] of Object.entries(categories)) {
        if (!totals) continue;

        for (const [valueField, centsField] of Object.entries(SUMMARY_CENTS_FIELDS)) {
            const classified = classifyMoney(totals[valueField]);

            if (classified.kind === "invalid") {
                invalid++;
                continue;
            }

            if (classified.kind === "absent") {
                // O total ausente vale ZERO neste documento (é o que
                // `toPeriodSummaryDocument` faz na leitura), então o espelho
                // também não precisa existir.
                continue;
            }

            const expected = classified.cents!;
            const stored = readCents(totals[centsField]);

            doubleCents += expected;
            storedCents += stored ?? expected;

            if (stored === null || stored !== expected) {
                if (stored !== null) divergent = true;
                (patch[categoryId] ??= {})[centsField] = expected;
            }
        }
    }

    return {
        patch: Object.keys(patch).length > 0 ? { categories: patch } : null,
        merge: true,
        divergent,
        // Um sumário não tem `*Cents` órfão: o total ausente vale zero e o
        // espelho simplesmente não existe.
        orphans: 0,
        invalid,
        doubleCents,
        storedCents,
    };
}

/**
 * `nextInvoice` mora DENTRO do documento da conta e tem o seu próprio par
 * (`amount`, `amountCents`). Ele é tratado à parte para que o patch use o
 * caminho aninhado, e não sobrescreva o mapa inteiro.
 */
function inspectNextInvoice(data: Record<string, unknown>): Record<string, unknown> | null {
    const raw = data.nextInvoice;
    if (!raw || typeof raw !== "object") return null;

    const next = raw as Record<string, unknown>;
    const amount = next.amount;
    if (typeof amount !== "number" || !Number.isFinite(amount)) return null;

    const expected = toCents(amount);
    if (readCents(next.amountCents) === expected) return null;

    // Mapa aninhado + merge, pelo mesmo motivo do sumário: o `update` com
    // `nextInvoice: {...}` substituiria o resumo inteiro.
    return { nextInvoice: { amountCents: expected } };
}

interface ScanContext {
    firestore: admin.firestore.Firestore;
    options: MigrateMoneyCentsOptions;
    summary: MigrateMoneyCentsSummary;
    log: (message: string) => void;
    operations: BatchOperation[];
}

/** Varre uma coleção, acumula as contagens e enfileira os patches. */
async function scanCollection(
    ctx: ScanContext,
    collection: admin.firestore.CollectionReference,
    tallyKey: string,
    inspect: (data: Record<string, unknown>) => CentsInspection
): Promise<void> {
    const pageSize = Math.max(1, ctx.options.pageSize ?? DEFAULT_PAGE_SIZE);
    const tally = ctx.summary.collections[tallyKey] ?? (ctx.summary.collections[tallyKey] = emptyTally());

    let cursorId: string | null = null;

    for (;;) {
        let query: admin.firestore.Query = collection
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pageSize);

        if (cursorId !== null) query = query.startAfter(cursorId);

        const snapshot = await query.get();
        if (snapshot.empty) return;

        for (const doc of snapshot.docs) {
            tally.scanned++;
            const data = doc.data() ?? {};
            const result = inspect(data);

            tally.sumFromDoubleCents += result.doubleCents;
            tally.sumFromCents += result.storedCents;
            tally.orphans += result.orphans;

            if (result.invalid > 0) {
                tally.invalid += result.invalid;
                if (tally.invalidSamples.length < 20) {
                    tally.invalidSamples.push(doc.ref.path);
                }
            }

            if (result.divergent) {
                tally.divergent++;
                if (tally.divergentSamples.length < 20) {
                    tally.divergentSamples.push(doc.ref.path);
                }
            }

            if (!result.patch) {
                tally.alreadyOk++;
                continue;
            }

            tally.migrated++;

            if (!ctx.options.dryRun && !ctx.options.verify) {
                ctx.operations.push(result.merge
                    ? { op: "set", ref: doc.ref, data: result.patch, options: { merge: true } }
                    : { op: "update", ref: doc.ref, data: result.patch });
            }
        }

        if (snapshot.size < pageSize) return;
        cursorId = snapshot.docs[snapshot.size - 1].id;
    }
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function migrateMoneyCents(
    firestore: admin.firestore.Firestore,
    options: MigrateMoneyCentsOptions,
    log: (message: string) => void = console.log
): Promise<MigrateMoneyCentsSummary> {
    const summary: MigrateMoneyCentsSummary = {
        workspaces: 0,
        collections: {},
        writesCommitted: 0,
        failed: 0,
        failedWorkspaces: [],
        pending: [],
        remaining: 0,
        invalid: 0,
    };

    for (const name of MIGRATED_COLLECTIONS) {
        summary.collections[name] = emptyTally();
    }

    const checkpointRef = firestore.collection("config").doc("cron_checkpoints");

    let allWorkspaceIds: string[];
    if (options.workspaceId) {
        allWorkspaceIds = [options.workspaceId];
    }
    else {
        allWorkspaceIds = (await firestore.collection("workspaces").listDocuments()).map((ref) => ref.id);
        allWorkspaceIds.sort();
    }

    // Checkpoint: a LISTA DE PENDENTES da execução anterior. A varredura
    // retoma por ela, e só por ela — um workspace que falhou continua na lista
    // e é revisitado, em vez de ficar atrás de um marcador de avanço e nunca
    // mais ser visto. Só vale para a base inteira: com `--workspace` não há o
    // que retomar.
    let resumeFrom: string[] | null = null;
    if (!options.workspaceId && !options.restart && !options.verify) {
        const doc = await checkpointRef.get();
        const value = doc.exists ? doc.data()?.[MONEY_CENTS_CHECKPOINT_FIELD] : null;
        if (Array.isArray(value) && value.length > 0) {
            const stored = new Set(value.filter((id): id is string => typeof id === "string"));
            // Interseção com a base atual: um workspace apagado desde a última
            // execução sai da lista sozinho.
            resumeFrom = allWorkspaceIds.filter((id) => stored.has(id));
        }
    }

    const workspaceIds = resumeFrom ?? allWorkspaceIds;

    const mode = options.verify ? "VERIFY" : options.dryRun ? "DRY-RUN" : "APPLY";
    log(
        `[migrate_money_cents] ${mode} — ${workspaceIds.length} de ${allWorkspaceIds.length} workspace(s) a inspecionar` +
        `${resumeFrom ? " (retomando a lista de pendentes da execução anterior)" : ""}.`
    );

    // Tudo que ainda não foi processado começa PENDENTE. Um workspace só sai
    // da lista quando termina sem erro; quem falha permanece.
    const pending = new Set(workspaceIds);

    for (const workspaceId of workspaceIds) {
        summary.workspaces++;
        const workspace = firestore.collection("workspaces").doc(workspaceId);
        const operations: BatchOperation[] = [];
        const ctx: ScanContext = { firestore, options, summary, log, operations };

        // Documentos já contados como "a migrar" ANTES deste workspace: a
        // diferença é o número que ele reporta.
        const migratedSoFar = () => Object.values(summary.collections).reduce((acc, t) => acc + t.migrated, 0);
        const before = migratedSoFar();

        try {
            const flat = (fields: Readonly<Record<string, string>>) =>
                (data: Record<string, unknown>) => inspectFlatDoc(data, fields);

            await scanCollection(ctx, workspace.collection("orders"), "orders", flat(MONEY_CENTS_FIELDS.orders));
            await scanCollection(ctx, workspace.collection("installments"), "installments", flat(MONEY_CENTS_FIELDS.installments));
            await scanCollection(ctx, workspace.collection("goals"), "goals", flat(MONEY_CENTS_FIELDS.goals));
            await scanCollection(ctx, workspace.collection("category_planning"), "category_planning", flat(MONEY_CENTS_FIELDS.category_planning));
            await scanCollection(ctx, workspace.collection("period_summaries"), "period_summaries", inspectSummaryDoc);

            // A conta carrega DOIS grupos de campos: os dela e o `amountCents`
            // de `nextInvoice`, que mora num mapa aninhado.
            await scanCollection(ctx, workspace.collection("accounts"), "accounts", (data) => {
                const base = inspectFlatDoc(data, MONEY_CENTS_FIELDS.accounts);
                const invoice = inspectNextInvoice(data);
                if (!invoice) return base;
                // `nextInvoice` é um mapa: o patch da conta inteira passa a ser
                // um `set` com merge para não substituir o resumo.
                return { ...base, merge: true, patch: { ...(base.patch ?? {}), ...invoice } };
            });

            // `listDocuments()`: traz também as contas "fantasmas" (documento
            // apagado que ainda tem subcoleção `balance`).
            const accountRefs = await workspace.collection("accounts").listDocuments();
            for (const accountRef of accountRefs) {
                await scanCollection(ctx, accountRef.collection("balance"), "balance", flat(BALANCE_CENTS_FIELDS));
            }

            if (!options.dryRun && !options.verify && operations.length > 0) {
                summary.writesCommitted += await commitPatches(firestore, operations, log);
            }

            // O número reportado vem da CONTAGEM, não da fila de operações: em
            // dry-run e em `--verify` nada é enfileirado, e imprimir
            // `operations.length` dizia sempre "0 documento(s) a atualizar"
            // justamente nos dois modos que existem para mostrar o volume.
            const found = migratedSoFar() - before;
            const verb = options.dryRun || options.verify ? "a atualizar" : "atualizado(s)";
            log(`[migrate_money_cents] ${workspaceId}: ${found} documento(s) ${verb}.`);

            // Concluído sem erro: sai da lista de pendentes.
            pending.delete(workspaceId);

            if (!options.workspaceId && !options.dryRun && !options.verify) {
                await writeCheckpoint(checkpointRef, [...pending]);
            }
        }
        catch (error) {
            summary.failed++;
            summary.failedWorkspaces.push(workspaceId);
            // NÃO sai de `pending`: a execução seguinte o visita de novo.
            log(`[migrate_money_cents] ${workspaceId}: FALHOU — ${error}`);
            if (!options.workspaceId && !options.dryRun && !options.verify) {
                await writeCheckpoint(checkpointRef, [...pending]);
            }
        }
    }

    summary.pending = [...pending].sort();
    summary.remaining = Object.values(summary.collections).reduce((acc, t) => acc + t.migrated, 0);
    summary.invalid = Object.values(summary.collections).reduce((acc, t) => acc + t.invalid, 0);

    if (!options.workspaceId && !options.dryRun && !options.verify) {
        // Lista vazia = base migrada; o campo é zerado para a próxima execução
        // começar do início em vez de ficar presa numa lista velha.
        await writeCheckpoint(checkpointRef, summary.pending);
    }

    logSummary(summary, options, log);
    return summary;
}

function formatMoney(cents: number): string {
    return (cents / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * O veredito da execução, e o que ele significa para o código de saída.
 *
 * `--verify` só passa quando **as três** contagens são zero: divergência
 * (inteiro discordando do `double`), pendência (`a_migrar > 0` — a base ainda
 * não está migrada) e campo inválido. Reportar "nenhuma divergência" numa base
 * em que o inteiro sequer existe seria dar um atestado de saúde para o silêncio.
 */
export function verdict(summary: MigrateMoneyCentsSummary): {
    ok: boolean;
    divergent: number;
    remaining: number;
    invalid: number;
    failed: number;
    reasons: string[];
} {
    const divergent = Object.values(summary.collections).reduce((acc, t) => acc + t.divergent, 0);
    const reasons: string[] = [];

    if (summary.failed > 0) {
        reasons.push(`${summary.failed} workspace(s) falharam: ${summary.failedWorkspaces.join(", ")}`);
    }
    if (summary.remaining > 0) {
        reasons.push(`${summary.remaining} documento(s) ainda sem os espelhos inteiros`);
    }
    if (divergent > 0) {
        reasons.push(`${divergent} documento(s) com *Cents divergindo do double`);
    }
    if (summary.invalid > 0) {
        reasons.push(`${summary.invalid} campo(s) monetário(s) presentes e NÃO numéricos`);
    }
    if (summary.pending.length > 0) {
        reasons.push(`${summary.pending.length} workspace(s) pendentes no checkpoint`);
    }

    return {
        ok: reasons.length === 0,
        divergent,
        remaining: summary.remaining,
        invalid: summary.invalid,
        failed: summary.failed,
        reasons,
    };
}

function logSummary(
    summary: MigrateMoneyCentsSummary,
    options: MigrateMoneyCentsOptions,
    log: (message: string) => void
): void {
    log(
        `[migrate_money_cents] Resumo — workspaces=${summary.workspaces}, escritas=${summary.writesCommitted}, ` +
        `falhas=${summary.failed}, pendentes=${summary.pending.length}.`
    );

    if (summary.failedWorkspaces.length > 0) {
        log(`[migrate_money_cents]   ⚠️  workspaces que FALHARAM (continuam no checkpoint): ${summary.failedWorkspaces.join(", ")}`);
    }
    if (summary.pending.length > 0) {
        log(`[migrate_money_cents]   pendentes para a próxima execução: ${summary.pending.join(", ")}`);
    }

    for (const name of MIGRATED_COLLECTIONS) {
        const tally = summary.collections[name];
        if (!tally || tally.scanned === 0) continue;

        log(
            `[migrate_money_cents]   ${name}: lidos=${tally.scanned}, ` +
            `a_migrar=${tally.migrated}, já_ok=${tally.alreadyOk}, divergentes=${tally.divergent}, ` +
            `órfãos=${tally.orphans}, inválidos=${tally.invalid}, ` +
            `soma_double=${formatMoney(tally.sumFromDoubleCents)}, soma_cents=${formatMoney(tally.sumFromCents)}`
        );

        if (tally.sumFromDoubleCents !== tally.sumFromCents) {
            log(
                `[migrate_money_cents]   ⚠️  ${name}: as duas somas DIFEREM em ` +
                `${formatMoney(tally.sumFromCents - tally.sumFromDoubleCents)}. ` +
                "Revise as amostras abaixo antes de aplicar."
            );
        }

        for (const path of tally.divergentSamples) {
            log(`[migrate_money_cents]     divergente: ${path}`);
        }
        for (const path of tally.invalidSamples) {
            log(`[migrate_money_cents]     campo monetário INVÁLIDO (não numérico): ${path}`);
        }
    }

    const result = verdict(summary);

    if (options.verify) {
        log(
            result.ok
                ? "[migrate_money_cents] VERIFY: OK — todo documento monetário tem o espelho inteiro, "
                  + "nenhum diverge do `double` e nenhum campo está sujo."
                : `[migrate_money_cents] VERIFY: FALHOU — ${result.reasons.join("; ")}.`
        );
        return;
    }

    if (!result.ok && !options.dryRun) {
        log(`[migrate_money_cents] ⚠️  A execução NÃO fechou: ${result.reasons.join("; ")}. Rode de novo.`);
    }
}

export function parseArgs(argv: string[]): MigrateMoneyCentsOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const pageSize = Number(getValue("--page-size="));

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        verify: argv.includes("--verify"),
        workspaceId: getValue("--workspace="),
        pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : undefined,
        restart: argv.includes("--restart"),
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
    };
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: options.projectId,
        });
    }

    const summary = await migrateMoneyCents(admin.firestore(), options);

    if (options.dryRun && !options.verify) {
        console.log("[migrate_money_cents] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    const result = verdict(summary);

    // Código de saída, por modo:
    //  - `--verify`: 0 só quando a base está migrada, coerente e limpa;
    //  - `--apply`: 0 só quando nenhum workspace falhou e nada ficou pendente;
    //  - dry-run: 0 é "a simulação rodou" — `a_migrar > 0` é o RESULTADO
    //    esperado dela, não um erro. Só falha se um workspace não pôde ser
    //    lido ou se há campo inválido/divergente a revisar antes do apply.
    const failed = options.verify
        ? !result.ok
        : options.dryRun
            ? result.failed > 0 || result.invalid > 0 || result.divergent > 0
            : !result.ok;

    process.exit(failed ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[migrate_money_cents] Erro fatal:", error);
        process.exit(1);
    });
}
