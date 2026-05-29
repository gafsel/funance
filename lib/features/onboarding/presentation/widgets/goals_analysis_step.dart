import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final goals = ref.watch(
      OnboardingViewProviders.onboarding.select(
        (s) => s.planningSuggestions?.goals ?? [],
      ),
    );
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
          Expanded(child: _buildSuggestedGoals(goals, notifier, context)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: goals.isEmpty ? null : () => notifier.nextStep(),
            child: Text(l10n.onboardingGoalsButton),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedGoals(
    List goals,
    OnboardingNotifier notifier,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final goal = goals[index];
        // Nota: Como estamos usando Riverpod reativo, precisamos saber se está selecionado.
        // Por simplificação neste step de onboarding, todos os sugeridos estão na lista inicialmente.
        // O toggle remove ou adiciona da lista de onboardingGoals.

        return Card(
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
                NumberFormat.simpleCurrency().format(goal.targetAmount),
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
}
