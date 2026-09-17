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
import { readCents, toCents } from "../core/utils/money";
import {
    BALANCE_CENTS_FIELDS,
    MONEY_CENTS_FIELDS,
    SUMMARY_CENTS_FIELDS,
} from "../features/finance/domain/models/finance.models";

/** Campo do checkpoint em `config/cron_checkpoints` — ESTÁVEL. */
export const MONEY_CENTS_CHECKPOINT_FIELD = "moneyCentsMigrationPath";

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
    /** Soma de todos os valores monetários, pelo `double` (em centavos). */
    sumFromDoubleCents: number;
    /** A mesma soma, pelo `*Cents` gravado (caindo no `double` quando ausente). */
    sumFromCents: number;
    /** Amostra de caminhos divergentes (no máximo 20). */
    divergentSamples: string[];
}

export interface MigrateMoneyCentsSummary {
    workspaces: number;
    /** Por coleção (`orders`, `installments`, ...). */
    collections: Record<string, CollectionTally>;
    /** Operações efetivamente commitadas (sempre 0 em dry-run e em --verify). */
    writesCommitted: number;
    failed: number;
    /** `true` quando a varredura foi interrompida e o checkpoint ficou gravado. */
    resumable: boolean;
}

function emptyTally(): CollectionTally {
    return {
        scanned: 0,
        migrated: 0,
        alreadyOk: 0,
        divergent: 0,
        sumFromDoubleCents: 0,
        sumFromCents: 0,
        divergentSamples: [],
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
    let doubleCents = 0;
    let storedCents = 0;

    for (const [valueField, centsField] of Object.entries(fields)) {
        const raw = data[valueField];
        const current = data[centsField];

        if (typeof raw !== "number" || !Number.isFinite(raw)) {
            // Ausente continua ausente: um inteiro pendurado sem `double` é
            // resíduo e sai.
            if (current !== undefined && current !== null) {
                patch[centsField] = admin.firestore.FieldValue.delete();
                divergent = true;
            }
            continue;
        }

        const expected = toCents(raw);
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
    let doubleCents = 0;
    let storedCents = 0;

    for (const [categoryId, totals] of Object.entries(categories)) {
        if (!totals) continue;

        for (const [valueField, centsField] of Object.entries(SUMMARY_CENTS_FIELDS)) {
            const raw = totals[valueField];
            const current = totals[centsField];

            if (typeof raw !== "number" || !Number.isFinite(raw)) {
                // O total ausente vale ZERO neste documento (é o que
                // `toPeriodSummaryDocument` faz na leitura), então o espelho
                // também não precisa existir.
                continue;
            }

            const expected = toCents(raw);
            const stored = readCents(current);

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
        resumable: false,
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

    // Checkpoint: retoma do workspace seguinte ao último concluído. Só vale
    // para a varredura da base inteira — com `--workspace` não há o que retomar.
    let resumeAfter: string | null = null;
    if (!options.workspaceId && !options.restart && !options.verify) {
        const doc = await checkpointRef.get();
        const value = doc.exists ? doc.data()?.[MONEY_CENTS_CHECKPOINT_FIELD] : null;
        resumeAfter = typeof value === "string" && value.length > 0 ? value : null;
    }

    const workspaceIds = resumeAfter
        ? allWorkspaceIds.filter((id) => id > resumeAfter!)
        : allWorkspaceIds;

    const mode = options.verify ? "VERIFY" : options.dryRun ? "DRY-RUN" : "APPLY";
    log(
        `[migrate_money_cents] ${mode} — ${workspaceIds.length} de ${allWorkspaceIds.length} workspace(s) a inspecionar` +
        `${resumeAfter ? ` (retomando depois de ${resumeAfter})` : ""}.`
    );

    for (const workspaceId of workspaceIds) {
        summary.workspaces++;
        const workspace = firestore.collection("workspaces").doc(workspaceId);
        const operations: BatchOperation[] = [];
        const ctx: ScanContext = { firestore, options, summary, log, operations };

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
                summary.writesCommitted += await commitInChunks(firestore, operations, DEFAULT_CHUNK_SIZE);
            }

            log(`[migrate_money_cents] ${workspaceId}: ${operations.length} documento(s) a atualizar.`);

            if (!options.workspaceId && !options.dryRun && !options.verify) {
                await checkpointRef.set(
                    { [MONEY_CENTS_CHECKPOINT_FIELD]: workspaceId, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
                    { merge: true }
                );
                summary.resumable = true;
            }
        }
        catch (error) {
            summary.failed++;
            log(`[migrate_money_cents] ${workspaceId}: FALHOU — ${error}`);
        }
    }

    // Varredura completa: o checkpoint é zerado para a próxima execução
    // começar do início (e não ficar presa no último workspace).
    if (!options.workspaceId && !options.dryRun && !options.verify && summary.failed === 0) {
        await checkpointRef.set(
            { [MONEY_CENTS_CHECKPOINT_FIELD]: null, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true }
        );
        summary.resumable = false;
    }

    logSummary(summary, options, log);
    return summary;
}

function formatMoney(cents: number): string {
    return (cents / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function logSummary(
    summary: MigrateMoneyCentsSummary,
    options: MigrateMoneyCentsOptions,
    log: (message: string) => void
): void {
    log(`[migrate_money_cents] Resumo — workspaces=${summary.workspaces}, escritas=${summary.writesCommitted}, falhas=${summary.failed}.`);

    for (const name of MIGRATED_COLLECTIONS) {
        const tally = summary.collections[name];
        if (!tally || tally.scanned === 0) continue;

        log(
            `[migrate_money_cents]   ${name}: lidos=${tally.scanned}, ` +
            `a_migrar=${tally.migrated}, já_ok=${tally.alreadyOk}, divergentes=${tally.divergent}, ` +
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
    }

    if (options.verify) {
        const totalDivergent = Object.values(summary.collections).reduce((acc, t) => acc + t.divergent, 0);
        log(
            totalDivergent === 0
                ? "[migrate_money_cents] VERIFY: nenhuma divergência |cents − round(double × 100)| > 0."
                : `[migrate_money_cents] VERIFY: ${totalDivergent} documento(s) com divergência. Rode com --apply.`
        );
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

    const divergent = options.verify
        ? Object.values(summary.collections).reduce((acc, t) => acc + t.divergent, 0)
        : 0;

    process.exit(summary.failed > 0 || divergent > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[migrate_money_cents] Erro fatal:", error);
        process.exit(1);
    });
}
