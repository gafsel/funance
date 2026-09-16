import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String get formatedAsIso {
    return "${formated("yyyy-MM-dd'T'HH:mm:ss.SSS")}Z";
  }

  String formated([String pattern = "dd/MM/yyyy", String? locale]) {
    return DateFormat(pattern, locale).format(this);
  }

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
