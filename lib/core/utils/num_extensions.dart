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

  /// O valor com sinal EXPLÍCITO quando ele é uma variação.
  ///
  /// Zero não leva sinal. O `+` afirma que algo subiu, e "+R$ 0,00" afirma
  /// uma subida de nada — uma semana sem movimento aparecia como se tivesse
  /// tido um ganho. É a mesma regra de `AppPalette.moneyInk`, que também
  /// trata zero como neutro de propósito: um saldo zerado não é uma boa nem
  /// uma má notícia.
  String asSignedCurrency({String? locale}) {
    final sign = this > 0 ? '+' : '';
    return '$sign${asCurrency(locale: locale)}';
  }
}
