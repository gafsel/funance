import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
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

class HistoryDesktopView extends ConsumerWidget {
  final TransactionListNotifier historyNotifier;

  const HistoryDesktopView({super.key, required this.historyNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: _buildTableHeader(context, l10n),
        ),
        // Lista de Transações
        Expanded(
          child: InfiniteListView.separator(
            FinanceViewProviders.history,
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0) +
                EdgeInsets.only(bottom: mq.padding.bottom),
            footerBuilder: (context) => HistoryPeriodSummary(),
            separatorBuilder: (context, before, after) {
              final bool isSameGroup =
                  before != null &&
                  after != null &&
                  before.referenceDate.year == after.referenceDate.year &&
                  before.referenceDate.month == after.referenceDate.month;

              final showHeader =
                  after != null && (before == null || !isSameGroup);

              if (showHeader) {
                return _buildDateHeader(context, after.referenceDate, l10n);
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

  Widget _buildDateHeader(
    BuildContext context,
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
        child: Text(
          dateText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTransactionTableItem(
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

        return InkWell(
          onTap: () async {
            final updated = await context.push<bool>(
              '/transactions/form',
              extra: {'installment': installment},
            );

            if (updated ?? false) {
              notifier.reset();
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isTransfer
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.3)
                              : (category?.color.asColor() ??
                                        AppColors.deepTurquoise)
                                    .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : category?.icon.asIcon() ?? Icons.category,
                          color: isTransfer
                              ? Theme.of(context).colorScheme.primary
                              : category?.color.asColor() ??
                                    AppColors.deepTurquoise,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
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
                  child:
                      installment.installmentType == InstallmentType.installment
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
                  child: Text(accountName, style: theme.textTheme.bodyMedium),
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
                // Ações
                SizedBox(
                  width: 40,
                  child: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () {
                          context.push(
                            '/transactions/form',
                            extra: {'installment': installment},
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.historyEdit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          // Precisamos de um pequeno delay para o menu fechar antes do dialog abrir
                          Future.delayed(
                            const Duration(milliseconds: 0),
                            () =>
                                _confirmDelete(context, notifier, installment),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.historyDelete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionListNotifier notifier,
    InstallmentModel installment,
  ) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          LoadingButton.text(
            onPressed: (loading) async {
              final navigator = Navigator.of(context);
              ReplicationCascade cascade = ReplicationCascade.none;

              if (installment.installmentType != InstallmentType.single) {
                final selectedCascade = await showDialog<ReplicationCascade>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.transactionDeleteCascadeTitle),
                    content: Text(l10n.transactionDeleteCascadeDescription),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, ReplicationCascade.none),
                        child: Text(l10n.transactionDeleteCascadeOnlyThis),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, ReplicationCascade.future),
                        child: Text(l10n.transactionDeleteCascadeThisAndNext),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, ReplicationCascade.all),
                        child: Text(l10n.transactionDeleteCascadeAll),
                      ),
                    ],
                  ),
                );

                if (selectedCascade == null) return;
                cascade = selectedCascade;
              }

              await loading(
                notifier.delete(installment.id, replicationCascade: cascade),
              );

              navigator.pop();
            },
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
