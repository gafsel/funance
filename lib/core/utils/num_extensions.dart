import 'package:intl/intl.dart';

extension NumExtensions on num {
  static NumberFormat _compactFormat(String? locale) =>
      NumberFormat.compact(locale: locale);

  String asCurrency({String? locale}) {
    return NumberFormat.simpleCurrency(locale: locale).format(this);
  }

  String asCompact({String? locale}) {
    return _compactFormat(locale).format(this);
  }

  String asPercent({String? locale}) {
    return "${(this * 100).asCompact(locale: locale)}%";
  }

  String asSignedCurrency({String? locale}) {
    final sign = this >= 0 ? '+' : '';
    return '$sign${asCurrency(locale: locale)}';
  }
}
