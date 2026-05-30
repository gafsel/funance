import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'account_selection_screen.dart';
import 'transaction_form_screen.dart';

class TransactionSelectionScreen extends ConsumerWidget {
  final OrderType type;

  const TransactionSelectionScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isExpense = type == OrderType.expense;
    final orderTypeFilter = isExpense ? OrderType.expense : OrderType.income;

    final categories = ref.watch(CategoryViewProviders.allStream).value ?? [];
    final filteredCategories = categories.where((c) {
      if (orderTypeFilter == OrderType.expense)
        return c.type == CategoryType.expense || c.type == CategoryType.both;
      return c.type == CategoryType.income || c.type == CategoryType.both;
    }).toList();

    filteredCategories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionCategoriesSection)),
      body: CustomScrollView(
        slivers: [
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == filteredCategories.length) {
                      // Opção de transferência
                      return _CategoryItem(
                        icon: Icons.swap_horiz,
                        color: AppColors.brightCyan,
                        label: l10n.transactionTypeTransfer,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (context) => AccountSelectionScreen(
                              title: l10n.transactionFromAccountLabel,
                              onAccountSelected: (fromAcc) {
                                Navigator.pop(context); // Fecha primeiro modal
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (context) => AccountSelectionScreen(
                                    title: l10n.transactionToAccountLabel,
                                    excludeAccountId: fromAcc?.id,
                                    onAccountSelected: (toAcc) {
                                      Navigator.pop(context); // Fecha segundo modal
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionFormScreen.creation(
                                                type: type,
                                                accountIdSource: fromAcc?.id,
                                                accountIdTarget: toAcc?.id,
                                              ),
                                        ),
                                        (route) => route.isFirst,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }

                    final cat = filteredCategories[index];
                    return _CategoryItem(
                      icon: _getIconData(cat.icon),
                      color: Color(
                        int.parse(cat.color.replaceFirst('#', '0xFF')),
                      ),
                      label: cat.name,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => AccountSelectionScreen(
                            title: l10n.transactionAccountLabel,
                            onAccountSelected: (acc) {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionFormScreen.creation(
                                        type: type,
                                        category: cat,
                                        accountIdSource: acc?.id,
                                      ),
                                ),
                                (route) => route.isFirst,
                              );
                            },
                          ),
                        );
                      },
                    );
                  }, childCount: filteredCategories.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'school':
        return Icons.school;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'movie':
        return Icons.movie;
      case 'flight':
        return Icons.flight;
      case 'work':
        return Icons.work;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'payments':
        return Icons.payments;
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.category;
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
