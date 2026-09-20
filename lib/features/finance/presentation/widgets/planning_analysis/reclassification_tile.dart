import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

/// Sugestão de mudar a alocação de uma categoria, com o botão que aplica.
///
/// É o único item da análise que MUDA dado do usuário — reclassificar mexe na
/// categoria de verdade. Quem escreve é a folha, que conhece o serviço e sabe
/// remover o item da lista depois; aqui fica só o "de → para" e o botão.
class ReclassificationTile extends StatelessWidget {
  final Planning503020AnalysisCategory item;
  final String currentLabel;
  final String suggestedLabel;
  final VoidCallback onApply;

  const ReclassificationTile({
    super.key,
    required this.item,
    required this.currentLabel,
    required this.suggestedLabel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        padding: AppSpacing.allSm,
        // O aro dourado marca a sugestão sem usar `rewarded`, que é reservado
        // a conquista.
        borderColor: AppColors.goldDeep.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.categoryName, style: theme.textTheme.titleSmall),
            AppSpacing.gapXxs,
            Row(
              children: [
                Text(currentLabel, style: theme.textTheme.labelSmall),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: Icon(Icons.arrow_forward, size: 14),
                ),
                Text(
                  suggestedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ],
            ),
            if (item.reason.isNotEmpty) ...[
              AppSpacing.gapXxs,
              Text(
                item.reason,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.ink2,
                ),
              ),
            ],
            AppSpacing.gapXs,
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.planningAnalysisApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
