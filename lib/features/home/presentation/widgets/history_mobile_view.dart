import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/history_period_summary.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryMobileView extends ConsumerWidget {
  final TransactionListNotifier historyNotifier;

  const HistoryMobileView({super.key, required this.historyNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return InfiniteListView.separator(
      FinanceViewProviders.history,
      padding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0) +
          EdgeInsets.only(bottom: mq.padding.bottom),
      footerBuilder: (context) => HistoryPeriodSummary(),
      separatorBuilder: (context, before, after) {
        final bool isSameGroup =
            before != null &&
            after != null &&
            _isSameDay(before.referenceDate, after.referenceDate);

        final showHeader = after != null && (before == null || !isSameGroup);

        if (showHeader) {
          return _buildDateHeader(context, after.referenceDate, l10n);
        }

        return const SizedBox.shrink();
      },
      itemBuilder: (context, item) {
        return _buildTransactionItem(
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
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(
    BuildContext context,
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
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required TransactionListNotifier notifier,
    required InstallmentModel installment,
    required CategoryModel? category,
  }) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final isExpense = installment.type == OrderType.expense;
    final isTransfer = installment.type == OrderType.transfer;

    Color amountColor;
    if (isTransfer) {
      amountColor = Theme.of(context).colorScheme.primary;
    } else if (isExpense) {
      amountColor = AppColors.error;
    } else {
      amountColor = AppColors.limeGreen;
    }

    String amountPrefix;
    if (isTransfer) {
      amountPrefix = '';
    } else {
      amountPrefix = isExpense ? '-' : '+';
    }

    return Consumer(
      builder: (context, ref, _) {
        String accountName;
        final source = installment.accountIdSource != null
            ? ref
                  .read(AccountViewProviders.byId(installment.accountIdSource!))
                  .whenOrNull(data: (data) => data)
            : null;

        if (isTransfer) {
          final target = installment.accountIdTarget != null
              ? ref
                    .read(
                      AccountViewProviders.byId(installment.accountIdTarget!),
                    )
                    .whenOrNull(data: (data) => data)
              : null;

          accountName = "${source?.name ?? '-'} ➡ ${target?.name ?? '-'}";
        } else {
          accountName = source?.name ?? "-";
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () async {
              final updated = await context.push<bool>(
                '/transactions/form',
                extra: {'installment': installment},
              );

              if (updated ?? false) {
                notifier.reset();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                spacing: 12,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isTransfer
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.3)
                              : (category?.color.asColor() ??
                                        AppColors.deepTurquoise)
                                    .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : category?.icon.asIcon() ?? Icons.category,
                          color: isTransfer
                              ? Theme.of(context).colorScheme.primary
                              : category?.color.asColor() ??
                                    AppColors.deepTurquoise,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color:
                                installment.status == InstallmentStatus.settled
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
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${isTransfer ? l10n.transactionActionTransfer : (category?.name ?? installment.category)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Icon(
                              Icons.circle,
                              size: 5,
                              color: Colors.grey.shade400,
                            ),
                            Text(accountName, style: theme.textTheme.bodySmall),
                            if (installment.installmentType ==
                                InstallmentType.installment)
                              Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.grey.shade400,
                              ),
                            if (installment.installmentType ==
                                InstallmentType.installment)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: const ShapeDecoration(
                                  shape: StadiumBorder(),
                                  color: AppColors.softGrey,
                                ),
                                child: Text(
                                  l10n.installmentCountDescription(
                                    installment.installmentCount ?? 1,
                                    installment.installmentNumber ?? 1,
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${amountPrefix.isNotEmpty ? '$amountPrefix ' : ''}${installment.referenceAmount.asCurrency(locale: locale)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
