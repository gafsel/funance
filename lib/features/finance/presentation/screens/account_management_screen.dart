import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/account_model.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/presentation/display_names.dart';

class AccountManagementScreen extends ConsumerWidget {
  final AccountType? initialType;

  const AccountManagementScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsByTypeAsync = ref.watch(AccountViewProviders.byTypeMap);

    // `initialType` FILTRA a lista; não abre formulário nenhum. Quem chega
    // aqui por `/workspace/accounts?type=creditCard` — a lista de contas da
    // home, tocando num cartão sem fatura — quer VER os cartões. Abrir a
    // criação por cima disso era responder outra pergunta.
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            // O "+" herda o tipo que a tela está mostrando: com a lista
            // filtrada em cartões, a conta nova já nasce cartão.
            onPressed: () => _showAccountDialog(context, ref, null, initialType),
          ),
        ],
      ),
      body: accountsByTypeAsync.when(
        data: (todosOsTipos) {
          final accountsByType = initialType == null
              ? todosOsTipos
              : {
                  for (final entry in todosOsTipos.entries)
                    if (entry.key == initialType) entry.key: entry.value,
                };

          if (accountsByType.isEmpty) {
            // Filtrada por tipo, "você ainda não tem contas" seria falso: o
            // usuário pode ter cinco contas correntes e nenhum cartão.
            return Center(
              child: Text(
                initialType == null
                    ? l10n.accountManagementEmpty
                    : l10n.accountManagementEmptyOfType,
              ),
            );
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
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView.forError(
              context,
              err,
              onRetry: () => Retry.accounts(ref),
            ),
          ),
        ),
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
      onTap: () {
        if (account.type != AccountType.creditCard) {
          context.push('/accounts/${account.id}/statement');
        } else {
          _showAccountDialog(context, ref, account);
        }
      },
      contentPadding: isGrid ? const EdgeInsets.symmetric(horizontal: 12) : null,
      leading: AccountLogo(account: account, size: 40, showMembers: true),
      title: Text(
        account.displayName(l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
            onPressed: () => context.push('/accounts/form?id=${account.id}'),
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
    // Sem conta é CRIAÇÃO: nada de `?id=` vazio, que a rota lia como o id ''
    // e respondia "este item não existe mais" em cima do formulário novo. O
    // tipo sugerido vai pela query, que é o que sobrevive a um refresh.
    if (account != null) {
      context.push('/accounts/form?id=${account.id}');
      return;
    }

    context.push(
      Uri(
        path: '/accounts/form',
        queryParameters: {
          if (initialType != null) 'type': initialType.name,
        },
      ).toString(),
    );
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
        content: Text(l10n.accountDeleteConfirm(account.displayName(l10n))),
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

}
