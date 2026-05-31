import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_list_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'history_desktop_view.dart';
import 'history_filter_bottom_sheet.dart';
import 'history_mobile_view.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyState = ref.watch(FinanceViewProviders.history);
    final historyNotifier = ref.watch(FinanceViewProviders.history.notifier);
    final query = historyState.query;

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
                    prefixIcon: const Icon(Icons.wallet),
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelText: l10n.accountNameLabel,
                  ),
                  onChanged: (value) {
                    historyNotifier.reset(query: query.copyWith(accountId: value));
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      _hasAdvancedFilters(query) ? Icons.filter_alt : Icons.filter_alt_outlined,
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
                        start: query.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
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
                      query.startDate == null ? Icons.calendar_today : Icons.calendar_month,
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
                  tooltip: l10n.clear,
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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return HistoryDesktopView(
                  historyNotifier: historyNotifier,
                );
              }

              return HistoryMobileView(
                historyNotifier: historyNotifier,
              );
            },
          ),
        ),
      ],
    );
  }

  bool _hasAdvancedFilters(TransactionQuery query) {
    return query.categoryId != null ||
        query.type != null ||
        query.description != null ||
        query.minAmount != null ||
        query.maxAmount != null ||
        query.status != null;
  }
}
