import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

/// Barra de um dos três grupos do 50-30-20: atual contra a meta.
///
/// O traço escuro vertical é a meta; o preenchimento é onde o mês está. É por
/// isso que a barra precisa de `LayoutBuilder` — a posição do traço é uma
/// fração da largura real, não um `FractionallySizedBox`, que só sabe esticar o
/// filho e não marcar um ponto.
class AllocationBar extends StatelessWidget {
  final String label;
  final Planning503020AnalysisGroup group;

  const AllocationBar({
    super.key,
    required this.label,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;
    final isOver = group.currentPct > group.targetPct;
    final barColor = isOver ? AppColors.coralOrange : AppColors.limeGreen;

    final deltaText = group.deltaBRL > 0
        ? l10n.planningAnalysisAboveBy(
            group.deltaBRL.asCurrency(locale: locale),
          )
        : group.deltaBRL < 0
        ? l10n.planningAnalysisBelowBy(
            (-group.deltaBRL).asCurrency(locale: locale),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${l10n.planningAnalysisCurrentPct((group.currentPct / 100).asPercent(locale: locale))} · '
              '${l10n.planningAnalysisTargetPct((group.targetPct / 100).asPercent(locale: locale))}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 12,
                  width: maxWidth * (group.currentPct / 100).clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Positioned(
                  left: (maxWidth * (group.targetPct / 100)).clamp(
                    0.0,
                    maxWidth - 2,
                  ),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: AppColors.darkNavy),
                ),
              ],
            );
          },
        ),
        if (deltaText != null) ...[
          const SizedBox(height: 2),
          Text(
            deltaText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOver ? AppColors.coralOrange : AppColors.vibrantTeal,
            ),
          ),
        ],
      ],
    );
  }
}
