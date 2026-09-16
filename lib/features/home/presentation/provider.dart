import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/home/presentation/controller/overview_notifier.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

sealed class MissionDomainProviders {
  static final service = Provider<MissionService>((ref) {
    return MissionService(
      financeService: ref.watch(FinanceDomainProviders.service),
      summaryService: ref.watch(PeriodSummaryDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
    );
  });
}

sealed class MissionViewProviders {
  static final mission = StreamProvider.autoDispose<MissionModel>((ref) {
    return ref.watch(MissionDomainProviders.service).watchMissions();
  });
}

class HomeViewProviders {
  static final period = StateProvider((ref) => DateTime.now());

  static final viewType = StateProvider((ref) => SummaryViewType.effective);

  static final historyPeriodType = StateProvider(
    (ref) => HistoryPeriodType.month,
  );

  static final summaryExpenses =
      NotifierProvider<ExpenseSummaryNotifier, SummaryState>(
        ExpenseSummaryNotifier.new,
      );

  static final summaryExpensesFull =
      NotifierProvider<ExpenseSummaryFullNotifier, SummaryState>(
        ExpenseSummaryFullNotifier.new,
      );

  static final summaryIncomes =
      NotifierProvider<IncomeSummaryNotifier, SummaryState>(
        IncomeSummaryNotifier.new,
      );

  static final summaryIncomesFull =
      NotifierProvider<IncomeSummaryFullNotifier, SummaryState>(
        IncomeSummaryFullNotifier.new,
      );

  static final summaryBalance =
      NotifierProvider<BalanceSummaryNotifier, BalanceState>(
        BalanceSummaryNotifier.new,
      );
}
