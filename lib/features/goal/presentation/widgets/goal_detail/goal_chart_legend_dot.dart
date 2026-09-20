import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Ponto de legenda do gráfico de progresso da meta.
///
/// Fica sobre o cabeçalho colorido da tela, e não sobre o fundo do app: por
/// isso as cores são fixas em branco translúcido em vez de saírem do tema.
/// Trocar por `colorScheme` aqui some com a legenda no tema claro.
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.brXs),
        ),
        AppSpacing.gapXxs,
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.inkInverse2),
        ),
      ],
    );
  }
}
