import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_providers.dart';

class WorkspaceInfoStep extends StatefulWidget {
  final OnboardingState state;
  final OnboardingNotifier notifier;
  const WorkspaceInfoStep({super.key, required this.state, required this.notifier});

  @override
  State<WorkspaceInfoStep> createState() => _WorkspaceInfoStepState();
}

class _WorkspaceInfoStepState extends State<WorkspaceInfoStep> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.workspaceName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
            onPressed: () => widget.notifier.previousStep(),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWorkspaceNameTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            widget.state.workspaceType == WorkspaceType.personal
                ? l10n.onboardingWorkspaceNamePersonalHint
                : l10n.onboardingWorkspaceNameBusinessHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.onboardingWorkspaceNameLabel,
            ),
            onChanged: (value) => widget.notifier.setWorkspaceName(value),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: widget.state.workspaceName.isEmpty || widget.state.isSubmitting
                ? null
                : () async {
                    final success = await widget.notifier.createWorkspace();
                    if (success) {
                      widget.notifier.nextStep();
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.onboardingWorkspaceCreateError)),
                      );
                    }
                  },
            child: widget.state.isSubmitting
                ? const CircularProgressIndicator(color: AppColors.deepTurquoise)
                : Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
