import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String get formatedAsIso {
    return "${formated("yyyy-MM-dd'T'HH:mm:ss.SSS")}Z";
  }

  String formated([String pattern = "dd/MM/yyyy", String? locale]) {
    return DateFormat(pattern, locale).format(this);
  }

  /// Soma (ou subtrai, com [days] negativo) dias de calendário.
  ///
  /// `add(Duration(days: n))` soma `n * 24h` absolutas: no dia em que o
  /// horário de verão começa ou termina isso cai uma hora antes ou depois da
  /// meia-noite pretendida. Reconstruir o `DateTime` pelos componentes deixa
  /// a própria plataforma resolver o fuso.
  DateTime addCalendarDays(int days) => DateTime(
    year,
    month,
    day + days,
    hour,
    minute,
    second,
    millisecond,
    microsecond,
  );

  /// Meia-noite local do dia seguinte a este.
  DateTime get nextMidnight => DateTime(year, month, day + 1);

  /// Chave de período mensal, `YYYY-MM`.
  ///
  /// Serve para chavear famílias de providers por mês: um `DateTime` como
  /// chave carrega hora, minuto e microssegundo e criaria uma família nova a
  /// cada instante.
  String get monthKey => "$year-${month.toString().padLeft(2, '0')}";

  static (int year, int month) parseMonthKey(String key) {
    final parts = key.split('-');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
