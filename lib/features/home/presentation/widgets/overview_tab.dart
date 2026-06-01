import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/accounts_view.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 120.0,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldos e Faturas
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.homeAccountsAndCards,
                      style: theme.textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        context.push('/workspace/accounts');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AccountsView(),
              ],
            ),
            const SizedBox(height: 32),
            // Onde está o dinheiro?
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeWhereIsMoney,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _PeriodSelection(),
              ],
            ),
            const SizedBox(height: 16),
            // View Type Selector
            _SummaryTypeSelection(),
            const SizedBox(height: 24),
            Text(
              l10n.expenses,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepTurquoise,
              ),
            ),
            const SizedBox(height: 16),
            const CategorySummaryView(categoryType: CategoryType.expense),
            const SizedBox(height: 32),
            Text(
              l10n.incomes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepTurquoise,
              ),
            ),
            const SizedBox(height: 16),
            const CategorySummaryView(categoryType: CategoryType.income),
            const SizedBox(height: 32),
            const BalanceSummaryView(),
          ],
        ),
      ),
    );
  }
}

class CategorySummaryView extends ConsumerWidget {
  final CategoryType categoryType;

  const CategorySummaryView({super.key, required this.categoryType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = categoryType == CategoryType.expense
        ? HomeViewProviders.summaryExpenses
        : HomeViewProviders.summaryIncomes;
    final state = ref.watch(provider);
    final overviewDate = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final locale = context.locale;

    final summaries = [
      ...state.summary,
      if (state.specificPlannedAmountOthers > 0 ||
          state.generalPlannedAmountOthers > 0 ||
          state.actualAmountOthers > 0)
        PeriodSummaryModel.month(
          category: CategoryModel(
            id: 'others',
            name: l10n.categoryOthers,
            icon: 'more_horiz',
            color: '#808080',
            type: categoryType,
          ),
          year: overviewDate.year,
          month: overviewDate.month,
          specificPlannedAmount: state.specificPlannedAmountOthers,
          generalPlannedAmount: state.generalPlannedAmountOthers,
          actualAmount: state.actualAmountOthers,
          lastUpdate: DateTime.now(),
        ),
    ];

    if (summaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: AppColors.deepTurquoise.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTransactionsInPeriod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepTurquoise.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        final chart = Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: summaries.map((summary) {
                      double amount = 0;
                      if (viewType == SummaryViewType.planning) {
                        amount = summary.plannedAmount;
                      } else {
                        amount = summary.actualAmount;
                      }

                      return PieChartSectionData(
                        color: summary.category.color.asColor(),
                        value: amount > 0 ? amount : 0,
                        radius: 20,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewType == SummaryViewType.planning
                        ? l10n.homeTotalPlanned
                        : l10n.homeTotalSpent,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    state.totalAmount.asCurrency(locale: locale),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTurquoise,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final legendList = Column(
          children: summaries.map((summary) {
            String value = '';
            double? progress;

            if (viewType == SummaryViewType.planning) {
              value = summary.plannedAmount.asCurrency(locale: locale);
            } else if (viewType == SummaryViewType.effective) {
              value = summary.actualAmount.asCurrency(locale: locale);
              if (summary.plannedAmount > 0) {
                progress = (summary.actualAmount / summary.plannedAmount).clamp(
                  0,
                  1.2,
                );
              }
            } else {
              value =
                  '${summary.actualAmount.asCurrency(locale: locale)} / ${summary.plannedAmount.asCurrency(locale: locale)}';
              if (summary.plannedAmount > 0) {
                progress = (summary.actualAmount / summary.plannedAmount).clamp(
                  0,
                  1.2,
                );
              }
            }

            return _buildCategoryItem(
              context,
              summary.category.name,
              value,
              summary.category.color.asColor(),
              progress: progress,
              secondaryProgress: summary.plannedAmount > 0
                  ? (summary.specificPlannedAmount / summary.plannedAmount)
                        .clamp(0, 1)
                  : null,
            );
          }).toList(),
        );

        if (isSmallScreen) {
          return Column(
            children: [chart, const SizedBox(height: 32), legendList],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: chart),
            const SizedBox(width: 32),
            Expanded(child: legendList),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    String amount,
    Color color, {
    double? progress,
    double? secondaryProgress,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTurquoise,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.deepTurquoise.withValues(alpha: 0.1),
                  ),
                  if (secondaryProgress != null)
                    FractionallySizedBox(
                      widthFactor: secondaryProgress,
                      child: Container(
                        height: 8,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      height: 8,
                      color: progress > 1 ? AppColors.coralOrange : color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BalanceSummaryView extends ConsumerWidget {
  const BalanceSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(HomeViewProviders.summaryBalance);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final locale = context.locale;

    final amount = viewType == SummaryViewType.planning
        ? state.totalPlanned
        : state.totalActual;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepTurquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepTurquoise.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.balance,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.deepTurquoise,
            ),
          ),
          Text(
            amount.asCurrency(locale: locale),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: amount >= 0 ? AppColors.limeGreen : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelection extends ConsumerWidget {
  const _PeriodSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewDate = ref.watch(HomeViewProviders.period);
    final theme = Theme.of(context);
    final locale = context.locale;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(HomeViewProviders.period.notifier).state = DateTime(
              overviewDate.year,
              overviewDate.month - 1,
            );
          },
        ),
        Text(
          '${overviewDate.formated("MMMM", locale)} ${overviewDate.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref.read(HomeViewProviders.period.notifier).state = DateTime(
              overviewDate.year,
              overviewDate.month + 1,
            );
          },
        ),
      ],
    );
  }
}

class _SummaryTypeSelection extends ConsumerWidget {
  const _SummaryTypeSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final viewType = ref.watch(HomeViewProviders.viewType);

    return Row(
      children: SummaryViewType.values.map((type) {
        final isSelected = viewType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(l10n.fromSummaryViewType(type)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(HomeViewProviders.viewType.notifier).state = type;
              }
            },
            selectedColor: AppColors.vibrantTeal.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.deepTurquoise : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}
