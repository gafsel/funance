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
  ///
  /// O sinal é decidido sobre o valor JÁ ARREDONDADO aos centavos, e não
  /// sobre o double cru. Uma soma de frações devolve `0,004` ou `-0,004`
  /// o tempo todo, e o texto deles é "R$ 0,00" nos dois casos: pelo valor
  /// cru, um saía com `+` e o outro com `−` — dois sinais opostos para a
  /// mesma frase. `-0.0` é o mesmo caso, e `> 0` sozinho já o resolvia por
  /// acidente, não por regra.
  String asSignedCurrency({String? locale}) {
    final cents = (this * 100).round();
    // Arredondado a zero, o valor é formatado como ZERO e não como ele
    // mesmo: `-0,004` sai de `asCurrency` como "-R$ 0,00", um sinal de menos
    // grudado num nada.
    if (cents == 0) return 0.asCurrency(locale: locale);
    return '${cents > 0 ? '+' : ''}${asCurrency(locale: locale)}';
  }
}
