import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
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
            padding: AppSpacing.allMd,
            child: PoolHeader(allocation: allocation),
          ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
            ),
            child: _MobilePoolHeader(allocation: allocation),
          ),
        Expanded(
          child: _PoolCategories(allocation: allocation, isMobile: isMobile),
        ),
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
        final theme = Theme.of(context);

        return Container(
          margin: AppSpacing.allXs,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? theme.primaryColor.withValues(alpha: 0.1)
                : AppColors.transparent,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: context.palette.line),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        MoneyText(value, style: theme.textTheme.labelMedium),
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
    final palette = context.palette;
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

    // Papel secundário de propósito: é a caixa que agrupa os cartões, e os
    // cartões é que são o papel principal.
    return Container(
      margin: AppSpacing.allXs,
      decoration: BoxDecoration(
        color: palette.paper2,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: palette.line),
      ),
      child: ListView.separated(
        padding: AppSpacing.allXs,
        itemCount: items.length,
        separatorBuilder: (context, index) => AppSpacing.gapXs,
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
