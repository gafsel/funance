import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/planning_503020_analysis_sheet.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/core/widgets/animated_switching_icon.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/widgets/error_view.dart';

class Planning503020Screen extends ConsumerWidget {
  const Planning503020Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: ref
                  .read(FinanceViewProviders.planning503020.notifier)
                  .previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final date = ref.watch(
                    FinanceViewProviders.planning503020.select(
                      (state) => state.date,
                    ),
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;

                      return Text(
                        isSmallScreen
                            ? DateFormat.yM(context.locale).format(date)
                            : DateFormat.yMMMM(context.locale).format(date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  );
                },
              ),
            ),
            IconButton(
              onPressed: ref
                  .read(FinanceViewProviders.planning503020.notifier)
                  .nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.planningAnalysisAction,
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _openAnalysis(context, ref),
          ),
          LoadingButton.icon(
            const Icon(Icons.save),
            onPressed: (loading) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              // Resolve a mensagem antes do await: depois dele o context pode
              // não estar mais montado.
              final successMessage = context.l10n.savedSuccess;

              await loading(
                ref.read(FinanceViewProviders.planning503020.notifier).submit(),
              );

              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(successMessage)),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final allocations = CategoryAllocation.values;
          final l10n = context.l10n;

          // Erro e carregamento vêm ANTES das pools: três colunas vazias são
          // indistinguíveis de "você não planejou nada".
          final erro = ref.watch(
            FinanceViewProviders.planning503020.select((s) => s.error),
          );
          if (erro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView.forError(
                  context,
                  erro,
                  onRetry: () => ref
                      .read(FinanceViewProviders.planning503020.notifier)
                      .retry(),
                ),
              ),
            );
          }

          final carregando = ref.watch(
            FinanceViewProviders.planning503020.select((s) => s.isLoading),
          );
          if (carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final header = Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: _buildHeader(l10n, context, isMobile),
          );

          if (isMobile) {
            return SafeArea(
              child: DefaultTabController(
                length: allocations.length,
                child: Column(
                  children: [
                    header,
                    TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.deepTurquoise,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      labelStyle: const TextStyle(fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: [
                        for (final allocation in allocations)
                          Tab(
                            height: 60,
                            child: _TabContent(allocation: allocation),
                          ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final allocation in allocations)
                            _PoolWidget(allocation: allocation, isMobile: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                header,
                Expanded(
                  child: Row(
                    children: [
                      for (final category in allocations)
                        Expanded(child: _PoolWidget(allocation: category)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAnalysis(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final analysis = await showLoadingModal(
        context,
        ref.read(PlanningAnalysisDomainProviders.service).analyze(),
        child: AnalysisLoadingView(
          title: l10n.planningAnalysisLoadingTitle,
          description: l10n.planningAnalysisLoadingDesc,
          firstPhaseDuration: const Duration(seconds: 45),
          totalDuration: const Duration(minutes: 2),
        ),
      );

      if (!context.mounted) return;
      await showPlanning503020AnalysisSheet(
        context,
        analysis,
        onRefresh: () {
          if (context.mounted) {
            _openAnalysis(context, ref);
          }
        },
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            callableErrorMessage(
              e,
              l10n.planningAnalysisError,
              offlineMessage: l10n.errorOfflineCallable,
            ),
          ),
        ),
      );
    }
  }

  Row _buildHeader(AppLocalizations l10n, BuildContext context, bool isMobile) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planning503020SummaryIncome,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Row(
                spacing: 4,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final totalIncomes = ref.watch(
                        FinanceViewProviders.planning503020.select(
                          (state) => state.totalIncomes,
                        ),
                      );
                      return AnimatedDouble.currency(
                        totalIncomes,
                        duration: Duration(milliseconds: 300),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  if (!isMobile)
                    Consumer(
                      builder: (context, ref, _) {
                        final actualPercentage = ref.watch(
                          FinanceViewProviders.planning503020GlobalProgress
                              .select((state) => state.actualPercentage),
                        );
                        return AnimatedDouble(
                          value: actualPercentage,
                          formatter: (context, value) =>
                              "(${value.asPercent(locale: context.locale)})",
                          duration: Duration(milliseconds: 300),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 10 : 14,
                              ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planning503020SummaryExpense,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Consumer(
                builder: (context, ref, _) {
                  final totalIncomes = ref.watch(
                    FinanceViewProviders.planning503020.select(
                      (state) => state.totalIncomes,
                    ),
                  );
                  final totalPlanned = ref.watch(
                    FinanceViewProviders.planning503020GlobalProgress.select(
                      (state) => state.totalPlanned,
                    ),
                  );
                  return AnimatedDouble.currency(
                    totalPlanned,
                    duration: Duration(milliseconds: 300),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: totalPlanned > totalIncomes ? Colors.red : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planning503020SummaryActual,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Row(
                spacing: 4,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final totalIncomes = ref.watch(
                        FinanceViewProviders.planning503020.select(
                          (state) => state.totalIncomes,
                        ),
                      );
                      final totalActual = ref.watch(
                        FinanceViewProviders.planning503020GlobalProgress
                            .select((state) => state.totalActual),
                      );
                      return AnimatedDouble.currency(
                        totalActual,
                        duration: const Duration(milliseconds: 300),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: totalActual > totalIncomes
                              ? Colors.red
                              : AppColors.darkNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  if (!isMobile)
                    Consumer(
                      builder: (context, ref, _) {
                        final totalIncomes = ref.watch(
                          FinanceViewProviders.planning503020.select(
                            (state) => state.totalIncomes,
                          ),
                        );
                        final totalActual = ref.watch(
                          FinanceViewProviders.planning503020GlobalProgress
                              .select((state) => state.totalActual),
                        );
                        final expenseActualPercentage = ref.watch(
                          FinanceViewProviders.planning503020GlobalProgress
                              .select((state) => state.expenseActualPercentage),
                        );
                        return AnimatedDouble(
                          value: expenseActualPercentage,
                          formatter: (context, value) =>
                              '(${value.asPercent(locale: context.locale)})',
                          duration: const Duration(milliseconds: 300),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: totalActual > totalIncomes
                                    ? Colors.red
                                    : AppColors.darkNavy,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 10 : 14,
                              ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabContent extends ConsumerWidget {
  final CategoryAllocation allocation;

  const _TabContent({required this.allocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(
      FinanceViewProviders.planning503020AllocationProgress(allocation),
    );
    final statusColor = progress.isOver ? Colors.red : Colors.green;
    final label = switch (allocation) {
      CategoryAllocation.essential => l10n.planning503020Essential,
      CategoryAllocation.comfort => l10n.planning503020Comfort,
      CategoryAllocation.investment => l10n.planning503020Investment,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(
              progress.isOver ? Icons.warning : Icons.check_circle,
              size: 14,
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: progress.currentPercentage.clamp(0.0, 1.0),
                backgroundColor: statusColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 15,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              left: 80 * allocation.idealPercentage,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

class _PoolWidget extends ConsumerWidget {
  final CategoryAllocation allocation;
  final bool isMobile;

  const _PoolWidget({required this.allocation, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPoolHeader(context),
          ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Consumer(
              builder: (context, ref, _) {
                final progress = ref.watch(
                  FinanceViewProviders.planning503020AllocationProgress(
                    allocation,
                  ),
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMobileHeaderItem(
                      context,
                      "Ideal",
                      progress.idealValue,
                    ),
                    _buildMobileHeaderItem(
                      context,
                      l10n.planning503020SummaryExpense,
                      progress.currentTotal,
                    ),
                    _buildMobileHeaderItem(
                      context,
                      l10n.planning503020SummaryActual,
                      progress.currentActual,
                    ),
                  ],
                );
              },
            ),
          ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(FinanceViewProviders.planning503020);

              final items = state.items
                  .where((item) => item.category.allocation == allocation)
                  .toList();

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    l10n.planning503020EmptyPool,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                    return _CategoryCard(
                      key: ValueKey(item.category.id),
                      item: item,
                      isMobile: isMobile,
                    );
                  },
                ),
              );
            },
          ),
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

  Widget _buildMobileHeaderItem(
    BuildContext context,
    String label,
    double value,
  ) {
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

  Widget _buildPoolHeader(BuildContext context) {
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
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
              },
            ),
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
        Consumer(
          builder: (context, ref, _) {
            final isOver = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.isOver),
            );
            final currentPercentage = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.currentPercentage),
            );
            final actualPercentage = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.actualPercentage),
            );
            final statusColor = isOver ? Colors.red : Colors.green;

            return LayoutBuilder(
              builder: (context, box) {
                final maxWidth = box.maxWidth;
                final progressWidth =
                    maxWidth * (currentPercentage.clamp(0.0, 1.0));
                final actualWidth =
                    maxWidth * (actualPercentage.clamp(0.0, 1.0));
                final idealX = (maxWidth * allocation.idealPercentage).clamp(
                  0.0,
                  maxWidth,
                );

                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 24,
                          margin: EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Barra de Planejado
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              curve: Curves.bounceOut,
                              duration: Duration(milliseconds: 300),
                              height: 24,
                              margin: EdgeInsets.only(top: 14),
                              width: progressWidth,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedDouble.percent(
                              currentPercentage,
                              duration: Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        // Barra de Real
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              curve: Curves.bounceOut,
                              duration: Duration(milliseconds: 300),
                              height: 24,
                              margin: EdgeInsets.only(top: 14),
                              width: actualWidth,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedDouble.percent(
                              actualPercentage,
                              duration: Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        // Linha da Meta
                        Positioned(
                          left: idealX - 30,
                          top: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: 60,
                            child: Column(
                              children: [
                                Text(
                                  context.l10n.planning503020TargetPercent(
                                    allocation.idealPercentage.asPercent(
                                      locale: context.locale,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final isOver = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.isOver),
            );
            final idealValue = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.idealValue),
            );
            final currentActual = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.currentActual),
            );
            final currentTotal = ref.watch(
              FinanceViewProviders.planning503020AllocationProgress(
                allocation,
              ).select((state) => state.currentTotal),
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
                      formatter: (context, value) =>
                          l10n.planning503020ActualAmount(
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
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategoryPlanning503020Item item;
  final bool isMobile;

  const _CategoryCard({super.key, required this.item, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);
    final isOverGeneral = item.generalAmount > 0;
    final actualOverLimit = isOverGeneral
        ? item.actualAmount > item.generalAmount
        : item.actualAmount > item.specificAmount;
    final specificOverLimit =
        isOverGeneral && item.specificAmount > item.generalAmount;

    if (isMobile) {
      return _card(
        context,
        l10n,
        currencyFormat,
        actualOverLimit,
        specificOverLimit,
        ref,
      );
    }

    return Draggable<String>(
      data: item.category.id,
      feedback: Material(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(item.category.displayName(context.l10n)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _card(
          context,
          l10n,
          currencyFormat,
          actualOverLimit,
          specificOverLimit,
          ref,
        ),
      ),
      child: _card(
        context,
        l10n,
        currencyFormat,
        actualOverLimit,
        specificOverLimit,
        ref,
      ),
    );
  }

  Widget _card(
    BuildContext context,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
    bool actualOverLimit,
    bool specificOverLimit,
    WidgetRef ref,
  ) {
    final hasAlert = specificOverLimit;
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.category.color.asColor().withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.category.icon.asIcon(),
                    color: item.category.color.asColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.category.displayName(context.l10n),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ),
                if (isMobile)
                  PopupMenuButton<CategoryAllocation>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (allocation) {
                      ref
                          .read(FinanceViewProviders.planning503020.notifier)
                          .moveCategory(item.category.id, allocation);
                    },
                    itemBuilder: (context) => [
                      for (final allocation in CategoryAllocation.values)
                        PopupMenuItem(
                          value: allocation,
                          child: Text(switch (allocation) {
                            CategoryAllocation.essential =>
                              l10n.planning503020Essential,
                            CategoryAllocation.comfort =>
                              l10n.planning503020Comfort,
                            CategoryAllocation.investment =>
                              l10n.planning503020Investment,
                          }),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MoneyFormField(
              key: ValueKey("${item.planningId}_${item.category.id}"),
              initialValue: item.generalAmount > 0 ? item.generalAmount : null,
              decoration: InputDecoration(
                labelText: 'Limite Mensal',
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                ref
                    .read(FinanceViewProviders.planning503020.notifier)
                    .updateAmount(item.category.id, value ?? 0.0);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.planning503020ActualLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkNavy.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  currencyFormat.format(item.actualAmount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: actualOverLimit ? Colors.red : AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.planning503020AlreadyPlanned,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkNavy.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  currencyFormat.format(item.specificAmount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: specificOverLimit ? Colors.red : AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            if (hasAlert) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.planning503020AlertSpecificGreater,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
