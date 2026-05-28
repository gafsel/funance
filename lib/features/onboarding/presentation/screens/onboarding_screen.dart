import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/welcome_step.dart';
import '../widgets/workspace_info_step.dart';
import '../widgets/accounts_step.dart';
import '../widgets/goals_analysis_step.dart';
import '../widgets/members_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));
    
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
              child: _buildStep(context, currentStep),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int currentStep) {
    switch (currentStep) {
      case 0:
        return const WelcomeStep();
      case 1:
        return const WorkspaceInfoStep();
      case 2:
        return const AccountsStep();
      case 3:
        return const GoalsAnalysisStep();
      case 4:
        return const MembersStep();
      default:
        return const WelcomeStep();
    }
  }
}
