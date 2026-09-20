import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/widgets/goal_detail/goal_chart_legend_dot.dart';

/// Gráfico "ideal vs. real" do detalhe da meta.
///
/// A linha tracejada é a trajetória que a meta precisaria seguir para bater o
/// alvo no prazo; a sólida é onde ela está. O par é o que responde à pergunta
/// que o percentual sozinho não responde — "estou atrasado?" — e por isso vive
/// dentro do cabeçalho, sobre o fundo colorido da conta.
class GoalProgressChart extends StatelessWidget {
  final GoalModel goal;
  final dynamic progress; // GoalProgressViewModel
  final Color statusColor;

  const GoalProgressChart({
    super.key,
    required this.goal,
    required this.progress,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final start = goal.startDate;
    final end = goal.deadline;
    final totalDays = end.difference(start).inDays.toDouble();
    if (totalDays <= 0) return const SizedBox.shrink();

    final target = goal.targetAmount;
    final current = goal.currentAmount;
    final today = DateTime.now();
    final elapsedDays = today.isAfter(end)
        ? totalDays
        : today.isBefore(start)
        ? 0.0
        : today.difference(start).inDays.toDouble();

    // Linha ideal: de 0 → target linearmente
    final idealSpots = [FlSpot(0, 0), FlSpot(totalDays, target)];

    // Linha real: de 0 no start → currentAmount no dia atual
    final realSpots = [
      FlSpot(0, 0),
      FlSpot(elapsedDays.clamp(0, totalDays), current.clamp(0, target)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.goalProgressChartTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.inkInverse2,
              ),
            ),
            const Spacer(),
            LegendDot(
              color: AppColors.inkInverse.withValues(alpha: 0.5),
              label: l10n.goalChartIdealLine,
            ),
            AppSpacing.gapSm,
            LegendDot(
              color: AppColors.progressStart,
              label: l10n.goalChartRealLine,
            ),
          ],
        ),
        AppSpacing.gapXs,
        SizedBox(
          height: 110,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return Text(
                          l10n.goalChartStartLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkInverse.withValues(alpha: 0.5),
                          ),
                        );
                      }
                      if (value == totalDays) {
                        return Text(
                          l10n.goalChartEndLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkInverse.withValues(alpha: 0.5),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              minX: 0,
              maxX: totalDays,
              minY: 0,
              maxY: target * 1.05,
              lineBarsData: [
                // Linha ideal (tracejada)
                LineChartBarData(
                  spots: idealSpots,
                  isCurved: false,
                  color: AppColors.inkInverse.withValues(alpha: 0.4),
                  barWidth: 1.5,
                  dotData: FlDotData(show: false),
                  dashArray: [6, 4],
                ),
                // Linha real (sólida, colorida)
                LineChartBarData(
                  spots: realSpots,
                  isCurved: true,
                  color: AppColors.progressStart,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.progressStart.withValues(alpha: 0.3),
                        AppColors.progressStart.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
