import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers/coaching_providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
import 'package:funances/features/home/presentation/controller/mission_controller.dart';
import 'package:funances/features/home/presentation/widgets/team_status_view.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);
    final canActionCoach = ref.watch(CoachingViewProviders.canActionCoach);
    final insightsAsync = ref.watch(coachingInsightsProvider);
    final missionAsync = ref.watch(missionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

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
                const AutomaticTransactionConsolidationWidget(),
                if (isLargeScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            insightsAsync.when(
                              data: (insights) {
                                if (insights.isEmpty && !canActionCoach) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _buildCoachingCall(
                                      context,
                                      ref,
                                      l10n,
                                      theme,
                                      canActionCoach,
                                      insights.isNotEmpty ? insights.first : null,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            missionAsync.when(
                              data: (mission) => Column(
                                children: [
                                  WeeklyMissionsView(mission: mission),
                                  const SizedBox(height: 32),
                                ],
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, st) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: missionAsync.when(
                          data: (mission) => TeamStatusView(mission: mission),
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  )
                else ...[
                  insightsAsync.when(
                    data: (insights) {
                      if (insights.isEmpty && !canActionCoach) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildCoachingCall(
                            context,
                            ref,
                            l10n,
                            theme,
                            canActionCoach,
                            insights.isNotEmpty ? insights.first : null,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  missionAsync.when(
                    data: (mission) => Column(
                      children: [
                        WeeklyMissionsView(mission: mission),
                        const SizedBox(height: 32),
                        TeamStatusView(mission: mission),
                        const SizedBox(height: 32),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ],
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
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

  Widget _buildCoachingCall(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    bool canAction,
    CoachingModel? lastCoaching,
  ) {
    final locale = context.locale;
    final bannerColors = _getBannerColors(canAction, lastCoaching);
    final accentColor = _getAccentColor(canAction, lastCoaching);
    final bannerIcon = _getBannerIcon(canAction, lastCoaching);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bannerColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 120,
              color: accentColor.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bannerIcon,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.coachingTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  canAction
                      ? l10n.coachingConsultingDesc
                      : lastCoaching?.message ??
                          l10n.coachingLastAnalysisFrom(
                            lastCoaching!.date.formated(l10n.formatSimpleDate, locale),
                          ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.9),
                  ),
                ),
                if (!canAction && lastCoaching != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.coachingLastAnalysisFrom(
                      DateFormat.yMMMMd(locale).format(lastCoaching.date),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.pureWhite.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!canAction && lastCoaching != null) {
                        ref
                            .read(
                              CoachingViewProviders.coachingNotifier.notifier,
                            )
                            .setCoaching(lastCoaching);
                        context.push('/coaching');
                        return;
                      }

                      try {
                        final coaching = await showLoadingModal(
                          context,
                          ref
                              .read(
                                CoachingViewProviders.coachingNotifier.notifier,
                              )
                              .generateCoaching(),
                          child: AnalysisLoadingView(
                            title: l10n.coachingConsulting,
                            description: l10n.coachingConsultingDesc,
                          ),
                        );

                        if (coaching != null && context.mounted) {
                          context.push('/coaching');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.coachingError)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      (canAction
                              ? l10n.coachingConsultAction
                              : l10n.coachingViewLast)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getBannerColors(bool canAction, CoachingModel? lastCoaching) {
    if (canAction) {
      return [AppColors.deepTurquoise, AppColors.vibrantTeal];
    }

    if (lastCoaching == null) {
      return [AppColors.darkNavy, AppColors.darkNavy.withValues(alpha: 0.8)];
    }

    switch (lastCoaching.type) {
      case CoachingType.warning:
        return [
          AppColors.error.withValues(alpha: 0.8),
          AppColors.error.withValues(alpha: 0.6),
        ];
      case CoachingType.tip:
        return [
          AppColors.limeGreen.withValues(alpha: 0.8),
          AppColors.limeGreen.withValues(alpha: 0.6),
        ];
      case CoachingType.insight:
      default:
        return [AppColors.deepTurquoise, AppColors.vibrantTeal];
    }
  }

  Color _getAccentColor(bool canAction, CoachingModel? lastCoaching) {
    if (canAction) {
      return AppColors.successGold;
    }

    if (lastCoaching == null) {
      return AppColors.vibrantTeal;
    }

    switch (lastCoaching.type) {
      case CoachingType.warning:
        return AppColors.coralOrange;
      case CoachingType.tip:
        return AppColors.antiqueGold;
      case CoachingType.insight:
      default:
        return AppColors.deepTurquoise;
    }
  }

  IconData _getBannerIcon(bool canAction, CoachingModel? lastCoaching) {
    if (canAction || lastCoaching == null) {
      return Icons.psychology;
    }

    switch (lastCoaching.type) {
      case CoachingType.warning:
        return Icons.warning_amber_rounded;
      case CoachingType.tip:
        return Icons.lightbulb_outline;
      case CoachingType.insight:
      default:
        return Icons.psychology;
    }
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = ref.watch(goalProgressProvider(goal));
    final locale = context.locale;

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
                            goal.targetAmount.asCurrency(locale: locale),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (goal.monthlyRequirement > 0)
                          Text(
                            l10n.goalMonthlyRequirementValue(
                              goal.monthlyRequirement.asCurrency(locale: locale),
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
                            progress.getStatusColor(context).withValues(alpha: .5),
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
                  Text(
                    goal.type == GoalType.saveMoney ||
                            goal.type == GoalType.payDebt
                        ? l10n.goalRemainingValue(
                        (goal.targetAmount - goal.currentAmount).asCurrency(locale: locale)
                          )
                        : progress.percent.asPercent(locale: locale),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    goal.deadline.formated(l10n.formatSimpleDate),
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
