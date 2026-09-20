import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_elevation.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/section_header.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class TransactionActionSheet extends StatefulWidget {
  final Function(OrderType)? onSelect;

  const TransactionActionSheet({super.key, this.onSelect});

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
        gradient: AppGradients.background,
        borderRadius: AppRadius.brSheet,
      ),
      child: Column(
        children: [
          // O respiro que sobrou do puxador desenhado à mão: quem o desenha
          // agora é o `bottomSheetTheme`.
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: AppSpacing.hMd,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeNewTransaction,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.inkInverse,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.inkInverse,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: AppSpacing.allXs,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.inkInverse.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader.sheet(
                    title: l10n.transactionRealizedSection,
                    subtitle: l10n.transactionRealizedSubtitle,
                    icon: Icons.check_circle_outline,
                  ),
                  AppSpacing.gapSm,
                  _buildActionGrid(context, InstallmentStatus.paid),
                  AppSpacing.gapXl,
                  SectionHeader.sheet(
                    title: l10n.transactionPlannedSection,
                    subtitle: l10n.transactionPlannedSubtitle,
                    icon: Icons.calendar_month_outlined,
                  ),
                  AppSpacing.gapSm,
                  _buildActionGrid(context, InstallmentStatus.pending),
                  AppSpacing.gapXl,
                  SectionHeader.sheet(
                    title: l10n.planningSectionTitle,
                    subtitle: l10n.planningSectionSubtitle,
                    icon: Icons.insights_outlined,
                  ),
                  AppSpacing.gapSm,
                  _buildPlanningToolsGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A largura da grade vem das constraints da FOLHA, não da janela: uma
  /// janela larga com a folha estreita (ou com o `NavigationRail` comendo
  /// 200px) media o espaço errado.
  Widget _grid(BuildContext context, List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: constraints.layout.isCompact ? constraints.maxWidth : 480.0,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, InstallmentStatus status) {
    final isScheduled = status == InstallmentStatus.pending;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return _grid(context, [
      _buildActionItem(
        context,
        icon: isScheduled ? Icons.savings_outlined : Icons.add_circle_outline,
        color: palette.successText,
        label: isScheduled
            ? l10n.transactionPlanIncome
            : l10n.transactionAddIncome,
        onTap: () => _navigateToForm(context, OrderType.income, status),
      ),
      _buildActionItem(
        context,
        icon: isScheduled
            ? Icons.event_note_outlined
            : Icons.remove_circle_outline,
        color: palette.dangerText,
        label: isScheduled
            ? l10n.transactionPlanExpense
            : l10n.transactionAddExpense,
        onTap: () => _navigateToForm(context, OrderType.expense, status),
      ),
      _buildActionItem(
        context,
        icon: isScheduled ? Icons.pending_actions_outlined : Icons.swap_horiz,
        color: palette.tealText,
        label: isScheduled
            ? l10n.transactionPlanTransfer
            : l10n.transactionTransfer,
        onTap: () => _navigateToForm(context, OrderType.transfer, status),
      ),
    ]);
  }

  Widget _buildPlanningToolsGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return _grid(context, [
      _buildActionItem(
        context,
        icon: Icons.assignment_turned_in_outlined,
        color: palette.successText,
        label: l10n.planningIncomeLimits,
        onTap: () {
          Navigator.pop(context);
          context.push('/planning?type=income');
        },
      ),
      _buildActionItem(
        context,
        icon: Icons.assignment_outlined,
        color: palette.dangerText,
        label: l10n.planningExpenseLimits,
        onTap: () {
          Navigator.pop(context);
          context.push('/planning?type=expense');
        },
      ),
      _buildActionItem(
        context,
        icon: Icons.pie_chart_outline,
        color: AppColors.goldDeep,
        label: l10n.planning503020Title,
        onTap: () {
          Navigator.pop(context);
          context.push('/planning-50-30-20');
        },
      ),
      // A conciliação era uma ação escondida dentro da tela de UMA conta:
      // quem nunca entrou no extrato de uma conta nunca soube que ela
      // existia. Aqui ela é uma ferramenta de estratégia como as outras,
      // e a escolha da conta acontece depois.
      _buildActionItem(
        context,
        icon: Icons.fact_check_outlined,
        color: palette.tealText,
        label: l10n.reconciliationAction,
        onTap: () {
          Navigator.pop(context);
          context.push('/reconciliation');
        },
      ),
    ]);
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: AppRadius.brMd,
          boxShadow: AppElevation.raised(palette.brightness),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: AppSpacing.allXs,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(child: Icon(icon, color: color, size: 24)),
              ),
            ),
            AppSpacing.gapXxs,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }

  /// O ponto de entrada decide o status: "Registrei" abre o lançamento como
  /// pago e "Agendar" como pendente. Não há mais seletor de status no
  /// formulário.
  void _navigateToForm(
    BuildContext context,
    OrderType type,
    InstallmentStatus status,
  ) {
    Navigator.pop(context);
    context.push('/transactions/form?type=${type.name}&status=${status.name}');
  }
}
