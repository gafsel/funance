import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(AccountViewProviders.all);
    final historyNotifier = ref.watch(FinanceViewProviders.history.notifier);
    final query = ref
        .watch(FinanceViewProviders.history)
        .map((state) => state.query);

    return Column(
      children: [
        // Topo: Filtros
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Seletor de Conta
              Expanded(
                child: accounts.when(
                  data: (accounts) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: query.accountId,
                          hint: Text(
                            l10n.homeAllAccounts,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                l10n.homeAllAccounts,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            ..._buildAccountItems(context, accounts),
                          ],
                          onChanged: (value) {
                            historyNotifier.reset(
                              query: query.copyWith(accountId: value),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 12),
              // Seletor de Período
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(
                        start:
                            query.startDate ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        end: query.endDate ?? DateTime.now(),
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return child!;
                      },
                    );

                    if (picked != null) {
                      historyNotifier.reset(
                        query: query.copyWith(
                          startDate: picked.start,
                          endDate: DateTime(
                            picked.end.year,
                            picked.end.month,
                            picked.end.day,
                            23,
                            59,
                            59,
                          ),
                        ),
                      );
                    } else {
                      // Se o usuário fechar ou cancelar, podemos oferecer uma forma de limpar?
                      // Para facilitar, se clicar e não escolher nada, não faz nada.
                      // Mas o usuário pediu "Todo o período". Vou adicionar um botão dedicado ou usar o null.
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      query.startDate == null
                          ? Icons.calendar_today
                          : Icons.calendar_month,
                      color: query.startDate == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (query.startDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    historyNotifier.reset(
                      query: query.copyWith(startDate: null, endDate: null),
                    );
                  },
                  icon: const Icon(Icons.close),
                  tooltip: l10n.clear, // Assumindo que existe, se não, "Limpar"
                ),
              ],
            ],
          ),
        ),
        if (query.startDate != null && query.endDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat.yMd().format(query.startDate!)} - ${DateFormat.yMd().format(query.endDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Lista de Transações
        Expanded(
          child: InfiniteListView.separator(
            FinanceViewProviders.history,
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 120),
            separatorBuilder: (context, before, after) {
              final showDateHeader = after != null &&
                  (before == null ||
                      !_isSameDay(before.referenceDate, after.referenceDate));

              if (showDateHeader) {
                return _buildDateHeader(context, after.referenceDate, l10n);
              }

              return SizedBox.shrink();
            },
            itemBuilder: (context, item) {
              final category = item.category;

              return _buildTransactionItem(
                context,
                notifier: historyNotifier,
                installment: item,
                category: category,
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

  List<DropdownMenuItem<String?>> _buildAccountItems(
    BuildContext context,
    List<AccountModel> accounts,
  ) {
    final grouped = <AccountType, List<AccountModel>>{};
    for (final acc in accounts) {
      grouped.putIfAbsent(acc.type, () => []).add(acc);
    }

    final items = <DropdownMenuItem<String?>>[];

    for (final type in AccountType.values) {
      final typeAccounts = grouped[type];
      if (typeAccounts == null || typeAccounts.isEmpty) continue;

      // Header do grupo
      items.add(
        DropdownMenuItem<String?>(
          enabled: false,
          value: 'header_${type.name}',
          child: Text(
            type.name.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      for (final acc in typeAccounts) {
        items.add(
          DropdownMenuItem<String?>(
            value: acc.id,
            child: Row(
              children: [
                Icon(
                  _getIconData(acc.icon),
                  size: 16,
                  color: Color(int.parse(acc.color.replaceAll('#', '0xFF'))),
                ),
                const SizedBox(width: 8),
                Text(
                  acc.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }

  AccountModel _unknownAccount() {
    return AccountModel.checking(
      id: '',
      name: '?',
      color: '#808080',
      icon: 'help',
      initialBalanceDate: DateTime.now(),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                  onPressed: (context) =>
                      _confirmDelete(context, notifier, installment),
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
                                : _parseColor(
                                    category?.color ?? '#14404C',
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTransfer
                                ? Icons.swap_horiz
                                : _getIconData(category?.icon ?? 'category'),
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
                              color:
                                  installment.status ==
                                      InstallmentStatus.settled
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
                    const SizedBox(width: 12),
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
                            '${isTransfer ? l10n.transactionActionTransfer : (category?.name ?? installment.category)} • $accountName',
                            style: theme.textTheme.bodySmall,
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

              await loading(
                notifier.delete(
                  installment.id,
                  replicationCascade: ReplicationCascade.none,
                ),
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
