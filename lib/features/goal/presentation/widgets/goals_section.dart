import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_progress_ui.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/widgets/empty_state.dart';

/// Seção de metas da Jornada.
///
/// Vive fora do `JourneyTab` para poder ser montada sozinha num teste de
/// widget: o resto da aba puxa coaching, missões e Party, cada um com os seus
/// providers e o seu Firebase, e nada disso tem a ver com a lista de metas.
class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(GoalViewProvider.goalsStream);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Listagem de Metas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.onboardingGoalsTitle,
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: context.palette.tealText),
              tooltip: l10n.journeyAddGoalTooltip,
              onPressed: () => _showAddGoalDialog(context),
            ),
          ],
        ),
        AppSpacing.gapMd,
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyGoals(context, l10n, theme);
            }

            // Metas encerradas saem da lista das que estão correndo:
            // uma meta que estourou o limite lado a lado com as ativas
            // sugere que ainda dá tempo de fazer alguma coisa por ela.
            // O mesmo vale para a meta cujo prazo venceu e que ainda
            // espera a apuração do servidor — ela também não corre mais.
            final running = [
              for (final goal in goals)
                if (!goal.isClosed) goal,
            ];
            final closed = [
              for (final goal in goals)
                if (goal.isClosed) goal,
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (running.isNotEmpty) _buildGoalGrid(context, running),
                if (closed.isNotEmpty) ...[
                  if (running.isNotEmpty) AppSpacing.gapLg,
                  Text(
                    l10n.journeyClosedGoalsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.palette.ink2,
                    ),
                  ),
                  AppSpacing.gapSm,
                  _buildGoalGrid(context, closed),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              ErrorView.forError(context, e, onRetry: () => Retry.goals(ref)),
        ),
      ],
    );
  }

  Widget _buildEmptyGoals(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return EmptyState.centered(
      icon: Icons.flag_outlined,
      title: l10n.goalEmptyMessage,
      message: l10n.goalEmptyExample,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      action: ElevatedButton.icon(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addGoalButton),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, [GoalModel? goal]) {
    context.push(goal == null ? '/goals/form' : '/goals/form?id=${goal.id}');
  }

  /// Grade responsiva de cards (a mesma quebra para as ativas e as encerradas).
  Widget _buildGoalGrid(BuildContext context, List<GoalModel> goals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Quatro cortes literais (600/900/1200) para o mesmo dado que o
        // design system já resolve: um cartão de meta por coluna do layout.
        final crossAxisCount = constraints.layout.columns;

        if (crossAxisCount > 1) {
          const spacing = AppSpacing.md;
          final width =
              (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
              crossAxisCount;
          return Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: goals.map((goal) {
                return SizedBox(
                  width: width.clamp(0.0, 400.0),
                  child: _buildGoalCard(context, goal),
                );
              }).toList(),
            ),
          );
        }

        return Column(
          children: goals
              .map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildGoalCard(context, goal),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final progress = goal.calculateProgress();
    final locale = context.locale;
    final statusColor = progress.getStatusColor(context);

    return AppCard(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.allXs,
                decoration: BoxDecoration(
                  color: palette.ink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.type == GoalType.saveMoney
                      ? Icons.savings
                      : goal.type == GoalType.payDebt
                      ? Icons.handshake
                      : Icons.trending_down,
                  color: palette.ink,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.titleMedium),
                    Text(
                      l10n.goalTargetTarget(
                        goal.targetAmount.asCurrency(locale: locale),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (goal.monthlyRequirement > 0)
                      Text(
                        l10n.goalMonthlyRequirementValue(
                          goal.monthlyRequirement.asCurrency(locale: locale),
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                  ],
                ),
              ),
              StatusPill(
                label: progress.getStatusText(l10n),
                color: statusColor,
                dense: true,
              ),
            ],
          ),
          AppSpacing.gapMd,
          // Duas camadas do MESMO componente: atrás a projeção, na frente
          // o realizado. A da frente não desenha trilho para não apagar a
          // de trás.
          Stack(
            children: [
              AppProgressBar(
                value: progress.predictionPercent,
                size: AppProgressSize.thick,
                color: statusColor.withValues(alpha: .5),
              ),
              Positioned.fill(
                child: AppProgressBar(
                  value: progress.percent,
                  size: AppProgressSize.thick,
                  color: statusColor,
                  trackColor: AppColors.transparent,
                  semanticLabel: goal.name,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // O texto muda com o tipo: nas metas de redução,
              // `currentAmount` é gasto contra um teto, não conquista.
              Expanded(
                child: Text(
                  goal.progressSummary(
                    l10n,
                    (value) => value.asCurrency(locale: locale),
                  ),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                goal.deadline.formated(l10n.formatSimpleDate),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (goal.isClosed) ...[
            AppSpacing.gapXxs,
            Row(
              children: [
                Icon(goal.outcomeIcon, size: 14, color: goal.outcomeColor),
                AppSpacing.gapXxs,
                Expanded(
                  child: Text(
                    goal.outcomeLabel(
                          l10n,
                          (date) => date.formated(l10n.formatSimpleDate),
                        ) ??
                        '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: goal.outcomeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
