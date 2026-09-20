import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';

class MembersStep extends ConsumerStatefulWidget {
  const MembersStep({super.key});

  @override
  ConsumerState<MembersStep> createState() => _MembersStepState();
}

class _MembersStepState extends ConsumerState<MembersStep> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inviteEmails = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.inviteEmails),
    );

    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);

    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.group_add_outlined,
            size: 64,
            color: AppColors.teal,
          ),
          AppSpacing.gapLg,
          Text(
            l10n.onboardingMembersTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXs,
          Text(
            l10n.onboardingMembersDesc,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.inviteEmailHint,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (value) {
                    notifier.addInviteEmail(value.trim());
                    _emailController.clear();
                  },
                ),
              ),
              AppSpacing.gapXs,
              IconButton(
                onPressed: () {
                  notifier.addInviteEmail(_emailController.text.trim());
                  _emailController.clear();
                },
                icon: const Icon(Icons.add, color: AppColors.goldInk),
                style: IconButton.styleFrom(backgroundColor: AppColors.gold),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Text(
            l10n.onboardingMembersListTitle,
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.gold),
          ),
          AppSpacing.gapXs,
          Expanded(
            child: AppCard(
              padding: EdgeInsets.zero,
              borderColor: AppColors.gold.withValues(alpha: 0.2),
              child: inviteEmails.isEmpty
                  ? EmptyState.message(l10n.onboardingMembersEmpty)
                  : ListView.builder(
                      padding: AppSpacing.vXs,
                      itemCount: inviteEmails.length,
                      itemBuilder: (context, index) {
                        final email = inviteEmails[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.mail_outline,
                            color: AppColors.teal,
                          ),
                          title: Text(email),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            onPressed: () => notifier.removeInviteEmail(email),
                          ),
                        );
                      },
                    ),
            ),
          ),
          AppSpacing.gapXl,
          LoadingButton.elevated(
            onPressed: (loading) async {
              await loading(notifier.nextStep());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.progressStart,
              foregroundColor: AppColors.surfaceDeep,
            ),
            child: Text(l10n.onboardingFinish),
          ),
        ],
      ),
    );
  }
}
