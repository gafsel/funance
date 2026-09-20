import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_theme.dart';
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
          spacing: AppSpacing.xs,
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
          // Três colunas só existem em tela de desktop: o corte é o do design
          // system, medido no PAINEL e não na janela.
          final isMobile = !constraints.layout.isWide;

          final allocations = CategoryAllocation.values;

          // Erro e carregamento vêm ANTES das pools: três colunas vazias são
          // indistinguíveis de "você não planejou nada".
          final erro = ref.watch(
            FinanceViewProviders.planning503020.select((s) => s.error),
          );
          if (erro != null) {
            return Center(
              child: Padding(
                padding: AppSpacing.allLg,
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
            padding: AppSpacing.allMd,
            color: context.palette.paper,
            child: PlanningSummaryHeader(isMobile: isMobile),
          );

          if (isMobile) {
            return SafeArea(
              child: DefaultTabController(
                length: allocations.length,
                child: Column(
                  children: [
                    header,
                    _AllocationTabBar(allocations: allocations),
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

/// As abas dos três pools, com a aba selecionada em superfície de jogo.
///
/// A aba escolhida é pintada com `surfaceDeep` — a "pasta" escura que dá a
/// cara de fichário à tela. O conteúdo dela, porém, continuava lendo a paleta
/// CLARA: o rótulo saía em `ink` sobre o fundo escuro (1,23:1, praticamente
/// invisível), e o ícone de status em `successInk`/`dangerInk` (2,02:1 e
/// 1,23:1, abaixo do piso de 3:1 de elemento gráfico). No tema claro a aba
/// aberta era a única que não dava para ler.
///
/// A correção é a do design system, não um hexadecimal escolhido a dedo: onde
/// a superfície é de jogo, o conteúdo passa a ler [AppTheme.onGame]. O rótulo
/// vira `inkInverse` (12,64:1), o ícone de estouro vira `danger` vivo
/// (3,39:1) e a marca da meta vira `inkInverse2` (8,01:1).
///
/// O `AnimatedBuilder` existe porque só o `TabController` sabe qual aba está
/// aberta, e o `Tab` não recebe esse estado — o `TabBar` só interpola a COR
/// do rótulo, nunca o tema de dentro dele.
class _AllocationTabBar extends StatelessWidget {
  const _AllocationTabBar({required this.allocations});

  final List<CategoryAllocation> allocations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TabBar(
        indicator: const BoxDecoration(
          color: AppColors.surfaceDeep,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sm),
          ),
        ),
        labelColor: AppColors.inkInverse,
        unselectedLabelColor: context.palette.ink2,
        // A tipografia sai do design system: a tela escrevia os rótulos em
        // `bodySmall` (texto corrido, peso 400) enquanto o resto do app usa
        // `labelLarge` nas abas. Era a mesma família, mas com outro peso e
        // outro tamanho — e de longe lia como "a fonte desta tela é outra".
        labelStyle: theme.textTheme.labelLarge,
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          for (var i = 0; i < allocations.length; i++)
            Tab(
              height: 60,
              child: AllocationTabLabel(
                allocation: allocations[i],
                onGame: controller.index == i,
              ),
            ),
        ],
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
        final isSmallScreen = constraints.layout.isCompact;

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
