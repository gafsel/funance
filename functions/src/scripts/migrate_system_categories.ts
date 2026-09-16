/**
 * Migração: garante as categorias de sistema (`initial-balance` e as virtuais
 * `virtual_*`) em todos os workspaces — criando as que faltam e marcando com
 * `isSystem: true` as que já existem sem a flag.
 *
 * Contexto: a categoria sintética `initial-balance` sempre foi embutida nas
 * orders/installments de saldo inicial (finance.service.syncInitialBalance),
 * mas nunca existiu como documento em `workspaces/{wid}/categories`. Por isso
 * ela sumia de qualquer lookup por id (coaching, 50-30-20, viabilidade) mesmo
 * continuando somada nos period_summaries. As categorias virtuais já existiam
 * como documentos, mas sem `isSystem`, e por isso apareciam nas telas de gestão
 * e entravam nas avaliações de badge. Workspaces novos já nascem corretos
 * (category.service.impl.createDefaultCategories); este script cobre os antigos.
 *
 * Características:
 *  - IDEMPOTENTE: pula o que já está correto; pode rodar N vezes.
 *  - NÃO sobrescreve nome/ícone/cor de documentos existentes: só acrescenta a
 *    flag `isSystem` (merge).
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
import { SYSTEM_CATEGORIES } from "../features/workspace/domain/models/category.model";

export interface MigrationOptions {
    dryRun: boolean;
    workspaceId?: string;
}

export interface MigrationSummary {
    /** Workspaces inspecionados. */
    scanned: number;
    /** Categorias de sistema criadas (não existiam). */
    created: number;
    /** Categorias existentes que ganharam `isSystem: true`. */
    flagged: number;
    /** Categorias que já estavam corretas. */
    skipped: number;
    /** Categorias que falharam. */
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
    const summary: MigrationSummary = { scanned: 0, created: 0, flagged: 0, skipped: 0, failed: 0 };

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

    log(`[migrate_system_categories] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s) a inspecionar, ${SYSTEM_CATEGORIES.length} categoria(s) de sistema por workspace.`);

    for (const workspaceId of workspaceIds) {
        summary.scanned++;
        const categories = firestore
            .collection("workspaces")
            .doc(workspaceId)
            .collection("categories");

        for (const category of SYSTEM_CATEGORIES) {
            // O id vira o id do documento; não é duplicado no payload.
            const payload: Record<string, any> = { ...category };
            delete payload.id;

            const docRef = categories.doc(category.id);

            try {
                const doc = await docRef.get();

                if (!doc.exists) {
                    if (options.dryRun) {
                        summary.created++;
                        log(`[migrate_system_categories] ${workspaceId}: CRIARIA '${category.id}' (dry-run).`);
                        continue;
                    }
                    await docRef.set(payload);
                    summary.created++;
                    log(`[migrate_system_categories] ${workspaceId}: '${category.id}' criada.`);
                    continue;
                }

                // Documento já existe: a única coisa que a migração ajusta é a
                // flag `isSystem`. Nome/ícone/cor do usuário são preservados.
                if (doc.data()?.isSystem === true) {
                    summary.skipped++;
                    log(`[migrate_system_categories] ${workspaceId}: '${category.id}' já marcada como isSystem — ignorada.`);
                    continue;
                }

                if (options.dryRun) {
                    summary.flagged++;
                    log(`[migrate_system_categories] ${workspaceId}: MARCARIA '${category.id}' com isSystem: true (dry-run).`);
                    continue;
                }

                await docRef.set({ isSystem: true }, { merge: true });
                summary.flagged++;
                log(`[migrate_system_categories] ${workspaceId}: '${category.id}' marcada com isSystem: true.`);
            }
            catch (error) {
                summary.failed++;
                log(`[migrate_system_categories] ${workspaceId}/${category.id}: FALHOU — ${error}`);
            }
        }
    }

    log(`[migrate_system_categories] Resumo: workspaces=${summary.scanned}, criadas=${summary.created}, marcadas=${summary.flagged}, ignoradas=${summary.skipped}, falhas=${summary.failed}.`);
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
