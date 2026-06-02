import { onSchedule } from "firebase-functions/v2/scheduler";
import { container } from "../../../../core/container";

export const generateRecurringInstallments = onSchedule(
    "every 4 hours",
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
    "0 0 1 * *", // Todo dia 1 do mês à meia-noite
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
