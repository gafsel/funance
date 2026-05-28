import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_providers.dart';
import '../widgets/account_form_dialog.dart';

class AccountManagementScreen extends ConsumerWidget {
  final AccountType? initialType;
  const AccountManagementScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsProvider);

    // Se o initialType estiver presente e o diálogo ainda não tiver sido mostrado, 
    // podemos disparar a abertura do diálogo após o primeiro frame.
    if (initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccountDialog(context, ref, null, initialType);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) => accounts.isEmpty
            ? Center(child: Text(l10n.accountManagementEmpty))
            : ListView.separated(
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(account.color.replaceAll('#', '0xFF'))),
                      child: Icon(
                        _getIconData(account.icon),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(account.name),
                    subtitle: Text(_getAccountTypeName(context, account.type)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showAccountDialog(context, ref, account),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, account),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }

  String _getAccountTypeName(BuildContext context, AccountType type) {
    final l10n = AppLocalizations.of(context)!;
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

  void _showAccountDialog(BuildContext context, WidgetRef ref, [AccountModel? account, AccountType? initialType]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountFormDialog(account: account, initialType: initialType),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AccountModel account) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountDeleteTitle),
        content: Text(l10n.accountDeleteConfirm(account.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(accountNotifierProvider.notifier).deleteAccount(account.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    return _availableIcons[name] ?? Icons.account_balance;
  }

  static const Map<String, IconData> _availableIcons = {
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'account_balance_wallet': Icons.account_balance_wallet,
    'money': Icons.money,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,
    'payments': Icons.payments,
    'wallet': Icons.wallet,
    'show_chart': Icons.show_chart,
    'pie_chart': Icons.pie_chart,
    'monetization_on': Icons.monetization_on,
  };
}
