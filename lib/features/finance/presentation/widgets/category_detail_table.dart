import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
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
    final isExpense = type == CategoryType.expense;

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        columns: [
          DataColumn(
            label: Text(
              l10n.category,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              l10n.overviewPlanning,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              l10n.overviewEffective,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              l10n.realization,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              l10n.difference,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: summaries.map((summary) {
          final realization = summary.plannedAmount > 0
              ? (summary.actualAmount / summary.plannedAmount)
              : 0.0;
          final difference = summary.actualAmount - summary.plannedAmount;
          
          Color statusColor;
          IconData statusIcon;

          if (summary.actualAmount == 0) {
            statusColor = Colors.grey;
            statusIcon = Icons.do_not_disturb_on;
          } else if (summary.actualAmount == summary.plannedAmount) {
            statusColor = AppColors.success;
            statusIcon = Icons.check_circle;
          } else {
            final isSuccess = isExpense
                ? summary.actualAmount < summary.plannedAmount
                : summary.actualAmount > summary.plannedAmount;
            
            statusColor = isSuccess ? AppColors.brightCyan : AppColors.error;
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
                      color: summary.category.color.asColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(summary.category.displayName(context.l10n)),
                  ],
                ),
              ),
              DataCell(Text(summary.plannedAmount.asCurrency(locale: locale))),
              DataCell(Text(summary.actualAmount.asCurrency(locale: locale))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    realization.asPercent(locale: context.locale),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  spacing: 8,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                    if (difference != 0)
                      Text(
                        diffText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
