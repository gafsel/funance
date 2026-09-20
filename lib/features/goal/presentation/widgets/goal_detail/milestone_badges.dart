import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Selos de 25%, 50%, 75% e 100% do progresso da meta.
///
/// Só aparecem em metas de acúmulo — em meta de redução, 100% é estourar o
/// orçamento, e comemorar isso seria premiar o erro. Quem decide se exibe é a
/// tela; este arquivo só sabe desenhar o selo aceso e o apagado.
class MilestoneBadges extends StatelessWidget {
  final double currentPercent;
  final Color statusColor;

  const MilestoneBadges({
    super.key,
    required this.currentPercent,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [25, 50, 75, 100];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((m) {
        final reached = (currentPercent * 100) >= m;
        return _Badge(label: '$m%', reached: reached, statusColor: statusColor);
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool reached;
  final Color statusColor;

  const _Badge({
    required this.label,
    required this.reached,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppDurations.respectingMotion(context, AppDurations.celebrate),
      curve: AppDurations.curve,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: reached
            ? LinearGradient(
                colors: [AppColors.progressStart, statusColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: reached ? null : AppColors.inkInverse.withValues(alpha: 0.1),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: reached
              ? AppColors.transparent
              : AppColors.inkInverse.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reached)
            const Icon(Icons.star, size: 12, color: AppColors.inkInverse),
          if (reached) AppSpacing.gapXxs,
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: reached
                  ? AppColors.inkInverse
                  : AppColors.inkInverse.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
