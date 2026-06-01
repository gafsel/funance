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
        } catch (error) {
            console.error("Erro ao gerar parcelas recorrentes:", error);
        }
    }
);
