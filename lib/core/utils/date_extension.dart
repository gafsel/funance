import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  get formatedAsIso {
    return formated("yyyy-MM-dd'T'HH:mm:ss.SSS") + "Z";
  }

  String formated([String pattern = "dd/MM/yyyy", String? locale]) {
    return DateFormat(pattern, locale).format(this);
  }
}
