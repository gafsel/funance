/**
 * Base inicial da Bússola da Liberdade (F2.2).
 *
 * O índice nasce de um cron que só recalcula workspaces SUJOS, e um workspace
 * só fica sujo quando alguém mexe nele. Numa base já existente isso significa
 * que quem não abrir o app não ganha bússola nenhuma — o app mostraria o
 * estado vazio para um usuário com três anos de histórico. Este script faz a
 * primeira passada: calcula e grava `financialHealth` e o
 * `health_history/{YYYY-MM}` do mês corrente de todo mundo.
 *
 * Depois dele, o caminho normal (carimbo no gatilho + cron de 15 min) mantém
 * tudo em dia sozinho.
 *
 * Características:
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply`. O dry-run CALCULA o índice
 *    (é leitura) e imprime o que gravaria, incluindo o retrato atual quando
 *    já existe — é assim que se revisa o efeito antes de aplicar.
 *  - IDEMPOTENTE: recalcular não muda nada se o estado do workspace não mudou;
 *    o próprio índice é determinístico dado `now`.
 *  - ISOLA FALHA: um workspace que lança é contado e não derruba os demais.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_health.js --project=<projectId>
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_health.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_health.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a execução a um único workspace
 */

import * as admin from "firebase-admin";

import { HealthRepositoryImpl } from "../features/health/data/repositories/health.repository.impl";
import { IHealthRepository } from "../features/health/domain/repositories/health.repository";
import { FinancialHealthService } from "../features/health/domain/services/financial_health.service";

export interface RecomputeHealthOptions {
    dryRun: boolean;
    workspaceId?: string;
    /** Injeção de relógio (testes): o índice é parametrizado por `now`. */
    now?: Date;
}

export interface RecomputeHealthSummary {
    /** Workspaces inspecionados. */
    scanned: number;
    /** Workspaces cujo retrato foi (ou seria) gravado. */
    written: number;
    /** Workspaces cujo retrato já era idêntico ao calculado. */
    unchanged: number;
    /** Workspaces em que o cálculo lançou. */
    failed: number;
}

/**
 * Núcleo do recálculo, isolado do bootstrap para permitir teste com mocks
 * (recebe o Firestore e o repositório por parâmetro).
 */
export async function recomputeHealth(
    firestore: admin.firestore.Firestore,
    repository: IHealthRepository,
    options: RecomputeHealthOptions,
    log: (message: string) => void = console.log
): Promise<RecomputeHealthSummary> {
    const summary: RecomputeHealthSummary = { scanned: 0, written: 0, unchanged: 0, failed: 0 };
    const service = new FinancialHealthService(repository);
    const now = options.now ?? new Date();

    const workspaceIds: string[] = [];
    if (options.workspaceId) {
        workspaceIds.push(options.workspaceId);
    }
    else {
        const snapshot = await firestore.collection("workspaces").select().get();
        for (const doc of snapshot.docs) {
            workspaceIds.push(doc.id);
        }
    }

    log(`[recompute_health] ${options.dryRun ? "DRY-RUN" : "APPLY"} — ${workspaceIds.length} workspace(s).`);

    for (const workspaceId of workspaceIds) {
        summary.scanned++;

        try {
            const computed = await service.computeHealth(workspaceId, now);
            const current = await repository.getCurrent(workspaceId);

            const same = current !== null &&
                current.score === computed.score &&
                current.tier === computed.tier &&
                current.monthKey === computed.monthKey;

            if (same) {
                summary.unchanged++;
                log(`[recompute_health] ${workspaceId}: já está em ${computed.score} (${computed.tier}) — nada a fazer.`);
                continue;
            }

            summary.written++;
            const from = current ? `${current.score} (${current.tier})` : "sem retrato";
            const verb = options.dryRun ? "GRAVARIA" : "gravado";
            log(
                `[recompute_health] ${workspaceId}: ${from} -> ${computed.score} (${computed.tier}) ` +
                `[fôlego=${computed.components.folego.score} poupança=${computed.components.poupanca.score} ` +
                `disciplina=${computed.components.disciplina.score} alívio=${computed.components.alivio.score}] (${verb}).`
            );

            if (!options.dryRun) {
                await repository.saveHistory(workspaceId, computed);
                await repository.saveCurrent(workspaceId, computed);
            }
        }
        catch (e) {
            summary.failed++;
            log(`[recompute_health] ${workspaceId}: FALHA — ${String(e)}`);
        }
    }

    log(
        `[recompute_health] Fim: workspaces=${summary.scanned} gravados=${summary.written} ` +
        `iguais=${summary.unchanged} falhas=${summary.failed}`
    );

    return summary;
}

/** Bootstrap: só roda quando o arquivo é executado direto por `node`. */
if (require.main === module) {
    const args = process.argv.slice(2);
    const dryRun = !args.includes("--apply");
    const projectId = args.find((a) => a.startsWith("--project="))?.split("=")[1]
        || process.env.GOOGLE_CLOUD_PROJECT;
    const workspaceId = args.find((a) => a.startsWith("--workspace="))?.split("=")[1];

    if (!projectId) {
        console.error("[recompute_health] Informe --project=<projectId> (ou defina GOOGLE_CLOUD_PROJECT).");
        process.exit(1);
    }

    admin.initializeApp({ projectId });
    admin.firestore().settings({ ignoreUndefinedProperties: false });

    recomputeHealth(admin.firestore(), new HealthRepositoryImpl(), { dryRun, workspaceId })
        .then((summary) => process.exit(summary.failed > 0 ? 1 : 0))
        .catch((e) => {
            console.error("[recompute_health] Erro fatal:", e);
            process.exit(1);
        });
}
