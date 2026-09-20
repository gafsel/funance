import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Uma linha da legenda: bolinha da cor da categoria, nome, valor e — quando
/// há progresso — a barra de execução.
///
/// A barra tem duas camadas porque no modo Planejamento o total da categoria
/// é a soma do que foi planejado nela especificamente com a fatia que vem do
/// planejamento geral; a camada cinza atrás é essa fatia específica. Estourar
/// o planejado pinta a barra de laranja em vez de deixá-la passar de 100% sem
/// aviso.
Widget buildOverviewCategoryItem(
  BuildContext context,
  String name,
  String amount,
  Color color, {
  double? progress,
  double? secondaryProgress,
}) {
  final theme = Theme.of(context);
  final palette = context.palette;
  return Padding(
    padding: AppSpacing.vXs,
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            Text(
              amount,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.ink),
            ),
          ],
        ),
        if (progress != null) ...[
          AppSpacing.gapXs,
          // Duas camadas: a de trás é a fatia que veio do planejamento geral.
          // `AppProgressBar` desenha uma só, e perder a segunda camada
          // mudaria o que a linha informa.
          ClipRRect(
            borderRadius: AppRadius.brXs,
            child: Stack(
              children: [
                Container(
                  height: AppSpacing.xs,
                  width: double.infinity,
                  color: palette.line,
                ),
                if (secondaryProgress != null)
                  FractionallySizedBox(
                    widthFactor: secondaryProgress,
                    child: Container(
                      height: AppSpacing.xs,
                      color: palette.ink3,
                    ),
                  ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: AppSpacing.xs,
                    color: progress > 1 ? AppColors.warning : color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
