import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/presentation/controllers/category_planning_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// F3.2 — "Definir limite para {categoria}" precisa chegar na tela de
/// planejamento com a resposta quase pronta. Cair numa lista de trinta
/// categorias, sem saber qual era e com o campo vazio, desfaria o convite.
class _FakeFinanceRepository implements IFinanceRepository {
  _FakeFinanceRepository([this.plannings = const []]);

  final List<CategoryPlanningModel> plannings;
  final List<CategoryPlanningModel> created = [];
  final List<CategoryPlanningModel> updated = [];

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  }) async => plannings;

  @override
  Future<void> addCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    created.add(planning);
  }

  @override
  Future<void> updateCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    updated.add(planning);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeCategoryRepository implements ICategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<CategoryModel> categories;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CategoryModel _category(String id) => CategoryModel(
  id: id,
  name: id,
  icon: 'category',
  color: '#333333',
);

final _categories = [
  _category('aluguel'),
  _category('lazer'),
  _category('mercado'),
];

CategoryPlanningNotifier _notifier(
  _FakeFinanceRepository repository, {
  String? highlightCategoryId,
  double? suggestedAmount,
}) {
  return CategoryPlanningNotifier(
    planningService: CategoryPlanningService(
      workspaceId: 'w1',
      repository: repository,
    ),
    categoryService: CategoryService(
      workspaceId: 'w1',
      repository: _FakeCategoryRepository(_categories),
    ),
    analytics: const NoopAnalyticsService(),
    type: CategoryType.expense,
    date: DateTime(2026, 9, 16),
    highlightCategoryId: highlightCategoryId,
    suggestedAmount: suggestedAmount,
  );
}

/// O notifier carrega no construtor; um `pump` de microtasks basta.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a categoria do convite vem primeiro, com o valor sugerido', () async {
    final repository = _FakeFinanceRepository();
    final notifier = _notifier(
      repository,
      highlightCategoryId: 'mercado',
      suggestedAmount: 370,
    );

    await _settle();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.highlightCategoryId, 'mercado');
    expect(notifier.state.items.first.category.id, 'mercado');
    expect(notifier.state.items.first.amount, 370);
    // Já nasce sujo: salvar sem tocar em nada grava a sugestão.
    expect(notifier.state.items.first.isDirty, isTrue);
  });

  test('a sugestão não sobrescreve um limite que o usuário já definiu', () async {
    final repository = _FakeFinanceRepository([
      CategoryPlanningModel(
        id: 'p1',
        category: _category('mercado'),
        amount: 900,
        startMonth: '2026-01',
        endMonth: CategoryPlanningService.openEndMonth,
      ),
    ]);

    final notifier = _notifier(
      repository,
      highlightCategoryId: 'mercado',
      suggestedAmount: 370,
    );

    await _settle();

    final item = notifier.state.items.first;
    expect(item.category.id, 'mercado');
    expect(item.amount, 900, reason: 'a decisão do usuário manda');
    expect(item.isDirty, isFalse);
  });

  test('sem categoria destacada a lista mantém a ordem de sempre', () async {
    final notifier = _notifier(_FakeFinanceRepository());

    await _settle();

    expect(
      notifier.state.items.map((item) => item.category.id),
      ['aluguel', 'lazer', 'mercado'],
    );
    expect(notifier.state.highlightCategoryId, isNull);
    expect(notifier.state.items.every((item) => !item.isDirty), isTrue);
  });

  test('salvar grava o limite sugerido sem o usuário digitar nada', () async {
    final repository = _FakeFinanceRepository();
    final notifier = _notifier(
      repository,
      highlightCategoryId: 'mercado',
      suggestedAmount: 370,
    );

    await _settle();
    await notifier.submit();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.category.id, 'mercado');
    expect(repository.created.single.amount, 370);
    expect(repository.created.single.startMonth, '2026-09');
  });
}
