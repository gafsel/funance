import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/core/widgets/animated_switching_icon.dart';
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
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            _PoolStatusIcon(allocation: allocation),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        AllocationProgressBar(allocation: allocation),
        const SizedBox(height: 12),
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
    final isOver = ref.watch(
      FinanceViewProviders.planning503020AllocationProgress(
        allocation,
      ).select((state) => state.isOver),
    );

    final statusColor = isOver ? Colors.red : Colors.green;

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

    final statusColor = isOver ? Colors.red : Colors.green;

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
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            AnimatedDouble(
              value: currentTotal,
              duration: Duration(milliseconds: 300),
              formatter: (context, value) => l10n.planning503020Total(
                value.asCurrency(locale: context.locale),
              ),
              style: TextStyle(
                color: statusColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          idealValue.asCurrency(locale: context.locale),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
