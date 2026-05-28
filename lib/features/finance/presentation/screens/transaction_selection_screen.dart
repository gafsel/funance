import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';
import 'package:funances/features/finance/presentation/providers/planning_providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'transaction_form_screen.dart';
import 'account_selection_screen.dart';

class TransactionSelectionScreen extends ConsumerWidget {
  final TransactionType type;

  const TransactionSelectionScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isExpense = type == TransactionType.expense || type == TransactionType.plannedExpense;
    final isPlannedFlow = type == TransactionType.plannedExpense || type == TransactionType.plannedIncome;
    final orderTypeFilter = isExpense ? OrderType.expense : OrderType.income;

    final categories = ref.watch(categoriesProvider).value ?? [];
    final filteredCategories = categories.where((c) {
      if (orderTypeFilter == OrderType.expense) return c.type == CategoryType.expense || c.type == CategoryType.both;
      return c.type == CategoryType.income || c.type == CategoryType.both;
    }).toList();

    filteredCategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text(isPlannedFlow ? l10n.transactionPlanExpense : l10n.transactionCategoriesSection),
      ),
      body: CustomScrollView(
        slivers: [
          if (!isPlannedFlow) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.transactionPlannedSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Consumer(builder: (context, ref, child) {
              final planningsAsync = ref.watch(planningsForPeriodProvider);
              return planningsAsync.when(
                data: (plannings) {
                  final filteredPlannings = plannings.where((p) {
                    if (isExpense) return p.category.type == CategoryType.expense || p.category.type == CategoryType.both;
                    return p.category.type == CategoryType.income || p.category.type == CategoryType.both;
                  }).toList();

                  final sortedPlannings = [...filteredPlannings];
                  sortedPlannings.sort((a, b) {
                    final summaryA = ref.watch(planningSummaryProvider(a.id)).value;
                    final summaryB = ref.watch(planningSummaryProvider(b.id)).value;
                    final hasSpentA = (summaryA?.actualAmount ?? 0) > 0;
                    final hasSpentB = (summaryB?.actualAmount ?? 0) > 0;
                    if (hasSpentA && !hasSpentB) return 1;
                    if (!hasSpentA && hasSpentB) return -1;
                    
                    return a.category.name.toLowerCase().compareTo(b.category.name.toLowerCase());
                  });

                  return sortedPlannings.isEmpty
                    ? const SliverToBoxAdapter(child: SizedBox())
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.crossAxisExtent > 900
                                ? 3
                                : constraints.crossAxisExtent > 600
                                    ? 2
                                    : 1;

                            if (crossAxisCount == 1) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final planning = sortedPlannings[index];
                                    return _buildPlanningItem(context, ref, planning, type, isExpense);
                                  },
                                  childCount: filteredPlannings.length,
                                ),
                              );
                            }

                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 100,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final planning = sortedPlannings[index];
                                  return _buildPlanningItem(context, ref, planning, type, isExpense);
                                },
                                childCount: filteredPlannings.length,
                              ),
                            );
                          },
                        ),
                      );
                },
                loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              );
            }),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.transactionCategoriesSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.crossAxisExtent > 1200
                    ? 8
                    : constraints.crossAxisExtent > 900
                        ? 6
                        : constraints.crossAxisExtent > 600
                            ? 4
                            : 3;

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == filteredCategories.length) {
                        // Opção de transferência
                        return _CategoryItem(
                          icon: Icons.swap_horiz,
                          color: AppColors.brightCyan,
                          label: l10n.transactionTypeTransfer,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountSelectionScreen(
                                  title: l10n.transactionFromAccountLabel,
                                  onAccountSelected: (fromAcc) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AccountSelectionScreen(
                                          title: l10n.transactionToAccountLabel,
                                          excludeAccountId: fromAcc.id,
                                          onAccountSelected: (toAcc) {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TransactionFormScreen(
                                                  initialType: type,
                                                  isTransfer: true,
                                                  initialAccountId: fromAcc.id,
                                                  initialToAccountId: toAcc.id,
                                                ),
                                              ),
                                              (route) => route.isFirst,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }

                      final cat = filteredCategories[index];
                      return _CategoryItem(
                        icon: _getIconData(cat.icon),
                        color:
                            Color(int.parse(cat.color.replaceFirst('#', '0xFF'))),
                        label: cat.name,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountSelectionScreen(
                                title: l10n.transactionAccountLabel,
                                onAccountSelected: (acc) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionFormScreen(
                                        initialType: type,
                                        initialCategory: cat,
                                        initialAccountId: acc.id,
                                      ),
                                    ),
                                    (route) => route.isFirst,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount:
                        filteredCategories.length + (isPlannedFlow ? 0 : 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningItem(
    BuildContext context,
    WidgetRef ref,
    PlanningModel planning,
    TransactionType type,
    bool isExpense,
  ) {
    final summaryAsync = ref.watch(planningSummaryProvider(planning.id));

    return summaryAsync.when(
      data: (summary) {
        final actual = summary?.actualAmount ?? 0;
        final planned =
            planning.amount; // Usar o valor do próprio planejamento como alvo
        final progress = planned > 0 ? actual / planned : 0.0;
        final hasSpent = actual >= planned && planned > 0;

        return Opacity(
          opacity: hasSpent ? 0.6 : 1.0,
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: hasSpent
                    ? AppColors.vibrantTeal.withValues(alpha: 0.5)
                    : AppColors.vibrantTeal,
                child: const Icon(Icons.event_note, color: Colors.white),
              ),
              title: Text(
                planning.category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'R\$ ${actual.toStringAsFixed(2)} / R\$ ${planned.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasSpent ? Colors.grey : AppColors.deepTurquoise,
                      fontWeight: hasSpent ? null : FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      backgroundColor:
                          AppColors.vibrantTeal.withValues(alpha: 0.1),
                      color: progress > 1 ? Colors.red : AppColors.brightCyan,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionFormScreen(
                      initialType: type,
                      initialCategory: planning.category,
                      initialAmount: planned - actual > 0
                          ? planned - actual
                          : planning.amount,
                      initialOrder: OrderModel.fromJson({
                        'runtimeType': isExpense ? 'expense' : 'income',
                        'id': '',
                        'description': planning.category.name,
                        'total_amount': planned - actual > 0
                            ? planned - actual
                            : planning.amount,
                        'category': planning.category.toJson(),
                        'installments_count': 1,
                        'date': DateTime.now().toIso8601String(),
                        'status': 'active',
                        'planning_id': planning.id,
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () =>
          const Card(child: ListTile(title: LinearProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'flash_on': return Icons.flash_on;
      case 'water_drop': return Icons.water_drop;
      case 'wifi': return Icons.wifi;
      case 'school': return Icons.school;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'fitness_center': return Icons.fitness_center;
      case 'movie': return Icons.movie;
      case 'flight': return Icons.flight;
      case 'work': return Icons.work;
      case 'savings': return Icons.savings;
      case 'trending_up': return Icons.trending_up;
      case 'payments': return Icons.payments;
      case 'account_balance': return Icons.account_balance;
      case 'credit_card': return Icons.credit_card;
      default: return Icons.category;
    }
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
