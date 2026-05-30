import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/account_selection_screen.dart';
import '../screens/transaction_form_screen.dart';
import '../screens/transaction_selection_screen.dart';

enum TransactionActionStep { initial, selectType }

class TransactionActionSheet extends StatefulWidget {
  final Function(OrderType)? onSelect;

  const TransactionActionSheet({
    super.key,
    this.onSelect,
  });

  @override
  State<TransactionActionSheet> createState() => _TransactionActionSheetState();
}

class _TransactionActionSheetState extends State<TransactionActionSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.pureWhite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Nova Transação",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.pureWhite),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.pureWhite.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    context,
                    "Lançamentos Realizados",
                    "Transações que já aconteceram e impactaram seu saldo.",
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildActionGrid(context, InstallmentStatus.paid),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                    context,
                    "Planejamentos",
                    "Previsões de gastos ou ganhos futuros para organizar suas finanças.",
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildActionGrid(context, InstallmentStatus.pending),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.paleGold, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.paleGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.pureWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, InstallmentStatus status) {
    final isPlanning = status == InstallmentStatus.pending;
    final l10n = AppLocalizations.of(context)!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.75,
      children: [
        _buildActionItem(
          context,
          icon: isPlanning ? Icons.savings_outlined : Icons.add_circle_outline,
          color: AppColors.limeGreen,
          label: isPlanning ? "Planejar\nReceita" : l10n.transactionAddIncome,
          onTap: () => _navigateToForm(context, OrderType.income, status),
        ),
        _buildActionItem(
          context,
          icon: isPlanning ? Icons.event_note_outlined : Icons.remove_circle_outline,
          color: AppColors.error,
          label: isPlanning ? "Planejar\nDespesa" : l10n.transactionAddExpense,
          onTap: () => _navigateToForm(context, OrderType.expense, status),
        ),
        _buildActionItem(
          context,
          icon: isPlanning ? Icons.pending_actions_outlined : Icons.swap_horiz,
          color: AppColors.vibrantTeal,
          label: isPlanning ? "Planejar\nTransferência" : l10n.transactionTransfer,
          onTap: () => _navigateToForm(context, OrderType.transfer, status),
        ),
        if (isPlanning) ...[
          _buildActionItem(
            context,
            icon: Icons.assignment_outlined,
            color: AppColors.error,
            label: "Limites\nde Despesas",
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Funcionalidade em desenvolvimento")),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.assignment_turned_in_outlined,
            color: AppColors.limeGreen,
            label: "Limites\nde Receitas",
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Funcionalidade em desenvolvimento")),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, OrderType type, InstallmentStatus status) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen.creation(
          type: type,
          status: status,
        ),
      ),
    );
  }
}
