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
