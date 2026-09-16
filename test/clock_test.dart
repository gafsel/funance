import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_wizard_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

mixin _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

class _FakeAccountRepository with _Unimplemented
    implements IAccountRepository {}

class _FakeCategoryRepository with _Unimplemented
    implements ICategoryRepository {
  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(const []);
}

class _FakePeriodSummaryRepository with _Unimplemented
    implements IPeriodSummaryRepository {
  final List<({int year, int week})> weekCalls = [];

  @override
  Stream<PeriodSummaryModel?> watchWeek(
    String workspaceId,
    int year,
    int week,
  ) {
    weekCalls.add((year: year, week: week));
    return Stream.value(null);
  }
}

class _FakeFinanceRepository with _Unimplemented implements IFinanceRepository {
  final List<({DateTime? startDate, DateTime? endDate})> watchCalls = [];
  final List<({DateTime? startDate, DateTime? endDate})> queryCalls = [];

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    watchCalls.add((startDate: startDate, endDate: endDate));
    return Stream.value(const []);
  }

  @override
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  }) async {
    queryCalls.add((startDate: startDate, endDate: endDate));
    return QueryChunk(items: const []);
  }
}

MissionService _missionService(
  DateTime now, {
  required _FakeFinanceRepository financeRepository,
  required _FakePeriodSummaryRepository summaryRepository,
}) {
  return MissionService(
    financeService: FinanceService(
      workspaceId: 'ws-1',
      repository: financeRepository,
      accountRepository: _FakeAccountRepository(),
      categoryRepository: _FakeCategoryRepository(),
    ),
    summaryService: PeriodSummaryService(
      workspaceId: 'ws-1',
      repository: summaryRepository,
    ),
    categoryService: CategoryService(
      workspaceId: 'ws-1',
      repository: _FakeCategoryRepository(),
    ),
    now: () => now,
  );
}

void main() {
  group('MissionService.weekWindow', () {
    test('vai de domingo a sábado', () {
      // Quarta-feira, 11/03/2026.
      final window = MissionService.weekWindow(DateTime(2026, 3, 11, 15, 42));

      expect(window.start, DateTime(2026, 3, 8));
      expect(window.end, DateTime(2026, 3, 14, 23, 59, 59));
      expect(window.start.weekday, DateTime.sunday);
      expect(window.end.weekday, DateTime.saturday);
    });

    test('num domingo a semana começa no próprio dia', () {
      final window = MissionService.weekWindow(DateTime(2026, 3, 8, 0, 1));

      expect(window.start, DateTime(2026, 3, 8));
      expect(window.end, DateTime(2026, 3, 14, 23, 59, 59));
    });

    test('num sábado a semana termina no próprio dia', () {
      final window = MissionService.weekWindow(DateTime(2026, 3, 14, 23, 0));

      expect(window.start, DateTime(2026, 3, 8));
      expect(window.end, DateTime(2026, 3, 14, 23, 59, 59));
    });

    test('atravessa a virada do ano', () {
      // Quinta-feira, 01/01/2026.
      final window = MissionService.weekWindow(DateTime(2026, 1, 1, 9));

      expect(window.start, DateTime(2025, 12, 28));
      expect(window.end, DateTime(2026, 1, 3, 23, 59, 59));
    });
  });

  test('o clock injetado define a janela consultada pelo MissionService', () {
    final financeRepository = _FakeFinanceRepository();
    final summaryRepository = _FakePeriodSummaryRepository();

    _missionService(
      DateTime(2026, 3, 11, 15, 42),
      financeRepository: financeRepository,
      summaryRepository: summaryRepository,
    ).watchMissions();

    expect(financeRepository.watchCalls, hasLength(2));

    // Atrasadas: tudo até um segundo antes do início da semana.
    expect(
      financeRepository.watchCalls.first.endDate,
      DateTime(2026, 3, 7, 23, 59, 59),
    );
    // Semana corrente.
    expect(financeRepository.watchCalls[1].startDate, DateTime(2026, 3, 8));
    expect(
      financeRepository.watchCalls[1].endDate,
      DateTime(2026, 3, 14, 23, 59, 59),
    );

    expect(summaryRepository.weekCalls, hasLength(1));
    expect(summaryRepository.weekCalls.single.year, 2026);
  });

  group('janela mensal do wizard', () {
    test('no último dia do mês cobre o mês inteiro', () {
      final range = TransactionWizardNotifier.monthRange(
        DateTime(2026, 1, 31, 23, 58),
      );

      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 1, 31, 23, 59, 59));
    });

    test('um minuto depois já é o mês seguinte', () {
      final range = TransactionWizardNotifier.monthRange(DateTime(2026, 2, 1));

      expect(range.start, DateTime(2026, 2, 1));
      // 2026 não é bissexto.
      expect(range.end, DateTime(2026, 2, 28, 23, 59, 59));
    });

    test('dezembro vira para janeiro sem estourar o ano', () {
      final range = TransactionWizardNotifier.monthRange(
        DateTime(2026, 12, 15),
      );

      expect(range.start, DateTime(2026, 12, 1));
      expect(range.end, DateTime(2026, 12, 31, 23, 59, 59));
    });
  });

  test('o wizard consulta o mês do clock injetado', () async {
    final financeRepository = _FakeFinanceRepository();
    final notifier = TransactionWizardNotifier(
      const TransactionWizardState(type: OrderType.expense),
      financeService: FinanceService(
        workspaceId: 'ws-1',
        repository: financeRepository,
        accountRepository: _FakeAccountRepository(),
        categoryRepository: _FakeCategoryRepository(),
      ),
      now: () => DateTime(2026, 1, 31, 23, 58),
    );
    addTearDown(notifier.dispose);

    notifier.selectCategory(
      const CategoryModel(
        id: 'cat-1',
        name: 'Mercado',
        icon: 'shopping_cart',
        color: '#FF0000',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(financeRepository.queryCalls, hasLength(1));
    expect(financeRepository.queryCalls.single.startDate, DateTime(2026, 1, 1));
    expect(
      financeRepository.queryCalls.single.endDate,
      DateTime(2026, 1, 31, 23, 59, 59),
    );
  });

  group('todayProvider', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    test('normaliza o relógio à meia-noite local', () {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 3, 11, 15, 42)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(todayProvider), DateTime(2026, 3, 11));
    });

    test('o período inicial da home deriva do dia corrente', () {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(
            () => DateTime(2026, 3, 31, 23, 59, 59),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(HomeViewProviders.period), DateTime(2026, 3, 31));
    });

    test('refresh reemite quando o dia vira', () {
      var now = DateTime(2026, 3, 31, 23, 59, 59);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);

      expect(container.read(todayProvider), DateTime(2026, 3, 31));

      // O que acontece quando o app volta do background já no mês seguinte.
      now = DateTime(2026, 4, 1, 8, 15);
      container.read(todayProvider.notifier).refresh();

      expect(container.read(todayProvider), DateTime(2026, 4, 1));
      expect(container.read(HomeViewProviders.period), DateTime(2026, 4, 1));
    });
  });
}
