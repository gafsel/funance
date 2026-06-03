import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AccountSelectionScreen extends ConsumerWidget {
  final String title;
  final String? excludeAccountId;
  final ValueChanged<AccountModel?> onAccountSelected;
  final bool showClearOption;

  const AccountSelectionScreen({
    super.key,
    required this.title,
    this.excludeAccountId,
    required this.onAccountSelected,
    this.showClearOption = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(AccountViewProviders.all);

    return accountsAsync.when(
      data: (accounts) {
        final filteredAccounts = accounts
            .where((acc) => acc.id != excludeAccountId)
            .toList();

        filteredAccounts.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (filteredAccounts.isEmpty && !showClearOption)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(child: Text(l10n.noAccountsFound)),
                )
              else
                Flexible(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final accountsByType =
                          ref.watch(AccountViewProviders.byTypeMap).value ?? {};

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 600
                              ? 2
                              : 1;

                          final List<Widget> slivers = [];

                          for (final entry in accountsByType.entries) {
                            final typeAccounts = entry.value
                                .where((acc) => acc.id != excludeAccountId)
                                .toList();
                            if (typeAccounts.isEmpty) continue;

                            typeAccounts.sort(
                              (a, b) => a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              ),
                            );

                            // Header do tipo
                            slivers.add(
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Text(
                                    _getAccountTypeName(entry.key, l10n),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            );

                            if (crossAxisCount == 1) {
                              slivers.add(
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _buildAccountCard(
                                          typeAccounts[index],
                                          l10n,
                                        ),
                                      ),
                                      childCount: typeAccounts.length,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              slivers.add(
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          mainAxisExtent: 80,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildAccountCard(
                                        typeAccounts[index],
                                        l10n,
                                      ),
                                      childCount: typeAccounts.length,
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          if (showClearOption) {
                            slivers.add(
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: _buildAddAccountOption(
                                          context,
                                          l10n,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: _buildClearOption(context, l10n),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            slivers.add(
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: _buildAddAccountOption(
                                          context,
                                          l10n,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // Adiciona um padding extra no final para evitar que o conteúdo fique colado na borda inferior
                          slivers.add(
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 16,
                              ),
                            ),
                          );

                          return CustomScrollView(
                            shrinkWrap: true,
                            slivers: slivers,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text(err.toString())),
      ),
    );
  }

  Widget _buildClearOption(BuildContext context, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(Icons.clear_all, color: Colors.grey),
        ),
        title: Text(l10n.clear),
        onTap: () => onAccountSelected(null),
      ),
    );
  }

  Widget _buildAddAccountOption(BuildContext context, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(Icons.add, color: Colors.grey),
        ),
        title: Text(l10n.accountCreateTitle),
        onTap: () {
          context.push('/accounts/form');
        },
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.color.asColor().withValues(alpha: 0.2),
          child: Icon(
            account.icon.asIcon(),
            color: account.color.asColor(),
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

}
