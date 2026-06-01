import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class HistoryPeriodSummary extends ConsumerWidget {
  const HistoryPeriodSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.watch(FinanceViewProviders.history.notifier);
    final totals = notifier.totals;

    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.periodSummary,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Spacer(),
                Expanded(
                  child: Text(
                    l10n.plannedLabel,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.realizedLabel,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSummaryRow(
            context,
            label: l10n.totalIncomes,
            plannedValue: totals.plannedIncomes,
            realizedValue: totals.realizedIncomes,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            label: l10n.totalExpenses,
            plannedValue: -totals.plannedExpenses,
            realizedValue: -totals.realizedExpenses,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            context,
            label: l10n.periodBalance,
            plannedValue: totals.plannedBalance,
            realizedValue: totals.realizedBalance,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required double plannedValue,
    required double realizedValue,
    bool isBold = false,
  }) {
    final locale = context.locale;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            plannedValue == 0
                ? '-'
                : plannedValue.asSignedCurrency(locale: locale),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  (plannedValue == 0
                          ? Colors.grey
                          : plannedValue > 0
                          ? AppColors.limeGreen
                          : AppColors.error)
                      .withValues(alpha: .75),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          child: Text(
            realizedValue == 0
                ? '-'
                : realizedValue.asSignedCurrency(locale: locale),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: (realizedValue == 0
                  ? Colors.grey
                  : realizedValue > 0
                  ? AppColors.limeGreen
                  : AppColors.error),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
