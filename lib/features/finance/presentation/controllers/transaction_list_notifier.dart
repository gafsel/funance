import 'dart:async';

import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/core/money/money.dart';

class TransactionListNotifier
    extends InfiniteListNotifier<TransactionQuery, InstallmentModel> {
  final FinanceService financeiroService;

  Timer? _debounceTimer;

  TransactionListNotifier({
    required this.financeiroService,
    TransactionQuery? initialQuery,
  }) : super(
         initialQuery:
             initialQuery ??
             TransactionQuery(
               startDate: HistoryPeriodType.month.getRange().$1,
               endDate: HistoryPeriodType.month.getRange().$2,
             ),
         executor: (query, {chunkRef}) async {
           return await financeiroService.queryInstallments(
             limit: 10,
             accountId: query.accountId,
             startDate: query.startDate,
             endDate: query.endDate,
             categoryId: query.categoryId,
             type: query.type,
             description: query.description,
             minAmount: query.minAmount,
             maxAmount: query.maxAmount,
             status: query.status,
             chunkRef: chunkRef,
           );
         },
       ) {
    load();
  }

  @override
  Future<void> reset({TransactionQuery? query}) async {
    if (query?.description != state.query.description) {
      // Busca por texto é debounced: o reset real roda depois do timer, então
      // este caminho não tem o que aguardar.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        unawaited(super.reset(query: query));
      });
      state = state.copyWith(query: query ?? state.query);
    } else {
      await super.reset(query: query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Os totais da lista, somados em centavos.
  ///
  /// Eram dezesseis acumuladores `double` percorrendo o mesmo laço. Numa lista
  /// de um mês inteiro, o resto do ponto flutuante aparecia como um centavo de
  /// diferença entre o cabeçalho e a soma das linhas — e ninguém sabia dizer
  /// qual dos dois estava certo. [Money] soma em `int`; o `toDouble()` só
  /// acontece na saída, porque os modelos ainda falam `double`.
  TransactionTotals get totals {
    var plannedIncomes = Money.zero;
    var realizedIncomes = Money.zero;
    var plannedExpenses = Money.zero;
    var realizedExpenses = Money.zero;
    var plannedTransfers = Money.zero;
    var realizedTransfers = Money.zero;
    var plannedInvoices = Money.zero;
    var realizedInvoices = Money.zero;
    final virtualPlanned = <VirtualCategory, Money>{};
    final virtualRealized = <VirtualCategory, Money>{};

    for (final item in state.items) {
      final planned = item.amount.asMoney;
      final realized = (item.paidAmount ?? 0.0).asMoney;
      final virtual = VirtualCategory.byId(item.category?.id);

      if (virtual != null) {
        virtualPlanned.update(
          virtual,
          (total) => total + planned,
          ifAbsent: () => planned,
        );
        virtualRealized.update(
          virtual,
          (total) => total + realized,
          ifAbsent: () => realized,
        );
      } else {
        switch (item.type) {
          case OrderType.income:
            plannedIncomes += planned;
            realizedIncomes += realized;
          case OrderType.expense:
            plannedExpenses += planned;
            realizedExpenses += realized;
          case OrderType.transfer:
            // A fatura é uma transferência, mas ela tem a própria linha
            // logo abaixo: contá-la aqui também a somaria duas vezes.
            if (!item.isInvoice) {
              plannedTransfers += planned;
              realizedTransfers += realized;
            }
        }
      }

      if (item.isInvoice) {
        plannedInvoices += planned;
        realizedInvoices += realized;
      }
    }

    return TransactionTotals(
      plannedIncomes: plannedIncomes.toDouble(),
      realizedIncomes: realizedIncomes.toDouble(),
      plannedExpenses: plannedExpenses.toDouble(),
      realizedExpenses: realizedExpenses.toDouble(),
      plannedTransfers: plannedTransfers.toDouble(),
      realizedTransfers: realizedTransfers.toDouble(),
      plannedInvoices: plannedInvoices.toDouble(),
      realizedInvoices: realizedInvoices.toDouble(),
      virtualTotals: {
        for (final virtual in virtualPlanned.keys)
          virtual: (
            planned: virtualPlanned[virtual]!.toDouble(),
            realized: virtualRealized[virtual]!.toDouble(),
          ),
      },
    );
  }

  Future<void> delete(
    String id, {
    required ReplicationCascade replicationCascade,
  }) async {
    await financeiroService.cancelInstallment(
      id,
      replicationCascade: replicationCascade,
    );

    state = state.copyWith(
      items: [...state.items.where((item) => item.id != id)],
    );
  }
}
