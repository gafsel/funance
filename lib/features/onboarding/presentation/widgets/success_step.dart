import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_spacing.dart';

class SuccessStep extends ConsumerStatefulWidget {
  const SuccessStep({super.key});

  @override
  ConsumerState<SuccessStep> createState() => _SuccessStepState();
}

class _SuccessStepState extends ConsumerState<SuccessStep> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);

    final slides = [
      _buildSuccessSlide(l10n),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptLimitsTitle,
        description: l10n.onboardingConceptLimitsDesc,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.teal,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptPlanningTitle,
        description: l10n.onboardingConceptPlanningDesc,
        icon: Icons.calendar_today_outlined,
        color: AppColors.gold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptTransactionsTitle,
        description: l10n.onboardingConceptTransactionsDesc,
        icon: Icons.receipt_long_outlined,
        color: AppColors.progressStart,
      ),
      // O jogo: XP/nível, missões/conquistas e o coach — os diferenciais do
      // produto precisam ser apresentados antes de o usuário cair na home.
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptXpTitle,
        description: l10n.onboardingConceptXpDesc,
        icon: Icons.bolt,
        color: AppColors.gold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptMissionsTitle,
        description: l10n.onboardingConceptMissionsDesc,
        icon: Icons.emoji_events_outlined,
        color: AppColors.gold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptCoachTitle,
        description: l10n.onboardingConceptCoachDesc,
        icon: Icons.psychology_outlined,
        color: AppColors.teal,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptFeaturesTitle,
        description: l10n.onboardingConceptFeaturesDesc,
        icon: Icons.explore_outlined,
        color: AppColors.warning,
      ),
    ];

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppSpacing.allXl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: slides,
            ),
          ),
          AppSpacing.gapLg,
          Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: slides.length,
              effect: const WormEffect(
                dotColor: AppColors.teal,
                activeDotColor: AppColors.gold,
                dotHeight: 10,
                dotWidth: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          if (_currentPage < slides.length - 1)
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: AppDurations.normal,
                  curve: AppDurations.curve,
                );
              },
              // Avançar é a ação secundária do slide; o ouro fica reservado
              // ao CTA final.
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              child: Text(l10n.onboardingNext),
            )
          else
            LoadingButton.elevated(
              onPressed: (loading) async {
                final router = GoRouter.of(context);
                await loading(notifier.nextStep());
                unawaited(router.pushReplacement("/splash"));
              },
              child: Text(l10n.onboardingSuccessCTA),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessSlide(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 100,
          color: AppColors.progressStart,
        ),
        AppSpacing.gapXl,
        Text(
          l10n.onboardingSuccessTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.gold,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapMd,
        Text(
          l10n.onboardingSuccessDesc,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXl,
        Text(
          l10n.onboardingStepConceptsDesc,
          // O itálico é a voz da frase (uma nota de rodapé do passo), não um
          // degrau da escala: só a cor e o tamanho viraram token.
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.gold.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConceptSlide(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: AppSpacing.allLg,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(icon, size: 64, color: color),
        ),
        AppSpacing.gapXl,
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.gold),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapMd,
        Text(
          description,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
