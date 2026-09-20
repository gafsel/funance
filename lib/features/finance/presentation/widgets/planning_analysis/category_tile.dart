import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

/// Cartão de uma categoria na análise 50-30-20: valor ideal e dica de economia.
///
/// Recebe cor e rótulo do status já resolvidos em vez de traduzir o enum aqui:
/// a folha é quem tem o `AppLocalizations` do contexto certo, e assim o cartão
/// serve igual se um dia a mesma análise for exibida fora do bottom sheet.
class CategoryTile extends StatelessWidget {
  final Planning503020AnalysisCategory category;
  final Color statusColor;
  final String statusLabel;

  const CategoryTile({
    super.key,
    required this.category,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final locale = context.locale;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        padding: AppSpacing.allSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                StatusPill(label: statusLabel, color: statusColor, dense: true),
              ],
            ),
            AppSpacing.gapXxs,
            Text(
              l10n.planningAnalysisIdealValue(
                category.idealMonthlyAmount.asCurrency(locale: locale),
                (category.idealPctOfIncome / 100).asPercent(locale: locale),
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (category.savingTip != null) ...[
              AppSpacing.gapXxs,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    size: 14,
                    color: AppColors.goldDeep,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      category.savingTip!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
