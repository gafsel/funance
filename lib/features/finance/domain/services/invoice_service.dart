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

  /// Data com o dia limitado ao último dia do mês (fechamento dia 31 em
  /// fevereiro vira 28/29 em vez de estourar para março). O overflow de mês
  /// (0, 13...) é normalizado pelo próprio DateTime.
  static DateTime _dateWithClampedDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  /// Calcula o range de datas (inclusive nas duas pontas) das transações que
  /// pertencem à fatura com vencimento em [invoiceDueDate].
  ///
  /// Regra de atribuição (mesma de [calculateInvoiceDueDate]): uma compra no
  /// próprio dia do fechamento já pertence à fatura SEGUINTE. Logo o ciclo vai
  /// do dia do fechamento anterior (inclusive) até a véspera do fechamento
  /// atual (inclusive) — o dia do fechamento atual fica de fora por completo.
  ///
  /// As bordas usam meia-noite/23:59:59 de propósito: as transações são
  /// normalizadas para 12:00, mas em fusos diferentes conforme a origem
  /// (12:00 local no app, 12:00 UTC no servidor). Bordas ao meio-dia faziam o
  /// dia de fechamento entrar ou sair da fatura dependendo de quem gravou.
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
    final currentClosingDate = _dateWithClampedDay(
      invoiceDueDate.year,
      isDueInNextMonth ? invoiceDueDate.month - 1 : invoiceDueDate.month,
      closingDay,
    );

    final previousClosingDate = _dateWithClampedDay(
      currentClosingDate.year,
      currentClosingDate.month - 1,
      closingDay,
    );

    return (
      previousClosingDate, // 00:00 do dia do fechamento anterior
      currentClosingDate.subtract(const Duration(seconds: 1)), // 23:59:59 da véspera do fechamento
    );
  }
}
