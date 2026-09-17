/**
 * Primeiro publish do catálogo de badges em `config/badges` (F2.7).
 *
 * O cron `publishBadgeCatalog` faz isso todo dia às 04:00 (America/Sao_Paulo),
 * mas ele só existe depois do deploy — e até a primeira execução o app não teria
 * catálogo nenhum para desenhar. Este script publica na hora.
 *
 * Características:
 *  - IDEMPOTENTE: compara a `version` (hash do conteúdo) e não escreve se ela
 *    já é a publicada. Pode rodar N vezes.
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply`. No dry-run ele imprime a
 *    versão calculada, a publicada e a contagem de badges.
 *  - Não toca em nenhum dado de usuário: `config/badges` é um documento do
 *    projeto, legível por qualquer usuário autenticado e fechado para escrita
 *    pelas security rules.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`).
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/publish_badge_catalog.js --project=<projectId>
 *   # 2) Publicação real:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/publish_badge_catalog.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa a escrita (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 */

import * as admin from "firebase-admin";
import { BadgeCatalogRepositoryImpl } from "../features/goal/data/repositories/badge_catalog.repository.impl";
import { IBadgeCatalogRepository } from "../features/goal/domain/repositories/badge_catalog.repository";
import { BadgeCatalogService, buildBadgeCatalog } from "../features/goal/domain/services/badge_catalog.service";

export interface PublishCatalogOptions {
    dryRun: boolean;
}

export interface PublishCatalogSummary {
    version: string;
    publishedVersion: string | null;
    badgeCount: number;
    /** `true` quando o documento foi (ou seria) escrito. */
    written: boolean;
}

export async function publishBadgeCatalogScript(
    repository: IBadgeCatalogRepository,
    options: PublishCatalogOptions,
    log: (message: string) => void = console.log
): Promise<PublishCatalogSummary> {
    const catalog = buildBadgeCatalog();
    const publishedVersion = await repository.getPublishedVersion();
    const upToDate = publishedVersion === catalog.version;

    log(`[publish_badge_catalog] ${options.dryRun ? "DRY-RUN" : "APPLY"} — versão calculada=${catalog.version} publicada=${publishedVersion ?? "(nenhuma)"} badges=${catalog.badges.length} níveis=${catalog.levelThresholds.length}`);

    if (upToDate) {
        log("[publish_badge_catalog] Catálogo já está na versão atual — nada a fazer.");
        return { version: catalog.version, publishedVersion, badgeCount: catalog.badges.length, written: false };
    }

    if (options.dryRun) {
        log("[publish_badge_catalog] PUBLICARIA o catálogo (dry-run).");
        return { version: catalog.version, publishedVersion, badgeCount: catalog.badges.length, written: true };
    }

    const result = await new BadgeCatalogService(repository).publishBadgeCatalog();
    log(`[publish_badge_catalog] Catálogo publicado (versão ${result.version}).`);
    return { version: result.version, publishedVersion, badgeCount: result.badgeCount, written: result.published };
}

/** Bootstrap: só roda quando o arquivo é executado direto por `node`. */
if (require.main === module) {
    const args = process.argv.slice(2);
    const dryRun = !args.includes("--apply");
    const projectId = args.find((a) => a.startsWith("--project="))?.split("=")[1]
        || process.env.GOOGLE_CLOUD_PROJECT;

    if (!projectId) {
        console.error("[publish_badge_catalog] Informe --project=<projectId> (ou defina GOOGLE_CLOUD_PROJECT).");
        process.exit(1);
    }

    admin.initializeApp({ projectId });
    admin.firestore().settings({ ignoreUndefinedProperties: false });

    publishBadgeCatalogScript(new BadgeCatalogRepositoryImpl(), { dryRun })
        .then(() => process.exit(0))
        .catch((e) => {
            console.error("[publish_badge_catalog] Erro fatal:", e);
            process.exit(1);
        });
}
