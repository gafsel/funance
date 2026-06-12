import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/widgets/planning_50_30_20_distribution_card.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/accounts_view.dart';
import 'package:funances/features/home/presentation/widgets/period_selection.dart';
import 'package:funances/features/home/presentation/widgets/summary_type_selection.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

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
                if (isLargeScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAccountsHeader(context, l10n, theme),
                            const SizedBox(height: 16),
                            const AccountsView(),
                            const SizedBox(height: 32),
                            const Planning503020DistributionCard(),
                            const SizedBox(height: 1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWhereIsMoneyHeader(l10n, theme),
                            const SizedBox(height: 16),
                            const SummaryTypeSelection(),
                            const SizedBox(height: 24),
                            _buildCategorySummaries(context, l10n, theme),
                            const SizedBox(height: 32),
                            const BalanceSummaryView(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  // Saldos e Faturas
                  _buildAccountsHeader(context, l10n, theme),
                  const SizedBox(height: 16),
                  const AccountsView(),
                  const SizedBox(height: 32),
                  // Distribuição 50-30-20
                  const Planning503020DistributionCard(),
                  const SizedBox(height: 32),
                  // Onde está o dinheiro?
                  _buildWhereIsMoneyHeader(l10n, theme),
                  const SizedBox(height: 16),
                  // View Type Selector
                  const SummaryTypeSelection(),
                  const SizedBox(height: 24),
                  _buildCategorySummaries(context, l10n, theme),
                  const SizedBox(height: 32),
                  const BalanceSummaryView(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsHeader(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildWhereIsMoneyHeader(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeWhereIsMoney,
            style: theme.textTheme.titleLarge,
          ),
        ),
        PeriodSelection(),
      ],
    );
  }

  Widget _buildCategorySummaries(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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
    final viewType = ref.watch(HomeViewProviders.viewType);
    final locale = context.locale;

    final summaries = [
      ...state.summary,
      if (state.specificPlannedAmountOthers > 0 ||
          state.generalPlannedAmountOthers > 0 ||
          state.actualAmountOthers > 0)
        OverviewCategorySummary(
          category: CategoryModel(
            id: 'others',
            name: l10n.categoryOthers,
            icon: 'more_horiz',
            color: '#808080',
            type: categoryType,
          ),
          specificPlannedAmount: state.specificPlannedAmountOthers,
          generalPlannedAmount: state.generalPlannedAmountOthers,
          actualAmount: state.actualAmountOthers,
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
        final isLargeScreen = constraints.maxWidth > 900;
        final isSmallScreen = constraints.maxWidth < 600;

        Widget chartWidget;

        if (viewType == SummaryViewType.comparison) {
          chartWidget = _buildComparisonChart(
            context,
            summaries,
            theme,
            l10n,
            locale,
            isLargeScreen,
          );
        } else {
          chartWidget = _buildDonutChart(
            context,
            summaries,
            state.totalAmount,
            viewType,
            theme,
            l10n,
            locale,
          );
        }

        final legendList = Column(
          children: summaries.map((summary) {
            String value = '';
            double? progress;

            if (viewType == SummaryViewType.planning) {
              value = summary.plannedAmount.asCurrency(locale: locale);
            } else if (viewType == SummaryViewType.effective) {
              value = summary.actualAmount.asCurrency(locale: locale);
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
              viewType == SummaryViewType.planning
                  ? summary.category.color.asColor().withValues(alpha: 0.4)
                  : summary.category.color.asColor(),
              progress: progress,
              secondaryProgress: viewType == SummaryViewType.planning &&
                      summary.plannedAmount > 0
                  ? (summary.specificPlannedAmount / summary.plannedAmount)
                        .clamp(0, 1)
                  : null,
            );
          }).toList(),
        );

        return Column(
          children: [
            if (isSmallScreen) ...[
              chartWidget,
              const SizedBox(height: 32),
              legendList,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chartWidget),
                  const SizedBox(width: 32),
                  Expanded(child: legendList),
                ],
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(
                  '/category-details?type=${categoryType.name}',
                ),
                icon: const Icon(Icons.list_alt),
                label: Text(l10n.homeOverviewShowDetails),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDonutChart(
    BuildContext context,
    List<OverviewCategorySummary> summaries,
    double totalAmount,
    SummaryViewType viewType,
    ThemeData theme,
    AppLocalizations l10n,
    String locale,
  ) {
    return Center(
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
                    color: viewType == SummaryViewType.planning
                        ? summary.category.color.asColor().withValues(alpha: 0.4)
                        : summary.category.color.asColor(),
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
                totalAmount.asCurrency(locale: locale),
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
  }

  Widget _buildComparisonChart(
    BuildContext context,
    List<OverviewCategorySummary> summaries,
    ThemeData theme,
    AppLocalizations l10n,
    String locale,
    bool isHorizontal,
  ) {
    final sortedSummaries = List<OverviewCategorySummary>.from(summaries)
      ..sort((a, b) {
        final valA = a.plannedAmount > a.actualAmount ? a.plannedAmount : a.actualAmount;
        final valB = b.plannedAmount > b.actualAmount ? b.plannedAmount : b.actualAmount;
        return valB.compareTo(valA);
      });

    // O maior valor deve ficar no topo. 
    // Com RotatedBox(1), o índice 0 fica no topo, então usamos a lista ordenada decrescentemente sem inverter.
    final chartSummaries = sortedSummaries;

    final maxVal = sortedSummaries.fold<double>(
      0,
      (max, s) =>
          s.plannedAmount > max
              ? (s.actualAmount > s.plannedAmount ? s.actualAmount : s.plannedAmount)
              : (s.actualAmount > max ? s.actualAmount : max),
    );

    return SizedBox(
      height: isHorizontal ? (sortedSummaries.length * 50.0).clamp(250.0, 600.0) : 250,
      child: RotatedBox(
        quarterTurns: isHorizontal ? 1 : 0,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final summary = chartSummaries[groupIndex];
                  final isPlanned = rodIndex == 0;
                  return BarTooltipItem(
                    '${summary.category.name}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: isPlanned ? l10n.overviewPlanning : l10n.overviewEffective,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                      TextSpan(
                        text: ': ${rod.toY.asCurrency(locale: locale)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= chartSummaries.length)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RotatedBox(
                        quarterTurns: isHorizontal ? -1 : 0,
                        child: Icon(
                          chartSummaries[value.toInt()].category.icon.asIcon(),
                          size: 16,
                          color: chartSummaries[value.toInt()].category.color.asColor(),
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !isHorizontal,
                  getTitlesWidget: (value, meta) {
                    return const SizedBox.shrink();
                  },
                  reservedSize: 0,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: chartSummaries.asMap().entries.map((entry) {
              final index = entry.key;
              final summary = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: summary.plannedAmount,
                    color: summary.category.color.asColor().withValues(alpha: 0.4),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: summary.actualAmount,
                    color: summary.category.color.asColor(),
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
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
