import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail/detail_item.dart';

/// Bloco de conta(s) do detalhe de transação.
///
/// Transferência tem duas contas e uma seta entre elas; todo o resto tem uma
/// só. Os dois casos dependem de leituras assíncronas por id, e o encadeamento
/// de `when` que isso exige era metade do `build` do sheet. Isolar aqui deixa o
/// sheet descrevendo a ordem das seções, não a resolução das contas.
class TransactionDetailAccounts extends StatelessWidget {
  final InstallmentModel installment;

  const TransactionDetailAccounts({super.key, required this.installment});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isTransfer = installment.type == OrderType.transfer;

    return Consumer(
      builder: (context, ref, _) {
        final sourceId = installment.accountIdSource;
        final targetId = installment.accountIdTarget;

        if (isTransfer && sourceId != null && targetId != null) {
          final sourceAccount = ref.watch(
            AccountViewProviders.byId(sourceId),
          );
          final targetAccount = ref.watch(
            AccountViewProviders.byId(targetId),
          );

          return sourceAccount.when(
            data: (source) => targetAccount.when(
              data: (target) => DetailItem(
                label: l10n.transactionAccountLabel,
                value: '',
                customValue: Row(
                  spacing: 8,
                  children: [
                    Row(
                      children: [
                        if (source != null) ...[
                          AccountLogo(
                            account: source,
                            size: 30,
                            showMembers: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            source.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else
                          Text(
                            '-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.antiqueGold,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (target != null) ...[
                            AccountLogo(
                              account: target,
                              size: 30,
                              showMembers: true,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else
                            Text(
                              '-',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
                icon: Icons.swap_horiz,
                iconColor: AppColors.antiqueGold,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        }

        return Column(
          children: [
            if (sourceId != null)
              ref
                  .watch(AccountViewProviders.byId(sourceId))
                  .when(
                    data: (account) => DetailItem(
                      label: l10n.transactionAccountLabel,
                      value: account?.name ?? '-',
                      customValue: account != null
                          ? Row(
                              children: [
                                AccountLogo(
                                  account: account,
                                  size: 30,
                                  showMembers: true,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  account.name,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            )
                          : null,
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppColors.antiqueGold,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
          ],
        );
      },
    );
  }
}
