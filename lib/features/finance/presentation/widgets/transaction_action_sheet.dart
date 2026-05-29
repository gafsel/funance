import 'package:flutter/material.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/account_selection_screen.dart';
import '../screens/transaction_form_screen.dart';
import '../screens/transaction_selection_screen.dart';

class TransactionActionSheet extends StatelessWidget {
  final Function(OrderType) onSelect;

  const TransactionActionSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        final crossAxisCount = isLargeScreen ? 3 : 2;

        // Calculate child aspect ratio based on width to keep it reasonable
        final itemWidth = constraints.maxWidth / crossAxisCount;
        final childAspectRatio = itemWidth / (isLargeScreen ? 140 : 160);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: childAspectRatio.clamp(0.8, 1.8),
                  children: [
                    _buildGridItem(
                      context,
                      icon: Icons.swap_horiz,
                      color: AppColors.vibrantTeal,
                      title: l10n.transactionTransfer,
                      description: l10n.transactionTransferDesc,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountSelectionScreen(
                              title: l10n.transactionSelectSourceAccount,
                              onAccountSelected: (sourceAccount) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountSelectionScreen(
                                      title: l10n
                                          .transactionSelectDestinationAccount,
                                      excludeAccountId: sourceAccount.id,
                                      onAccountSelected: (targetAccount) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TransactionFormScreen.creation(
                                                  type: OrderType.transfer,
                                                  accountIdSource:
                                                      sourceAccount.id,
                                                  accountIdTarget:
                                                      targetAccount.id,
                                                ),
                                          ),
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
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.remove_circle_outline,
                      color: AppColors.coralOrange,
                      title: l10n.transactionAddExpense,
                      description: l10n.transactionAddExpenseDesc,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransactionSelectionScreen(
                                  type: OrderType.expense,
                                ),
                          ),
                        );
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.add_circle_outline,
                      color: AppColors.successGold,
                      title: l10n.transactionAddIncome,
                      description: l10n.transactionAddIncomeDesc,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransactionSelectionScreen(
                                  type: OrderType.income,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 10,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
