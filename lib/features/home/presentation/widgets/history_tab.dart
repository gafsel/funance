import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyState = ref.watch(historyProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );

    return Column(
      children: [
        // Topo: Filtros
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Seletor de Conta
              Expanded(
                child: accountsAsync.when(
                  data: (accounts) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: historyState.accountId,
                          hint: Text(
                            l10n.homeAllAccounts,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            ..._buildAccountItems(context, accounts),
                          ],
                          onChanged: (value) {
                            ref.read(historyProvider.notifier).setFilters(
                                  accountId: value,
                                  clearAccountId: value == null,
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
                        start: historyState.startDate ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        end: historyState.endDate ?? DateTime.now(),
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return child!;
                      },
                    );

                    if (picked != null) {
                      ref
                          .read(historyProvider.notifier)
                          .setFilters(
                            startDate: picked.start,
                            endDate: DateTime(
                              picked.end.year,
                              picked.end.month,
                              picked.end.day,
                              23,
                              59,
                              59,
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      historyState.startDate == null 
                          ? Icons.calendar_today
                          : Icons.calendar_month,
                      color: historyState.startDate == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (historyState.startDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ref.read(historyProvider.notifier).setFilters(clearDate: true);
                  },
                  icon: const Icon(Icons.close),
                  tooltip: l10n.clear, // Assumindo que existe, se não, "Limpar"
                ),
              ],
            ],
          ),
        ),
        if (historyState.startDate != null || historyState.endDate != null)
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
                  '${DateFormat.yMd().format(historyState.startDate!)} - ${DateFormat.yMd().format(historyState.endDate!)}',
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
          child: historyState.orders.isEmpty && !historyState.isLoading
              ? Center(
                  child: Text(
                    l10n.noTransactionsInPeriod,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 120,
                  ),
                  itemCount:
                      historyState.orders.length +
                      (historyState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == historyState.orders.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final order = historyState.orders[index];
                    final showDateHeader =
                        index == 0 ||
                        !_isSameDay(
                          order.date,
                          historyState.orders[index - 1].date,
                        );

                    final category = categoriesAsync.when(
                      data: (cats) => cats.firstWhere(
                        (c) => c.id == order.category.id,
                        orElse: () => order.category,
                      ),
                      loading: () => CategoryModel(
                        id: '',
                        name: '...',
                        icon: 'category',
                        color: '#4A8C9C',
                      ),
                      error: (_, __) => CategoryModel(
                        id: '',
                        name: '!',
                        icon: 'category',
                        color: '#4A8C9C',
                      ),
                    );

    final accountData = accountsAsync.when(
      data: (accs) {
        final metadata = order.metadata ?? {};
        final accountId = metadata['accountId'] ??
            metadata['fromAccountId'] ??
            metadata['account_id'];
        
        AccountModel mainAcc;
        if (accountId == null) {
          if (order.type == OrderType.transfer) {
            final toId = metadata['toAccountId'];
            mainAcc = toId != null 
              ? accs.firstWhere((a) => a.id == toId, orElse: () => _unknownAccount())
              : _unknownAccount();
          } else {
            mainAcc = _unknownAccount();
          }
        } else {
          mainAcc = accs.firstWhere(
            (a) => a.id == accountId,
            orElse: () {
              if (order.type == OrderType.transfer) {
                final toId = metadata['toAccountId'];
                return toId != null
                  ? accs.firstWhere((a) => a.id == toId, orElse: () => _unknownAccount())
                  : _unknownAccount();
              }
              return _unknownAccount();
            },
          );
        }

        String name = mainAcc.name;
        if (order.type == OrderType.transfer && mainAcc.id.isNotEmpty) {
          final toId = metadata['toAccountId'];
          final fromId = metadata['fromAccountId'] ?? metadata['accountId'];
          
          final fromAccount = accs.firstWhere((a) => a.id == fromId, orElse: () => _unknownAccount());
          final toAccount = accs.firstWhere((a) => a.id == toId, orElse: () => _unknownAccount());
          
          if (fromAccount.id.isNotEmpty && toAccount.id.isNotEmpty) {
             name = '${fromAccount.name} → ${toAccount.name}';
          }
        }
        return (account: mainAcc, name: name);
      },
      loading: () => (
        account: AccountModel(
          id: '',
          name: '...',
          color: '#808080',
          icon: 'help',
          type: AccountType.checking,
          initialBalanceDate: DateTime.now(),
        ),
        name: '...'
      ),
      error: (_, __) => (
        account: AccountModel(
          id: '',
          name: '!',
          icon: 'help',
          color: '#808080',
          type: AccountType.checking,
          initialBalanceDate: DateTime.now(),
        ),
        name: '!'
      ),
    );

    final account = accountData.account;
    final accountName = accountData.name;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(context, order.date, l10n),
                        _buildTransactionItem(
                          context,
                          order: order,
                          category: category,
                          accountName: accountName,
                          currencyFormat: currencyFormat,
                          l10n: l10n,
                        ),
                      ],
                    );
                  },
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
    return AccountModel(
      id: '',
      name: '?',
      color: '#808080',
      icon: 'help',
      type: AccountType.checking,
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
    required OrderModel order,
    required CategoryModel? category,
    required String accountName,
    required NumberFormat currencyFormat,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final isExpense = order.type == OrderType.expense;
    final isTransfer = order.type == OrderType.transfer;

    Color amountColor;
    if (isTransfer) {
      amountColor = Theme.of(context).colorScheme.primary;
    } else if (isExpense) {
      amountColor = Theme.of(context).colorScheme.error;
    } else {
      amountColor = AppColors.limeGreen;
    }

    String amountPrefix;
    if (isTransfer) {
      amountPrefix = '';
    } else {
      amountPrefix = isExpense ? '-' : '+';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Slidable(
        key: ValueKey(order.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                TransactionType initialType;
                if (order.type == OrderType.transfer) {
                  initialType = TransactionType.transfer;
                } else if (order.type == OrderType.expense) {
                  initialType = TransactionType.expense;
                } else {
                  initialType = TransactionType.income;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionFormScreen(
                      initialType: initialType,
                      initialOrder: order,
                    ),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: Icons.edit,
              label: l10n.historyEdit,
            ),
            SlidableAction(
              onPressed: (context) => _confirmDelete(context, order, l10n),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              icon: Icons.delete,
              label: l10n.historyDelete,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            TransactionType initialType;
            if (order.type == OrderType.transfer) {
              initialType = TransactionType.transfer;
            } else if (order.type == OrderType.expense) {
              initialType = TransactionType.expense;
            } else {
              initialType = TransactionType.income;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen(
                  initialType: initialType,
                  initialOrder: order,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
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
                    isTransfer
                        ? Icons.swap_horiz
                        : _getIconData(category?.icon ?? 'category'),
                    color: isTransfer
                        ? Theme.of(context).colorScheme.primary
                        : _parseColor(category?.color ?? '#14404C'),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isTransfer ? l10n.transactionActionTransfer : (category?.name ?? order.category)} • $accountName',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${amountPrefix.isNotEmpty ? '$amountPrefix ' : ''}${currencyFormat.format(order.totalAmount)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    OrderModel order,
    AppLocalizations l10n,
  ) {
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
          TextButton(
            onPressed: () {
              ref
                  .read(transactionNotifierProvider.notifier)
                  .deleteTransaction(order.id);
              ref.read(historyProvider.notifier).loadOrders(isRefresh: true);
              Navigator.pop(context);
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
