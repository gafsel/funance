import 'package:funances/features/finance/domain/models/account_model.dart';

class InvoiceService {
  static const List<String> holidays = [
    "01-01", // Ano Novo
    "04-21", // Tiradentes
    "05-01", // Dia do Trabalho
    "09-07", // Independência
    "10-12", // Padroeira
    "11-02", // Finados
    "11-15", // Proclamação da República
    "12-25", // Natal
  ];

  static bool isHoliday(DateTime date) {
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return holidays.contains("$month-$day");
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static DateTime getNextBusinessDay(DateTime date) {
    DateTime nextDate = date;
    while (isWeekend(nextDate) || isHoliday(nextDate)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    return nextDate;
  }

  static DateTime calculateInvoiceDueDate(DateTime paymentDate, AccountModel account) {
    if (account is! CreditCardAccount) {
      return paymentDate;
    }

    final closingDay = account.closingDay;
    final dueDay = account.dueDay;

    // Se a transação for em fim de semana ou feriado, usa o próximo dia útil como referência
    final referenceDate = getNextBusinessDay(paymentDate);

    final refYear = referenceDate.year;
    final refMonth = referenceDate.month;
    final refDay = referenceDate.day;

    // Se o dia de vencimento for menor que o dia de fechamento, o vencimento é no mês seguinte
    final isDueInNextMonth = dueDay < closingDay;

    DateTime invoiceDueDate;

    if (refDay < closingDay) {
      // Impacta o vencimento correspondente ao fechamento deste mês
      int dueMonth = isDueInNextMonth ? refMonth + 1 : refMonth;
      int dueYear = refYear;
      if (dueMonth > 12) {
        dueMonth -= 12;
        dueYear++;
      }
      invoiceDueDate = DateTime(dueYear, dueMonth, dueDay, 12);
    } else {
      // Impacta o vencimento correspondente ao fechamento do PRÓXIMO mês
      int dueMonth = isDueInNextMonth ? refMonth + 2 : refMonth + 1;
      int dueYear = refYear;
      if (dueMonth > 12) {
        dueMonth -= 12;
        dueYear++;
      }
      invoiceDueDate = DateTime(dueYear, dueMonth, dueDay, 12);
    }

    return invoiceDueDate;
  }

  /// Calcula o range de datas (inclusive) das transações que pertencem a uma fatura com vencimento em [invoiceDueDate].
  static (DateTime, DateTime) calculateInvoiceCycleRange(DateTime invoiceDueDate, AccountModel account) {
    if (account is! CreditCardAccount) {
      return (invoiceDueDate, invoiceDueDate);
    }

    final closingDay = account.closingDay;
    final dueDay = account.dueDay;
    final isDueInNextMonth = dueDay < closingDay;

    // O fechamento que gerou esse vencimento:
    // Se isDueInNextMonth for true, invoiceDueDate.month = closingMonth + 1
    // Caso contrário, invoiceDueDate.month = closingMonth
    
    DateTime currentClosingDate = DateTime(
      invoiceDueDate.year,
      isDueInNextMonth ? invoiceDueDate.month - 1 : invoiceDueDate.month,
      closingDay,
      12
    );
    
    // Se por algum motivo o mês ficou inválido (ex: subtraiu 1 de janeiro)
    if (currentClosingDate.month != (isDueInNextMonth ? (invoiceDueDate.month - 1 == 0 ? 12 : invoiceDueDate.month - 1) : invoiceDueDate.month)) {
       // Ajuste manual se necessário, mas o construtor do DateTime costuma lidar com isso.
       // Ex: DateTime(2024, 0, 10) vira 2023-12-10.
    }

    // O fechamento anterior:
    DateTime previousClosingDate = DateTime(
      currentClosingDate.year,
      currentClosingDate.month - 1,
      closingDay,
      12
    );

    // O range da fatura é:
    // Início: Próximo dia útil após o fechamento anterior (inclusive)
    // Fim: Dia anterior ao próximo dia útil após o fechamento atual (inclusive)
    // Na verdade, a lógica simplificada do calculateInvoiceDueDate usa o nextBusinessDay da transação.
    // Então, transação T pertence à fatura se getNextBusinessDay(T).day estiver entre previousClosingDate e currentClosingDate.

    // Vamos definir o range como:
    // Start: Dia que, se for a data de referência, cai nesta fatura.
    // O primeiro dia que cai nesta fatura é o dia do fechamento anterior.
    // Se refDay >= closingDay, cai na fatura do mês seguinte.
    // Então para a fatura atual (que tem fechamento em currentClosingDate),
    // a data de referência deve ser >= previousClosingDate AND < currentClosingDate.

    return (previousClosingDate, currentClosingDate.subtract(const Duration(seconds: 1)));
  }
}
