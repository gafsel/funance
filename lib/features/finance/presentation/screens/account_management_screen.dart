import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/account_model.dart';
import 'account_form_screen.dart';

class AccountManagementScreen extends ConsumerWidget {
  final AccountType? initialType;

  const AccountManagementScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsByTypeAsync = ref.watch(AccountViewProviders.byTypeMap);

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
      body: accountsByTypeAsync.when(
        data: (accountsByType) {
          if (accountsByType.isEmpty) {
            return Center(child: Text(l10n.accountManagementEmpty));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;

              final List<Widget> slivers = [];

              for (final entry in accountsByType.entries) {
                final typeAccounts = [...entry.value]..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

                if (typeAccounts.isEmpty) continue;

                // Header do tipo
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.fromAccountType(entry.key),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );

                if (crossAxisCount == 1) {
                  slivers.add(
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final account = typeAccounts[index];
                          return Column(
                            children: [
                              _buildAccountTile(context, ref, account),
                              if (index < typeAccounts.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        },
                        childCount: typeAccounts.length,
                      ),
                    ),
                  );
                } else {
                  slivers.add(
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 80,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAccountTile(
                            context,
                            ref,
                            typeAccounts[index],
                            isGrid: true,
                          ),
                          childCount: typeAccounts.length,
                        ),
                      ),
                    ),
                  );
                }
              }

              // Adiciona um padding extra no final
              slivers.add(
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16,
                  ),
                ),
              );

              return CustomScrollView(slivers: slivers);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    WidgetRef ref,
    AccountModel account, {
    bool isGrid = false,
  }) {
    final l10n = context.l10n;

    final tile = ListTile(
      contentPadding: isGrid
          ? const EdgeInsets.symmetric(horizontal: 12)
          : null,
      leading: CircleAvatar(
        backgroundColor: Color(
          int.parse(account.color.replaceAll('#', '0xFF')),
        ),
        child: Icon(_getIconData(account.icon), color: Colors.white, size: 20),
      ),
      title: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.fromAccountType(account.type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showAccountDialog(context, ref, account),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context, ref, account),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );

    if (isGrid) {
      return Card(
        margin: EdgeInsets.zero,
        child: Center(child: tile),
      );
    }
    return tile;
  }

  void _showAccountDialog(
    BuildContext context,
    WidgetRef ref, [
    AccountModel? account,
    AccountType? initialType,
  ]) {
    context.push('/accounts/form?id=${account?.id ?? ''}');
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) {
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
              ref.read(AccountDomainProviders.service).delete(account.id);
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
