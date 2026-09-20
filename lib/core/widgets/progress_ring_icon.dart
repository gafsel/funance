import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Um ícone dentro de um anel de progresso.
///
/// É a peça que a Party da Visão Geral usava para desenhar cada categoria —
/// o anel dizia quanta vida o desafio tinha, o disco de trás dava a cor da
/// categoria e o pictograma dizia qual era. A Party saiu da Visão Geral
/// (decisão 9 do dono: *"essa visão não faz mais sentido com a nova visão de
/// jogo"*), mas o desenho não tinha nada de errado — ele é uma boa forma de
/// mostrar "um item, um estado, um quanto" numa grade.
///
/// Por isso ele mora aqui e não lá: a vila do HUD mensal vai montar uma grade
/// no mesmo formato, e a alternativa seria a segunda grade nascer com um
/// segundo desenho do mesmo anel.
///
/// Widget puro — nenhum provider, nenhuma decisão de domínio. Quem passa
/// `progress` já o calculou, e quem passa `color` já julgou.
class ProgressRingIcon extends StatelessWidget {
  const ProgressRingIcon({
    super.key,
    required this.progress,
    required this.icon,
    required this.color,
    this.iconColor,
    this.diameter = 40,
    this.strokeWidth = 4,
    this.iconSize = 24,
    this.semanticLabel,
  });

  /// De 0 a 1. Fora dessa faixa, o anel vem preso.
  final double progress;

  final IconData icon;

  /// A tinta do anel — e do disco de trás, quando [iconColor] não diz outra.
  final Color color;

  /// A tinta do pictograma e do disco. Quando o anel JULGA (verde, âmbar,
  /// vermelho) e o ícone IDENTIFICA (a cor da categoria), as duas são
  /// diferentes.
  final Color? iconColor;

  final double diameter;
  final double strokeWidth;
  final double iconSize;

  /// O que o anel diz, para quem não o vê.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? color;

    return Semantics(
      label: semanticLabel,
      value: semanticLabel == null
          ? null
          : '${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Container(
              padding: AppSpacing.allXxs,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
