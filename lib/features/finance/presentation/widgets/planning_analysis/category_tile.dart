import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
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
    final locale = context.locale;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.categoryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.planningAnalysisIdealValue(
              category.idealMonthlyAmount.asCurrency(locale: locale),
              (category.idealPctOfIncome / 100).asPercent(locale: locale),
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (category.savingTip != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 14,
                  color: AppColors.antiqueGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.savingTip!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
