import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/utils/date_extension.dart';

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
      // O card é a leitura do mês inteiro: sumir sem explicação fazia o
      // usuário achar que o 50-30-20 tinha deixado de existir.
      error: (e, _) => Padding(
        padding: AppSpacing.vXs,
        child: ErrorView.forError(
          context,
          e,
          onRetry: () =>
              Retry.planning503020(ref, overviewDate, overviewDate.monthKey),
        ),
      ),
      loading: () =>
          const AppCard(child: Center(child: CircularProgressIndicator())),
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
    final theme = Theme.of(context);
    final palette = context.palette;

    return AppCard(
      onTap: () => context.push('/planning-50-30-20'),
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
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      l10n.planning503020Subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.ink),
            ],
          ),
          AppSpacing.gapLg,
          _DistributionBar(
            title: l10n.planning503020Planned,
            essential: distribution.essential.plannedAmount,
            comfort: distribution.comfort.plannedAmount,
            investment: distribution.investment.plannedAmount,
            currencyFormat: currencyFormat,
            isPlanned: true,
          ),
          AppSpacing.gapMd,
          _DistributionBar(
            title: l10n.planning503020Actual,
            essential: distribution.essential.actualAmount,
            comfort: distribution.comfort.actualAmount,
            investment: distribution.investment.actualAmount,
            currencyFormat: currencyFormat,
            isPlanned: false,
          ),
          AppSpacing.gapLg,
          const _Legend(),
        ],
      ),
    );
  }
}

/// Uma das duas leituras da distribuição: o planejado (esmaecido) e o real.
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.title,
    required this.essential,
    required this.comfort,
    required this.investment,
    required this.currencyFormat,
    required this.isPlanned,
  });

  final String title;
  final double essential;
  final double comfort;
  final double investment;
  final NumberFormat currencyFormat;
  final bool isPlanned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final total = essential + comfort + investment;

    // As três cores são DADO semântico: são as pools do 50/30/20. O planejado
    // é a mesma cor esmaecida, para que o real leia como o que já aconteceu.
    final alpha = isPlanned ? 0.4 : 1.0;

    // A porcentagem REAL vai dentro da faixa — é o que responde "estou
    // gastando quanto no essencial?", e a legenda embaixo só mostra o alvo.
    // Só a barra do real a carrega: a do planejado está a 40% de opacidade
    // sobre o papel, e nenhum texto passa no contraste ali.
    final percent = isPlanned || total <= 0
        ? null
        : NumberFormat.percentPattern(context.locale);
    String? labelFor(double value) => percent?.format(value / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isPlanned ? FontWeight.normal : null,
                color: isPlanned ? palette.ink2 : null,
              ),
            ),
            Text(
              currencyFormat.format(total),
              style: theme.textTheme.labelMedium?.copyWith(
                color: isPlanned ? palette.ink2 : null,
              ),
            ),
          ],
        ),
        AppSpacing.gapXs,
        AppPoolBar(
          height: 16,
          semanticLabel: title,
          segments: total <= 0
              ? const []
              : [
                  PoolSegment(
                    fraction: essential / total,
                    color: AppColors.pool50.withValues(alpha: alpha),
                    label: labelFor(essential),
                  ),
                  PoolSegment(
                    fraction: comfort / total,
                    color: AppColors.pool30.withValues(alpha: alpha),
                    label: labelFor(comfort),
                  ),
                  PoolSegment(
                    fraction: investment / total,
                    color: AppColors.pool20.withValues(alpha: alpha),
                    label: labelFor(investment),
                  ),
                ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LegendItem(
          color: AppColors.pool50,
          label: l10n.planning503020Essential,
          percentage: '50%',
        ),
        _LegendItem(
          color: AppColors.pool30,
          label: l10n.planning503020Comfort,
          percentage: '30%',
        ),
        _LegendItem(
          color: AppColors.pool20,
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
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$label ($percentage)',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
