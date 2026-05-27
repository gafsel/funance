import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_providers.dart';

class GoalsStep extends StatelessWidget {
  final OnboardingNotifier notifier;
  const GoalsStep({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 80, color: AppColors.successGold),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingGoalsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingGoalsDesc,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          const LinearProgressIndicator(
            value: 0.75,
            backgroundColor: AppColors.deepTurquoise,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brightCyan),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => notifier.nextStep(),
            child: Text(l10n.onboardingGoalsButton),
          ),
        ],
      ),
    );
  }
}
