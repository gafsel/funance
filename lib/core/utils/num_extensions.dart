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

  /// O dinheiro como o JOGO o mostra: `R$ 12,1k`, `R$ 980`, `R$ 1,2M`.
  ///
  /// Decisão do dono: a cena é "uma referência lúdica do estado da semana", e
  /// `R$ 12.122,33` é um número de extrato — onze caracteres que obrigam a
  /// contar casas para saber a ordem de grandeza. Na barra de vida o que
  /// importa é "doze mil", e os centavos ainda custavam largura justamente
  /// onde ela é escassa: a 400px o placar tem duas colunas e um marcador de
  /// dia no meio.
  ///
  /// As regras, todas elas:
  ///
  /// - **abaixo de mil**, o valor inteiro e nada mais: `R$ 980`. Os centavos
  ///   somem sempre — eles nunca mudam a leitura de uma barra;
  /// - **de mil a um milhão**, milhares com UMA casa: `R$ 12,1k`. A casa cai
  ///   quando ela é zero (`R$ 12k` e não `R$ 12,0k`): a casa decimal existe
  ///   para separar 12,1 de 12,9, e um zero ali só ocupa espaço;
  /// - **de um milhão para cima**, a mesma regra com `M`: `R$ 1,2M`;
  /// - **negativo** leva o menos tipográfico (`−`), o mesmo que a cena usa nos
  ///   números que descem. Um valor que ARREDONDA para zero não leva sinal
  ///   nenhum — `−R$ 0` afirmaria uma perda de nada.
  ///
  /// O corte de faixa é feito sobre o valor JÁ ARREDONDADO: por ordem de
  /// grandeza crua, `R$ 999.999,00` cairia na faixa dos milhares e sairia
  /// como `R$ 1.000,0k`, que é pior que o número exato. Aqui ele é `R$ 1M`.
  ///
  /// O símbolo e o separador decimal vêm do locale (`R$ 12,1k` em português,
  /// `$12.1k` em inglês). Os sufixos `k` e `M` são os mesmos nos dois: foi o
  /// que o dono escreveu, e são o que o público de jogo lê sem legenda.
  ///
  /// **As folhas de detalhe continuam em [asCurrency].** Este formatador é
  /// para o relance; quando o usuário toca para ver o que compõe o número,
  /// ele tem direito aos centavos.
  String asCompactCurrency({String? locale}) {
    final value = toDouble();
    final abs = value.abs();

    // Os limiares não são 1e6 e 1e3: são o ponto a partir do qual o
    // ARREDONDAMENTO da faixa de cima já devolve 1,0. Ver a explicação acima.
    final (double scaled, String suffix) = abs >= 999950
        ? (abs / 1000000, 'M')
        : abs >= 999.5
        ? (abs / 1000, 'k')
        : (abs, '');

    // Sem sufixo o número é inteiro; com sufixo ele tem uma casa — e a casa
    // desaparece quando é zero.
    final rounded = suffix.isEmpty
        ? scaled.roundToDouble()
        : (scaled * 10).roundToDouble() / 10;
    final decimals = rounded == rounded.roundToDouble() ? 0 : 1;

    final text = NumberFormat.simpleCurrency(
      locale: locale,
      decimalDigits: decimals,
    ).format(rounded);

    return '${value < 0 && rounded != 0 ? '−' : ''}$text$suffix';
  }
}
