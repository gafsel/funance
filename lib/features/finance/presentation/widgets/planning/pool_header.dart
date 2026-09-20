import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/core/widgets/animated_switching_icon.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/planning/allocation_progress_bar.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Cabeçalho de uma pool em tela larga: nome, descrição, a barra e os totais.
class PoolHeader extends StatelessWidget {
  const PoolHeader({super.key, required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    final title = switch (allocation) {
      CategoryAllocation.essential => l10n.planning503020Essential,
      CategoryAllocation.comfort => l10n.planning503020Comfort,
      CategoryAllocation.investment => l10n.planning503020Investment,
    };

    final description = switch (allocation) {
      CategoryAllocation.essential => l10n.planning503020EssentialDesc,
      CategoryAllocation.comfort => l10n.planning503020ComfortDesc,
      CategoryAllocation.investment => l10n.planning503020InvestmentDesc,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            _PoolStatusIcon(allocation: allocation),
          ],
        ),
        AppSpacing.gapXxs,
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
        ),
        AppSpacing.gapSm,
        AllocationProgressBar(allocation: allocation),
        AppSpacing.gapSm,
        _PoolTotals(allocation: allocation),
      ],
    );
  }
}

class _PoolStatusIcon extends ConsumerWidget {
  const _PoolStatusIcon({required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final isOver = ref.watch(
      FinanceViewProviders.planning503020AllocationProgress(
        allocation,
      ).select((state) => state.isOver),
    );

    final statusColor = isOver ? palette.dangerText : palette.successText;

    return AnimatedSwitchingIcon(
      isOver ? Icons.warning : Icons.check_circle,
      duration: const Duration(milliseconds: 300),
      size: 20,
      color: statusColor,
    );
  }
}

class _PoolTotals extends ConsumerWidget {
  const _PoolTotals({required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final progressOf = FinanceViewProviders.planning503020AllocationProgress(
      allocation,
    );
    final isOver = ref.watch(progressOf.select((state) => state.isOver));
    final idealValue = ref.watch(
      progressOf.select((state) => state.idealValue),
    );
    final currentActual = ref.watch(
      progressOf.select((state) => state.currentActual),
    );
    final currentTotal = ref.watch(
      progressOf.select((state) => state.currentTotal),
    );

    final statusColor = isOver ? palette.dangerText : palette.successText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDouble(
              value: currentActual,
              duration: Duration(milliseconds: 300),
              formatter: (context, value) => l10n.planning503020ActualAmount(
                value.asCurrency(locale: context.locale),
              ),
              style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
            ),
            AnimatedDouble(
              value: currentTotal,
              duration: Duration(milliseconds: 300),
              formatter: (context, value) => l10n.planning503020Total(
                value.asCurrency(locale: context.locale),
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        MoneyText(idealValue, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
