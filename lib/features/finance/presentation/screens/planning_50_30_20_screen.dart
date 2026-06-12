import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/build_context_extension.dart';
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

class Planning503020Screen extends ConsumerStatefulWidget {
  const Planning503020Screen({super.key});

  @override
  ConsumerState<Planning503020Screen> createState() =>
      _Planning503020ScreenState();
}

class _Planning503020ScreenState extends ConsumerState<Planning503020Screen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
            Consumer(
              builder: (context, ref, _) {
                final date = ref.watch(
                  FinanceViewProviders.planning503020.select(
                    (state) => state.date,
                  ),
                );

                return Text(DateFormat.yMMMM(context.locale).format(date));
              },
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
          LoadingButton.icon(
            const Icon(Icons.save),
            onPressed: (loading) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await loading(
                ref.read(FinanceViewProviders.planning503020.notifier).submit(),
              );

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Salvo com sucesso!')),
                );
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final allocations = CategoryAllocation.values;

          final header = Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
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
                            spacing: 8,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  );
                                },
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final actualPercentage = ref.watch(
                                    FinanceViewProviders
                                        .planning503020GlobalProgress
                                        .select(
                                          (state) => state.actualPercentage,
                                        ),
                                  );
                                  return AnimatedDouble(
                                    value: actualPercentage,
                                    formatter: (context, value) =>
                                        "(${value.asPercent(locale: context.locale)})",
                                    duration: Duration(milliseconds: 300),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                FinanceViewProviders
                                    .planning503020GlobalProgress
                                    .select((state) => state.totalPlanned),
                              );
                              return AnimatedDouble.currency(
                                totalPlanned,
                                duration: Duration(milliseconds: 300),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: totalPlanned > totalIncomes
                                          ? Colors.red
                                          : null,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.planning503020SummaryActual,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Row(
                            spacing: 8,
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final totalIncomes = ref.watch(
                                    FinanceViewProviders.planning503020.select(
                                      (state) => state.totalIncomes,
                                    ),
                                  );
                                  final totalActual = ref.watch(
                                    FinanceViewProviders
                                        .planning503020GlobalProgress
                                        .select((state) => state.totalActual),
                                  );
                                  return AnimatedDouble.currency(
                                    totalActual,
                                    duration: const Duration(milliseconds: 300),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: totalActual > totalIncomes
                                              ? Colors.red
                                              : AppColors.darkNavy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  );
                                },
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final totalIncomes = ref.watch(
                                    FinanceViewProviders.planning503020.select(
                                      (state) => state.totalIncomes,
                                    ),
                                  );
                                  final totalActual = ref.watch(
                                    FinanceViewProviders
                                        .planning503020GlobalProgress
                                        .select((state) => state.totalActual),
                                  );
                                  final expenseActualPercentage = ref.watch(
                                    FinanceViewProviders
                                        .planning503020GlobalProgress
                                        .select(
                                          (state) =>
                                              state.expenseActualPercentage,
                                        ),
                                  );
                                  return AnimatedDouble(
                                    value: expenseActualPercentage,
                                    formatter: (context, value) =>
                                        '(${value.asPercent(locale: context.locale)})',
                                    duration: const Duration(milliseconds: 300),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: totalActual > totalIncomes
                                              ? Colors.red
                                              : AppColors.darkNavy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                header,
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: [
                      for (final category in allocations)
                        _PoolWidget(allocation: category),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
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
          );
        },
      ),
    );
  }
}

class _PoolWidget extends ConsumerWidget {
  final CategoryAllocation allocation;

  const _PoolWidget({required this.allocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

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
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPoolHeader(context),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final state = ref.watch(
                      FinanceViewProviders.planning503020,
                    );

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
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CategoryCard(
                            key: ValueKey(item.category.id),
                            item: item,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            ).textTheme.bodySmall?.color?.withOpacity(0.7),
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
            final totalPlanned = ref.watch(
              FinanceViewProviders.planning503020GlobalProgress.select(
                (state) => state.totalPlanned,
              ),
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
                            color: Colors.grey.withOpacity(0.1),
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
                                color: statusColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedDouble.percent(
                              currentPercentage,
                              duration: Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor.withOpacity(0.7),
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
                                  'Meta: ${allocation.idealPercentage.asPercent(locale: context.locale)}',
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
                        color: statusColor.withOpacity(0.7),
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

  const _CategoryCard({super.key, required this.item});

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
          child: Text(item.category.name),
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
      shadowColor: Colors.black.withOpacity(0.3),
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
                    color: item.category.color.asColor().withOpacity(0.2),
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
                    item.category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MoneyFormField(
              key: ValueKey("${item.planningId}_${item.category.id}"),
              initialValue: item.generalAmount > 0 ? item.generalAmount : null,
              decoration: InputDecoration(
                labelText: 'Limite Mensal',
                fillColor: Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
                    color: AppColors.darkNavy.withOpacity(0.7),
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
                  'Já previsto:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkNavy.withOpacity(0.7),
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
                  color: Colors.orange.withOpacity(0.1),
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
