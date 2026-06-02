import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groupedAccountsAsync = ref.watch(AccountViewProviders.byTypeMap);

    return groupedAccountsAsync.when(
      data: (groupedAccounts) {
        final types = AccountType.values.where((t) => groupedAccounts.containsKey(t)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeAccountsAndCards,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...types.map((type) => _buildExpandableType(context, ref, type, groupedAccounts[type] ?? [])),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildExpandableType(BuildContext context, WidgetRef ref, AccountType type, List<AccountModel> accounts) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;
    final total = ref.watch(AccountViewProviders.latestBalanceByType(type));

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.fromAccountType(type), style: theme.textTheme.bodyMedium),
        trailing: Text(
          total.asCurrency(locale: locale),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        children: accounts.map((account) => _buildAccountItem(context, ref, account)).toList(),
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, WidgetRef ref, AccountModel account) {
    final locale = context.locale;
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(AccountViewProviders.latestBalanceById(account.id));

    return balanceAsync.when(
      data: (balance) {
        final color = Color(int.parse(account.color.replaceAll('#', '0xFF')));
        return ListTile(
          onTap: () => context.push('/workspace/accounts?type=${account.type.name}'),
          contentPadding: const EdgeInsets.only(left: 16),
          leading: Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Text(account.name, style: theme.textTheme.bodySmall),
          trailing: Text(
            balance.balance.asCurrency(locale: locale),
            style: theme.textTheme.bodySmall,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
