import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
import 'package:funances/features/goal/presentation/widgets/goal_form_dialog.dart';
import 'package:intl/intl.dart';
import 'package:funances/l10n/app_localizations.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
                icon: const Icon(Icons.add_circle, color: AppColors.deepTurquoise),
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
              return Column(
                children: goals.map((goal) => _buildGoalCard(context, ref, goal)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text(e.toString())),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyScore(BuildContext context, AppLocalizations l10n, ThemeData theme) {
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

  Widget _buildEmptyGoals(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: AppColors.vibrantTeal),
            const SizedBox(height: 16),
            Text(
              l10n.goalEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goalEmptyExample,
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
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

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GoalFormDialog(),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalModel goal) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Cálculo de Progresso e Status
    final double percent;
    final String statusText;
    final Color statusColor;
    final bool isLost;

    final now = DateTime.now();
    final totalDays = goal.deadline.difference(DateTime.now().subtract(const Duration(days: 30))).inDays.toDouble(); // Simplificado
    final daysPassed = 30.0; // Simplificado para exemplo
    final timePercent = (daysPassed / (totalDays + daysPassed)).clamp(0.0, 1.0);

    if (goal.type == GoalType.saveMoney) {
      percent = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
      isLost = percent < timePercent * 0.5 && goal.deadline.isBefore(now.add(const Duration(days: 7)));
      
      if (percent >= 1.0) {
        statusText = l10n.statusOnTrack;
        statusColor = AppColors.brightCyan;
      } else if (isLost) {
        statusText = l10n.statusLost;
        statusColor = AppColors.coralOrange;
      } else if (percent < timePercent * 0.8) {
        statusText = l10n.statusBehind;
        statusColor = AppColors.coralOrange;
      } else if (percent < timePercent) {
        statusText = l10n.statusAtRisk;
        statusColor = AppColors.successGold;
      } else {
        statusText = l10n.statusOnTrack;
        statusColor = AppColors.limeGreen;
      }
    } else {
      // Redução de gastos
      final currentSpending = goal.currentAmount; // Valor gasto no mês atual para a categoria
      
      // Se gastou menos que a meta, está indo bem.
      // Progresso aqui é o quanto do "limite" ainda tenho ou o quão longe estou do estouro
      percent = (currentSpending / goal.targetAmount).clamp(0.0, 1.0);
      
      if (currentSpending > goal.targetAmount) {
        statusText = l10n.statusLost;
        statusColor = AppColors.coralOrange;
        isLost = true;
      } else if (currentSpending > goal.targetAmount * 0.9) {
        statusText = l10n.statusAtRisk;
        statusColor = AppColors.successGold;
        isLost = false;
      } else {
        statusText = l10n.statusOnTrack;
        statusColor = AppColors.limeGreen;
        isLost = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => GoalFormDialog(goal: goal),
        ),
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
                      goal.type == GoalType.saveMoney ? Icons.savings : Icons.trending_down,
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
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${l10n.goalTargetAmountLabel}: R\$ ${goal.targetAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
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
                    widthFactor: goal.type == GoalType.saveMoney ? percent : (1 - percent),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: AppGradients.progressGradient,
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
                    goal.type == GoalType.saveMoney
                        ? l10n.goalRemainingAmount('R\$ ${(goal.targetAmount - goal.currentAmount).toStringAsFixed(0)}')
                        : '${(percent * 100).toInt()}% do limite gasto',
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
