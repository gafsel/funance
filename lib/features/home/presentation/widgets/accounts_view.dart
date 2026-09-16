import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/utils/string_util.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAccountsAsync = ref.watch(AccountViewProviders.byTypeMap);

    return groupedAccountsAsync.when(
      data: (groupedAccounts) {
        final types = AccountType.values
            .where((t) => groupedAccounts.containsKey(t))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...types.map(
              (type) => _buildExpandableType(
                context,
                ref,
                type,
                groupedAccounts[type] ?? [],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildExpandableType(
    BuildContext context,
    WidgetRef ref,
    AccountType type,
    List<AccountModel> accounts,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;

    double total = 0;
    final Map<String, double> totalsByMonth = {};

    if (type == AccountType.creditCard) {
      for (final account in accounts) {
        final nextInvoice = ref
            .watch(AccountViewProviders.nextInvoiceByAccountId(account.id))
            .value;
        if (nextInvoice != null) {
          total += nextInvoice.amount;
          final monthKey = nextInvoice.dueDate.formated('MMMM', locale);
          totalsByMonth[monthKey] =
              (totalsByMonth[monthKey] ?? 0) + nextInvoice.amount;
        }
      }
    } else {
      total = ref.watch(AccountViewProviders.latestBalanceByType(type));
    }

    final List<String> sortedMonthKeys = totalsByMonth.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM', locale).parse(a);
        final dateB = DateFormat('MMMM', locale).parse(b);
        return dateA.compareTo(dateB);
      });

    final showMonthlyTotal =
        type == AccountType.creditCard && totalsByMonth.length > 1;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.fromAccountType(type),
          style: theme.textTheme.bodyMedium,
        ),
        trailing: showMonthlyTotal
            ? Text(
                sortedMonthKeys
                    .map(
                      (month) =>
                          '${month.capitalize()}: ${totalsByMonth[month]!.asCurrency(locale: locale)}',
                    )
                    .join(" | "),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(
                total.asCurrency(locale: locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
        children: accounts
            .map((account) => _buildAccountItem(context, ref, account))
            .toList(),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) {
    final locale = context.locale;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(
      AccountViewProviders.latestBalanceById(account.id),
    );

    return balanceAsync.when(
      data: (balance) {
        final color = Color(int.parse(account.color.replaceAll('#', '0xFF')));

        if (account.type == AccountType.creditCard) {
          final creditCard = account as CreditCardAccount;
          final nextInvoiceAsync = ref.watch(
            AccountViewProviders.nextInvoiceByAccountId(account.id),
          );
          final usedLimit = -balance.balance;
          final availableLimit = (creditCard.limit - usedLimit).clamp(
            0.0,
            creditCard.limit,
          );
          final progress = creditCard.limit > 0
              ? (usedLimit / creditCard.limit).clamp(0.0, 1.0)
              : 0.0;

          return ListTile(
            onTap: () {
              final nextInvoice = nextInvoiceAsync.valueOrNull;
              if (nextInvoice != null) {
                context.push('/invoices/detail', extra: nextInvoice);
              } else {
                context.push('/workspace/accounts?type=${account.type.name}');
              }
            },
            contentPadding: const EdgeInsets.only(left: 16, right: 16),
            leading: AccountLogo(
              account: account,
              size: 32,
              showMembers: true,
            ),
            title: Text(account.name, style: theme.textTheme.bodySmall),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: color,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usedLimit.asCurrency(locale: locale),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    Text(
                      availableLimit.asCurrency(locale: locale),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: nextInvoiceAsync.when(
              data: (nextInvoice) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (nextInvoice?.amount ?? 0.0).asCurrency(locale: locale),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextInvoice != null)
                    Text(
                      nextInvoiceAsync.when(
                        data: (invoice) =>
                            invoice?.dueDate.formated(l10n.formatSimpleDate) ??
                            "-",
                        error: (_, _) => "",
                        loading: () => "",
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                ],
              ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          );
        }

        return ListTile(
          onTap: () {
            if (account.type == AccountType.creditCard) {
              context.push('/workspace/accounts?type=${account.type.name}');
            } else {
              context.push('/accounts/${account.id}/statement');
            }
          },
          contentPadding: const EdgeInsets.only(left: 16, right: 16),
          leading: AccountLogo(
            account: account,
            size: 32,
            showMembers: true,
          ),
          title: Text(account.name, style: theme.textTheme.bodySmall),
          trailing: Text(
            balance.balance.asCurrency(locale: locale),
            style: theme.textTheme.bodySmall,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
