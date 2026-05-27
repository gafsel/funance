import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/welcome_step.dart';
import '../widgets/workspace_info_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/members_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    // Tema customizado para fundo escuro do onboarding
    final darkContentTheme = Theme.of(context).copyWith(
      textTheme: AppTheme.darkTextTheme,
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            labelStyle: const TextStyle(color: AppColors.paleGold),
            hintStyle: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.5)),
            prefixIconColor: AppColors.paleGold,
          ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: SafeArea(
          child: Theme(
            data: darkContentTheme,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(context, state, notifier),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingState state, OnboardingNotifier notifier) {
    switch (state.currentStep) {
      case 0:
        return WelcomeStep(notifier: notifier);
      case 1:
        return WorkspaceInfoStep(state: state, notifier: notifier);
      case 2:
        return GoalsStep(notifier: notifier);
      case 3:
        return MembersStep(state: state, notifier: notifier);
      default:
        return WelcomeStep(notifier: notifier);
    }
  }
}
