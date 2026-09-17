import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/overview/overview_category_item.dart';
import 'package:funances/features/home/presentation/widgets/overview/overview_comparison_chart.dart';
import 'package:funances/features/home/presentation/widgets/overview/overview_donut_chart.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// O bloco de um tipo de categoria (despesas ou receitas): gráfico à esquerda,
/// legenda à direita — empilhados no celular.
///
/// O mesmo widget serve os dois tipos porque a única diferença entre eles é o
/// provider de onde vêm os números; duplicar a montagem faria duas telas que
/// precisariam ser corrigidas em par.
class CategorySummaryView extends ConsumerWidget {
  final CategoryType categoryType;

  const CategorySummaryView({super.key, required this.categoryType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = categoryType == CategoryType.expense
        ? HomeViewProviders.summaryExpenses
        : HomeViewProviders.summaryIncomes;
    final asyncState = ref.watch(provider);
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final locale = context.locale;

    // Sem rede, esta tela dizia "nenhum lançamento no período": a falha de
    // leitura virava uma lista vazia e a lista vazia virava uma afirmação
    // sobre o mês do usuário. O erro tem precedência sobre o estado vazio.
    if (asyncState.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorView.forError(
          context,
          asyncState.error,
          onRetry: () => Retry.monthSummary(ref, period.monthKey),
        ),
      );
    }

    final state = asyncState.valueOrNull;
    if (state == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final summaries = [
      ...state.summary,
      if (state.specificPlannedAmountOthers > 0 ||
          state.generalPlannedAmountOthers > 0 ||
          state.actualAmountOthers > 0)
        OverviewCategorySummary(
          // Sem nome guardado: a palavra sai do l10n na hora de desenhar
          // (`displayName`), como no gráfico da fatura.
          category: CategoryModel(
            id: CategoryModel.othersId,
            name: '',
            icon: 'more_horiz',
            color: '#808080',
            type: categoryType,
          ),
          specificPlannedAmount: state.specificPlannedAmountOthers,
          generalPlannedAmount: state.generalPlannedAmountOthers,
          actualAmount: state.actualAmountOthers,
        ),
    ];

    // Garantir que a categoria "Outros" agrupada fique por último
    // Já que state.summary vem ordenado do notifier, só precisamos garantir
    // que o item que acabamos de adicionar (se adicionado) esteja na posição correta.
    // Como usamos spread e depois o if, ele já está por último.
    // No entanto, se houver uma categoria "Outros" real em state.summary,
    // o notifier já a colocou no final de state.summary.

    if (summaries.isEmpty) {
      return EmptyState.centered(
        icon: Icons.pie_chart_outline,
        title: l10n.noTransactionsInPeriod,
        compact: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.layout;
        final isLargeScreen = layout.isWide;
        final isSmallScreen = layout.isCompact;

        Widget chartWidget;

        if (viewType == SummaryViewType.comparison) {
          chartWidget = buildOverviewComparisonChart(
            context,
            summaries,
            theme,
            l10n,
            locale,
            isLargeScreen,
          );
        } else {
          chartWidget = buildOverviewDonutChart(
            context,
            summaries,
            state.totalAmount,
            viewType,
            theme,
            l10n,
            locale,
          );
        }

        final legendList = Column(
          children: summaries.map((summary) {
            String value = '';
            double? progress;

            if (viewType == SummaryViewType.planning) {
              value = summary.plannedAmount.asCurrency(locale: locale);
            } else if (viewType == SummaryViewType.effective) {
              value = summary.actualAmount.asCurrency(locale: locale);
            } else {
              value =
                  '${summary.actualAmount.asCurrency(locale: locale)} / ${summary.plannedAmount.asCurrency(locale: locale)}';
            }

            return buildOverviewCategoryItem(
              context,
              summary.category.name,
              value,
              viewType == SummaryViewType.planning
                  ? summary.category.color.asColor().withValues(alpha: 0.4)
                  : summary.category.color.asColor(),
              progress: viewType == SummaryViewType.comparison
                  ? null
                  : progress,
              secondaryProgress:
                  viewType == SummaryViewType.planning &&
                      summary.plannedAmount > 0
                  ? (summary.specificPlannedAmount / summary.plannedAmount)
                        .clamp(0, 1)
                  : null,
            );
          }).toList(),
        );

        return Column(
          children: [
            if (isSmallScreen) ...[
              chartWidget,
              AppSpacing.gapXl,
              legendList,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chartWidget),
                  AppSpacing.gapXl,
                  Expanded(child: legendList),
                ],
              ),
            AppSpacing.gapMd,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    context.push('/category-details?type=${categoryType.name}'),
                icon: const Icon(Icons.list_alt),
                label: Text(l10n.homeOverviewShowDetails),
              ),
            ),
          ],
        );
      },
    );
  }
}
