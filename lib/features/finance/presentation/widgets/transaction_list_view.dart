import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail_sheet.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_item.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

typedef TransactionListViewNotifier =
    InfiniteListNotifier<TransactionQuery, InstallmentModel>;

typedef TransactionListViewProvider =
    StateNotifierProvider<
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
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final isDesktop = mq.size.width > 900;
    final historyNotifier = ref.read(provider.notifier);

    if (isDesktop) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: _buildTableHeader(context, l10n),
          ),
          Expanded(
            child: InfiniteListView.separator(
              provider,
              padding:
                  const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    top: 0,
                  ) +
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
                  return _buildDesktopDateHeader(
                    context,
                    ref,
                    after.referenceDate,
                    l10n,
                  );
                }

                return const SizedBox.shrink();
              },
              itemBuilder: (context, item) {
                return _buildTransactionTableItem(
                  context,
                  notifier: historyNotifier,
                  installment: item,
                  category: item.category,
                );
              },
              emptyStateBuilder: (context) => Center(
                child: Text(
                  l10n.noTransactionsInPeriod,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InfiniteListView.separator(
      provider,
      padding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0) +
          EdgeInsets.only(bottom: mq.padding.bottom),
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
              _buildDateHeader(context, ref, after.referenceDate, l10n),
            ],
          );
        }

        return const Divider(height: 1);
      },
      itemBuilder: (context, item) {
        return TransactionListItem(
          notifier: historyNotifier,
          installment: item,
          accountId: accountId,
        );
      },
      emptyStateBuilder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            l10n.noTransactionsInPeriod,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
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
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                    accountId: accountId!,
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
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopDateHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    AppLocalizations l10n,
  ) {
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
                      accountId: accountId!,
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
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(l10n.date, style: textStyle)),
          const SizedBox(width: 12),
          SizedBox(width: 44, child: Text('', style: textStyle)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(l10n.historyFilterDescriptionLabel, style: textStyle),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.transactionInstallmentsLabel, style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.historyAccountLabel, style: textStyle),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.historyFilterStatusLabel, style: textStyle),
          ),
          SizedBox(
            width: 120,
            child: Text(
              l10n.transactionAmountLabel,
              style: textStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTableItem(
    BuildContext context, {
    required TransactionListViewNotifier notifier,
    required InstallmentModel installment,
    required CategoryModel? category,
  }) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final isExpense = installment.type == OrderType.expense;
    final isTransfer = installment.type == OrderType.transfer;

    Color amountColor;
    String amountPrefix;

    if (isTransfer) {
      if (accountId != null) {
        final isOutgoing = installment.accountIdSource == accountId;
        amountColor = isOutgoing ? AppColors.error : AppColors.limeGreen;
        amountPrefix = isOutgoing ? '-' : '+';
      } else {
        amountColor = Theme.of(context).colorScheme.primary;
        amountPrefix = '';
      }
    } else if (isExpense) {
      amountColor = AppColors.error;
      amountPrefix = '-';
    } else {
      amountColor = AppColors.limeGreen;
      amountPrefix = '+';
    }

    return InkWell(
      onTap: () {
        if (installment.isInvoice) {
          context.push('/invoices/detail', extra: installment);
        } else {
          TransactionDetailSheet.show(
            context,
            installment,
            onUpdated: () => notifier.reset(),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            // Data
            SizedBox(
              width: 90,
              child: Text(
                installment.referenceDate.formated(
                  l10n.formatSimpleDate,
                  locale,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ícone e Status
            SizedBox(
              width: 44,
              child: CategoryIcon.forInstallment(installment),
            ),
            const SizedBox(width: 12),
            // Descrição
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isTransfer ? l10n.transactionActionTransfer : (category?.name ?? installment.category)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Parcelas
            Expanded(
              flex: 1,
              child: installment.installmentType == InstallmentType.installment
                  ? Text(
                      l10n.installmentCountDescription(
                        installment.installmentCount ?? 1,
                        installment.installmentNumber ?? 1,
                      ),
                      style: theme.textTheme.bodySmall,
                    )
                  : const Text('-'),
            ),
            // Conta
            Expanded(
              flex: 2,
              child: Consumer(
                builder: (context, ref, _) {
                  String accountName;
                  final source = installment.accountIdSource != null
                      ? ref
                            .watch(
                              AccountViewProviders.byId(
                                installment.accountIdSource!,
                              ),
                            )
                            .whenOrNull(data: (data) => data)
                      : null;

                  if (isTransfer) {
                    final target = installment.accountIdTarget != null
                        ? ref
                              .watch(
                                AccountViewProviders.byId(
                                  installment.accountIdTarget!,
                                ),
                              )
                              .whenOrNull(data: (data) => data)
                        : null;

                    accountName =
                        "${source?.name ?? '-'} ➡ ${target?.name ?? '-'}";
                  } else {
                    accountName = source?.name ?? "-";
                  }

                  return Text(accountName, style: theme.textTheme.bodyMedium);
                },
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: installment.status == InstallmentStatus.settled
                          ? AppColors.deepPurple
                          : installment.status == InstallmentStatus.paid
                          ? AppColors.limeGreen
                          : AppColors.antiqueGold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      installment.status == InstallmentStatus.settled
                          ? Icons.done_all
                          : installment.status == InstallmentStatus.paid
                          ? Icons.check
                          : Icons.schedule,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    installment.status == InstallmentStatus.settled
                        ? l10n.statusSettled
                        : installment.status == InstallmentStatus.paid
                        ? l10n.statusPaid
                        : l10n.statusPending,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: installment.status == InstallmentStatus.settled
                          ? AppColors.deepPurple
                          : installment.status == InstallmentStatus.paid
                          ? AppColors.limeGreen
                          : AppColors.antiqueGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Valor
            SizedBox(
              width: 120,
              child: Text(
                '${amountPrefix.isNotEmpty ? '$amountPrefix ' : ''}${installment.referenceAmount.asCurrency(locale: locale)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
