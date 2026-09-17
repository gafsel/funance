import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Separadores de data da lista de transações — um por modo de exibição.
///
/// São dois porque os modos agrupam em granularidades diferentes: os cartões
/// quebram por DIA (e ganham "hoje"/"ontem"), a tabela quebra por MÊS. O que
/// eles têm em comum é o saldo da conta naquele ponto, que só aparece quando a
/// lista está filtrada por uma conta — daí o `accountId` opcional nos dois.
Widget buildTransactionDateHeader(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
  AppLocalizations l10n, {
  required String? accountId,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.addCalendarDays(-1);
  final checkDate = DateTime(date.year, date.month, date.day);

  String dateText;
  if (checkDate == today) {
    dateText = l10n.today;
  } else if (checkDate == yesterday) {
    dateText = l10n.yesterday;
  } else {
    dateText = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  return Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 16) +
        EdgeInsets.only(top: 16, bottom: 8),
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (accountId != null)
          Consumer(
            builder: (context, ref, _) {
              final balanceAsync = ref.watch(
                AccountViewProviders.balanceAtDate((
                  accountId: accountId,
                  date: date,
                )),
              );
              return balanceAsync.when(
                data: (balance) => Text(
                  balance.balance.asCurrency(locale: context.locale),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
      ],
    ),
  );
}

Widget buildTransactionDesktopDateHeader(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
  AppLocalizations l10n, {
  required String? accountId,
}) {
  String dateText = DateFormat.yMMMM(
    Localizations.localeOf(context).toString(),
  ).format(date);
  // Capitalize first letter
  if (dateText.isNotEmpty) {
    dateText = dateText[0].toUpperCase() + dateText.substring(1);
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (accountId != null)
            Consumer(
              builder: (context, ref, _) {
                final balanceAsync = ref.watch(
                  AccountViewProviders.balanceAtDate((
                    accountId: accountId,
                    date: date,
                  )),
                );
                return balanceAsync.when(
                  data: (balance) => Text(
                    balance.balance.asCurrency(locale: context.locale),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
    ),
  );
}
