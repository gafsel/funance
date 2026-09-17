import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_typography.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/features/finance/presentation/providers.dart';

/// Resumo do mês: receita prevista, despesa prevista e gasto real.
///
/// Eram três colunas quase idênticas escritas por extenso, 168 linhas com
/// cinco `Consumer` — cada uma repetindo o mesmo rótulo pequeno em cima e o
/// mesmo par valor/percentual embaixo. O percentual só aparece em tela larga
/// porque no mobile ele empurrava o valor para fora da coluna.
class PlanningSummaryHeader extends StatelessWidget {
  const PlanningSummaryHeader({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      spacing: AppSpacing.md,
      children: [
        _SummaryMetric(
          label: l10n.planning503020SummaryIncome,
          value: const _PlannedIncomeValue(),
          percent: isMobile ? null : const _IncomePercentValue(),
        ),
        _SummaryMetric(
          label: l10n.planning503020SummaryExpense,
          value: const _PlannedExpenseValue(),
        ),
        _SummaryMetric(
          label: l10n.planning503020SummaryActual,
          value: const _ActualExpenseValue(),
          percent: isMobile ? null : const _ActualExpensePercentValue(),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.percent,
  });

  final String label;
  final Widget value;

  /// `null` no mobile: não cabe.
  final Widget? percent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          if (percent == null)
            value
          else
            Row(spacing: AppSpacing.xxs, children: [value, percent!]),
        ],
      ),
    );
  }
}

const _valueDuration = Duration(milliseconds: 300);

class _PlannedIncomeValue extends ConsumerWidget {
  const _PlannedIncomeValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalIncomes = ref.watch(
      FinanceViewProviders.planning503020.select((state) => state.totalIncomes),
    );

    return AnimatedDouble.currency(
      totalIncomes,
      duration: _valueDuration,
      style: theme.textTheme.titleMedium?.tabularFigures.copyWith(
        color: context.palette.successText,
      ),
    );
  }
}

class _IncomePercentValue extends ConsumerWidget {
  const _IncomePercentValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actualPercentage = ref.watch(
      FinanceViewProviders.planning503020GlobalProgress.select(
        (state) => state.actualPercentage,
      ),
    );

    return AnimatedDouble(
      value: actualPercentage,
      formatter: (context, value) =>
          "(${value.asPercent(locale: context.locale)})",
      duration: _valueDuration,
      style: theme.textTheme.titleSmall?.tabularFigures.copyWith(
        color: context.palette.successText,
      ),
    );
  }
}

class _PlannedExpenseValue extends ConsumerWidget {
  const _PlannedExpenseValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalIncomes = ref.watch(
      FinanceViewProviders.planning503020.select((state) => state.totalIncomes),
    );
    final totalPlanned = ref.watch(
      FinanceViewProviders.planning503020GlobalProgress.select(
        (state) => state.totalPlanned,
      ),
    );

    return AnimatedDouble.currency(
      totalPlanned,
      duration: _valueDuration,
      style: theme.textTheme.titleMedium?.tabularFigures.copyWith(
        // Planejar mais do que se recebe é o erro que a tela existe para
        // mostrar: o número vira vermelho antes de o mês começar.
        color: totalPlanned > totalIncomes ? context.palette.dangerText : null,
      ),
    );
  }
}

class _ActualExpenseValue extends ConsumerWidget {
  const _ActualExpenseValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final totalIncomes = ref.watch(
      FinanceViewProviders.planning503020.select((state) => state.totalIncomes),
    );
    final totalActual = ref.watch(
      FinanceViewProviders.planning503020GlobalProgress.select(
        (state) => state.totalActual,
      ),
    );

    return AnimatedDouble.currency(
      totalActual,
      duration: _valueDuration,
      style: theme.textTheme.titleMedium?.tabularFigures.copyWith(
        color: totalActual > totalIncomes ? palette.dangerText : palette.ink,
      ),
    );
  }
}

class _ActualExpensePercentValue extends ConsumerWidget {
  const _ActualExpensePercentValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final totalIncomes = ref.watch(
      FinanceViewProviders.planning503020.select((state) => state.totalIncomes),
    );
    final totalActual = ref.watch(
      FinanceViewProviders.planning503020GlobalProgress.select(
        (state) => state.totalActual,
      ),
    );
    final expenseActualPercentage = ref.watch(
      FinanceViewProviders.planning503020GlobalProgress.select(
        (state) => state.expenseActualPercentage,
      ),
    );

    return AnimatedDouble(
      value: expenseActualPercentage,
      formatter: (context, value) =>
          '(${value.asPercent(locale: context.locale)})',
      duration: _valueDuration,
      style: theme.textTheme.titleSmall?.tabularFigures.copyWith(
        color: totalActual > totalIncomes ? palette.dangerText : palette.ink,
      ),
    );
  }
}
