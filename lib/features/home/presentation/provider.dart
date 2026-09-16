import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/home/presentation/controller/overview_notifier.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/widgets/history_period_filter.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

sealed class MissionDomainProviders {
  static final service = Provider<MissionService>((ref) {
    // A janela da semana é calculada quando o stream é criado; observar
    // `todayProvider` faz o serviço (e o stream) serem refeitos na virada do
    // dia, em vez de ficarem presos no dia em que o app abriu.
    final today = ref.watch(todayProvider);

    return MissionService(
      financeService: ref.watch(FinanceDomainProviders.service),
      summaryService: ref.watch(PeriodSummaryDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
      now: () => today,
    );
  });
}

sealed class MissionViewProviders {
  static final mission = StreamProvider.autoDispose<MissionModel>((ref) {
    return ref.watch(MissionDomainProviders.service).watchMissions();
  });
}

/// Período selecionado nos resumos.
///
/// Segue o dia corrente enquanto o usuário não escolher um mês à mão; a partir
/// daí a virada do dia (meia-noite ou volta do background) não mexe mais na
/// escolha dele. `chooseToday()` volta a seguir o relógio.
class PeriodNotifier extends Notifier<DateTime> {
  DateTime? _chosenByUser;

  @override
  DateTime build() {
    final today = ref.watch(todayProvider);
    return _chosenByUser ?? today;
  }

  void choose(DateTime period) {
    _chosenByUser = period;
    state = period;
  }

  void chooseToday() {
    _chosenByUser = null;
    state = ref.read(todayProvider);
  }
}

class HomeViewProviders {
  /// O valor inicial vem do `todayProvider` (e não de `DateTime.now()` no
  /// corpo do provider, que congelaria a data no instante da criação).
  static final period = NotifierProvider<PeriodNotifier, DateTime>(
    PeriodNotifier.new,
  );

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
