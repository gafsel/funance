import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class CategoryDetailItem extends StatelessWidget {
  final OverviewCategorySummary summary;
  final CategoryType type;
  final String locale;

  const CategoryDetailItem({
    super.key,
    required this.summary,
    required this.type,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    final realization = summary.plannedAmount > 0
        ? (summary.actualAmount / summary.plannedAmount)
        : 0.0;

    final difference = summary.actualAmount - summary.plannedAmount;
    final isExpense = type == CategoryType.expense;

    Color statusColor;
    IconData statusIcon;

    if (summary.actualAmount == 0) {
      statusColor = palette.ink3;
      statusIcon = Icons.do_not_disturb_on;
    } else if (summary.actualAmount == summary.plannedAmount) {
      statusColor = palette.successText;
      statusIcon = Icons.check_circle;
    } else {
      final isSuccess = isExpense
          ? summary.actualAmount < summary.plannedAmount
          : summary.actualAmount > summary.plannedAmount;

      statusColor = isSuccess ? palette.tealText : palette.dangerText;
      statusIcon = isSuccess ? Icons.check_circle : Icons.error;
    }

    final diffText = difference == 0
        ? '-'
        : (difference > 0
              ? l10n.exceededAmount(difference.abs().asCurrency(locale: locale))
              : l10n.missingAmount(
                  difference.abs().asCurrency(locale: locale),
                ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: AppCard(
        padding: AppSpacing.allSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: AppSpacing.allXs,
                  decoration: BoxDecoration(
                    // A cor da categoria é DADO: vem do que o usuário
                    // escolheu, não do tema.
                    color: summary.category.color.asColor().withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    summary.category.icon.asIcon(),
                    color: summary.category.color.asColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    summary.category.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Icon(statusIcon, color: statusColor, size: 20),
              ],
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: _buildAmount(
                    l10n.overviewPlanning,
                    summary.plannedAmount,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildAmount(
                    l10n.overviewEffective,
                    summary.actualAmount,
                    theme,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.realization, style: theme.textTheme.bodySmall),
                      AppSpacing.gapXxs,
                      StatusPill(
                        label: realization.asPercent(locale: context.locale),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildValue(
                    l10n.difference,
                    diffText,
                    theme,
                    isBold: true,
                    valueColor: difference == 0 ? null : statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmount(String label, double amount, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        AppSpacing.gapXxs,
        MoneyText(amount, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildValue(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        AppSpacing.gapXxs,
        Text(
          value,
          style:
              (isBold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
                  ?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
