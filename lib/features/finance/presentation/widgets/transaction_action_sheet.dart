import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/transaction_providers.dart';
import '../screens/transaction_selection_screen.dart';
import '../screens/account_selection_screen.dart';
import '../screens/transaction_form_screen.dart';

class TransactionActionSheet extends StatelessWidget {
  final Function(TransactionType) onSelect;

  const TransactionActionSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.deepTurquoise,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionItem(
            context,
            icon: Icons.swap_horiz,
            color: AppColors.vibrantTeal,
            title: l10n.transactionTransfer,
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
                            title: l10n.transactionSelectDestinationAccount,
                            excludeAccountId: sourceAccount.id,
                            onAccountSelected: (targetAccount) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionFormScreen(
                                    initialType: TransactionType.expense,
                                    isTransfer: true,
                                    initialAccountId: sourceAccount.id,
                                    initialToAccountId: targetAccount.id,
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
          const SizedBox(height: 8),
          _buildActionItem(
            context,
            icon: Icons.remove_circle_outline,
            color: AppColors.coralOrange,
            title: l10n.transactionAddExpense,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionSelectionScreen(type: TransactionType.expense),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionItem(
            context,
            icon: Icons.add_circle_outline,
            color: AppColors.successGold,
            title: l10n.transactionAddIncome,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionSelectionScreen(type: TransactionType.income),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionItem(
            context,
            icon: Icons.event_note_outlined,
            color: AppColors.vibrantTeal,
            title: l10n.transactionPlanExpense,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionSelectionScreen(type: TransactionType.plannedExpense),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionItem(
            context,
            icon: Icons.event_available_outlined,
            color: AppColors.brightCyan,
            title: l10n.transactionPlanIncome,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionSelectionScreen(type: TransactionType.plannedIncome),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.pureWhite),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.pureWhite)),
      onTap: onTap,
    );
  }
}
