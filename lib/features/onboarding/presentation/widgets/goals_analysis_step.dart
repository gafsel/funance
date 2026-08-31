import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/onboarding/presentation/controller/onboarding_notifier.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class GoalsAnalysisStep extends ConsumerWidget {
  const GoalsAnalysisStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.planningSuggestions),
    );
    final goals = suggestions?.goals ?? [];
    final plannings = suggestions?.plannings ?? [];

    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
            onPressed: () => notifier.previousStep(),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingGoalsAnalysisTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.paleGold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingGoalsAnalysisDesc,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (goals.isNotEmpty) ...[
                    Text(
                      l10n.onboardingSuggestedGoalsTitle,
                      style: const TextStyle(
                        color: AppColors.paleGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestedGoals(goals, notifier, context),
                    const SizedBox(height: 24),
                  ],
                  if (plannings.isNotEmpty) ...[
                    Text(
                      l10n.onboardingSuggestedPlanningsTitle,
                      style: const TextStyle(
                        color: AppColors.paleGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestedPlannings(plannings, notifier, context),
                  ],
                  if (goals.isEmpty && plannings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        l10n.onboardingNoSuggestions,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.pureWhite.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Sempre habilitado: sem sugestões da IA o usuário precisa poder
          // seguir em frente (metas podem ser criadas depois, na Jornada).
          ElevatedButton(
            onPressed: () => notifier.nextStep(),
            child: Text(l10n.onboardingGoalsButton),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedGoals(
    List<GoalModel> goals,
    OnboardingNotifier notifier,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.locale;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Card(
          margin: EdgeInsets.zero,
          color: AppColors.deepTurquoise.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.paleGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: const Icon(Icons.auto_awesome, color: AppColors.paleGold),
            title: Text(
              goal.name,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              l10n.goalTargetTarget(
                goal.targetAmount.asCurrency(locale: locale),
              ),
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.coralOrange,
              ),
              onPressed: () => notifier.removeGoal(goal),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedPlannings(
    List<CategoryPlanningModel> plannings,
    OnboardingNotifier notifier,
    BuildContext context,
  ) {
    final locale = context.locale;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plannings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final planning = plannings[index];
        return Card(
          margin: EdgeInsets.zero,
          color: AppColors.deepTurquoise.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.paleGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              planning.category.icon.asIcon(),
              color: planning.category.color.asColor(),
            ),
            title: Text(
              planning.category.name,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              planning.amount.asCurrency(locale: locale),
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.coralOrange,
              ),
              onPressed: () => notifier.removePlanning(planning),
            ),
          ),
        );
      },
    );
  }
}
