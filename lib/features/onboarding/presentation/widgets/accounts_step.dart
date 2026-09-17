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
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';

class AccountsStep extends ConsumerWidget {
  const AccountsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(AccountViewProviders.all);
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);

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
          const SizedBox(height: 24),
          Text(
            l10n.onboardingAccountsTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.paleGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAccountsDesc,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          const SizedBox(height: 32),
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
          const SizedBox(height: 24),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paleGold,
              foregroundColor: AppColors.deepTurquoise,
            ),
            child: Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OnboardingNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: AppColors.pureWhite.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingAccountsEmpty,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showAddAccount(context, notifier),
            icon: const Icon(Icons.add),
            label: Text(l10n.onboardingAccountsAdd),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.paleGold,
              side: const BorderSide(color: AppColors.paleGold),
            ),
          ),
        ],
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return OutlinedButton.icon(
            onPressed: () => _showAddAccount(context, notifier),
            icon: const Icon(Icons.add),
            label: Text(l10n.onboardingAccountsAddAnother),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.paleGold,
              side: const BorderSide(color: AppColors.paleGold),
            ),
          );
        }

        final account = accounts[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.deepTurquoise.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.paleGold.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(
                int.parse(account.color.replaceAll('#', '0xFF')),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white),
            ),
            title: Text(
              account.name,
              style: const TextStyle(color: AppColors.pureWhite),
            ),
            subtitle: Text(
              l10n.fromAccountType(account.type),
              style: TextStyle(
                color: AppColors.pureWhite.withValues(alpha: 0.7),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.coralOrange,
              ),
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
