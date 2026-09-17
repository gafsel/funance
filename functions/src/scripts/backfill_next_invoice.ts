/**
 * Backfill: preenche `accounts/{accountId}.nextInvoice` nas contas de cartão
 * que já existem (F1.8).
 *
 * Contexto: o resumo da próxima fatura passou a viver no documento da conta,
 * escrito pelo servidor. Contas criadas ANTES do deploy não têm o campo, e o
 * cliente mostra "calculando" até que algum evento (pagamento, edição do
 * cartão) ou o cron da madrugada o preencha. Este script antecipa isso para a
 * base inteira, de uma vez.
 *
 * Ele preenche TAMBÉM a janela do ciclo (`cycleStart`/`cycleEnd`/`closingDate`)
 * nas orders e parcelas de fatura já existentes. É o que a tela de detalhe usa
 * para listar as compras de UMA fatura qualquer — inclusive uma antiga, aberta
 * pelo histórico, de que `nextInvoice` não fala. Sem esse preenchimento, a
 * fatura antiga abre com a lista vazia até ser tocada de novo.
 *
 * Características:
 *  - IDEMPOTENTE: pula quem já tem `nextInvoice` (`--force` recalcula).
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *  - Reproduz EXATAMENTE o que o servidor faz em tempo real: a mesma consulta
 *    (`isInvoice` + `accountIds` + `pending`, ordenada por `dueDate`) e o mesmo
 *    `InvoiceService`. Não existe regra de fatura escrita aqui.
 *  - Escreve em lotes de no máximo 400 operações (`commitInChunks`).
 *  - Log por conta, com resumo final.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/backfill_next_invoice.js --project=<projectId>
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/backfill_next_invoice.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/backfill_next_invoice.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a execução a um único workspace
 *   --force              recalcula também as contas e faturas que já têm os campos
 */

import * as admin from "firebase-admin";
import { AccountType, InstallmentStatus } from "../features/finance/domain/models/finance.models";
import { InvoiceService } from "../features/finance/domain/services/invoice.service";
import { BatchOperation, commitInChunks } from "../core/utils/batch.utils";
import { toDateKey } from "../core/utils/date_key";

export interface BackfillOptions {
    dryRun: boolean;
    workspaceId?: string;
    force?: boolean;
    /** Injeção de relógio (testes e execuções determinísticas). */
    now?: Date;
}

export interface BackfillSummary {
    /** Workspaces inspecionados. */
    workspaces: number;
    /** Contas de cartão encontradas. */
    cards: number;
    /** Contas que ganharam (ou ganhariam) `nextInvoice`. */
    filled: number;
    /** Contas que já tinham o campo e foram ignoradas. */
    skipped: number;
    /** Faturas (order + parcela) que ganharam a janela do ciclo. */
    cyclesFilled: number;
    /** Faturas que já tinham a janela e foram ignoradas. */
    cyclesSkipped: number;
    /** Contas que falharam. */
    failed: number;
}

