import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/finance/domain/models/category_month_summary_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountsByTypeAsync = ref.watch(accountsByTypeProvider);
    final summariesAsync = ref.watch(categorySummariesProvider);
    final overviewDate = ref.watch(overviewDateProvider);
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );
    final monthFormat = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    );
    final selectedAccountType = ref.watch(overviewAccountTypeProvider);

    Map<AccountType, double> totalByGroup = {
      for (var type in AccountType.values) type: 0.0,
    };

    if (accountsByTypeAsync.hasValue) {
      final grouped = accountsByTypeAsync.value!;
      for (final type in grouped.keys) {
        final accounts = grouped[type]!;
        for (final account in accounts) {
          final balance = ref.watch(latestAccountBalanceProvider(account.id)).value?.balance ?? 0;
          totalByGroup[type] = (totalByGroup[type] ?? 0) + balance;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 120.0,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldos e Faturas
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            accountsByTypeAsync.when(
              data: (groupedAccounts) {
                final types = AccountType.values;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: types.map((type) {
                          final isSelected = selectedAccountType == type;
                          final count = groupedAccounts[type]?.length ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_getAccountTypeName(context, type)),
                                  if (count > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '($count)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? AppColors.deepTurquoise
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref
                                    .read(overviewAccountTypeProvider.notifier)
                                    .state = selected ? type : null;
                              },
                              selectedColor: AppColors.vibrantTeal.withValues(
                                alpha: 0.2,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.deepTurquoise
                                    : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: Builder(
                        builder: (context) {
                          final displayTypes = selectedAccountType != null
                              ? [selectedAccountType]
                              : types;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayTypes.fold<int>(
                              0,
                              (total, type) =>
                                  total +
                                  (groupedAccounts[type]?.length ?? 0) +
                                  2,
                            ),
                            itemBuilder: (context, index) {
                              int currentIdx = 0;
                              for (final type in displayTypes) {
                                final accounts = groupedAccounts[type] ?? [];
                                final typeCount = accounts.length + 2;

                                if (index >= currentIdx &&
                                    index < currentIdx + typeCount) {
                                  final innerIndex = index - currentIdx;
                                  if (innerIndex == 0) {
                                    return _buildGroupTotalCard(
                                      context,
                                      type,
                                      totalByGroup[type] ?? 0,
                                      currencyFormat,
                                    );
                                  }
                                  if (innerIndex == accounts.length + 1) {
                                    return _buildAddAccountCard(context, type);
                                  }
                                  final account = accounts[innerIndex - 1];
                                  return _buildAccountItem(
                                    context,
                                    ref,
                                    account,
                                    currencyFormat,
                                  );
                                }
                                currentIdx += typeCount;
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, __) => Text(err.toString()),
            ),
            const SizedBox(height: 32),
            // Onde está o dinheiro?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.homeWhereIsMoney, style: theme.textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        ref.read(overviewDateProvider.notifier).state =
                            DateTime(overviewDate.year, overviewDate.month - 1);
                      },
                    ),
                    Text(
                      '${monthFormat.format(overviewDate)} ${overviewDate.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        ref.read(overviewDateProvider.notifier).state =
                            DateTime(overviewDate.year, overviewDate.month + 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // View Type Selector
            Row(
              children: OverviewViewType.values.map((type) {
                final isSelected = ref.watch(overviewViewTypeProvider) == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getViewTypeName(context, type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(overviewViewTypeProvider.notifier).state =
                            type;
                      }
                    },
                    selectedColor: AppColors.vibrantTeal.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.deepTurquoise : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            summariesAsync.when(
              data: (allSummaries) {
                final viewType = ref.watch(overviewViewTypeProvider);

                // Filtrar para mostrar apenas categorias de despesas (expense)
                // Ignorar categorias de receitas (income)
                final filteredSummaries = allSummaries.where((s) => s.category.type != CategoryType.income).toList();

                // Ordenar por valor (de maior para menor) baseado no viewType
                final sortedSummaries = [...filteredSummaries];
                sortedSummaries.sort((a, b) {
                  double valA = 0;
                  double valB = 0;
                  if (viewType == OverviewViewType.planning) {
                    valA = a.plannedAmount;
                    valB = b.plannedAmount;
                  } else {
                    valA = a.totalDebit;
                    valB = b.totalDebit;
                  }
                  return valB.compareTo(valA);
                });

                // Limitar a 10 registros e agrupar o resto em "Outros"
                List<CategoryMonthSummaryModel> displaySummaries = [];
                CategoryMonthSummaryModel? othersSummary;

                if (sortedSummaries.length > 10) {
                  displaySummaries = sortedSummaries.sublist(0, 9);
                  final others = sortedSummaries.sublist(9);

                  int othersCount = 0;
                  double othersPlanned = 0;
                  double othersDebit = 0;
                  double othersCredit = 0;

                  for (var s in others) {
                    othersPlanned += s.plannedAmount;
                    othersDebit += s.totalDebit;
                    othersCredit += s.totalCredit;
                    othersCount += s.count;
                  }

                  othersSummary = CategoryMonthSummaryModel(
                    id: '',
                    category: CategoryModel(
                      id: 'others',
                      name: l10n.categoryOthers,
                      icon: 'more_horiz',
                      color: '#808080',
                      type: CategoryType.both,
                    ),
                    year: overviewDate.year,
                    month: overviewDate.month,
                    totalDebit: othersDebit,
                    totalCredit: othersCredit,
                    plannedAmount: othersPlanned,
                    actualAmount: 0,
                    count: othersCount,
                    lastUpdate: DateTime.now(),
                  );
                  displaySummaries.add(othersSummary);
                } else {
                  displaySummaries = sortedSummaries;
                }

                double totalAmount = 0;
                if (viewType == OverviewViewType.planning) {
                  totalAmount = filteredSummaries.fold<double>(
                    0,
                    (sum, item) => sum + item.plannedAmount,
                  );
                } else {
                  totalAmount = filteredSummaries.fold<double>(
                    0,
                    (sum, item) => sum + item.totalDebit,
                  );
                }

                if (filteredSummaries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 64,
                            color: AppColors.deepTurquoise.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTransactionsInPeriod,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.deepTurquoise.withValues(
                                alpha: 0.5,
                              ),
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
                                sections: displaySummaries.map((summary) {
                                  double amount = 0;
                                  if (viewType == OverviewViewType.planning) {
                                    amount = summary.plannedAmount;
                                  } else {
                                    amount = summary.totalDebit;
                                  }

                                  final color = Color(
                                    int.parse(
                                      summary.category.color
                                          .replaceAll('#', '0xFF'),
                                    ),
                                  );

                                  return PieChartSectionData(
                                    color: color,
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
                                viewType == OverviewViewType.planning
                                    ? l10n.homeTotalPlanned
                                    : l10n.homeTotalSpent,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                currencyFormat.format(totalAmount),
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
                      children: displaySummaries.map((summary) {
                        final color = Color(
                          int.parse(
                            summary.category.color.replaceAll('#', '0xFF'),
                          ),
                        );
                        String value = '';
                        double? progress;

                        if (viewType == OverviewViewType.planning) {
                          value = currencyFormat.format(summary.plannedAmount);
                        } else if (viewType == OverviewViewType.effective) {
                          value = currencyFormat.format(summary.totalDebit);
                        } else {
                          value =
                              '${currencyFormat.format(summary.totalDebit)} / ${currencyFormat.format(summary.plannedAmount)}';
                          if (summary.plannedAmount > 0) {
                            progress =
                                (summary.totalDebit / summary.plannedAmount)
                                    .clamp(0, 1.2);
                          }
                        }

                        return _buildCategoryItem(
                          context,
                          summary.category.name,
                          value,
                          color,
                          progress: progress,
                        );
                      }).toList(),
                    );

                    if (isSmallScreen) {
                      return Column(
                        children: [
                          chart,
                          const SizedBox(height: 32),
                          legendList,
                        ],
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
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, __) => Center(child: Text(err.toString())),
            ),
          ],
        ),
    );
  }

  Widget _buildGroupTotalCard(
    BuildContext context,
    AccountType type,
    double total,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.homeTotalBalance,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.paleGold,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(total),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
    NumberFormat format,
  ) {
    final balanceAsync = ref.watch(latestAccountBalanceProvider(account.id));

    return balanceAsync.when(
      data: (balance) {
        final currentBalance = balance.balance;
        final color = Color(int.parse(account.color.replaceAll('#', '0xFF')));
        final icon = _getIconData(account.icon);

        if (account.type == AccountType.creditCard) {
          final limit = (account.metadata['limit'] as num?)?.toDouble() ?? 0.0;
          final usedPercent = limit > 0
              ? (currentBalance.abs() / limit).clamp(0.0, 1.0)
              : 0.0;

          return _buildCreditCard(
            context,
            name: account.name,
            invoice: format.format(currentBalance.abs()),
            limitPercent: usedPercent,
            icon: icon,
            color: color,
          );
        }

        return _buildAccountCard(
          context,
          name: account.name,
          balance: format.format(currentBalance),
          icon: icon,
          color: color,
        );
      },
      loading: () => const SizedBox(
        width: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildAddAccountCard(BuildContext context, AccountType type) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountManagementScreen(initialType: type),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.vibrantTeal.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.vibrantTeal,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.accountCreateTypeAction(_getAccountTypeName(context, type)),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.deepTurquoise,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAccountTypeName(BuildContext context, AccountType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case AccountType.checking:
        return l10n.accountTypeChecking;
      case AccountType.investment:
        return l10n.accountTypeInvestment;
      case AccountType.creditCard:
        return l10n.accountTypeCreditCard;
      case AccountType.debt:
        return l10n.accountTypeDebt;
    }
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String name,
    required String balance,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white70),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                balance,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(
    BuildContext context, {
    required String name,
    required String invoice,
    required double limitPercent,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodySmall),
              Text(
                invoice,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.coralOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: limitPercent,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: AppColors.coralOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    return _availableIcons[name] ?? Icons.account_balance;
  }

  static const Map<String, IconData> _availableIcons = {
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'account_balance_wallet': Icons.account_balance_wallet,
    'money': Icons.money,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,
    'payments': Icons.payments,
    'wallet': Icons.wallet,
    'show_chart': Icons.show_chart,
    'pie_chart': Icons.pie_chart,
    'monetization_on': Icons.monetization_on,
  };

  String _getViewTypeName(BuildContext context, OverviewViewType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case OverviewViewType.planning:
        return l10n.overviewPlanning;
      case OverviewViewType.effective:
        return l10n.overviewEffective;
      case OverviewViewType.comparison:
        return l10n.overviewComparison;
    }
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    String amount,
    Color color, {
    double? progress,
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
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.deepTurquoise.withValues(alpha: 0.1),
                color: progress > 1 ? AppColors.coralOrange : color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
