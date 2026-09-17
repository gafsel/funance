import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail_sheet.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:go_router/go_router.dart';

typedef TransactionTableRowNotifier =
    InfiniteListNotifier<TransactionQuery, InstallmentModel>;

/// Uma linha da tabela de transações (modo desktop).
///
/// É o equivalente desktop do `TransactionListItem`, e é o trecho mais longo da
/// lista: sete colunas, cada uma com sua própria regra de cor, sinal e leitura
/// assíncrona de conta. Enquanto morava dentro da `TransactionListView`, essa
/// massa escondia o que a tela realmente faz — escolher entre tabela e cartões.
Widget buildTransactionTableRow(
  BuildContext context, {
  required TransactionTableRowNotifier notifier,
  required InstallmentModel installment,
  required CategoryModel? category,
  required String? accountId,
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
        context.push('/invoices/${installment.id}');
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

                  return Row(
                    spacing: 8,
                    children: [
                      if (source != null) ...[
                        AccountLogo(
                          account: source,
                          size: 30,
                          showMembers: true,
                        ),
                      ],
                      Text(
                        source?.name ?? "-",
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Icon(Icons.arrow_forward, size: 14),
                      if (target != null) ...[
                        AccountLogo(
                          account: target,
                          size: 30,
                          showMembers: true,
                        ),
                      ],
                      Expanded(
                        child: Text(
                          target?.name ?? "-",
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  spacing: 8,
                  children: [
                    if (source != null)
                      AccountLogo(
                        account: source,
                        size: 30,
                        showMembers: true,
                      ),
                    Expanded(
                      child: Text(
                        source?.name ?? "-",
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
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
