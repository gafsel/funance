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
        // Topo: Filtros (Placeholders por enquanto)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  l10n.homeAllAccounts,
                  isSelected: true,
                ),
                _buildPeriodChip(context, l10n.homeThisMonth, isSelected: true),
                _buildPeriodChip(context, l10n.homeLastMonth),
              ],
            ),
          ),
        ),
        // Lista de Transações
        Expanded(
          child: historyState.orders.isEmpty && !historyState.isLoading
              ? Center(child: Text(l10n.noTransactionsInPeriod))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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

                    final account = accountsAsync.when(
                      data: (accs) {
                        final accountId = order.metadata?['accountId'] ?? order.metadata?['account_id'] ?? '';
                        return accs.firstWhere(
                          (a) => a.id == accountId,
                          orElse: () => AccountModel(
                            id: '',
                            name: '?',
                            color: '#808080',
                            icon: 'help',
                            type: AccountType.checking,
                            initialBalanceDate: DateTime.now(),
                          ),
                        );
                      },
                      loading: () => AccountModel(
                        id: '',
                        name: '...',
                        color: '#808080',
                        icon: 'help',
                        type: AccountType.checking,
                        initialBalanceDate: DateTime.now(),
                      ),
                      error: (_, __) => AccountModel(
                        id: '',
                        name: '!',
                        color: '#808080',
                        icon: 'help',
                        type: AccountType.checking,
                        initialBalanceDate: DateTime.now(),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(context, order.date, l10n),
                        _buildTransactionItem(
                          context,
                          order: order,
                          category: category,
                          accountName: account?.name ?? '',
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label, {
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        backgroundColor: AppColors.pureWhite,
        selectedColor: AppColors.vibrantTeal.withValues(alpha: 0.2),
        checkmarkColor: AppColors.deepTurquoise,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.deepTurquoise : AppColors.vibrantTeal,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    String label, {
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (val) {},
      ),
    );
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.vibrantTeal,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Slidable(
        key: ValueKey(order.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionFormScreen(
                      initialType: (order.type == OrderType.expense
                          ? TransactionType.expense
                          : TransactionType.income),
                      initialOrder: order,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.vibrantTeal,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: l10n.historyEdit,
            ),
            SlidableAction(
              onPressed: (context) => _confirmDelete(context, order, l10n),
              backgroundColor: AppColors.coralOrange,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: l10n.historyDelete,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen(
                  initialType: (order.type == OrderType.expense
                      ? TransactionType.expense
                      : TransactionType.income),
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
                    color: _parseColor(
                      category?.color ?? '#14404C',
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(category?.icon ?? 'category'),
                    color: _parseColor(category?.color ?? '#14404C'),
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
                        '${category?.name ?? order.category} • $accountName',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'} ${currencyFormat.format(order.totalAmount)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? AppColors.coralOrange
                        : AppColors.limeGreen,
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
