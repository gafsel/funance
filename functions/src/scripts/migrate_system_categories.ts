/**
 * Migração: cria a categoria de sistema `initial-balance` nos workspaces que
 * ainda não a possuem.
 *
 * Contexto: a categoria sintética `initial-balance` sempre foi embutida nas
 * orders/installments de saldo inicial (finance.service.syncInitialBalance),
 * mas nunca existiu como documento em `workspaces/{wid}/categories`. Por isso
 * ela sumia de qualquer lookup por id (coaching, 50-30-20, viabilidade) mesmo
 * continuando somada nos period_summaries. Workspaces novos já nascem com ela
 * (category.service.impl.createDefaultCategories); este script cobre os antigos.
 *
 * Características:
 *  - IDEMPOTENTE: pula workspaces que já têm o documento; pode rodar N vezes.
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *  - Log por workspace, com resumo final.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_system_categories.js --project=<projectId>
 *   # 2) Execução real (somente após revisar a saída do dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/migrate_system_categories.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace (útil para teste)
 */

import * as admin from "firebase-admin";
import { INITIAL_BALANCE_CATEGORY, INITIAL_BALANCE_CATEGORY_ID } from "../features/workspace/domain/models/category.model";

export interface MigrationOptions {
    dryRun: boolean;
    workspaceId?: string;
}

export interface MigrationSummary {
    scanned: number;
    created: number;
    skipped: number;
    failed: number;
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function migrateSystemCategories(
    firestore: admin.firestore.Firestore,
    options: MigrationOptions,
    log: (message: string) => void = console.log
): Promise<MigrationSummary> {
    const summary: MigrationSummary = { scanned: 0, created: 0, skipped: 0, failed: 0 };

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

    log(`[migrate_system_categories] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s) a inspecionar.`);

    // O id vira o id do documento; não deve ser duplicado no payload.
    const categoryData: Record<string, any> = { ...INITIAL_BALANCE_CATEGORY };
    delete categoryData.id;

    for (const workspaceId of workspaceIds) {
        summary.scanned++;
        const docRef = firestore
            .collection("workspaces")
            .doc(workspaceId)
            .collection("categories")
            .doc(INITIAL_BALANCE_CATEGORY_ID);

        try {
            const doc = await docRef.get();

            if (doc.exists) {
                summary.skipped++;
                log(`[migrate_system_categories] ${workspaceId}: já possui '${INITIAL_BALANCE_CATEGORY_ID}' — ignorado.`);
                continue;
            }

            if (options.dryRun) {
                summary.created++;
                log(`[migrate_system_categories] ${workspaceId}: CRIARIA '${INITIAL_BALANCE_CATEGORY_ID}' (dry-run).`);
                continue;
            }

            await docRef.set(categoryData);
            summary.created++;
            log(`[migrate_system_categories] ${workspaceId}: '${INITIAL_BALANCE_CATEGORY_ID}' criada.`);
        }
        catch (error) {
            summary.failed++;
            log(`[migrate_system_categories] ${workspaceId}: FALHOU — ${error}`);
        }
    }

    log(`[migrate_system_categories] Resumo: inspecionados=${summary.scanned}, criados=${summary.created}, ignorados=${summary.skipped}, falhas=${summary.failed}.`);
    return summary;
}

export function parseArgs(argv: string[]): MigrationOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    return {
        // Dry-run é o padrão: só escreve com --apply explícito.
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

    const summary = await migrateSystemCategories(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[migrate_system_categories] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[migrate_system_categories] Erro fatal:", error);
        process.exit(1);
    });
}
