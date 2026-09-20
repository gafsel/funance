import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
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
/// A **Party saiu daqui** (decisão 9 do dono: "essa visão não faz mais
/// sentido com a nova visão de jogo"). Ela tinha vindo da Home por um bom
/// motivo — falava de planejamento por categoria, que é o assunto desta aba
/// —, mas era um segundo jogo dentro do app, com uma vida, um status e um
/// emoji próprios, competindo com a luta da semana que agora abre a primeira
/// aba. O anel dela sobreviveu genérico em
/// `core/widgets/progress_ring_icon.dart`.
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
        final isLargeScreen = constraints.layout.isWide;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.bottomBarSafeArea,
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
                            AppSpacing.gapMd,
                            const AccountsView(),
                            AppSpacing.gapXl,
                            const Planning503020DistributionCard(),
                            const SizedBox(height: 1),
                          ],
                        ),
                      ),
                      AppSpacing.gapXl,
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWhereIsMoneyHeader(l10n, theme),
                            AppSpacing.gapMd,
                            const SummaryTypeSelection(),
                            AppSpacing.gapLg,
                            _buildCategorySummaries(context, l10n, theme),
                            AppSpacing.gapXl,
                            const BalanceSummaryView(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  // Saldos e Faturas
                  _buildAccountsHeader(context, l10n, theme),
                  AppSpacing.gapMd,
                  const AccountsView(),
                  AppSpacing.gapXl,
                  // Distribuição 50-30-20
                  const Planning503020DistributionCard(),
                  AppSpacing.gapXl,
                  // Onde está o dinheiro?
                  _buildWhereIsMoneyHeader(l10n, theme),
                  AppSpacing.gapMd,
                  // View Type Selector
                  const SummaryTypeSelection(),
                  AppSpacing.gapLg,
                  _buildCategorySummaries(context, l10n, theme),
                  AppSpacing.gapXl,
                  const BalanceSummaryView(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsHeader(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.homeAccountsAndCards, style: theme.textTheme.titleLarge),
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
          child: Text(l10n.homeWhereIsMoney, style: theme.textTheme.titleLarge),
        ),
        PeriodSelection(),
      ],
    );
  }

  Widget _buildCategorySummaries(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenses,
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.palette.ink,
          ),
        ),
        AppSpacing.gapMd,
        const CategorySummaryView(categoryType: CategoryType.expense),
        AppSpacing.gapXl,
        Text(
          l10n.incomes,
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.palette.ink,
          ),
        ),
        AppSpacing.gapMd,
        const CategorySummaryView(categoryType: CategoryType.income),
      ],
    );
  }
}
