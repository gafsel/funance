import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O donut de "onde está o dinheiro", com o total no miolo.
///
/// É função e não widget de propósito: o `CategorySummaryView` monta o gráfico
/// e a legenda lado a lado dentro do mesmo `LayoutBuilder`, e embrulhar isto
/// num widget só para separar o arquivo acrescentaria um nó à árvore sem
/// mudar nada do que aparece.
Widget buildOverviewDonutChart(
  BuildContext context,
  List<OverviewCategorySummary> summaries,
  double totalAmount,
  SummaryViewType viewType,
  ThemeData theme,
  AppLocalizations l10n,
  String locale,
) {
  return Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: summaries.map((summary) {
                double amount = 0;
                if (viewType == SummaryViewType.planning) {
                  amount = summary.plannedAmount;
                } else {
                  amount = summary.actualAmount;
                }

                return PieChartSectionData(
                  color: viewType == SummaryViewType.planning
                      ? summary.category.color.asColor().withValues(alpha: 0.4)
                      : summary.category.color.asColor(),
                  value: amount > 0 ? amount : 0,
                  radius: 20,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viewType == SummaryViewType.planning
                  ? l10n.homeTotalPlanned
                  : l10n.homeTotalSpent,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              totalAmount.asCurrency(locale: locale),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepTurquoise,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
