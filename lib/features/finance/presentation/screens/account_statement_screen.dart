import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/controllers/account_statement_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/detail_header.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_filter_bottom_sheet.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_view.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';

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
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView.forError(
              context,
              error,
              // `byId` deriva de `all`: invalidar o derivado deixava o erro
              // cacheado da lista de contas de pé.
              onRetry: () => Retry.accounts(ref),
            ),
          ),
        ),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            body: Center(child: Text(context.l10n.accountNotFound)),
          );
        }

        final latestBalanceAsync = ref.watch(AccountViewProviders.latestBalanceById(account.id));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverDetailHeader(
                      title: account.name,
                      subtitle: latestBalanceAsync.when(
                        data: (balance) => balance.balance.asCurrency(locale: context.locale),
                        loading: () => "...",
                        error: (_, _) => "---",
                      ),
                      backgroundColor: account.color.asColor(),
                      logo: AccountLogo(account: account, size: 40, showMembers: true,),
                      expandedHeight: 300,
                      chips: [
                        DetailHeaderChip(
                          icon: account.icon.asIcon(),
                          label: context.l10n.fromAccountType(account.type),
                        ),
                      ],
                      actions: [
                        DetailHeaderAction(
                          icon: Icons.edit_outlined,
                          label: context.l10n.editButton,
                          onPressed: () {
                            context.push('/accounts/form?id=${account.id}');
                          },
                          tooltip: context.l10n.editButton,
                        ),
                        DetailHeaderAction(
                          icon: Icons.account_balance_wallet_outlined,
                          label: context.l10n.reconciliationTitle,
                          onPressed: () {
                            context.push('/reconciliation?accountId=${account.id}');
                          },
                          tooltip: context.l10n.reconciliationTitle,
                        ),
                      ],
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.pureWhite,
                          unselectedLabelColor: AppColors.pureWhite.withValues(alpha: 0.6),
                          indicatorColor: AppColors.brightCyan,
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
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      final theme = Theme.of(context);
                      final l10n = context.l10n;
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                l10n.transactionNewTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              title: Text(l10n.transactionTypeExpense),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/transactions/form?type=expense&accountIdSource=${account.id}');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                              title: Text(l10n.transactionTypeIncome),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/transactions/form?type=income&accountIdSource=${account.id}');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                              title: Text(l10n.transactionTypeTransfer),
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/transactions/form?type=transfer&accountIdSource=${account.id}');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                backgroundColor: AppColors.successGold,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: AppColors.darkNavy),
              ),
            );
          },
        );
      },
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

    return Column(
      children: [
        _buildFilterBar(context, ref, provider),
        Expanded(
          child: TransactionListView(
            provider: provider,
            accountId: accountId,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    AutoDisposeStateNotifierProvider<
      AccountStatementNotifier,
      InfiniteListState<TransactionQuery, InstallmentModel>
    >
    provider,
  ) {
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
                backgroundColor: Colors.transparent,
                builder: (context) => TransactionFilterBottomSheet(
                  initialQuery: state.query,
                  hiddenFields: const {TransactionFilterField.account},
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
      color: AppColors.deepTurquoise,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
