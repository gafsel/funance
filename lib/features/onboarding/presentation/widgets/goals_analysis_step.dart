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

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/money_text.dart';
import 'package:funances/core/presentation/display_names.dart';

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

    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: Icon(Icons.arrow_back, color: context.palette.ink),
            onPressed: () => notifier.previousStep(),
          ),
          AppSpacing.gapLg,
          Text(
            l10n.onboardingGoalsAnalysisTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.gold,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            l10n.onboardingGoalsAnalysisDesc,
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.gapXl,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (goals.isNotEmpty) ...[
                    Text(
                      l10n.onboardingSuggestedGoalsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    AppSpacing.gapSm,
                    _buildSuggestedGoals(goals, notifier, context),
                    AppSpacing.gapLg,
                  ],
                  if (plannings.isNotEmpty) ...[
                    Text(
                      l10n.onboardingSuggestedPlanningsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    AppSpacing.gapSm,
                    _buildSuggestedPlannings(plannings, notifier, context),
                  ],
                  if (goals.isEmpty && plannings.isEmpty)
                    EmptyState.message(
                      l10n.onboardingNoSuggestions,
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.gapLg,
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
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return AppCard(
          padding: EdgeInsets.zero,
          borderColor: AppColors.gold.withValues(alpha: 0.2),
          child: ListTile(
            leading: const Icon(Icons.auto_awesome, color: AppColors.gold),
            title: Text(displayOr(goal.name, l10n.unnamedGoal)),
            subtitle: Text(
              l10n.goalTargetTarget(
                goal.targetAmount.asCurrency(locale: locale),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.warning),
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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plannings.length,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, index) {
        final planning = plannings[index];
        return AppCard(
          padding: EdgeInsets.zero,
          borderColor: AppColors.gold.withValues(alpha: 0.2),
          child: ListTile(
            leading: Icon(
              planning.category.icon.asIcon(),
              // A cor da categoria é DADO: é a que o usuário escolheu.
              color: planning.category.color.asColor(),
            ),
            title: Text(planning.category.displayName(context.l10n)),
            subtitle: MoneyText(planning.amount),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.warning),
              onPressed: () => notifier.removePlanning(planning),
            ),
          ),
        );
      },
    );
  }
}
