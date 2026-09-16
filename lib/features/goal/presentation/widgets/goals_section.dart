import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_progress_ui.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.deepTurquoise,
                      ),
                      tooltip: l10n.journeyAddGoalTooltip,
                      onPressed: () => _showAddGoalDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          if (running.isNotEmpty) const SizedBox(height: 24),
                          Text(
                            l10n.journeyClosedGoalsTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGoalGrid(context, closed),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(e.toString())),
                ),
      ],
    );
  }

  Widget _buildEmptyGoals(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.vibrantTeal,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.goalEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goalEmptyExample,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addGoalButton),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, [GoalModel? goal]) {
    context.push('/goals/form', extra: goal);
  }

  /// Grade responsiva de cards (a mesma quebra para as ativas e as encerradas).
  Widget _buildGoalGrid(BuildContext context, List<GoalModel> goals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        if (crossAxisCount > 1) {
          const spacing = 16.0;
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
                  padding: const EdgeInsets.only(bottom: 16),
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
    final progress = goal.calculateProgress();
    final locale = context.locale;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/goals/${goal.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.deepTurquoise.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      goal.type == GoalType.saveMoney
                          ? Icons.savings
                          : goal.type == GoalType.payDebt
                          ? Icons.handshake
                          : Icons.trending_down,
                      color: AppColors.deepTurquoise,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.goalTargetTarget(
                            goal.targetAmount.asCurrency(locale: locale),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (goal.monthlyRequirement > 0)
                          Text(
                            l10n.goalMonthlyRequirementValue(
                              goal.monthlyRequirement.asCurrency(
                                locale: locale,
                              ),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.deepTurquoise,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: progress
                          .getStatusColor(context)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      progress.getStatusText(l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: progress.getStatusColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.deepTurquoise.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.predictionPercent,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.limeGreen,
                            progress
                                .getStatusColor(context)
                                .withValues(alpha: .5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.percent,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.limeGreen,
                            progress.getStatusColor(context),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  const SizedBox(width: 8),
                  Text(
                    goal.deadline.formated(l10n.formatSimpleDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (goal.isClosed) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(goal.outcomeIcon, size: 14, color: goal.outcomeColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        goal.outcomeLabel(
                              l10n,
                              (date) => date.formated(l10n.formatSimpleDate),
                            ) ??
                            '',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
