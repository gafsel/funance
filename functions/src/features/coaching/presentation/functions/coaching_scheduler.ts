import { onSchedule } from "firebase-functions/v2/scheduler";
import { container } from "../../../../core/container";
import {
    AI_SCHEDULE_OPTIONS,
    CRON_AI_WORKSPACE_CONCURRENCY,
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
} from "../../../../core/config/functions.config";
import { forEachWorkspacePaged } from "../../../../core/utils/cron_runner";

const ACTIVITY_WINDOW_DAYS = 14;

/** Chave ESTÁVEL do checkpoint (ver core/utils/cron_runner.ts). */
const CHECKPOINT_KEY = "weekly_coaching";

/**
 * Coaching proativo: toda segunda-feira às 06:00 (America/Sao_Paulo) gera o insight
 * automaticamente para workspaces com atividade recente (alguma parcela paga nos
 * últimos 14 dias), gravando o resultado server-side.
 *
 * Reusa CoachingService.generateCoaching, que já:
 * - retorna o insight existente se houver um com menos de 5 dias (evita chamadas desnecessárias ao Gemini);
 * - persiste o documento em workspaces/{id}/financial_coaching.
 *
 * A varredura é paginada com checkpoint (F5.5): quando o tempo acaba, a
 * execução para no workspace atual e a seguinte retoma dali, em vez de
 * recomeçar do zero e nunca alcançar o fim da coleção.
 */
export const generateWeeklyCoaching = onSchedule(
    {
        schedule: "0 6 * * 1",
        timeZone: "America/Sao_Paulo",
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        const financeRepository = container.financeRepository;
        const coachingService = container.coachingService;

        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - ACTIVITY_WINDOW_DAYS);

        console.log("Coaching proativo: iniciando varredura de workspaces...");

        let generated = 0;
        let skipped = 0;

        const result = await forEachWorkspacePaged(
            {
                checkpointKey: CHECKPOINT_KEY,
                pageSize: CRON_PAGE_SIZE,
                // Cada workspace pode virar uma chamada paga ao Gemini.
                concurrency: CRON_AI_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                const hasActivity = await financeRepository.hasPaidInstallmentSince(workspaceId, cutoff);
                if (!hasActivity) {
                    skipped++;
                    return;
                }

                await coachingService.generateCoaching(workspaceId);
                generated++;
            }
        );

        console.log(
            `Coaching proativo finalizado. Processados: ${generated}, sem atividade: ${skipped}, ` +
            `falhas: ${result.failed}. Varredura ${result.completed
                ? "completa"
                : `interrompida em ${result.lastWorkspaceId} (retoma na próxima execução)`}.`
        );
    }
);
