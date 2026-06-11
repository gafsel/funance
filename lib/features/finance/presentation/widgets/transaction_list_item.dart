import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:go_router/go_router.dart';

class TransactionListItem extends ConsumerWidget {
  final InstallmentModel installment;
  final CategoryModel? category;
  final TransactionListNotifier notifier;

  const TransactionListItem({
    super.key,
    required this.installment,
    this.category,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    String accountName;
    final source = installment.accountIdSource != null
        ? ref
              .watch(AccountViewProviders.byId(installment.accountIdSource!))
              .whenOrNull(data: (data) => data)
        : null;

    if (isTransfer) {
      final target = installment.accountIdTarget != null
          ? ref
                .watch(AccountViewProviders.byId(installment.accountIdTarget!))
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
                    Text(
                      accountName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
