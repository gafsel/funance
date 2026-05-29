import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class AccountSelectionScreen extends ConsumerWidget {
  final String title;
  final String? excludeAccountId;
  final ValueChanged<AccountModel> onAccountSelected;

  const AccountSelectionScreen({
    super.key,
    required this.title,
    this.excludeAccountId,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(AccountViewProviders.all);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: accountsAsync.when(
        data: (accounts) {
          final filteredAccounts = accounts
              .where((acc) => acc.id != excludeAccountId)
              .toList();

          filteredAccounts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          if (filteredAccounts.isEmpty) {
            return Center(child: Text(l10n.noAccountsFound));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;

              if (crossAxisCount == 1) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAccounts.length,
                  itemBuilder: (context, index) {
                    final account = filteredAccounts[index];
                    return _buildAccountCard(account, l10n);
                  },
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 100,
                ),
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return _buildAccountCard(account, l10n);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(
            int.parse(account.color.replaceFirst('#', '0xFF')),
          ).withValues(alpha: 0.2),
          child: Icon(
            _getIconData(account.icon),
            color: Color(int.parse(account.color.replaceFirst('#', '0xFF'))),
          ),
        ),
        title: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _getAccountTypeName(account.type, l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => onAccountSelected(account),
      ),
    );
  }

  String _getAccountTypeName(AccountType type, AppLocalizations l10n) {
    switch (type) {
      case AccountType.checking:
        return l10n.accountTypeChecking;
      case AccountType.investment:
        return l10n.accountTypeInvestment;
      case AccountType.creditCard:
        return l10n.accountTypeCreditCard;
      case AccountType.debt:
        return l10n.accountTypeDebt;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'payments':
        return Icons.payments;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance;
    }
  }
}