/**
 * Núcleo do backfill, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function backfillNextInvoice(
    firestore: admin.firestore.Firestore,
    options: BackfillOptions,
    log: (message: string) => void = console.log
): Promise<BackfillSummary> {
    const summary: BackfillSummary = {
        workspaces: 0, cards: 0, filled: 0, skipped: 0,
        cyclesFilled: 0, cyclesSkipped: 0, failed: 0,
    };
    const now = options.now ?? new Date();

    const workspaceIds: string[] = [];
    if (options.workspaceId) {
        workspaceIds.push(options.workspaceId);
    }
    else {
        // select() sem campos: só as referências (payload mínimo).
        const snapshot = await firestore.collection("workspaces").select().get();
        for (const doc of snapshot.docs) {
            workspaceIds.push(doc.id);
        }
    }

    log(`[backfill_next_invoice] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s) a inspecionar.`);

    for (const workspaceId of workspaceIds) {
        summary.workspaces++;

        const accountsCollection = firestore
            .collection("workspaces")
            .doc(workspaceId)
            .collection("accounts");

        let cards: admin.firestore.QueryDocumentSnapshot[];
        try {
            const snapshot = await accountsCollection
                .where("isDeleted", "==", false)
                .where("runtimeType", "==", AccountType.creditCard)
                .get();
            cards = snapshot.docs;
        }
        catch (error) {
            summary.failed++;
            log(`[backfill_next_invoice] ${workspaceId}: FALHOU ao listar cartões — ${error}`);
            continue;
        }

        const operations: BatchOperation[] = [];

        for (const card of cards) {
            summary.cards++;
            const account = card.data();

            // A janela do ciclo das faturas é INDEPENDENTE do resumo da conta,
            // e por isso roda ANTES de qualquer skip. Basta o cron das 03:45
            // passar uma vez — a primeira madrugada depois do deploy — para
            // toda conta ganhar `nextInvoice`; se o skip valesse também aqui, o
            // histórico de faturas ficaria para sempre em "fatura em
            // fechamento", sem nada que o recuperasse.
            try {
                const cycles = await backfillInvoiceCycles(
                    firestore,
                    workspaceId,
                    card.id,
                    account,
                    options,
                    operations,
                    log
                );
                summary.cyclesFilled += cycles.filled;
                summary.cyclesSkipped += cycles.skipped;
            }
            catch (error) {
                summary.failed++;
                log(`[backfill_next_invoice] ${workspaceId}/${card.id}: FALHOU ao preencher os ciclos — ${error}`);
            }

            if (account.nextInvoice && !options.force) {
                summary.skipped++;
                log(`[backfill_next_invoice] ${workspaceId}/${card.id}: já tem nextInvoice — resumo ignorado.`);
                continue;
            }

            try {
                const pending = await firestore
                    .collection("workspaces")
                    .doc(workspaceId)
                    .collection("installments")
                    .where("isInvoice", "==", true)
                    .where("accountIds", "array-contains", card.id)
                    .where("status", "==", InstallmentStatus.pending)
                    .orderBy("dueDate")
                    .limit(1)
                    .get();

                const invoice = pending.docs[0];
                const invoiceData = invoice?.data();

                const dueDate: Date = invoiceData?.dueDate?.toDate
                    ? invoiceData.dueDate.toDate()
                    : InvoiceService.resolveUpcomingDueDate(now, account as any);

                const cycle = InvoiceService.calculateInvoiceCycleRange(dueDate, account as any);

                const nextInvoice = {
                    dueDate: admin.firestore.Timestamp.fromDate(dueDate),
                    closingDate: admin.firestore.Timestamp.fromDate(cycle.closingDate),
                    cycleStart: admin.firestore.Timestamp.fromDate(cycle.start),
                    cycleEnd: admin.firestore.Timestamp.fromDate(cycle.end),
                    amount: typeof invoiceData?.amount === "number" ? invoiceData.amount : 0,
                    orderId: invoiceData?.orderId ?? InvoiceService.invoiceOrderId(card.id, dueDate),
                    installmentId: invoice?.id ?? null,
                    status: invoiceData?.status ?? InstallmentStatus.pending,
                    updatedAt: admin.firestore.Timestamp.fromDate(now),
                };

                summary.filled++;
                log(
                    `[backfill_next_invoice] ${workspaceId}/${card.id}: ` +
                    `${options.dryRun ? "GRAVARIA" : "gravando"} nextInvoice ` +
                    `vencimento=${toDateKey(dueDate)} valor=${nextInvoice.amount} ` +
                    `ciclo=${toDateKey(cycle.start)}..${toDateKey(cycle.end)} ` +
                    `parcela=${nextInvoice.installmentId ?? "nenhuma"}.`
                );

                if (!options.dryRun) {
                    operations.push({
                        op: "set",
                        ref: card.ref,
                        data: { nextInvoice },
                        options: { merge: true },
                    });
                }
            }
            catch (error) {
                summary.failed++;
                log(`[backfill_next_invoice] ${workspaceId}/${card.id}: FALHOU — ${error}`);
            }
        }

        if (operations.length > 0) {
            try {
                await commitInChunks(firestore, operations);
            }
            catch (error) {
                // O lote é do workspace inteiro: uma falha aqui invalida tudo
                // o que foi contado acima para ele. O relatório diz isso em vez
                // de tentar reverter os contadores item a item.
                summary.failed++;
                log(
                    `[backfill_next_invoice] ${workspaceId}: FALHOU ao gravar o lote de ` +
                    `${operations.length} escrita(s) — ${error}. Os números deste workspace ` +
                    "no resumo não valem; rode de novo."
                );
            }
        }
    }

    log(
        `[backfill_next_invoice] Resumo: workspaces=${summary.workspaces}, cartões=${summary.cards}, ` +
        `preenchidas=${summary.filled}, ignoradas=${summary.skipped}, ` +
        `ciclos=${summary.cyclesFilled} (${summary.cyclesSkipped} já tinham), ` +
        `falhas=${summary.failed}.`
    );
    return summary;
}

/**
 * Preenche `cycleStart`/`cycleEnd`/`closingDate` nas faturas do cartão que
 * ainda não os têm (orders e parcelas criadas antes de F1.8).
 *
 * Roda para TODO cartão, tenha ele `nextInvoice` ou não: os dois preenchimentos
 * respondem por coisas diferentes — o resumo fala da próxima fatura, a janela
 * fala de cada fatura já existente, inclusive as que só o histórico abre.
 *
 * A janela é recalculada a partir do vencimento da própria fatura e da
 * configuração ATUAL do cartão — é a melhor aproximação disponível: a
 * configuração de quando a fatura nasceu não foi guardada em lugar nenhum. Daí
 * em diante ela fica congelada, e este é o último recálculo.
 */
