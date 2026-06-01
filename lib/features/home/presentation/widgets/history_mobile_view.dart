import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
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
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: 0,
      ) + EdgeInsets.only(bottom: mq.padding.bottom),
      separatorBuilder: (context, before, after) {
        final bool isSameGroup = before != null &&
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
          child: Slidable(
            key: ValueKey(installment.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    context.push(
                      '/transactions/form',
                      extra: {'installment': installment},
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  icon: Icons.edit,
                  label: l10n.historyEdit,
                ),
                SlidableAction(
                  onPressed: (context) => _confirmDelete(context, notifier, installment),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  icon: Icons.delete,
                  label: l10n.historyDelete,
                ),
              ],
            ),
            child: InkWell(
              onTap: () {},
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
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                                : _parseColor(
                                    category?.color ?? '#14404C',
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTransfer ? Icons.swap_horiz : _getIconData(category?.icon ?? 'category'),
                            color: isTransfer
                                ? Theme.of(context).colorScheme.primary
                                : _parseColor(category?.color ?? '#14404C'),
                            size: 20,
                          ),
                        ),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
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
                              Text(
                                accountName,
                                style: theme.textTheme.bodySmall,
                              ),
                              if (installment.installmentType == InstallmentType.installment)
                                Icon(
                                  Icons.circle,
                                  size: 5,
                                  color: Colors.grey.shade400,
                                ),
                              if (installment.installmentType == InstallmentType.installment)
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
                        onPressed: () => Navigator.pop(context, ReplicationCascade.none),
                        child: Text(l10n.transactionDeleteCascadeOnlyThis),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, ReplicationCascade.future),
                        child: Text(l10n.transactionDeleteCascadeThisAndNext),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, ReplicationCascade.all),
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.deepTurquoise;
    }
  }

  IconData _getIconData(String iconName) {
    return _availableIcons[iconName] ?? Icons.category;
  }

  static const Map<String, IconData> _availableIcons = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'home': Icons.home,
    'commute': Icons.commute,
    'category': Icons.category,
    'work': Icons.work,
    'school': Icons.school,
    'medical_services': Icons.medical_services,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'shopping_bag': Icons.shopping_bag,
    'payments': Icons.payments,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    'pets': Icons.pets,
    'cleaning_services': Icons.cleaning_services,
    'build': Icons.build,
    'subscriptions': Icons.subscriptions,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'celebration': Icons.celebration,
  };
}
