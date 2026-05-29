import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'type_card.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/logo-horizontal.png',
            height: 100,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.pureWhite
            ),
          ),
          const SizedBox(height: 48),
          TypeCard(
            title: l10n.onboardingPersonalTitle,
            description: l10n.onboardingPersonalDesc,
            icon: Icons.person,
            onTap: () => notifier.setWorkspaceType(WorkspaceType.personal),
          ),
          const SizedBox(height: 16),
          TypeCard(
            title: l10n.onboardingBusinessTitle,
            description: l10n.onboardingBusinessDesc,
            icon: Icons.business,
            onTap: () => notifier.setWorkspaceType(WorkspaceType.business),
          ),
        ],
      ),
    );
  }
}
