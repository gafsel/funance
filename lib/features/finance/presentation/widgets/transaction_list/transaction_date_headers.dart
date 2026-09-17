import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
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
  final theme = Theme.of(context);
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
        AppSpacing.hMd +
        const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateText,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (accountId != null) _Balance(accountId: accountId, date: date),
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
  final theme = Theme.of(context);
  final palette = context.palette;

  String dateText = DateFormat.yMMMM(
    Localizations.localeOf(context).toString(),
  ).format(date);
  // Capitalize first letter
  if (dateText.isNotEmpty) {
    dateText = dateText[0].toUpperCase() + dateText.substring(1);
  }

  return Container(
    padding: AppSpacing.vMd,
    color: palette.paper2,
    width: double.infinity,
    child: Padding(
      padding: AppSpacing.hMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (accountId != null) _Balance(accountId: accountId, date: date),
        ],
      ),
    ),
  );
}

/// O saldo da conta naquele ponto da lista. Era o mesmo bloco duas vezes,
/// palavra por palavra, nos dois separadores.
class _Balance extends ConsumerWidget {
  const _Balance({required this.accountId, required this.date});

  final String accountId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(
      AccountViewProviders.balanceAtDate((accountId: accountId, date: date)),
    );

    return balanceAsync.when(
      data: (balance) =>
          MoneyText(balance.balance, style: theme.textTheme.titleSmall),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
