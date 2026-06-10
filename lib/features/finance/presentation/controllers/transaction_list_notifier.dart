import 'dart:async';

import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

class TransactionListNotifier
    extends InfiniteListNotifier<TransactionQuery, InstallmentModel> {
  final FinanceService financeiroService;

  Timer? _debounceTimer;

  TransactionListNotifier({required this.financeiroService})
    : super(
        initialQuery: TransactionQuery(
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
  void reset({TransactionQuery? query}) {
    if (query?.description != state.query.description) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        super.reset(query: query);
      });
      state = state.copyWith(query: query ?? state.query);
    } else {
      super.reset(query: query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  TransactionTotals get totals {
    double plannedIncomes = 0;
    double realizedIncomes = 0;
    double plannedExpenses = 0;
    double realizedExpenses = 0;
    double plannedTransfers = 0;
    double realizedTransfers = 0;
    double plannedInvoices = 0;
    double realizedInvoices = 0;
    double plannedVirtualDebtExpense = 0;
    double realizedVirtualDebtExpense = 0;
    double plannedVirtualDebtIncome = 0;
    double realizedVirtualDebtIncome = 0;
    double plannedVirtualInvestmentExpense = 0;
    double realizedVirtualInvestmentExpense = 0;
    double plannedVirtualInvestmentIncome = 0;
    double realizedVirtualInvestmentIncome = 0;

    for (final item in state.items) {
      final categoryId = item.category?.id;
      final isVirtualDebtExpense =
          categoryId == CategoryModel.virtualDebtExpenseId;
      final isVirtualDebtIncome =
          categoryId == CategoryModel.virtualDebtIncomeId;
      final isVirtualInvestmentExpense =
          categoryId == CategoryModel.virtualInvestmentExpenseId;
      final isVirtualInvestmentIncome =
          categoryId == CategoryModel.virtualInvestmentIncomeId;

      if (isVirtualDebtExpense) {
        plannedVirtualDebtExpense += item.amount;
        realizedVirtualDebtExpense += item.paidAmount ?? 0.0;
      } else if (isVirtualDebtIncome) {
        plannedVirtualDebtIncome += item.amount;
        realizedVirtualDebtIncome += item.paidAmount ?? 0.0;
      } else if (isVirtualInvestmentExpense) {
        plannedVirtualInvestmentExpense += item.amount;
        realizedVirtualInvestmentExpense += item.paidAmount ?? 0.0;
      } else if (isVirtualInvestmentIncome) {
        plannedVirtualInvestmentIncome += item.amount;
        realizedVirtualInvestmentIncome += item.paidAmount ?? 0.0;
      } else {
        if (item.type == OrderType.income) {
          plannedIncomes += item.amount;
          realizedIncomes += item.paidAmount ?? 0.0;
        } else if (item.type == OrderType.expense) {
          plannedExpenses += item.amount;
          realizedExpenses += item.paidAmount ?? 0.0;
        } else if (item.type == OrderType.transfer) {
          if (!item.isInvoice) {
            plannedTransfers += item.amount;
            realizedTransfers += item.paidAmount ?? 0.0;
          }
        }
      }

      if (item.isInvoice) {
        plannedInvoices += item.amount;
        realizedInvoices += item.paidAmount ?? 0.0;
      }
    }

    return TransactionTotals(
      plannedIncomes: plannedIncomes,
      realizedIncomes: realizedIncomes,
      plannedExpenses: plannedExpenses,
      realizedExpenses: realizedExpenses,
      plannedTransfers: plannedTransfers,
      realizedTransfers: realizedTransfers,
      plannedInvoices: plannedInvoices,
      realizedInvoices: realizedInvoices,
      plannedVirtualDebtExpense: plannedVirtualDebtExpense,
      realizedVirtualDebtExpense: realizedVirtualDebtExpense,
      plannedVirtualDebtIncome: plannedVirtualDebtIncome,
      realizedVirtualDebtIncome: realizedVirtualDebtIncome,
      plannedVirtualInvestmentExpense: plannedVirtualInvestmentExpense,
      realizedVirtualInvestmentExpense: realizedVirtualInvestmentExpense,
      plannedVirtualInvestmentIncome: plannedVirtualInvestmentIncome,
      realizedVirtualInvestmentIncome: realizedVirtualInvestmentIncome,
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
