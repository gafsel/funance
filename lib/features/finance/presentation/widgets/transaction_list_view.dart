import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list/transaction_date_headers.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list/transaction_table_header.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list/transaction_table_row.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_item.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/widgets/empty_state.dart';

typedef TransactionListViewNotifier =
    InfiniteListNotifier<TransactionQuery, InstallmentModel>;

/// Todas as listas de transações são `autoDispose`; as que precisam manter
/// cache entre navegações chamam `ref.keepAlive()` explicitamente.
typedef TransactionListViewProvider =
    AutoDisposeStateNotifierProvider<
      TransactionListViewNotifier,
      InfiniteListState<TransactionQuery, InstallmentModel>
    >;

class TransactionListView extends ConsumerWidget {
  final TransactionListViewProvider provider;
  final WidgetBuilder? footerBuilder;
  final String? accountId;

  const TransactionListView({
    super.key,
    required this.provider,
    this.footerBuilder,
    this.accountId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A escolha entre TABELA e cartões é sobre o espaço que esta lista tem,
    // não sobre o tamanho da janela. Com o `NavigationRail` estendido (200px),
    // uma janela de 1000px dizia "desktop" enquanto o painel real tinha ~800:
    // a tabela renderizava num espaço que não a comporta. Todo o resto do app
    // já decide por `LayoutBuilder`; esta tela era a exceção.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth > 900
          ? _table(context, ref)
          : _cards(context, ref),
    );
  }

  Widget _table(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final historyNotifier = ref.read(provider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: buildTransactionTableHeader(context, l10n),
        ),
        Expanded(
          child: InfiniteListView.separator(
            provider,
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0) +
                EdgeInsets.only(bottom: mq.padding.bottom),
            footerBuilder: footerBuilder,
            separatorBuilder: (context, before, after) {
              final bool isSameGroup =
                  before != null &&
                  after != null &&
                  before.referenceDate.year == after.referenceDate.year &&
                  before.referenceDate.month == after.referenceDate.month;

              final showHeader =
                  after != null && (before == null || !isSameGroup);

              if (showHeader) {
                return buildTransactionDesktopDateHeader(
                  context,
                  ref,
                  after.referenceDate,
                  l10n,
                  accountId: accountId,
                );
              }

              return const SizedBox.shrink();
            },
            itemBuilder: (context, item) {
              return buildTransactionTableRow(
                context,
                notifier: historyNotifier,
                installment: item,
                category: item.category,
                accountId: accountId,
              );
            },
            emptyStateBuilder: (context) => EmptyState.message(
              l10n.noTransactionsInPeriod,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cards(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final historyNotifier = ref.read(provider.notifier);

    return InfiniteListView.separator(
      provider,
      padding: EdgeInsets.only(bottom: mq.padding.bottom),
      footerBuilder: footerBuilder,
      separatorBuilder: (context, before, after) {
        final bool isSameGroup =
            before != null &&
            after != null &&
            _isSameDay(before.referenceDate, after.referenceDate);

        final showHeader = after != null && (before == null || !isSameGroup);

        if (showHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (before != null) const Divider(height: 1),
              buildTransactionDateHeader(
                context,
                ref,
                after.referenceDate,
                l10n,
                accountId: accountId,
              ),
            ],
          );
        }

        return SizedBox.shrink();
      },
      itemBuilder: (context, item) {
        return TransactionListItem(
          notifier: historyNotifier,
          installment: item,
          accountId: accountId,
        );
      },
      // Mesma frase, mesmo estilo: o padding maior é o único resto da
      // divergência que existia entre os dois vazios desta tela.
      emptyStateBuilder: (context) => EmptyState.message(
        l10n.noTransactionsInPeriod,
        padding: const EdgeInsets.all(32.0),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
