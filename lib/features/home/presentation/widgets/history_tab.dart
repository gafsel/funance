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
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'history_filter_bottom_sheet.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyNotifier = ref.watch(FinanceViewProviders.history.notifier);
    final query = ref
        .watch(FinanceViewProviders.history)
        .map((state) => state.query);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return Column(
          children: [
            // Topo: Filtros
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Seletor de Conta
                  Expanded(
                    child: AccountFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.wallet),
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        labelText: l10n.accountNameLabel,
                      ),
                      onChanged: (value) {
                        historyNotifier.reset(
                          query: query.copyWith(accountId: value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botão de Filtro Avançado
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => HistoryFilterBottomSheet(
                            initialQuery: query,
                            onApply: (newQuery) {
                              historyNotifier.reset(query: newQuery);
                            },
                          ),
                        );
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
                          _hasAdvancedFilters(query)
                              ? Icons.filter_alt
                              : Icons.filter_alt_outlined,
                          color: _hasAdvancedFilters(query)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                                DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
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
                      tooltip:
                          l10n.clear, // Assumindo que existe, se não, "Limpar"
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
            if (isLargeScreen)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: _buildTableHeader(context, l10n),
              ),
            // Lista de Transações
            Expanded(
              child: InfiniteListView.separator(
                FinanceViewProviders.history,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 120,
                  top: isLargeScreen ? 0 : 0,
                ),
                separatorBuilder: (context, before, after) {
                  final bool isSameGroup;
                  if (isLargeScreen) {
                    isSameGroup =
                        before != null &&
                        after != null &&
                        before.referenceDate.year == after.referenceDate.year &&
                        before.referenceDate.month == after.referenceDate.month;
                  } else {
                    isSameGroup =
                        before != null &&
                        after != null &&
                        _isSameDay(before.referenceDate, after.referenceDate);
                  }

                  final showHeader =
                      after != null && (before == null || !isSameGroup);

                  if (showHeader) {
                    return _buildDateHeader(
                      context,
                      after.referenceDate,
                      l10n,
                      isLargeScreen,
                    );
                  }

                  return SizedBox.shrink();
                },
                itemBuilder: (context, item) {
                  final category = item.category;

                  if (isLargeScreen) {
                    return _buildTransactionTableItem(
                      context,
                      notifier: historyNotifier,
                      installment: item,
                      category: category,
                    );
                  }

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
      },
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _hasAdvancedFilters(TransactionQuery query) {
    return query.categoryId != null ||
        query.type != null ||
        query.description != null ||
        query.minAmount != null ||
        query.maxAmount != null ||
        query.status != null;
  }

  Widget _buildDateHeader(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
    bool isLargeScreen,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (isLargeScreen) {
      dateText = DateFormat.yMMMM(
        Localizations.localeOf(context).toString(),
      ).format(date);
      // Capitalize first letter
      if (dateText.isNotEmpty) {
        dateText = dateText[0].toUpperCase() + dateText.substring(1);
      }
    } else if (checkDate == today) {
      dateText = l10n.today;
    } else if (checkDate == yesterday) {
      dateText = l10n.yesterday;
    } else {
      dateText = DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(date);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      color: isLargeScreen
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : null,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 16 : 0),
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
          SizedBox(width: 44, child: Text('', style: textStyle)), // Ícone
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(l10n.historyFilterDescriptionLabel, style: textStyle),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.transactionInstallmentsLabel, style: textStyle),
          ),
          Expanded(flex: 2, child: Text('Conta', style: textStyle)),
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
          const SizedBox(width: 40), // Espaço para ações
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
                              : _parseColor(
                                  category?.color ?? '#14404C',
                                ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : _getIconData(category?.icon ?? 'category'),
                          color: isTransfer
                              ? Theme.of(context).colorScheme.primary
                              : _parseColor(category?.color ?? '#14404C'),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 1,
                                  ),
                                  decoration: ShapeDecoration(
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
