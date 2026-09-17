import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/planning/planning_category_card.dart';
import 'package:funances/features/finance/presentation/widgets/planning/pool_header.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/widgets/empty_state.dart';

/// Uma das três pools do 50-30-20.
///
/// Em tela larga é um alvo de arrasto: mover uma categoria entre pools é a
/// ação central da tela. No mobile o arrasto não existe (as pools estão em
/// abas diferentes) e a troca acontece pelo menu do cartão.
class PlanningPoolColumn extends ConsumerWidget {
  const PlanningPoolColumn({
    super.key,
    required this.allocation,
    this.isMobile = false,
  });

  final CategoryAllocation allocation;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PoolHeader(allocation: allocation),
          ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: _MobilePoolHeader(allocation: allocation),
          ),
        Expanded(child: _PoolCategories(allocation: allocation, isMobile: isMobile)),
      ],
    );

    if (isMobile) {
      return content;
    }

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        ref
            .read(FinanceViewProviders.planning503020.notifier)
            .moveCategory(details.data, allocation);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: content,
        );
      },
    );
  }
}

/// No mobile a barra da pool já está na aba; aqui sobram os três números.
class _MobilePoolHeader extends ConsumerWidget {
  const _MobilePoolHeader({required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(
      FinanceViewProviders.planning503020AllocationProgress(allocation),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MobileHeaderItem(
          label: l10n.planning503020IdealLabel,
          value: progress.idealValue,
        ),
        _MobileHeaderItem(
          label: l10n.planning503020SummaryExpense,
          value: progress.currentTotal,
        ),
        _MobileHeaderItem(
          label: l10n.planning503020SummaryActual,
          value: progress.currentActual,
        ),
      ],
    );
  }
}

class _MobileHeaderItem extends StatelessWidget {
  const _MobileHeaderItem({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
        Text(
          value.asCurrency(locale: context.locale),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PoolCategories extends ConsumerWidget {
  const _PoolCategories({required this.allocation, required this.isMobile});

  final CategoryAllocation allocation;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(FinanceViewProviders.planning503020);

    final items = state.items
        .where((item) => item.category.allocation == allocation)
        .toList();

    if (items.isEmpty) {
      return EmptyState.message(
        l10n.planning503020EmptyPool,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return PlanningCategoryCard(
            key: ValueKey(item.category.id),
            item: item,
            isMobile: isMobile,
          );
        },
      ),
    );
  }
}
