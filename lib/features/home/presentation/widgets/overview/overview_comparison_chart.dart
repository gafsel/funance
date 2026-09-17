import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Barras de planejado x efetivo, por categoria.
///
/// No desktop o gráfico é rotacionado (`RotatedBox`) em vez de trocado por um
/// `BarChart` horizontal: o fl_chart não tem barras horizontais, e girar o
/// widget inteiro é o que mantém tooltip, ordem e cores idênticos nas duas
/// orientações. Os ícones do eixo são girados de volta para não ficarem
/// deitados.
Widget buildOverviewComparisonChart(
  BuildContext context,
  List<OverviewCategorySummary> summaries,
  ThemeData theme,
  AppLocalizations l10n,
  String locale,
  bool isHorizontal,
) {
  final sortedSummaries = List<OverviewCategorySummary>.from(summaries)
    ..sort((a, b) {
      final valA = a.plannedAmount > a.actualAmount ? a.plannedAmount : a.actualAmount;
      final valB = b.plannedAmount > b.actualAmount ? b.plannedAmount : b.actualAmount;
      return valB.compareTo(valA);
    });

  // O maior valor deve ficar no topo.
  // Com RotatedBox(1), o índice 0 fica no topo, então usamos a lista ordenada decrescentemente sem inverter.
  final chartSummaries = sortedSummaries;

  final maxVal = sortedSummaries.fold<double>(
    0,
    (max, s) =>
        s.plannedAmount > max
            ? (s.actualAmount > s.plannedAmount ? s.actualAmount : s.plannedAmount)
            : (s.actualAmount > max ? s.actualAmount : max),
  );

  return SizedBox(
    height: isHorizontal ? (sortedSummaries.length * 50.0).clamp(250.0, 600.0) : 250,
    child: RotatedBox(
      quarterTurns: isHorizontal ? 1 : 0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final summary = chartSummaries[groupIndex];
                final isPlanned = rodIndex == 0;
                return BarTooltipItem(
                  '${summary.category.displayName(l10n)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: isPlanned ? l10n.overviewPlanning : l10n.overviewEffective,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: ': ${rod.toY.asCurrency(locale: locale)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= chartSummaries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: RotatedBox(
                      quarterTurns: isHorizontal ? -1 : 0,
                      child: Icon(
                        chartSummaries[value.toInt()].category.icon.asIcon(),
                        size: 16,
                        color: chartSummaries[value.toInt()].category.color.asColor(),
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !isHorizontal,
                getTitlesWidget: (value, meta) {
                  return const SizedBox.shrink();
                },
                reservedSize: 0,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: chartSummaries.asMap().entries.map((entry) {
            final index = entry.key;
            final summary = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: summary.plannedAmount,
                  color: summary.category.color.asColor().withValues(alpha: 0.4),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: summary.actualAmount,
                  color: summary.category.color.asColor(),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}
