import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';
import 'package:funances/l10n/app_localizations.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedAccountType = ref.watch(AccountViewProviders.overviewType);
    final groupedAccounts =
        ref.watch(AccountViewProviders.byTypeMap).value ??
        {selectedAccountType: []};

    final types = AccountType.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptions(types, selectedAccountType, groupedAccounts, l10n, ref),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
            (groupedAccounts[selectedAccountType]?.length ?? 0) + 2,
            itemBuilder: (context, index) {
              int currentIdx = 0;
              final accounts =
                  groupedAccounts[selectedAccountType] ?? [];
              final typeCount = accounts.length + 2;

              if (index >= currentIdx &&
                  index < currentIdx + typeCount) {
                final innerIndex = index - currentIdx;
                if (innerIndex == 0) {
                  if (accounts.length > 1) {
                    return _buildGroupTotalCard(
                      context,
                      selectedAccountType,
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }
                if (innerIndex == accounts.length + 1) {
                  return _buildAddAccountCard(
                    context,
                    selectedAccountType,
                  );
                }
                final account = accounts[innerIndex - 1];
                return _buildAccountItem(context, account);
              }
              currentIdx += typeCount;
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  SingleChildScrollView _buildOptions(List<AccountType> types, AccountType selectedAccountType, Map<AccountType, List<AccountModel>> groupedAccounts, AppLocalizations l10n, WidgetRef ref) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: types.map((type) {
            final isSelected = selectedAccountType == type;
            final count = groupedAccounts[type]?.length ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.fromAccountType(type)),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($count)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.deepTurquoise
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(
                    AccountViewProviders.overviewType.notifier,
                  )
                      .state =
                      type;
                },
                selectedColor: AppColors.vibrantTeal.withValues(
                  alpha: 0.2,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.deepTurquoise
                      : Colors.grey,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      );
  }

  Widget _buildAddAccountCard(BuildContext context, AccountType type) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountManagementScreen(initialType: type),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.vibrantTeal.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.vibrantTeal,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.accountCreateTypeAction(l10n.fromAccountType(type)),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.deepTurquoise,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTotalCard(BuildContext context, AccountType type) {
    final locale = context.locale;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Consumer(
      builder: (context, ref, _) {
        final total = ref.watch(AccountViewProviders.latestBalanceByType(type));

        return Container(
          width: 180,
          margin: const EdgeInsets.only(right: 12),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.backgroundGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.homeTotalBalance,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.paleGold,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total.asCurrency(locale: locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditCard(
    BuildContext context, {
    required String name,
    required String invoice,
    required double limitPercent,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodySmall),
              Text(
                invoice,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.coralOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: limitPercent,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: AppColors.coralOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, AccountModel account) {
    final locale = context.locale;
    return Consumer(
      builder: (context, ref, _) {
        final balanceAsync = ref.watch(
          AccountViewProviders.latestBalanceById(account.id),
        );

        return balanceAsync.when(
          data: (balance) {
            final currentBalance = balance.balance;
            final color = Color(
              int.parse(account.color.replaceAll('#', '0xFF')),
            );
            final icon = Icons.eighteen_mp;

            if (account.type == AccountType.creditCard) {
              final limit = account is CreditCardAccount
                  ? (account.limit ?? 0.0)
                  : 0.0;
              final usedPercent = limit > 0
                  ? (currentBalance.abs() / limit).clamp(0.0, 1.0)
                  : 0.0;

              return _buildCreditCard(
                context,
                name: account.name,
                invoice: currentBalance.abs().asCurrency(locale: locale),
                limitPercent: usedPercent,
                icon: icon,
                color: color,
              );
            }

            return _buildAccountCard(
              context,
              name: account.name,
              balance: currentBalance.asCurrency(locale: locale),
              icon: icon,
              color: color,
            );
          },
          loading: () => const SizedBox(
            width: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        );
      },
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String name,
    required String balance,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white70),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                balance,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
