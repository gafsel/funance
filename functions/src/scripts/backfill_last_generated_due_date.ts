/**
 * Migração: preenche `lastGeneratedDueDate` nas orders RECORRENTES que estão
 * sem o campo, usando o vencimento da última parcela já existente da order.
 *
 * Contexto: o cron `generateRecurringInstallments` avança uma order recorrente
 * a partir de `lastGeneratedDueDate`. A query do cron usa
 * `where("lastGeneratedDueDate", "<", threshold)`, e o Firestore NÃO casa
 * documentos em que o campo não existe — então uma order recorrente sem o campo
 * simplesmente nunca é estendida (o serviço também recusa estendê-la: sem a
 * marca não há como saber onde a série parou, e o fallback antigo para "hoje"
 * inventava parcelas). Este script cria a marca a partir do que já existe.
 *
 * Características:
 *  - IDEMPOTENTE: pula orders que já têm o campo; pode rodar N vezes.
 *  - NÃO cria parcela nenhuma: só grava `lastGeneratedDueDate` na order. Quem
 *    gera as parcelas que faltam é o cron diário, no formato normal.
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *  - Log por order, com resumo final.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/backfill_last_generated_due_date.js --project=<projectId>
 *   # 2) Execução real (somente após revisar a saída do dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/backfill_last_generated_due_date.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace (útil para teste)
 */

import * as admin from "firebase-admin";
import { InstallmentType } from "../features/finance/domain/models/finance.models";

export interface BackfillOptions {
    dryRun: boolean;
    workspaceId?: string;
}

export interface BackfillSummary {
    /** Orders recorrentes inspecionadas. */
    scanned: number;
    /** Orders que receberam (ou receberiam) `lastGeneratedDueDate`. */
    filled: number;
    /** Orders que já tinham o campo. */
    skippedAlreadySet: number;
    /** Orders recorrentes sem nenhuma parcela: não há de onde inferir a data. */
    skippedNoInstallments: number;
    /** Orders que falharam. */
    failed: number;
}

/** Converte Timestamp/Date/string em Date, ou null se não der. */
function toDate(raw: any): Date | null {
    if (!raw) return null;

    let date: Date;
    if (typeof raw.toDate === "function") date = raw.toDate();
    else if (raw instanceof Date) date = raw;
    else date = new Date(raw);

    return Number.isNaN(date.getTime()) ? null : date;
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function backfillLastGeneratedDueDate(
    firestore: admin.firestore.Firestore,
    options: BackfillOptions,
    log: (message: string) => void = console.log
): Promise<BackfillSummary> {
    const summary: BackfillSummary = {
        scanned: 0,
        filled: 0,
        skippedAlreadySet: 0,
        skippedNoInstallments: 0,
        failed: 0,
    };

    // Com --workspace a busca é na subcoleção do workspace; sem ela, no grupo
    // de coleções `orders` (todas as orders da base).
    const ordersQuery = options.workspaceId
        ? firestore.collection("workspaces").doc(options.workspaceId).collection("orders")
            .where("installmentType", "==", InstallmentType.recurring)
        : firestore.collectionGroup("orders")
            .where("installmentType", "==", InstallmentType.recurring);

    const snapshot = await ordersQuery.get();

    log(`[backfill_last_generated_due_date] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${snapshot.docs.length} order(s) recorrente(s) a inspecionar.`);

    for (const orderDoc of snapshot.docs) {
        summary.scanned++;

        const orderId = orderDoc.id;
        const workspaceId = orderDoc.ref.parent.parent?.id;

        try {
            if (!workspaceId) {
                summary.failed++;
                log(`[backfill_last_generated_due_date] ${orderId}: FALHOU — não foi possível resolver o workspace da order.`);
                continue;
            }

            const data = orderDoc.data() || {};

            if (toDate(data.lastGeneratedDueDate)) {
                summary.skippedAlreadySet++;
                log(`[backfill_last_generated_due_date] ${workspaceId}/${orderId}: já tem lastGeneratedDueDate — ignorada.`);
                continue;
            }

            // Query só por igualdade (não precisa de índice composto): o máximo
            // é calculado em memória. Uma order recorrente tem poucas dezenas
            // de parcelas.
            const installments = await firestore
                .collection("workspaces").doc(workspaceId).collection("installments")
                .where("orderId", "==", orderId)
                .get();

            let lastDueDate: Date | null = null;
            for (const installment of installments.docs) {
                const dueDate = toDate(installment.data()?.dueDate);
                if (!dueDate) continue;
                if (!lastDueDate || dueDate.getTime() > lastDueDate.getTime()) {
                    lastDueDate = dueDate;
                }
            }

            if (!lastDueDate) {
                summary.skippedNoInstallments++;
                log(`[backfill_last_generated_due_date] ${workspaceId}/${orderId}: sem parcelas com vencimento válido — nada a inferir.`);
                continue;
            }

            // Meio-dia: mesma convenção de todas as datas de vencimento do
            // projeto (evita virada de dia por fuso).
            lastDueDate.setHours(12, 0, 0, 0);

            if (options.dryRun) {
                summary.filled++;
                log(`[backfill_last_generated_due_date] ${workspaceId}/${orderId}: GRAVARIA lastGeneratedDueDate=${lastDueDate.toISOString()} (dry-run).`);
                continue;
            }

            await orderDoc.ref.set(
                { lastGeneratedDueDate: admin.firestore.Timestamp.fromDate(lastDueDate) },
                { merge: true }
            );
            summary.filled++;
            log(`[backfill_last_generated_due_date] ${workspaceId}/${orderId}: lastGeneratedDueDate=${lastDueDate.toISOString()} gravado.`);
        }
        catch (error) {
            summary.failed++;
            log(`[backfill_last_generated_due_date] ${workspaceId ?? "?"}/${orderId}: FALHOU — ${error}`);
        }
    }

    log(`[backfill_last_generated_due_date] Resumo: orders=${summary.scanned}, preenchidas=${summary.filled}, já_preenchidas=${summary.skippedAlreadySet}, sem_parcelas=${summary.skippedNoInstallments}, falhas=${summary.failed}.`);
    return summary;
}

export function parseArgs(argv: string[]): BackfillOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        workspaceId: getValue("--workspace="),
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

    const summary = await backfillLastGeneratedDueDate(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[backfill_last_generated_due_date] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[backfill_last_generated_due_date] Erro fatal:", error);
        process.exit(1);
    });
}
