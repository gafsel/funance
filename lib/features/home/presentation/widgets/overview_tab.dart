import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/presentation/widgets/planning_50_30_20_distribution_card.dart';
import 'package:funances/features/home/presentation/widgets/accounts_view.dart';
import 'package:funances/features/home/presentation/widgets/overview/balance_summary_view.dart';
import 'package:funances/features/home/presentation/widgets/overview/category_summary_view.dart';
import 'package:funances/features/home/presentation/widgets/period_selection.dart';
import 'package:funances/features/home/presentation/widgets/summary_type_selection.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

// Os dois blocos vivem em `overview/` desde que este arquivo foi quebrado por
// responsabilidade, mas continuam saindo por aqui: os testes e quem já
// importava `overview_tab.dart` não precisam saber onde eles passaram a morar.
export 'package:funances/features/home/presentation/widgets/overview/balance_summary_view.dart';
export 'package:funances/features/home/presentation/widgets/overview/category_summary_view.dart';

/// A aba Visão Geral: contas, distribuição 50-30-20 e "onde está o dinheiro".
///
/// A mesma sequência de blocos em duas montagens — duas colunas acima de 900px,
/// empilhada abaixo. É repetição literal de propósito: tentar unificar as duas
/// com widgets condicionais custa mais do que a duplicação de uma lista de
/// filhos que quase nunca muda.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 120.0,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLargeScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAccountsHeader(context, l10n, theme),
                            const SizedBox(height: 16),
                            const AccountsView(),
                            const SizedBox(height: 32),
                            const Planning503020DistributionCard(),
                            const SizedBox(height: 1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWhereIsMoneyHeader(l10n, theme),
                            const SizedBox(height: 16),
                            const SummaryTypeSelection(),
                            const SizedBox(height: 24),
                            _buildCategorySummaries(context, l10n, theme),
                            const SizedBox(height: 32),
                            const BalanceSummaryView(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  // Saldos e Faturas
                  _buildAccountsHeader(context, l10n, theme),
                  const SizedBox(height: 16),
                  const AccountsView(),
                  const SizedBox(height: 32),
                  // Distribuição 50-30-20
                  const Planning503020DistributionCard(),
                  const SizedBox(height: 32),
                  // Onde está o dinheiro?
                  _buildWhereIsMoneyHeader(l10n, theme),
                  const SizedBox(height: 16),
                  // View Type Selector
                  const SummaryTypeSelection(),
                  const SizedBox(height: 24),
                  _buildCategorySummaries(context, l10n, theme),
                  const SizedBox(height: 32),
                  const BalanceSummaryView(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsHeader(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.homeAccountsAndCards,
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            context.push('/workspace/accounts');
          },
        ),
      ],
    );
  }

  Widget _buildWhereIsMoneyHeader(AppLocalizations l10n, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeWhereIsMoney,
            style: theme.textTheme.titleLarge,
          ),
        ),
        PeriodSelection(),
      ],
    );
  }

  Widget _buildCategorySummaries(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenses,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.deepTurquoise,
          ),
        ),
        const SizedBox(height: 16),
        const CategorySummaryView(categoryType: CategoryType.expense),
        const SizedBox(height: 32),
        Text(
          l10n.incomes,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.deepTurquoise,
          ),
        ),
        const SizedBox(height: 16),
        const CategorySummaryView(categoryType: CategoryType.income),
      ],
    );
  }
}
