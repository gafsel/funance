import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
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
    
    final realization = summary.plannedAmount > 0 
        ? (summary.actualAmount / summary.plannedAmount)
        : 0.0;
    
    final difference = summary.actualAmount - summary.plannedAmount;
    final isExpense = type == CategoryType.expense;
    
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
            ? l10n.exceededAmount(difference.abs().asCurrency(locale: locale))
            : l10n.missingAmount(difference.abs().asCurrency(locale: locale)));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: summary.category.color.asColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    summary.category.icon.asIcon(),
                    color: summary.category.color.asColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary.category.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildValue(l10n.overviewPlanning, summary.plannedAmount.asCurrency(locale: locale), theme)),
                Expanded(child: _buildValue(l10n.overviewEffective, summary.actualAmount.asCurrency(locale: locale), theme)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.realization, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          realization.asPercent(locale: context.locale),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildValue(String label, String value, ThemeData theme, {bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value, 
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
