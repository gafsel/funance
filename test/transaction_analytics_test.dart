import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// Registro de chamadas do analytics, para verificar o que o formulário emite.
class FakeAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  }) async {
    events.add((
      name: AnalyticsEvents.transactionSaved,
      params: {'status': status, 'had_planning': hadPlanning, 'type': type},
    ));
  }

  @override
  Future<void> logInstallmentPaid() async {
    events.add((name: AnalyticsEvents.installmentPaid, params: {}));
  }

  @override
  Future<void> logMissionCompleted() async {
    events.add((name: AnalyticsEvents.missionCompleted, params: {}));
  }

  @override
  Future<void> logOnboardingStep(String step) async {}

  @override
  Future<void> logAccountCreated(String type) async {}

  @override
  Future<void> logPlanningCreated() async {}

  @override
  Future<void> logCoachingOpened() async {}

  @override
  Future<void> logReconciliationDone() async {}

  ({String name, Map<String, Object> params})? find(String name) =>
      events.where((e) => e.name == name).firstOrNull;
}

// Os repositórios nunca são tocados: o FinanceService de teste sobrescreve
// todos os métodos usados no submit.
class _UnusedFinanceRepository implements IFinanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnusedAccountRepository implements IAccountRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnusedCategoryRepository implements ICategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class FakeFinanceService extends FinanceService {
  FakeFinanceService({this.plannings = const []})
    : super(
        workspaceId: 'ws-test',
        repository: _UnusedFinanceRepository(),
        accountRepository: _UnusedAccountRepository(),
        categoryRepository: _UnusedCategoryRepository(),
      );

  final List<CategoryPlanningModel> plannings;
  final List<OrderModel> savedOrders = [];

  @override
  Future<OrderModel> addOrder(OrderModel order) async {
    final saved = order.copyWith(id: 'order-salva');
    savedOrders.add(saved);
    return saved;
  }

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings({
    String? startMonth,
    String? endMonth,
  }) async => plannings;
}

CategoryModel _category({String id = 'cat-1'}) => CategoryModel(
  id: id,
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#FF0000',
);

TransactionFormNotifier _notifier({
  required FakeAnalyticsService analytics,
  required FakeFinanceService financeService,
  InstallmentStatus status = InstallmentStatus.pending,
}) {
  return TransactionFormNotifier(
    TransactionFormState.creation(
      type: OrderType.expense,
      status: status,
      category: _category(),
      amount: 100,
      description: 'Compra do mês',
      date: DateTime(2026, 3, 10),
    ),
    financeService: financeService,
    categoryService: CategoryService(
      workspaceId: 'ws-test',
      repository: _UnusedCategoryRepository(),
    ),
    analytics: analytics,
  );
}

void main() {
  group('TransactionFormNotifier analytics', () {
    test('emite transaction_saved ao salvar o formulário', () async {
      final analytics = FakeAnalyticsService();
      final financeService = FakeFinanceService();

      await _notifier(
        analytics: analytics,
        financeService: financeService,
      ).submit();

      final event = analytics.find(AnalyticsEvents.transactionSaved);

      expect(event, isNotNull, reason: 'transaction_saved deveria ser emitido');
      expect(event!.params['status'], 'pending');
      expect(event.params['type'], 'expense');
      expect(event.params['had_planning'], isFalse);
      expect(financeService.savedOrders, hasLength(1));
    });

    test('had_planning é true quando a categoria tem planejamento no mês', () async {
      final analytics = FakeAnalyticsService();
      final financeService = FakeFinanceService(
        plannings: [
          CategoryPlanningModel(
            id: 'plan-1',
            category: _category(),
            amount: 500,
            startMonth: '2026-03',
            endMonth: '2099-12',
          ),
        ],
      );

      await _notifier(
        analytics: analytics,
        financeService: financeService,
      ).submit();

      expect(
        analytics.find(AnalyticsEvents.transactionSaved)!.params['had_planning'],
        isTrue,
      );
    });

    test('não emite installment_paid ao criar uma ordem pendente', () async {
      final analytics = FakeAnalyticsService();

      await _notifier(
        analytics: analytics,
        financeService: FakeFinanceService(),
      ).submit();

      expect(analytics.find(AnalyticsEvents.installmentPaid), isNull);
    });

    test('nenhum parâmetro carrega valor monetário, descrição ou id', () async {
      final analytics = FakeAnalyticsService();

      await _notifier(
        analytics: analytics,
        financeService: FakeFinanceService(),
      ).submit();

      final values = analytics
          .find(AnalyticsEvents.transactionSaved)!
          .params
          .values
          .map((v) => v.toString())
          .toList();

      expect(values, isNot(contains('100.0')));
      expect(values, isNot(contains('Compra do mês')));
      expect(values, isNot(contains('cat-1')));
      expect(values, isNot(contains('order-salva')));
    });
  });
}
