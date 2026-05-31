import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.group_add_outlined,
                size: 64,
                color: AppColors.brightCyan,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingMembersTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.paleGold,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingMembersDesc,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        hintText: 'exemplo@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (value) {
                        notifier.addInviteEmail(value.trim());
                        _emailController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      notifier.addInviteEmail(_emailController.text.trim());
                      _emailController.clear();
                    },
                    icon: const Icon(Icons.add, color: AppColors.deepTurquoise),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.paleGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingMembersListTitle,
                style: const TextStyle(
                  color: AppColors.paleGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepTurquoise.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.paleGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: inviteEmails.isEmpty
                      ? Center(
                          child: Text(
                            l10n.onboardingMembersEmpty,
                            style: TextStyle(
                              color: AppColors.pureWhite.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: inviteEmails.length,
                          itemBuilder: (context, index) {
                            final email = inviteEmails[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.mail_outline,
                                color: AppColors.brightCyan,
                              ),
                              title: Text(
                                email,
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.coralOrange,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    notifier.removeInviteEmail(email),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton.elevated(
                onPressed: (loading) async {
                  final navigator = Navigator.of(context);

                  await loading(notifier.nextStep());

                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: AppColors.deepTurquoise,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l10n.onboardingFinish),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
