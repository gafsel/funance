import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
import 'package:funances/features/goal/presentation/screen/goal_form_screen.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 120.0,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placar do Mês (Simplificado para o exemplo)
            _buildMonthlyScore(context, l10n, theme),
            const SizedBox(height: 24),
            // Listagem de Metas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.onboardingGoalsTitle,
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.deepTurquoise,
                  ),
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
                      final spacing = 16.0;
                      final width =
                          (constraints.maxWidth -
                              (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: goals.map((goal) {
                            return SizedBox(
                              width: width.clamp(0.0, 400.0),
                              child: _buildGoalCard(context, ref, goal),
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
                              child: _buildGoalCard(context, ref, goal),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(e.toString())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyScore(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.progressGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brightCyan.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppColors.pureWhite, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeTotalSavedMonth(r'R$ 500'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.homePointsEarned(50),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalModel goal) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = ref.watch(goalProgressProvider(goal));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showAddGoalDialog(context, goal),
        onLongPress: () => ref.read(goalsProvider.notifier).deleteGoal(goal.id),
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
                            NumberFormat.simpleCurrency().format(
                              goal.targetAmount,
                            ),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (goal.monthlyRequirement > 0)
                          Text(
                            l10n.goalMonthlyRequirementValue(
                              NumberFormat.simpleCurrency().format(
                                goal.monthlyRequirement,
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
                  Text(
                    goal.type == GoalType.saveMoney ||
                            goal.type == GoalType.payDebt
                        ? l10n.goalRemainingValue(
                            NumberFormat.simpleCurrency().format(
                              goal.targetAmount - goal.currentAmount,
                            ),
                          )
                        : l10n.goalProgressValue(
                            (progress.percent * 100).toInt().toString(),
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat.yMd().format(goal.deadline),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
