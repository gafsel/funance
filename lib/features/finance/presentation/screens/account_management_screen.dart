import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_providers.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: account?.name);
    final initialBalanceController = TextEditingController(text: account?.initialBalance.toString() ?? '0');
    
    // Additional fields
    final limitController = TextEditingController(text: account?.metadata['limit']?.toString());
    final dueDayController = TextEditingController(text: account?.metadata['dueDay']?.toString());
    final closingDayController = TextEditingController(text: account?.metadata['closingDay']?.toString());
    final interestRateController = TextEditingController(text: account?.metadata['interestRate']?.toString());

    AccountType selectedType = account?.type ?? initialType ?? AccountType.checking;
    String selectedColor = account?.color ?? '#4A8C9C';
    String selectedIcon = account?.icon ?? 'account_balance';
    DateTime initialBalanceDate = account?.initialBalanceDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(account == null ? l10n.accountCreateTitle : l10n.accountEditTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.accountNameLabel),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: initialBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.initialBalanceLabel,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.initialBalanceDateLabel),
                  subtitle: Text(DateFormat.yMd(Localizations.localeOf(context).languageCode).format(initialBalanceDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialBalanceDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => initialBalanceDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AccountType>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: l10n.accountTypeLabel),
                  items: AccountType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getAccountTypeName(context, type)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                if (selectedType == AccountType.creditCard) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: limitController,
                    decoration: InputDecoration(labelText: l10n.accountLimitLabel),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dueDayController,
                          decoration: InputDecoration(labelText: l10n.accountDueDayLabel),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: closingDayController,
                          decoration: InputDecoration(labelText: l10n.accountClosingDayLabel),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                if (selectedType == AccountType.investment || selectedType == AccountType.debt) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: interestRateController,
                    decoration: InputDecoration(labelText: l10n.accountInterestRateLabel),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                const SizedBox(height: 24),
                Text(l10n.accountColorLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.categoryColors.map((color) {
                    final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = colorHex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(l10n.accountIconLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableIcons.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
                        ),
                        child: Icon(entry.value, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final metadata = Map<String, dynamic>.from(account?.metadata ?? {});
                  
                  if (selectedType == AccountType.creditCard) {
                    metadata['limit'] = double.tryParse(limitController.text) ?? 0.0;
                    metadata['dueDay'] = int.tryParse(dueDayController.text) ?? 1;
                    metadata['closingDay'] = int.tryParse(closingDayController.text) ?? 1;
                  } else if (selectedType == AccountType.investment || selectedType == AccountType.debt) {
                    metadata['interestRate'] = double.tryParse(interestRateController.text) ?? 0.0;
                  }

                  final newAccount = AccountModel(
                    id: account?.id ?? '',
                    name: nameController.text,
                    type: selectedType,
                    color: selectedColor,
                    icon: selectedIcon,
                    metadata: metadata,
                    initialBalance: double.tryParse(initialBalanceController.text) ?? 0.0,
                    initialBalanceDate: initialBalanceDate,
                  );

                  if (account == null) {
                    ref.read(accountNotifierProvider.notifier).createAccount(newAccount);
                  } else {
                    ref.read(accountNotifierProvider.notifier).updateAccount(newAccount);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
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
