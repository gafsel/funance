import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail_sheet.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
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
      child: Padding(
        padding:
            AppSpacing.hMd +
            const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
        child: Row(
          spacing: AppSpacing.xs,
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
                      color: _statusFill(installment.status),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(installment.status),
                      size: 10,
                      color: AppColors.inkInverse,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.gapMd,
                  Text(
                    installment.description,
                    style: theme.textTheme.titleMedium,
                  ),
                  Consumer(
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
                            if (source != null)
                              AccountLogo(
                                account: source,
                                size: 30,
                                showMembers: true,
                              ),
                            Text(
                              source?.name ?? '-',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.ink2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Icon(Icons.arrow_forward, size: 12),
                            if (target != null)
                              AccountLogo(
                                account: target,
                                size: 30,
                                showMembers: true,
                              ),
                            Expanded(
                              child: Text(
                                target?.name ?? '-',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: palette.ink2,
                                ),
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
                            AccountLogo(
                              account: source,
                              size: 30,
                              showMembers: true,
                            ),
                          Expanded(
                            child: Text(
                              source?.name ?? "-",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.ink2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  amountPrefix == '-'
                      ? -installment.referenceAmount
                      : installment.referenceAmount,
                  showSign: amountPrefix.isNotEmpty,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                  ),
                ),
                if (installment.installmentCount != null &&
                    installment.installmentCount! > 1)
                  Text(
                    l10n.installmentCountDescription(
                      installment.installmentCount!,
                      installment.installmentNumber!,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.ink2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// O selo de status é um preenchimento com ícone claro por cima — por isso
  /// aqui vale a cor cheia (`success`, `violet`, `goldDeep`) e não a tinta de
  /// texto da paleta.
  static Color _statusFill(InstallmentStatus status) => switch (status) {
    InstallmentStatus.settled => AppColors.violet,
    InstallmentStatus.paid => AppColors.success,
    _ => AppColors.goldDeep,
  };

  static IconData _statusIcon(InstallmentStatus status) => switch (status) {
    InstallmentStatus.settled => Icons.done_all,
    InstallmentStatus.paid => Icons.check,
    _ => Icons.schedule,
  };
}
