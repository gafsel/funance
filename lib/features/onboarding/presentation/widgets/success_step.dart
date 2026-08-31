import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_colors.dart';

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
        color: AppColors.brightCyan,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptPlanningTitle,
        description: l10n.onboardingConceptPlanningDesc,
        icon: Icons.calendar_today_outlined,
        color: AppColors.successGold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptTransactionsTitle,
        description: l10n.onboardingConceptTransactionsDesc,
        icon: Icons.receipt_long_outlined,
        color: AppColors.limeGreen,
      ),
      // O jogo: XP/nível, missões/conquistas e o coach — os diferenciais do
      // produto precisam ser apresentados antes de o usuário cair na home.
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptXpTitle,
        description: l10n.onboardingConceptXpDesc,
        icon: Icons.bolt,
        color: AppColors.successGold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptMissionsTitle,
        description: l10n.onboardingConceptMissionsDesc,
        icon: Icons.emoji_events_outlined,
        color: AppColors.paleGold,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptCoachTitle,
        description: l10n.onboardingConceptCoachDesc,
        icon: Icons.psychology_outlined,
        color: AppColors.vibrantTeal,
      ),
      _buildConceptSlide(
        context,
        title: l10n.onboardingConceptFeaturesTitle,
        description: l10n.onboardingConceptFeaturesDesc,
        icon: Icons.explore_outlined,
        color: AppColors.coralOrange,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
              const SizedBox(height: 24),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: slides.length,
                  effect: const WormEffect(
                    dotColor: AppColors.vibrantTeal,
                    activeDotColor: AppColors.paleGold,
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (_currentPage < slides.length - 1)
                ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantTeal,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.onboardingNext),
                )
              else
                LoadingButton.elevated(
                  onPressed: (loading) async {
                    final router = GoRouter.of(context);
                    await loading(notifier.nextStep());
                    router.pushReplacement("/splash");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGold,
                    foregroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(l10n.onboardingSuccessCTA),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessSlide(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 100,
          color: AppColors.limeGreen,
        ),
        const SizedBox(height: 32),
        Text(
          l10n.onboardingSuccessTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.paleGold,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingSuccessDesc,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(
          l10n.onboardingStepConceptsDesc,
          style: TextStyle(
            color: AppColors.paleGold.withValues(alpha: 0.7),
            fontSize: 16,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(
            icon,
            size: 64,
            color: color,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.paleGold,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
