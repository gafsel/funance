import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/planning/allocation_tab_label.dart';
import 'package:funances/features/finance/presentation/widgets/planning/planning_analysis_action.dart';
import 'package:funances/features/finance/presentation/widgets/planning/planning_summary_header.dart';
import 'package:funances/features/finance/presentation/widgets/planning/pool_column.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Planejamento 50-30-20
//
// O arquivo tinha 1109 linhas, e o maior método do pacote inteiro estava
// aqui: `_PoolWidget._buildPoolHeader`, 261 linhas de gráfico desenhado à
// mão. Tudo foi para `presentation/widgets/planning/`; a tela guarda a
// navegação de mês, os dois arranjos (abas no mobile, três colunas no
// desktop) e a ordem de erro → carregando → conteúdo.
// ─────────────────────────────────────────────────────────────────────────────

class Planning503020Screen extends ConsumerWidget {
  const Planning503020Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: ref
                  .read(FinanceViewProviders.planning503020.notifier)
                  .previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            const Expanded(child: _MonthLabel()),
            IconButton(
              onPressed: ref
                  .read(FinanceViewProviders.planning503020.notifier)
                  .nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          const PlanningAnalysisAction(),
          LoadingButton.icon(
            const Icon(Icons.save),
            onPressed: (loading) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              // Resolve a mensagem antes do await: depois dele o context pode
              // não estar mais montado.
              final successMessage = context.l10n.savedSuccess;

              await loading(
                ref.read(FinanceViewProviders.planning503020.notifier).submit(),
              );

              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(successMessage)),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final allocations = CategoryAllocation.values;

          // Erro e carregamento vêm ANTES das pools: três colunas vazias são
          // indistinguíveis de "você não planejou nada".
          final erro = ref.watch(
            FinanceViewProviders.planning503020.select((s) => s.error),
          );
          if (erro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView.forError(
                  context,
                  erro,
                  onRetry: () => ref
                      .read(FinanceViewProviders.planning503020.notifier)
                      .retry(),
                ),
              ),
            );
          }

          final carregando = ref.watch(
            FinanceViewProviders.planning503020.select((s) => s.isLoading),
          );
          if (carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final header = Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: PlanningSummaryHeader(isMobile: isMobile),
          );

          if (isMobile) {
            return SafeArea(
              child: DefaultTabController(
                length: allocations.length,
                child: Column(
                  children: [
                    header,
                    TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.deepTurquoise,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      labelStyle: const TextStyle(fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: [
                        for (final allocation in allocations)
                          Tab(
                            height: 60,
                            child: AllocationTabLabel(allocation: allocation),
                          ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final allocation in allocations)
                            PlanningPoolColumn(
                              allocation: allocation,
                              isMobile: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                header,
                Expanded(
                  child: Row(
                    children: [
                      for (final category in allocations)
                        Expanded(
                          child: PlanningPoolColumn(allocation: category),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// O mês em foco, por extenso quando cabe e abreviado quando não.
class _MonthLabel extends ConsumerWidget {
  const _MonthLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(
      FinanceViewProviders.planning503020.select((state) => state.date),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Text(
          isSmallScreen
              ? DateFormat.yM(context.locale).format(date)
              : DateFormat.yMMMM(context.locale).format(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
