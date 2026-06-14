import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail_sheet.dart';
import 'package:go_router/go_router.dart';

typedef TransactionListItemNotifier =
    InfiniteListNotifier<TransactionQuery, InstallmentModel>;

class TransactionListItem extends StatelessWidget {
  final InstallmentModel installment;
  final TransactionListItemNotifier notifier;
  final String? accountId;

  const TransactionListItem({
    super.key,
    required this.installment,
    required this.notifier,
    this.accountId,
  });

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            spacing: 12,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CategoryIcon.forInstallment(installment),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
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
                    if (installment.category != null)
                      Text(
                        installment.category!.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Consumer(
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

                        return Text(
                          accountName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$amountPrefix${installment.referenceAmount.asCurrency(locale: locale)}",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (installment.installmentCount != null &&
                      installment.installmentCount! > 1)
                    Text(
                      "${installment.installmentNumber}/${installment.installmentCount}",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
