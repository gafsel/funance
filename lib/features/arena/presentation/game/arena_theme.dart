import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_typography.dart';

/// As decisões de cor, tipo e movimento que a cena do Flame precisa.
///
/// O Flame não tem `BuildContext`: um componente não consegue ler
/// `context.palette` nem `theme.textTheme`. Sem um objeto como este, cada
/// partícula e cada número flutuante acabaria com um hexadecimal escrito à
/// mão dentro do jogo — exatamente o que `test/design_hygiene_test.dart`
/// existe para impedir. Aqui os tokens atravessam a fronteira **uma vez**, no
/// `build` da tela.
@immutable
class ArenaTheme {
  const ArenaTheme({
    required this.heal,
    required this.damage,
    required this.gold,
    required this.ink,
    required this.ink2,
    required this.shadow,
    required this.exhaustion,
    required this.numberStyle,
    required this.labelStyle,
    required this.reduceMotion,
  });

  /// Lida do `BuildContext` da tela — o único lugar onde ela pode ser lida.
  factory ArenaTheme.of(BuildContext context) {
    final palette = context.palette;

    return ArenaTheme(
      heal: palette.successText,
      damage: palette.dangerText,
      gold: AppColors.gold,
      ink: palette.onGame,
      ink2: palette.onGame2,
      // A sombra no chão e o filtro de exaustão são o MESMO preto do fundo
      // profundo, em opacidades diferentes: qualquer outro cinza brigaria com
      // o azul da identidade.
      shadow: AppColors.surfaceDeep.withValues(alpha: 0.35),
      exhaustion: AppColors.surfaceDeep.withValues(alpha: 0.55),
      numberStyle: AppTypography.counter(palette.onGame),
      labelStyle: AppTypography.body14(palette.onGame2),
      reduceMotion: AppDurations.reduceMotion(context),
    );
  }

  final Color heal;
  final Color damage;
  final Color gold;
  final Color ink;
  final Color ink2;
  final Color shadow;
  final Color exhaustion;

  /// Base dos números flutuantes (+R$ / −R$). O tamanho é reescrito para
  /// unidades de mundo por quem desenha.
  final TextStyle numberStyle;

  /// Base do nome do herói e da cicatriz do monstro.
  final TextStyle labelStyle;

  /// `MediaQuery.disableAnimations`. Quando verdadeiro, a cena **mostra o
  /// resultado** em vez de animá-lo: nada de tremor, avanço ou moeda voando.
  final bool reduceMotion;

  @override
  bool operator ==(Object other) =>
      other is ArenaTheme &&
      other.heal == heal &&
      other.damage == damage &&
      other.gold == gold &&
      other.ink == ink &&
      other.ink2 == ink2 &&
      other.shadow == shadow &&
      other.exhaustion == exhaustion &&
      other.numberStyle == numberStyle &&
      other.labelStyle == labelStyle &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(
    heal,
    damage,
    gold,
    ink,
    ink2,
    shadow,
    exhaustion,
    numberStyle,
    labelStyle,
    reduceMotion,
  );
}
