import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'history_desktop_view.dart';
import 'history_filter_bottom_sheet.dart';
import 'history_mobile_view.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  Widget _buildSearchField(
    BuildContext context,
    TransactionListNotifier historyNotifier,
    TransactionQuery query,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return TextFormField(
      decoration: InputDecoration(
        hintText: l10n.historyFilterDescriptionLabel,
        prefixIcon: const Icon(Icons.search),
        fillColor: theme.colorScheme.surfaceContainerHighest,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (value) {
        historyNotifier.reset(
          query: query.copyWith(description: value.isEmpty ? null : value),
        );
      },
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    TransactionQuery query,
    TransactionListNotifier historyNotifier,
  ) {
    return Material(
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyState = ref.watch(FinanceViewProviders.history);
    final historyNotifier = ref.read(FinanceViewProviders.history.notifier);
    final periodType = ref.watch(HomeViewProviders.historyPeriodType);
    final query = historyState.query;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;

        return Column(
          children: [
            // Topo: Filtros
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HistoryPeriodFilter(
                          selectedType: periodType,
                          startDate: query.startDate,
                          endDate: query.endDate,
                          onSelected: (type, start, end) {
                            ref
                                .read(
                              HomeViewProviders
                                  .historyPeriodType
                                  .notifier,
                            )
                                .state =
                                type;
                            historyNotifier.reset(
                              query: query.copyWith(
                                startDate: start,
                                endDate: end,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSearchField(
                                context,
                                historyNotifier,
                                query,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildFilterButton(context, query, historyNotifier),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Filtro de Período (Fixo à esquerda)
                        SizedBox(
                          width: 350,
                          child: HistoryPeriodFilter(
                            selectedType: periodType,
                            startDate: query.startDate,
                            endDate: query.endDate,
                            onSelected: (type, start, end) {
                              ref
                                      .read(
                                        HomeViewProviders
                                            .historyPeriodType
                                            .notifier,
                                      )
                                      .state =
                                  type;
                              historyNotifier.reset(
                                query: query.copyWith(
                                  startDate: start,
                                  endDate: end,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Filtro por Texto
                        Expanded(
                          child: _buildSearchField(
                            context,
                            historyNotifier,
                            query,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botão de Filtro Avançado
                        _buildFilterButton(context, query, historyNotifier),
                      ],
                    ),
            ),
            // Badges para filtros da modal
            if (_hasAdvancedFilters(query))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (query.accountId != null)
                        Consumer(
                          builder: (context, ref, child) {
                            final accountAsync = ref.watch(
                              AccountViewProviders.byId(query.accountId!),
                            );
                            final accountName = accountAsync.when(
                              data: (account) =>
                                  account?.name ?? query.accountId,
                              loading: () => query.accountId,
                              error: (_, __) => query.accountId,
                            );

                            return _FilterBadge(
                              label:
                                  '${l10n.historyAccountLabel}: $accountName',
                              onClear: () => historyNotifier.reset(
                                query: query.copyWith(accountId: null),
                              ),
                            );
                          },
                        ),
                      if (query.categoryId != null)
                        Consumer(
                          builder: (context, ref, child) {
                            final categoryAsync = ref.watch(
                              CategoryViewProviders.byId(query.categoryId!),
                            );
                            final categoryName = categoryAsync.when(
                              data: (category) =>
                                  category?.name ?? query.categoryId,
                              loading: () => query.categoryId,
                              error: (_, __) => query.categoryId,
                            );

                            return _FilterBadge(
                              label:
                                  '${l10n.historyFilterCategoryLabel}: $categoryName',
                              onClear: () => historyNotifier.reset(
                                query: query.copyWith(categoryId: null),
                              ),
                            );
                          },
                        ),
                      if (query.type != null)
                        _FilterBadge(
                          label:
                              '${l10n.historyFilterTypeLabel}: ${query.type == OrderType.income
                                  ? l10n.transactionTypeIncome
                                  : query.type == OrderType.expense
                                  ? l10n.transactionTypeExpense
                                  : l10n.transactionTypeTransfer}',
                          onClear: () => historyNotifier.reset(
                            query: query.copyWith(type: null),
                          ),
                        ),
                      if (query.status != null)
                        _FilterBadge(
                          label:
                              '${l10n.historyFilterStatusLabel}: ${query.status == InstallmentStatus.paid
                                  ? l10n.statusPaid
                                  : query.status == InstallmentStatus.pending
                                  ? l10n.statusPending
                                  : l10n.statusSettled}',
                          onClear: () => historyNotifier.reset(
                            query: query.copyWith(status: null),
                          ),
                        ),
                      if (query.minAmount != null)
                        _FilterBadge(
                          label:
                              '${l10n.historyFilterMinAmountLabel}: ${query.minAmount!.asCurrency()}',
                          onClear: () => historyNotifier.reset(
                            query: query.copyWith(minAmount: null),
                          ),
                        ),
                      if (query.maxAmount != null)
                        _FilterBadge(
                          label:
                              '${l10n.historyFilterMaxAmountLabel}: ${query.maxAmount!.asCurrency()}',
                          onClear: () => historyNotifier.reset(
                            query: query.copyWith(maxAmount: null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: isMobile
                  ? HistoryMobileView(historyNotifier: historyNotifier)
                  : HistoryDesktopView(historyNotifier: historyNotifier),
            ),
          ],
        );
      },
    );
  }

  bool _hasAdvancedFilters(TransactionQuery query) {
    return query.accountId != null ||
        query.categoryId != null ||
        query.type != null ||
        query.minAmount != null ||
        query.maxAmount != null ||
        query.status != null;
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _FilterBadge({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(10),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
