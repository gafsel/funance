import { AccountModel } from "../models/finance.models";

export class InvoiceService {
    private static HOLIDAYS = [
        "01-01", // Ano Novo
        "04-21", // Tiradentes
        "05-01", // Dia do Trabalho
        "09-07", // Independência
        "10-12", // Padroeira
        "11-02", // Finados
        "11-15", // Proclamação da República
        "12-25", // Natal
        // Datas móveis (Carnaval, Sexta-feira Santa, Corpus Christi) exigiriam cálculo mais complexo.
        // Por enquanto seguiremos com as fixas conforme o exemplo de "nacional" geralmente referenciado.
    ];

    static isHoliday(date: Date): boolean {
        const month = (date.getMonth() + 1).toString().padStart(2, "0");
        const day = date.getDate().toString().padStart(2, "0");
        return this.HOLIDAYS.includes(`${month}-${day}`);
    }

    static isWeekend(date: Date): boolean {
        const day = date.getDay();
        return day === 0 || day === 6; // 0 = Domingo, 6 = Sábado
    }

    static getNextBusinessDay(date: Date): Date {
        const nextDate = new Date(date);
        while (this.isWeekend(nextDate) || this.isHoliday(nextDate)) {
            nextDate.setDate(nextDate.getDate() + 1);
        }
        return nextDate;
    }

    static calculateInvoiceDueDate(paymentDate: Date, account: AccountModel): Date {
        const closingDay = account.closingDay || 5;
        const dueDay = account.dueDay || 10;

        // Se a transação for em fim de semana ou feriado, usa o próximo dia útil como referência
        const referenceDate = this.getNextBusinessDay(paymentDate);

        const refYear = referenceDate.getFullYear();
        const refMonth = referenceDate.getMonth();
        const refDay = referenceDate.getDate();

        // Se o dia de vencimento for menor que o dia de fechamento, o vencimento é no mês seguinte
        const isDueInNextMonth = dueDay < closingDay;

        let invoiceDueDate: Date;

        // Regras:
        // - transação até antes do fechamento => impacta a fatura do próximo vencimento
        // - transação entre o fechamento e o vencimento (se no mesmo mês) => impacta o vencimento do outro mês
        // - transação depois do fechamento => impacta o vencimento do mês seguinte (referente ao ciclo)

        if (refDay < closingDay) {
            // Impacta o vencimento correspondente ao fechamento deste mês
            // Se isDueInNextMonth for true, o vencimento deste fechamento é no mês seguinte
            const dueMonth = isDueInNextMonth ? refMonth + 1 : refMonth;
            invoiceDueDate = this.buildClampedDate(refYear, dueMonth, dueDay);
        }
        else {
            // Impacta o vencimento correspondente ao fechamento do PRÓXIMO mês
            // Se isDueInNextMonth for true, o vencimento desse fechamento será refMonth + 2
            const dueMonth = isDueInNextMonth ? refMonth + 2 : refMonth + 1;
            invoiceDueDate = this.buildClampedDate(refYear, dueMonth, dueDay);
        }

        return invoiceDueDate;
    }

    /**
     * Cria a data com o dia limitado ao último dia do mês (clamp), evitando que
     * vencimentos em dia 29-31 "estourem" para o mês seguinte (ex.: 31/02 virando 03/03),
     * o que geraria faturas duplicadas já que o id da fatura deriva da data.
     * Mesmo padrão usado em finance.service.ts na geração de installments.
     */
    static buildClampedDate(year: number, month: number, day: number): Date {
        // new Date normaliza month fora de 0-11 (ex.: 13 vira janeiro do ano seguinte)
        const normalized = new Date(year, month, 1, 12);
        const lastDayOfMonth = new Date(normalized.getFullYear(), normalized.getMonth() + 1, 0).getDate();
        return new Date(normalized.getFullYear(), normalized.getMonth(), Math.min(day, lastDayOfMonth), 12);
    }

}
