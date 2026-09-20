import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/presentation/display_names.dart';

class CategoryDetailTable extends StatelessWidget {
  final List<OverviewCategorySummary> summaries;
  final CategoryType type;
  final String locale;

  const CategoryDetailTable({
    super.key,
    required this.summaries,
    required this.type,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final isExpense = type == CategoryType.expense;

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: AppSpacing.lg,
        columns: [
          DataColumn(label: Text(l10n.category)),
          DataColumn(label: Text(l10n.overviewPlanning), numeric: true),
          DataColumn(label: Text(l10n.overviewEffective), numeric: true),
          DataColumn(label: Text(l10n.realization), numeric: true),
          DataColumn(label: Text(l10n.difference)),
        ],
        rows: summaries.map((summary) {
          final realization = summary.plannedAmount > 0
              ? (summary.actualAmount / summary.plannedAmount)
              : 0.0;
          final difference = summary.actualAmount - summary.plannedAmount;

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
                    ? l10n.exceededAmount(
                        difference.abs().asCurrency(locale: locale),
                      )
                    : l10n.missingAmount(
                        difference.abs().asCurrency(locale: locale),
                      ));

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      summary.category.icon.asIcon(),
                      // A cor da categoria é DADO, escolhida pelo usuário.
                      color: summary.category.color.asColor(),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(summary.category.displayName(context.l10n)),
                  ],
                ),
              ),
              DataCell(MoneyText(summary.plannedAmount)),
              DataCell(MoneyText(summary.actualAmount)),
              DataCell(
                StatusPill(
                  label: realization.asPercent(locale: context.locale),
                  color: statusColor,
                ),
              ),
              DataCell(
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    if (difference != 0)
                      Text(
                        diffText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
