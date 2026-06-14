import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_filter_bottom_sheet.dart';
import 'package:funances/features/finance/presentation/widgets/detail_header.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_view.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:go_router/go_router.dart';

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

        final latestBalanceAsync = ref.watch(AccountViewProviders.latestBalanceById(account.id));
        final membersAsync = ref.watch(WorkspaceViewProviders.members);

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
                        error: (_, __) => "---",
                      ),
                      backgroundColor: account.color.asColor(),
                      logo: AccountLogo(account: account, size: 40),
                      members: membersAsync.when(
                        data: (members) => members.where((m) => account.ownerIds.contains(m.id)).toList(),
                        loading: () => [],
                        error: (_, __) => [],
                      ),
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
                            context.push('/accounts/form', extra: account);
                          },
                          tooltip: context.l10n.editButton,
                        ),
                        DetailHeaderAction(
                          icon: Icons.account_balance_wallet_outlined,
                          label: context.l10n.reconciliationTitle,
                          onPressed: () {
                            context.push('/reconciliation', extra: account);
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
