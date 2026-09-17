import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_elevation.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
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
  final palette = context.palette;
  final isExpense = installment.type == OrderType.expense;
  final isTransfer = installment.type == OrderType.transfer;

  Color amountColor;
  String amountPrefix;

  if (isTransfer) {
    if (accountId != null) {
      final isOutgoing = installment.accountIdSource == accountId;
      amountColor = isOutgoing ? palette.dangerText : palette.successText;
      amountPrefix = isOutgoing ? '-' : '+';
    } else {
      amountColor = theme.colorScheme.primary;
      amountPrefix = '';
    }
  } else if (isExpense) {
    amountColor = palette.dangerText;
    amountPrefix = '-';
  } else {
    amountColor = palette.successText;
    amountPrefix = '+';
  }

  // O selo é um preenchimento com ícone claro por cima; o rótulo ao lado é
  // texto sobre papel. Daí duas cores para o mesmo estado.
  final statusFill = switch (installment.status) {
    InstallmentStatus.settled => AppColors.violet,
    InstallmentStatus.paid => AppColors.success,
    _ => AppColors.goldDeep,
  };
  final statusInk = switch (installment.status) {
    InstallmentStatus.settled => AppColors.violet,
    InstallmentStatus.paid => palette.successText,
    _ => AppColors.goldDeep,
  };

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
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: AppElevation.hairline(palette.line)),
      ),
      child: Row(
        children: [
          // Data
          SizedBox(
            width: 90,
            child: Text(
              installment.referenceDate.formated(l10n.formatSimpleDate, locale),
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Ícone e Status
          SizedBox(width: 44, child: CategoryIcon.forInstallment(installment)),
          const SizedBox(width: AppSpacing.sm),
          // Descrição
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.description,
                  style: theme.textTheme.titleSmall,
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
                    spacing: AppSpacing.xs,
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
                  spacing: AppSpacing.xs,
                  children: [
                    if (source != null)
                      AccountLogo(account: source, size: 30, showMembers: true),
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
                  padding: AppSpacing.allXxs,
                  decoration: BoxDecoration(
                    color: statusFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    switch (installment.status) {
                      InstallmentStatus.settled => Icons.done_all,
                      InstallmentStatus.paid => Icons.check,
                      _ => Icons.schedule,
                    },
                    size: 12,
                    color: AppColors.inkInverse,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  switch (installment.status) {
                    InstallmentStatus.settled => l10n.statusSettled,
                    InstallmentStatus.paid => l10n.statusPaid,
                    _ => l10n.statusPending,
                  },
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusInk,
                  ),
                ),
              ],
            ),
          ),
          // Valor
          SizedBox(
            width: 120,
            child: MoneyText(
              amountPrefix == '-'
                  ? -installment.referenceAmount
                  : installment.referenceAmount,
              showSign: amountPrefix.isNotEmpty,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
            ),
          ),
        ],
      ),
    ),
  );
}
