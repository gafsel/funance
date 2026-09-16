/**
 * Migração (F1.4): preenche `dateKey` e `delta` nos documentos de saldo diário
 * `workspaces/{wid}/accounts/{aid}/balance/{YYYY-MM-DD}`.
 *
 * Contexto: antes de F1.4 o documento de saldo tinha apenas `balance` (saldo
 * acumulado) e o id era a data em UTC. O modelo novo guarda também:
 *
 *   - `dateKey` — a mesma string do id, agora como CAMPO indexado. É ele que
 *     permite `where("dateKey", "<", key).orderBy("dateKey", "desc")`, no lugar
 *     do `orderBy(documentId(), "desc")` (que o emulador rejeita e que em
 *     produção depende de um índice `__name__ DESC`);
 *   - `delta` — a soma dos movimentos DO DIA, calculada aqui como
 *     `balance - balance do dia anterior`.
 *
 * O que este script NÃO faz:
 *   - não move documento de dia: ids gravados em UTC que deveriam estar no dia
 *     anterior (movimento perto da meia-noite de Brasília) continuam onde
 *     estão. Corrigir isso é papel do `rebuild_workspace.ts`, que recalcula a
 *     série inteira a partir das parcelas;
 *   - não recalcula `balance`: o acumulado existente é a verdade daqui.
 *
 * Características:
 *   - IDEMPOTENTE: pula documentos que já estão no formato novo e com o `delta`
 *     coerente; pode rodar N vezes.
 *   - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *   - Escreve em lotes de no máximo 400 operações (`commitInChunks`).
 *   - Log por conta, com resumo final.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_balance_date_key.js --project=<projectId>
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_balance_date_key.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_balance_date_key.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace
 *   --page-size=<n>      documentos de saldo lidos por página (default 500)
 */

import * as admin from "firebase-admin";
import { BatchOperation, commitInChunks } from "../core/utils/batch.utils";
import { isDateKey } from "../core/utils/date_key";

export interface MigrateBalanceOptions {
    dryRun: boolean;
    workspaceId?: string;
    pageSize?: number;
}

export interface MigrateBalanceSummary {
    /** Workspaces inspecionados. */
    workspaces: number;
    /** Contas inspecionadas (inclusive as apagadas logicamente). */
    accounts: number;
    /** Documentos de saldo lidos. */
    scanned: number;
    /** Documentos que receberam (ou receberiam) `dateKey`/`delta`. */
    migrated: number;
    /** Documentos que já estavam no formato novo. */
    skippedAlreadyMigrated: number;
    /** Documentos com id fora do padrão `YYYY-MM-DD`: não dá para inferir o dia. */
    skippedInvalidId: number;
    /** Contas que falharam. */
    failed: number;
}

const DEFAULT_PAGE_SIZE = 500;
const EPSILON = 0.005;

const roundCents = (value: number) => Math.round(value * 100) / 100;

function toNumber(value: unknown): number {
    const parsed = typeof value === "number" ? value : Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function migrateBalanceDateKey(
    firestore: admin.firestore.Firestore,
    options: MigrateBalanceOptions,
    log: (message: string) => void = console.log
): Promise<MigrateBalanceSummary> {
    const summary: MigrateBalanceSummary = {
        workspaces: 0,
        accounts: 0,
        scanned: 0,
        migrated: 0,
        skippedAlreadyMigrated: 0,
        skippedInvalidId: 0,
        failed: 0,
    };

    const pageSize = Math.max(1, options.pageSize ?? DEFAULT_PAGE_SIZE);

    const workspaceIds = options.workspaceId
        ? [options.workspaceId]
        : (await firestore.collection("workspaces").listDocuments()).map((ref) => ref.id);

    log(`[migrate_balance_date_key] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s) a inspecionar.`);

    for (const workspaceId of workspaceIds) {
        summary.workspaces++;

        // listDocuments(): traz também as contas "fantasmas" (documento apagado
        // que ainda tem subcoleção `balance`).
        const accountRefs = await firestore
            .collection("workspaces").doc(workspaceId).collection("accounts")
            .listDocuments();

        for (const accountRef of accountRefs) {
            summary.accounts++;

            try {
                const operations: BatchOperation[] = [];
                let previousBalance = 0;
                let cursorId: string | null = null;
                let accountScanned = 0;
                let accountMigrated = 0;

                for (;;) {
                    let query: admin.firestore.Query = accountRef.collection("balance")
                        .orderBy(admin.firestore.FieldPath.documentId())
                        .limit(pageSize);

                    if (cursorId !== null) {
                        query = query.startAfter(cursorId);
                    }

                    const snapshot = await query.get();
                    if (snapshot.empty) break;

                    for (const doc of snapshot.docs) {
                        summary.scanned++;
                        accountScanned++;

                        const data = doc.data() ?? {};

                        if (!isDateKey(doc.id)) {
                            // Id fora do padrão: o script não inventa o dia.
                            summary.skippedInvalidId++;
                            log(`[migrate_balance_date_key] ${workspaceId}/${accountRef.id}/${doc.id}: id fora do padrão YYYY-MM-DD — ignorado.`);
                            continue;
                        }

                        const balance = toNumber(data.balance);
                        const expectedDelta = roundCents(balance - previousBalance);
                        previousBalance = balance;

                        const dateKeyOk = data.dateKey === doc.id;
                        const deltaOk = typeof data.delta === "number" && Math.abs(data.delta - expectedDelta) <= EPSILON;

                        if (dateKeyOk && deltaOk) {
                            summary.skippedAlreadyMigrated++;
                            continue;
                        }

                        summary.migrated++;
                        accountMigrated++;

                        if (!options.dryRun) {
                            operations.push({
                                op: "update",
                                ref: doc.ref,
                                data: { dateKey: doc.id, delta: expectedDelta },
                            });
                        }
                    }

                    if (snapshot.size < pageSize) break;
                    cursorId = snapshot.docs[snapshot.size - 1].id;
                }

                if (accountScanned === 0) continue;

                if (options.dryRun) {
                    log(`[migrate_balance_date_key] ${workspaceId}/${accountRef.id}: GRAVARIA dateKey/delta em ${accountMigrated} de ${accountScanned} documento(s) (dry-run).`);
                    continue;
                }

                const committed = await commitInChunks(firestore, operations);
                log(`[migrate_balance_date_key] ${workspaceId}/${accountRef.id}: ${committed} documento(s) atualizado(s) de ${accountScanned} lido(s).`);
            }
            catch (error) {
                summary.failed++;
                log(`[migrate_balance_date_key] ${workspaceId}/${accountRef.id}: FALHOU — ${error}`);
            }
        }
    }

    log(
        "[migrate_balance_date_key] Resumo: " +
        `workspaces=${summary.workspaces}, contas=${summary.accounts}, saldos=${summary.scanned}, ` +
        `migrados=${summary.migrated}, já_migrados=${summary.skippedAlreadyMigrated}, ` +
        `id_inválido=${summary.skippedInvalidId}, falhas=${summary.failed}.`
    );
    return summary;
}

export function parseArgs(argv: string[]): MigrateBalanceOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const pageSize = Number(getValue("--page-size="));

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        workspaceId: getValue("--workspace="),
        pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : undefined,
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

    const summary = await migrateBalanceDateKey(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[migrate_balance_date_key] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[migrate_balance_date_key] Erro fatal:", error);
        process.exit(1);
    });
}
