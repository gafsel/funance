import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/features/home/presentation/controller/history_filter_notifier.dart';
import 'package:funances/features/home/presentation/controller/overview_notifier.dart';
import 'package:funances/features/home/presentation/model/history_filter_view_models.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';

class HomeViewProviders {
  static final period = StateProvider((ref) => DateTime.now());

  static final viewType = StateProvider((ref) => SummaryViewType.effective);

  static final historyPeriodType = StateProvider((ref) => HistoryPeriodType.month);

  static final historyFilter =
      StateNotifierProvider.autoDispose.family<HistoryFilterNotifier, HistoryFilterState, TransactionQuery>((
    ref,
    query,
  ) {
    return HistoryFilterNotifier(HistoryFilterState.fromQuery(query));
  });

  static final summaryExpenses = NotifierProvider<ExpenseSummaryNotifier, SummaryState>(
    ExpenseSummaryNotifier.new,
  );

  static final summaryIncomes = NotifierProvider<IncomeSummaryNotifier, SummaryState>(
    IncomeSummaryNotifier.new,
  );

  static final summaryBalance = NotifierProvider<BalanceSummaryNotifier, BalanceState>(
    BalanceSummaryNotifier.new,
  );
}
