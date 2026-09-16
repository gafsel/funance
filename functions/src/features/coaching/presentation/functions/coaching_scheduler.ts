import { onSchedule } from "firebase-functions/v2/scheduler";
import { container } from "../../../../core/container";
import { AI_SCHEDULE_OPTIONS } from "../../../../core/config/functions.config";

const ACTIVITY_WINDOW_DAYS = 14;

/**
 * Coaching proativo: toda segunda-feira às 06:00 (America/Sao_Paulo) gera o insight
 * automaticamente para workspaces com atividade recente (alguma parcela paga nos
 * últimos 14 dias), gravando o resultado server-side.
 *
 * Reusa CoachingService.generateCoaching, que já:
 * - retorna o insight existente se houver um com menos de 5 dias (evita chamadas desnecessárias ao Gemini);
 * - persiste o documento em workspaces/{id}/financial_coaching.
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
        const workspaceIds = await financeRepository.getAllWorkspaces();

        let generated = 0;
        let skipped = 0;
        let failed = 0;

        for (const workspaceId of workspaceIds) {
            try {
                const hasActivity = await financeRepository.hasPaidInstallmentSince(workspaceId, cutoff);
                if (!hasActivity) {
                    skipped++;
                    continue;
                }

                await coachingService.generateCoaching(workspaceId);
                generated++;
            }
            catch (error) {
                failed++;
                console.error(`Coaching proativo: falha no workspace ${workspaceId}:`, error);
            }
        }

        console.log(`Coaching proativo finalizado. Processados: ${generated}, sem atividade: ${skipped}, falhas: ${failed}.`);
    }
);
