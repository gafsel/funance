  import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeNewTransaction,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.pureWhite,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.pureWhite, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.pureWhite.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    context,
                    l10n.transactionRealizedSection,
                    l10n.transactionRealizedSubtitle,
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildActionGrid(context, InstallmentStatus.paid),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    context,
                    l10n.transactionPlannedSection,
                    l10n.transactionPlannedSubtitle,
                    Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildActionGrid(context, InstallmentStatus.pending),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    context,
                    l10n.planningSectionTitle,
                    l10n.planningSectionSubtitle,
                    Icons.insights_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanningToolsGrid(context),
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
            Icon(icon, color: AppColors.antiqueGold, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.antiqueGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.pureWhite.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, InstallmentStatus status) {
    final isScheduled = status == InstallmentStatus.pending;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxGridWidth = screenWidth > 600 ? 480.0 : screenWidth;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: maxGridWidth,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildActionItem(
              context,
              icon: isScheduled ? Icons.savings_outlined : Icons.add_circle_outline,
              color: AppColors.limeGreen,
              label: isScheduled ? l10n.transactionPlanIncome : l10n.transactionAddIncome,
              onTap: () => _navigateToForm(context, OrderType.income, status),
            ),
            _buildActionItem(
              context,
              icon: isScheduled ? Icons.event_note_outlined : Icons.remove_circle_outline,
              color: AppColors.error,
              label: isScheduled ? l10n.transactionPlanExpense : l10n.transactionAddExpense,
              onTap: () => _navigateToForm(context, OrderType.expense, status),
            ),
            _buildActionItem(
              context,
              icon: isScheduled ? Icons.pending_actions_outlined : Icons.swap_horiz,
              color: AppColors.vibrantTeal,
              label: isScheduled ? l10n.transactionPlanTransfer : l10n.transactionTransfer,
              onTap: () => _navigateToForm(context, OrderType.transfer, status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningToolsGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxGridWidth = screenWidth > 600 ? 480.0 : screenWidth;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: maxGridWidth,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildActionItem(
              context,
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.limeGreen,
              label: l10n.planningIncomeLimits,
              onTap: () {
                Navigator.pop(context);
                context.push('/planning?type=income');
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.assignment_outlined,
              color: AppColors.error,
              label: l10n.planningExpenseLimits,
              onTap: () {
                Navigator.pop(context);
                context.push('/planning?type=expense');
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.pie_chart_outline,
              color: AppColors.antiqueGold,
              label: l10n.planning503020Title,
              onTap: () {
                Navigator.pop(context);
                context.push('/planning-50-30-20');
              },
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
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
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  child: Icon(icon, color: color, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// O ponto de entrada decide o status: "Registrei" abre o lançamento como
  /// pago e "Agendar" como pendente. Não há mais seletor de status no
  /// formulário.
  void _navigateToForm(BuildContext context, OrderType type, InstallmentStatus status) {
    Navigator.pop(context);
    context.push('/transactions/form?type=${type.name}&status=${status.name}');
  }
}
