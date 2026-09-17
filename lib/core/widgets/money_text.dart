import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../utils/build_context_extension.dart';
import '../utils/num_extensions.dart';

/// Um valor monetário na tela.
///
/// Três coisas que nenhuma das dezenas de `Text(valor.asCurrency())` do app
/// fazia de forma consistente:
///
/// 1. **Algarismos tabulares.** Sem eles, uma coluna de valores dança a cada
///    atualização e os pontos decimais não se alinham entre linhas.
/// 2. **Cor pelo sinal**, e só quando o sinal importa. Um saldo negativo é
///    vermelho; o *total de despesas do mês* não é — ele é negativo por
///    definição, e pintá-lo de vermelho todo mês não informa nada.
/// 3. **Sinal explícito** quando o widget está mostrando uma variação, não um
///    saldo.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.value, {
    super.key,
    this.style,
    this.colorBySign = false,
    this.showSign = false,
    this.compact = false,
    this.textAlign,
    this.maxLines = 1,
    this.hero = false,
  });

  /// Variação: sinal explícito e cor pelo sinal. Para "▲ R$ 1.200 esta
  /// semana", "+ R$ 450", "− R$ 62,90".
  const MoneyText.delta(
    double value, {
    Key? key,
    TextStyle? style,
    bool compact = false,
    TextAlign? textAlign,
  }) : this(
         value,
         key: key,
         style: style,
         colorBySign: true,
         showSign: true,
         compact: compact,
         textAlign: textAlign,
       );

  /// Número grande de destaque: saldo do mês, total da fatura, valor da meta.
  const MoneyText.hero(
    double value, {
    Key? key,
    bool colorBySign = false,
    TextAlign? textAlign,
  }) : this(
         value,
         key: key,
         colorBySign: colorBySign,
         textAlign: textAlign,
         hero: true,
       );

  final double value;
  final TextStyle? style;
  final bool colorBySign;
  final bool showSign;

  /// Forma curta ("R$ 4,3 mil"). Só para gráfico e rótulo de eixo — nunca
  /// para um valor que o usuário precise conferir.
  final bool compact;

  final TextAlign? textAlign;
  final int? maxLines;

  /// Escala de destaque (32/38, display, tabular).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final locale = context.locale;

    final text = compact
        ? value.asCompact(locale: locale)
        : (showSign
              ? value.asSignedCurrency(locale: locale)
              : value.asCurrency(locale: locale));

    final base =
        style ??
        (hero
            ? AppTypography.hero(palette.ink)
            : theme.textTheme.bodyMedium ?? const TextStyle());

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: base.tabularFigures.copyWith(
        color: colorBySign ? palette.moneyInk(value) : base.color,
      ),
    );
  }
}
