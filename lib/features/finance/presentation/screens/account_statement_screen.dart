import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_statement_filter_bottom_sheet.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AccountStatementScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountStatementScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountStatementScreen> createState() =>
      _AccountStatementScreenState();
}

class _AccountStatementScreenState extends ConsumerState<AccountStatementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(AccountViewProviders.byId(widget.accountId));

    return accountAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text(error.toString()))),
      data: (account) {
        if (account == null) return const Scaffold(body: Center(child: Text('Conta não encontrada')));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: isDesktop ? 280 : 220,
                      pinned: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          onPressed: () {
                            context.push('/reconciliation', extra: account);
                          },
                          tooltip: context.l10n.reconciliationTitle,
                        ),
                        const SizedBox(width: 8),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: _buildHeader(context, account, isDesktop),
                        titlePadding: EdgeInsets.zero,
                        title: LayoutBuilder(
                          builder: (context, constraints) {
                            final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
                            if (settings == null) return const SizedBox.shrink();
                            final deltaExtent = settings.maxExtent - settings.minExtent;
                            final t = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);
                            if (t > 0.7) {
                              return Container(
                                height: settings.minExtent,
                                padding: const EdgeInsets.symmetric(horizontal: 48),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  account.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.antiqueGold,
                          unselectedLabelColor: AppColors.pureWhite.withValues(alpha: 0.5),
                          indicatorColor: AppColors.antiqueGold,
                          tabs: [
                            Tab(text: context.l10n.accountStatementCurrent),
                            Tab(text: context.l10n.accountStatementFuture),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _StatementList(accountId: widget.accountId, isFuture: false, isDesktop: isDesktop),
                    _StatementList(accountId: widget.accountId, isFuture: true, isDesktop: isDesktop),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AccountModel account, bool isDesktop) {
    final theme = Theme.of(context);
    final locale = context.locale;
    final latestBalanceAsync = ref.watch(AccountViewProviders.latestBalanceById(account.id));

    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.backgroundGradient,
      ),
      padding: EdgeInsets.fromLTRB(24, isDesktop ? 100 : 60, 24, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 600;

          if (useVerticalLayout) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: account.color.asColor().withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        account.icon.asIcon(),
                        color: account.color.asColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            context.l10n.fromAccountType(account.type),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.pureWhite.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.currentBalance,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.7),
                  ),
                ),
                latestBalanceAsync.when(
                  data: (balance) => Text(
                    balance.balance.asCurrency(locale: locale),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.pureWhite, strokeWidth: 2)),
                  error: (_, __) => const Text('---', style: TextStyle(color: AppColors.pureWhite)),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: account.color.asColor().withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            account.icon.asIcon(),
                            color: account.color.asColor(),
                            size: isDesktop ? 40 : 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: (isDesktop ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall)?.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                context.l10n.fromAccountType(account.type),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.pureWhite.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.currentBalance,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.pureWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    latestBalanceAsync.when(
                      data: (balance) => Text(
                        balance.balance.asCurrency(locale: locale),
                        style: (isDesktop ? theme.textTheme.displaySmall : theme.textTheme.headlineMedium)?.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: AppColors.pureWhite)),
                      error: (_, __) => const Text('---', style: TextStyle(color: AppColors.pureWhite)),
                    ),
                  ],
                ),
              ),
              if (constraints.maxWidth > 800) ...[
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.account_balance_wallet_outlined,
                        context.l10n.fromAccountType(account.type),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.antiqueGold),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementList extends ConsumerWidget {
  final String accountId;
  final bool isFuture;
  final bool isDesktop;

  const _StatementList({
    required this.accountId,
    required this.isFuture,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = FinanceViewProviders.statement((accountId: accountId, isFuture: isFuture));
    final l10n = context.l10n;

    return Column(
      children: [
        _buildFilterBar(context, ref, provider),
        if (isDesktop) _buildTableHeader(context, l10n),
        Expanded(
          child: InfiniteListView.separator(
            provider,
            padding: const EdgeInsets.only(bottom: 16),
            emptyStateBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  context.l10n.noRecordsFound,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            separatorBuilder: (context, before, after) {
              final bool isSameGroup = before != null &&
                  after != null &&
                  (isDesktop
                      ? _isSameMonth(before.referenceDate, after.referenceDate)
                      : _isSameDay(before.referenceDate, after.referenceDate));

              final showHeader = after != null && (before == null || !isSameGroup);

              if (showHeader) {
                return _DateHeader(
                  accountId: accountId,
                  date: after.referenceDate,
                  isDesktop: isDesktop,
                );
              }

              return const SizedBox.shrink();
            },
            itemBuilder: (context, item) {
              if (isDesktop) {
                return _TransactionTableItem(
                  accountId: accountId,
                  installment: item,
                  onTap: () => _onItemTap(context, ref, item, provider),
                );
              }

              return _TransactionItem(
                accountId: accountId,
                installment: item,
                onTap: () => _onItemTap(context, ref, item, provider),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    InstallmentModel item,
    dynamic provider,
  ) async {
    final updated = await context.push<bool>(
      '/transactions/form',
      extra: {'installment': item},
    );
    if (updated ?? false) {
      ref.read(provider.notifier).reset();
    }
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(l10n.date, style: textStyle)),
          const SizedBox(width: 12),
          SizedBox(width: 44, child: Text('', style: textStyle)),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(l10n.historyFilterDescriptionLabel, style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.transactionInstallmentsLabel, style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.historyFilterStatusLabel, style: textStyle),
          ),
          SizedBox(
            width: 150,
            child: Text(
              l10n.transactionAmountLabel,
              style: textStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, dynamic provider) {
    final state = ref.watch(provider);
    final hasFilter = state.query.categoryId != null ||
        state.query.type != null ||
        state.query.description != null ||
        state.query.minAmount != null ||
        state.query.maxAmount != null ||
        state.query.status != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.transactions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => AccountStatementFilterBottomSheet(
                  initialQuery: state.query,
                  onApply: (query) {
                    ref.read(provider.notifier).reset(query: query);
                  },
                ),
              );
            },
            icon: Icon(
              hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasFilter ? AppColors.antiqueGold : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}

class _DateHeader extends ConsumerWidget {
  final String accountId;
  final DateTime date;
  final bool isDesktop;

  const _DateHeader({
    required this.accountId,
    required this.date,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (!isDesktop) {
      if (checkDate == today) {
        dateText = l10n.today;
      } else if (checkDate == yesterday) {
        dateText = l10n.yesterday;
      } else {
        dateText = DateFormat.yMMMMd(context.locale).format(date);
      }
    } else {
      dateText = DateFormat.yMMMM(context.locale).format(date);
    }

    final balanceAsync = ref.watch(AccountViewProviders.balanceAtDate((accountId: accountId, date: date)));

    return Container(
      color: isDesktop ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : null,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          balanceAsync.when(
            data: (balance) => Text(
              balance.balance.asCurrency(locale: context.locale),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TransactionTableItem extends StatelessWidget {
  final String accountId;
  final InstallmentModel installment;
  final VoidCallback onTap;

  const _TransactionTableItem({
    required this.accountId,
    required this.installment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.locale;
    final l10n = context.l10n;
    final isExpense = installment.type == OrderType.expense;
    final isTransfer = installment.type == OrderType.transfer;

    Color amountColor;
    String amountPrefix;

    if (isTransfer) {
      final isOutgoing = installment.accountIdSource == accountId;
      amountColor = isOutgoing ? AppColors.error : AppColors.limeGreen;
      amountPrefix = isOutgoing ? '-' : '+';
    } else if (isExpense) {
      amountColor = AppColors.error;
      amountPrefix = '-';
    } else {
      amountColor = AppColors.limeGreen;
      amountPrefix = '+';
    }

    return InkWell(
      onTap: onTap,
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
              width: 100,
              child: Text(
                DateFormat.yMd(locale).format(installment.referenceDate),
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
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (installment.category != null)
                    Text(
                      installment.category!.name,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            // Parcelas
            Expanded(
              flex: 2,
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
            // Status
            Expanded(
              flex: 2,
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
              width: 150,
              child: Text(
                '$amountPrefix${installment.referenceAmount.asCurrency(locale: locale)}',
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
}

class _TransactionItem extends StatelessWidget {
  final String accountId;
  final InstallmentModel installment;
  final VoidCallback onTap;

  const _TransactionItem({
    required this.accountId,
    required this.installment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = installment.type == OrderType.expense;
    final isTransfer = installment.type == OrderType.transfer;

    Color amountColor;
    String amountPrefix;

    if (isTransfer) {
      final isOutgoing = installment.accountIdSource == accountId;
      amountColor = isOutgoing ? AppColors.error : AppColors.limeGreen;
      amountPrefix = isOutgoing ? '-' : '+';
    } else if (isExpense) {
      amountColor = AppColors.error;
      amountPrefix = '-';
    } else {
      amountColor = AppColors.limeGreen;
      amountPrefix = '+';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Row(
            spacing: 12,
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
                    if (installment.category != null)
                      Text(
                        installment.category!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$amountPrefix${installment.referenceAmount.asCurrency(locale: context.locale)}',
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
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
