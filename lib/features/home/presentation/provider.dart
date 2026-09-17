import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/data/repositories/journey_repository_impl.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/models/monthly_available_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/domain/repositories/journey_repository.dart';
import 'package:funances/features/home/domain/services/journey_service.dart';
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

sealed class JourneyDomainProviders {
  static final repository = Provider<IJourneyRepository>(
    (ref) => JourneyRepositoryImpl(),
  );

  static final service = Provider<JourneyService>((ref) {
    return JourneyService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? '',
      repository: ref.watch(repository),
    );
  });
}

sealed class JourneyViewProviders {
  /// Semana corrente, do SERVIDOR.
  ///
  /// O campo `currentWeekId` do workspace é a única identidade de semana do
  /// projeto. O cálculo local só entra quando o campo ainda não existe (base
  /// anterior ao F1.9), para a tela não ficar sem missões esperando um cron.
  static final currentWeekId = Provider<String>((ref) {
    final fromServer = ref.watch(
      WorkspaceViewProviders.workspace.select(
        (state) => state.currentWorkspace?.currentWeekId,
      ),
    );

    if (fromServer != null && fromServer.isNotEmpty) return fromServer;

    return JourneyService.weekIdFor(ref.watch(todayProvider));
  });

  /// As três missões da semana, como o servidor as escreveu.
  static final weeklyMissions =
      StreamProvider.autoDispose<List<WeeklyMissionModel>>((ref) {
        return ref
            .watch(JourneyDomainProviders.service)
            .watchWeeklyMissions(ref.watch(currentWeekId));
      });

  /// XP da semana corrente. `null` = o servidor ainda não abriu o documento.
  static final weeklyXp = StreamProvider.autoDispose<double?>((ref) {
    return ref
        .watch(JourneyDomainProviders.service)
        .watchWeeklyXp(ref.watch(currentWeekId));
  });

  /// Bússola da Liberdade. `null` = índice ainda não publicado.
  static final financialHealth = StreamProvider.autoDispose<FinancialHealth?>((
    ref,
  ) {
    return ref.watch(JourneyDomainProviders.service).watchFinancialHealth();
  });

  /// Últimos seis meses do índice, do mais recente para o mais antigo.
  static final healthHistory =
      StreamProvider.autoDispose<List<FinancialHealthPoint>>((ref) {
        return ref
            .watch(JourneyDomainProviders.service)
            .watchHealthHistory(months: 6);
      });

  /// "Quanto posso gastar até o fim do mês".
  ///
  /// Sempre no mês CORRENTE (e não no período escolhido na Visão Geral): a
  /// pergunta é sobre o mês em que o usuário está vivendo. Navegar para
  /// outubro não muda quanto sobra hoje.
  static final monthlyAvailable = StreamProvider.autoDispose<MonthlyAvailable>((
    ref,
  ) {
    final today = ref.watch(todayProvider);
    final summaries = ref.watch(
      PeriodSummaryViewProviders.monthSummary(today.monthKey),
    );

    final pending = ref
        .watch(FinanceDomainProviders.service)
        .watchInstallments(
          type: OrderType.expense,
          status: InstallmentStatus.pending,
          startDate: DateTime(today.year, today.month, 1),
          // Dia 0 do mês seguinte é o último dia deste; o fim do dia entra
          // porque `referenceDate` é normalizado às 12:00.
          endDate: DateTime(today.year, today.month + 1, 0, 23, 59, 59),
        );

    return summaries.when(
      loading: () => const Stream.empty(),
      error: (error, stack) => Stream.error(error, stack),
      data: (list) => pending.map(
        (installments) => MonthlyAvailable.from(
          summaries: list,
          pendingInstallments: installments,
        ),
      ),
    );
  });
}

/// Período selecionado nos resumos.
///
/// Segue o dia corrente enquanto o usuário não escolher outro mês; a partir daí
/// a virada do dia (meia-noite ou volta do background) não mexe mais na escolha
/// dele. Navegar de volta ao mês corrente religa o acompanhamento automático —
/// é o único gesto que a UI oferece para isso, e é o que o usuário faz na
/// prática quando quer voltar ao "agora".
class PeriodNotifier extends Notifier<DateTime> {
  DateTime? _chosenByUser;

  @override
  DateTime build() {
    final today = ref.watch(todayProvider);
    return _chosenByUser ?? today;
  }

  void choose(DateTime period) {
    final today = ref.read(todayProvider);
    final isCurrentMonth =
        period.year == today.year && period.month == today.month;

    _chosenByUser = isCurrentMonth ? null : period;
    state = isCurrentMonth ? today : period;
  }
}

class HomeViewProviders {
  /// O valor inicial vem do `todayProvider` (e não de `DateTime.now()` no
  /// corpo do provider, que congelaria a data no instante da criação).
  static final period = NotifierProvider<PeriodNotifier, DateTime>(
    PeriodNotifier.new,
  );

  /// Aba aberta na Home (0 Jornada, 1 Visão Geral, 2 Histórico, 3 Ajustes).
  ///
  /// Existe para uma aba conseguir levar a outra: o `TabController` é estado
  /// interno da `HomeScreen`, e sem este intermediário o cabeçalho da Jornada
  /// não teria como cumprir "toque para ver o mês na Visão Geral".
  static final selectedTab = StateProvider<int>((ref) => 0);

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
