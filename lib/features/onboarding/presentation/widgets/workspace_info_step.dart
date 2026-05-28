import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceInfoStep extends ConsumerWidget {
  const WorkspaceInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceType = ref.watch(onboardingNotifierProvider.select((s) => s.workspaceType));
    final workspaceName = ref.watch(onboardingNotifierProvider.select((s) => s.workspaceName));
    final isSubmitting = ref.watch(onboardingNotifierProvider.select((s) => s.isSubmitting));
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
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
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWorkspaceNameTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            workspaceType == WorkspaceType.personal
                ? l10n.onboardingWorkspaceNamePersonalHint
                : l10n.onboardingWorkspaceNameBusinessHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: workspaceName,
            decoration: InputDecoration(
              labelText: l10n.onboardingWorkspaceNameLabel,
            ),
            onChanged: (value) => notifier.setWorkspaceName(value),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: workspaceName.isEmpty || isSubmitting
                ? null
                : () async {
                    final success = await notifier.createWorkspace();
                    if (success) {
                      notifier.nextStep();
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.onboardingWorkspaceCreateError)),
                      );
                    }
                  },
            child: isSubmitting
                ? const CircularProgressIndicator(color: AppColors.deepTurquoise)
                : Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
