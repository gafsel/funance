import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class Planning503020DistributionCard extends ConsumerWidget {
  const Planning503020DistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewDate = ref.watch(HomeViewProviders.period);
    final distributionAsync = ref.watch(
      FinanceViewProviders.planning503020Distribution(overviewDate),
    );

    return distributionAsync.when(
      data: (distribution) =>
          _DistributionCardContent(distribution: distribution),
      error: (e, s) => const SizedBox.shrink(),
      loading: () => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _DistributionCardContent extends StatelessWidget {
  final Planning503020Distribution distribution;

  const _DistributionCardContent({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);
    final percentageFormat = NumberFormat.percentPattern(context.locale);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push('/planning-50-30-20'),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.deepTurquoise.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.planning503020DistributionTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepTurquoise,
                          ),
                        ),
                        Text(
                          l10n.planning503020Subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.deepTurquoise,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDistributionBar(
                context,
                title: l10n.planning503020Planned,
                essential: distribution.essential.plannedAmount,
                comfort: distribution.comfort.plannedAmount,
                investment: distribution.investment.plannedAmount,
                totalIncome: distribution.totalIncome,
                currencyFormat: currencyFormat,
                percentageFormat: percentageFormat,
                isPlanned: true,
              ),
              const SizedBox(height: 20),
              _buildDistributionBar(
                context,
                title: l10n.planning503020Actual,
                essential: distribution.essential.actualAmount,
                comfort: distribution.comfort.actualAmount,
                investment: distribution.investment.actualAmount,
                totalIncome: distribution.totalActualIncome > 0
                    ? distribution.totalActualIncome
                    : distribution.totalIncome,
                currencyFormat: currencyFormat,
                percentageFormat: percentageFormat,
                isPlanned: false,
              ),
              const SizedBox(height: 24),
              _buildLegend(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionBar(
    BuildContext context, {
    required String title,
    required double essential,
    required double comfort,
    required double investment,
    required double totalIncome,
    required NumberFormat currencyFormat,
    required NumberFormat percentageFormat,
    required bool isPlanned,
  }) {
    final total = essential + comfort + investment;
    final theme = Theme.of(context);

    // Cores mais vibrantes e profissionais
    final essentialColor = Colors.blue.shade600;
    final comfortColor = Colors.orange.shade600;
    final investmentColor = Colors.green.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isPlanned ? FontWeight.normal : FontWeight.bold,
                color: isPlanned
                    ? theme.textTheme.labelMedium?.color?.withValues(alpha: 0.7)
                    : null,
              ),
            ),
            Text(
              currencyFormat.format(total),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPlanned
                    ? theme.textTheme.labelMedium?.color?.withValues(alpha: 0.7)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: total <= 0
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      if (essential > 0)
                        Expanded(
                          flex: (essential * 1000).toInt(),
                          child: Container(
                            color: essentialColor.withValues(
                              alpha: isPlanned ? 0.4 : 1.0,
                            ),
                            alignment: Alignment.center,
                            child: _BarPercentage(
                              value: essential / total,
                              percentageFormat: percentageFormat,
                            ),
                          ),
                        ),
                      if (comfort > 0)
                        Expanded(
                          flex: (comfort * 1000).toInt(),
                          child: Container(
                            color: comfortColor.withValues(
                              alpha: isPlanned ? 0.4 : 1.0,
                            ),
                            alignment: Alignment.center,
                            child: _BarPercentage(
                              value: comfort / total,
                              percentageFormat: percentageFormat,
                            ),
                          ),
                        ),
                      if (investment > 0)
                        Expanded(
                          flex: (investment * 1000).toInt(),
                          child: Container(
                            color: investmentColor.withValues(
                              alpha: isPlanned ? 0.4 : 1.0,
                            ),
                            alignment: Alignment.center,
                            child: _BarPercentage(
                              value: investment / total,
                              percentageFormat: percentageFormat,
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

  Widget _buildLegend(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LegendItem(
          color: Colors.blue,
          label: l10n.planning503020Essential,
          percentage: '50%',
        ),
        _LegendItem(
          color: Colors.orange,
          label: l10n.planning503020Comfort,
          percentage: '30%',
        ),
        _LegendItem(
          color: Colors.green,
          label: l10n.planning503020Investment,
          percentage: '20%',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($percentage)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _BarPercentage extends StatelessWidget {
  final double value;
  final NumberFormat percentageFormat;

  const _BarPercentage({required this.value, required this.percentageFormat});

  @override
  Widget build(BuildContext context) {
    if (value < 0.1) return const SizedBox.shrink();
    return Text(
      percentageFormat.format(value),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
