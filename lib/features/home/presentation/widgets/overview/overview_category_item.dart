import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

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
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            Text(
              amount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepTurquoise,
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: AppColors.deepTurquoise.withValues(alpha: 0.1),
                ),
                if (secondaryProgress != null)
                  FractionallySizedBox(
                    widthFactor: secondaryProgress,
                    child: Container(
                      height: 8,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: 8,
                    color: progress > 1 ? AppColors.coralOrange : color,
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