async function backfillInvoiceCycles(
    firestore: admin.firestore.Firestore,
    workspaceId: string,
    accountId: string,
    account: admin.firestore.DocumentData,
    options: BackfillOptions,
    operations: BatchOperation[],
    log: (message: string) => void
): Promise<{ filled: number; skipped: number }> {
    const workspace = firestore.collection("workspaces").doc(workspaceId);

    const invoices = await workspace
        .collection("installments")
        .where("isInvoice", "==", true)
        .where("accountIds", "array-contains", accountId)
        .get();

    let filled = 0;
    let skipped = 0;

    for (const doc of invoices.docs) {
        const data = doc.data();
        if (data.cycleStart && data.cycleEnd && !options.force) {
            skipped++;
            continue;
        }

        const dueDate: Date | null = data.dueDate?.toDate ? data.dueDate.toDate() : null;
        if (!dueDate) continue;

        const cycle = InvoiceService.calculateInvoiceCycleRange(dueDate, account as any);
        const payload = {
            cycleStart: admin.firestore.Timestamp.fromDate(cycle.start),
            cycleEnd: admin.firestore.Timestamp.fromDate(cycle.end),
            closingDate: admin.firestore.Timestamp.fromDate(cycle.closingDate),
        };

        filled++;
        log(
            `[backfill_next_invoice] ${workspaceId}/${accountId}: ` +
            `${options.dryRun ? "GRAVARIA" : "gravando"} ciclo da fatura ${doc.id} ` +
            `(${toDateKey(cycle.start)}..${toDateKey(cycle.end)}).`
        );

        if (options.dryRun) continue;

        operations.push({ op: "set", ref: doc.ref, data: payload, options: { merge: true } });
        if (typeof data.orderId === "string" && data.orderId.length > 0) {
            operations.push({
                op: "set",
                ref: workspace.collection("orders").doc(data.orderId),
                data: payload,
                options: { merge: true },
            });
        }
    }

    return { filled, skipped };
}

export function parseArgs(argv: string[]): BackfillOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    return {
        // Dry-run é o padrão: só escreve com --apply explícito.
        dryRun: !argv.includes("--apply"),
        force: argv.includes("--force"),
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

    const summary = await backfillNextInvoice(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[backfill_next_invoice] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[backfill_next_invoice] Erro fatal:", error);
        process.exit(1);
    });
}
