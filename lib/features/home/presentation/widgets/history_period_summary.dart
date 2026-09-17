import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/money_text.dart';
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
      margin: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.periodSummary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AppSpacing.gapMd,
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
          if (totals.plannedIncomes != 0 || totals.realizedIncomes != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSummaryRow(
                context,
                label: l10n.totalIncomes,
                plannedValue: totals.plannedIncomes,
                realizedValue: totals.realizedIncomes,
              ),
            ),
          if (totals.plannedExpenses != 0 || totals.realizedExpenses != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSummaryRow(
                context,
                label: l10n.totalExpenses,
                plannedValue: -totals.plannedExpenses,
                realizedValue: -totals.realizedExpenses,
              ),
            ),
          if (totals.plannedTransfers != 0 || totals.realizedTransfers != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSummaryRow(
                context,
                label: l10n.totalTransfers,
                plannedValue: totals.plannedTransfers,
                realizedValue: totals.realizedTransfers,
              ),
            ),
          if (totals.plannedInvoices != 0 || totals.realizedInvoices != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSummaryRow(
                context,
                label: l10n.totalInvoices,
                plannedValue: totals.plannedInvoices,
                realizedValue: totals.realizedInvoices,
                isError: true,
              ),
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
    bool isError = false,
  }) {
    final palette = context.palette;

    Color getColor(double value) {
      if (value == 0) return palette.ink2;
      if (isError) return palette.dangerText;
      return palette.moneyInk(value);
    }

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: plannedValue == 0
              ? Text(
                  '-',
                  textAlign: TextAlign.right,
                  style: _valueStyle(
                    context,
                    isBold,
                  )?.copyWith(color: getColor(0).withValues(alpha: .75)),
                )
              : MoneyText(
                  plannedValue,
                  showSign: true,
                  textAlign: TextAlign.right,
                  style: _valueStyle(context, isBold)?.copyWith(
                    color: getColor(plannedValue).withValues(alpha: .75),
                  ),
                ),
        ),
        Expanded(
          child: realizedValue == 0
              ? Text(
                  '-',
                  textAlign: TextAlign.right,
                  style: _valueStyle(
                    context,
                    isBold,
                  )?.copyWith(color: getColor(0)),
                )
              : MoneyText(
                  realizedValue,
                  showSign: true,
                  textAlign: TextAlign.right,
                  style: _valueStyle(
                    context,
                    isBold,
                  )?.copyWith(color: getColor(realizedValue)),
                ),
        ),
      ],
    );
  }

  /// 14 regular ou 14 semibold: a linha de total é a única em negrito.
  TextStyle? _valueStyle(BuildContext context, bool isBold) => isBold
      ? Theme.of(context).textTheme.titleSmall
      : Theme.of(context).textTheme.bodyMedium;
}
