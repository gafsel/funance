import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/onboarding/presentation/controller/onboarding_notifier.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/widgets/empty_state.dart';

class AccountsStep extends ConsumerWidget {
  const AccountsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(AccountViewProviders.all);
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);

    return Padding(
      padding: AppSpacing.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: Icon(Icons.arrow_back, color: context.palette.ink),
            onPressed: () {
              notifier.previousStep();
            },
          ),
          AppSpacing.gapLg,
          Text(
            l10n.onboardingAccountsTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.gold),
          ),
          AppSpacing.gapXs,
          Text(
            l10n.onboardingAccountsDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppSpacing.gapXl,
          Expanded(
            child: accountsAsync.when(
              data: (accounts) => accounts.isEmpty
                  ? _buildEmptyState(context, notifier)
                  : _buildAccountList(context, accounts, notifier),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: ErrorView.forError(
                  context,
                  e,
                  onRetry: () => Retry.accounts(ref),
                ),
              ),
            ),
          ),
          AppSpacing.gapLg,
          LoadingButton.elevated(
            onPressed: (loading) async {
              await showLoadingModal(
                context,
                notifier.nextStep(),
                child: AnalysisLoadingView(
                  title: l10n.onboardingPlanningAnalyzingTitle,
                  description: l10n.onboardingPlanningAnalyzingDesc,
                  firstPhaseDuration: const Duration(seconds: 20),
                  totalDuration: const Duration(minutes: 1, seconds: 20),
                ),
              );
            },
            child: Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OnboardingNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;

    return EmptyState.centered(
      icon: Icons.account_balance_outlined,
      title: l10n.onboardingAccountsEmpty,
      compact: true,
      action: OutlinedButton.icon(
        onPressed: () => _showAddAccount(context, notifier),
        icon: const Icon(Icons.add),
        label: Text(l10n.onboardingAccountsAdd),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _buildAccountList(
    BuildContext context,
    List<AccountModel> accounts,
    OnboardingNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      itemCount: accounts.length + 1,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return OutlinedButton.icon(
            onPressed: () => _showAddAccount(context, notifier),
            icon: const Icon(Icons.add),
            label: Text(l10n.onboardingAccountsAddAnother),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
            ),
          );
        }

        final account = accounts[index];
        return AppCard(
          padding: EdgeInsets.zero,
          borderColor: AppColors.gold.withValues(alpha: 0.2),
          child: ListTile(
            leading: CircleAvatar(
              // A cor da conta é DADO: vem do que o usuário escolheu.
              backgroundColor: Color(
                int.parse(account.color.replaceAll('#', '0xFF')),
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppColors.inkInverse,
              ),
            ),
            title: Text(account.name),
            subtitle: Text(l10n.fromAccountType(account.type)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.warning),
              onPressed: () => notifier.removeOnboardingAccount(account.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddAccount(BuildContext context, OnboardingNotifier notifier) {
    context.push('/accounts/form');
  }
}
