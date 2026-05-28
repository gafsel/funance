import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_dialog.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_providers.dart';

class AccountsStep extends ConsumerWidget {
  const AccountsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(onboardingNotifierProvider.select((s) => s.onboardingAccounts));
    final isAnalyzing = ref.watch(onboardingNotifierProvider.select((s) => s.isAnalyzing));
    final currentStep = ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
            onPressed: () {
              if (currentStep > 0) {
                notifier.previousStep();
              }
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
            child: accounts.isEmpty
                ? _buildEmptyState(context, notifier)
                : _buildAccountList(context, accounts, notifier),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: accounts.isEmpty || isAnalyzing
                ? null
                : () => notifier.analyzeAccounts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paleGold,
              foregroundColor: AppColors.deepTurquoise,
            ),
            child: isAnalyzing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTurquoise),
                  )
                : Text(l10n.continueButton.toUpperCase()),
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
          Icon(Icons.account_balance_outlined,
              size: 64, color: AppColors.pureWhite.withValues(alpha: 0.3)),
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

  Widget _buildAccountList(BuildContext context, List accounts, OnboardingNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      itemCount: accounts.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            border: Border.all(color: AppColors.paleGold.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Color(int.parse(account.color.replaceAll('#', '0xFF'))),
              child: const Icon(Icons.account_balance, color: Colors.white),
            ),
            title: Text(account.name,
                style: const TextStyle(color: AppColors.pureWhite)),
            subtitle: Text(
              account.fileName != null
                  ? l10n.onboardingAccountsAttachment(account.fileName!)
                  : l10n.onboardingAccountsManual,
              style: TextStyle(color: AppColors.pureWhite.withValues(alpha: 0.7)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.coralOrange),
              onPressed: () => notifier.removeOnboardingAccount(account.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddAccount(BuildContext context, OnboardingNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountFormDialog(
        onSave: (account, orders, plannings) {
          notifier.addOnboardingAccount(account);
          notifier.addOnboardingOrders(orders);
          notifier.addOnboardingPlannings(plannings);
        },
      ),
    );
  }
}
