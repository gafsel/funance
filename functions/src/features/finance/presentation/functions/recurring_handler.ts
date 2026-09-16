import { onSchedule } from "firebase-functions/v2/scheduler";
import { container } from "../../../../core/container";

/**
 * Fuso dos crons de manutenção. O cliente e o negócio raciocinam em horário de
 * Brasília; sem `timeZone` o agendador usa UTC e o "03:30" viraria 00:30 local.
 */
export const FINANCE_CRON_TIME_ZONE = "America/Sao_Paulo";

/**
 * Geração de parcelas recorrentes: DIÁRIA, de madrugada.
 *
 * Antes rodava "every 4 hours" — 6 varreduras por dia de uma tarefa cuja
 * unidade de avanço é o MÊS (a order só ganha parcela quando o horizonte de
 * previsibilidade passa de mês). As cinco execuções extras só custavam leituras
 * de collection group e competiam com o tráfego do usuário.
 */
export const generateRecurringInstallments = onSchedule(
    {
        schedule: "30 3 * * *",
        timeZone: FINANCE_CRON_TIME_ZONE,
    },
    async () => {
        const financeService = container.financeService;

        console.log("Iniciando geração de parcelas recorrentes...");
        try {
            await financeService.generateRecurringInstallments();
            console.log("Geração de parcelas recorrentes finalizada com sucesso.");
        }
        catch (error) {
            console.error("Erro ao gerar parcelas recorrentes:", error);
        }
    }
);

/**
 * F1.9 — reafirma `currentWeekId`/`currentWeekStart` em todos os workspaces.
 *
 * Roda no DOMINGO de madrugada, logo depois da virada da semana no fuso do
 * produto, para que o cliente leia a semana corrente do servidor em vez de
 * calculá-la. Fora do cron, o marcador também é reafirmado sob demanda por
 * qualquer handler que mexa em dado semanal (ver `WeekSyncService`).
 */
export const syncWorkspaceCurrentWeek = onSchedule(
    {
        schedule: "10 0 * * 0",
        timeZone: FINANCE_CRON_TIME_ZONE,
    },
    async () => {
        try {
            const result = await container.weekSyncService.syncAllWorkspaces();
            console.log(`Semana corrente sincronizada: ${result.updated} de ${result.scanned} workspaces atualizados.`);
        }
        catch (error) {
            console.error("Erro ao sincronizar a semana corrente dos workspaces:", error);
        }
    }
);

export const generateCategoryPlanningSummaries = onSchedule(
    {
        // Todo dia 1 do mês, à meia-noite de Brasília.
        schedule: "0 0 1 * *",
        timeZone: FINANCE_CRON_TIME_ZONE,
    },
    async () => {
        const summaryService = container.summaryService;

        console.log("Iniciando geração de summaries de planejamento...");
        try {
            await summaryService.generateCategoryPlanningSummaries();
            console.log("Geração de summaries de planejamento finalizada com sucesso.");
        }
        catch (error) {
            console.error("Erro ao gerar summaries de planejamento:", error);
        }
    }
);
