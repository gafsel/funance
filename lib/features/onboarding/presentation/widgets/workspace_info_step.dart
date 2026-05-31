import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceInfoStep extends ConsumerWidget {
  const WorkspaceInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.workspace),
    );
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
            onPressed: () {
              notifier.previousStep();
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWorkspaceNameTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            workspace.type == WorkspaceType.personal
                ? l10n.onboardingWorkspaceNamePersonalHint
                : l10n.onboardingWorkspaceNameBusinessHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.onboardingWorkspaceNameLabel,
            ),
            onChanged: (value) => notifier.setWorkspaceName(value),
          ),
          const Spacer(),
          LoadingButton.elevated(
            onPressed: workspace.name.isEmpty
                ? null
                : (loading) async {
                    await loading(notifier.nextStep());
                  },
            child: Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
