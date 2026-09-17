import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// Guarda os documentos de `category_planning` em memória, com a mesma
/// semântica de consulta do Firestore: um planejamento vale num mês quando
/// `startMonth <= mês <= endMonth`.
class _FakeFinanceRepository implements IFinanceRepository {
  _FakeFinanceRepository([List<CategoryPlanningModel> seed = const []]) {
    for (final planning in seed) {
      docs[planning.id] = planning;
    }
  }

  final Map<String, CategoryPlanningModel> docs = {};
  var _nextId = 0;

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  }) async {
    if (startMonth == null) return docs.values.toList();

    return docs.values
        .where(
          (planning) =>
              planning.startMonth.compareTo(startMonth) <= 0 &&
              planning.endMonth.compareTo(startMonth) >= 0,
        )
        .toList();
  }

  @override
  Future<void> addCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    // Como no Firestore, o id do documento é do servidor e o do modelo é
    // descartado.
    final id = 'doc-${_nextId++}';
    docs[id] = planning.copyWith(id: id);
  }

  @override
  Future<void> updateCategoryPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    docs[planning.id] = planning;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeCategoryRepository implements ICategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<CategoryModel> categories;
  final List<CategoryModel> updated = [];

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);

  @override
  Future<WriteOutcome> updateCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    updated.add(category);

    return WriteOutcome.confirmed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

const _mercado = CategoryModel(
  id: 'cat-mercado',
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#FF0000',
);

CategoryPlanningService _service(_FakeFinanceRepository repository) =>
    CategoryPlanningService(workspaceId: 'ws-test', repository: repository);

CategoryPlanningModel _planning({
  String id = 'plan-1',
  double amount = 500,
  String startMonth = '2026-01',
  String endMonth = CategoryPlanningService.openEndMonth,
}) => CategoryPlanningModel(
  id: id,
  category: _mercado,
  amount: amount,
  startMonth: startMonth,
  endMonth: endMonth,
);

void main() {
  group('CategoryPlanningService.previousMonth', () {
    test('volta um mês dentro do ano', () {
      expect(CategoryPlanningService.previousMonth('2026-09'), '2026-08');
    });

    test('janeiro volta para dezembro do ano anterior', () {
      expect(CategoryPlanningService.previousMonth('2026-01'), '2025-12');
    });
  });

  group('definir limite', () {
    test('cria um planejamento aberto quando não havia nenhum', () async {
      final repository = _FakeFinanceRepository();

      final changed = await _service(repository).setLimit(
        category: _mercado,
        amount: 800,
        month: '2026-09',
      );

      expect(changed, isTrue);
      expect(repository.docs, hasLength(1));

      final created = repository.docs.values.single;
      expect(created.amount, 800);
      expect(created.startMonth, '2026-09');
      expect(created.endMonth, CategoryPlanningService.openEndMonth);
    });

    test(
      'versiona: encerra o vigente no mês anterior e abre um novo',
      () async {
        final repository = _FakeFinanceRepository([
          _planning(amount: 500, startMonth: '2026-01'),
        ]);

        await _service(repository).setLimit(
          category: _mercado,
          amount: 800,
          month: '2026-09',
        );

        expect(repository.docs, hasLength(2));

        final anterior = repository.docs['plan-1']!;
        expect(anterior.amount, 500, reason: 'o histórico não é reescrito');
        expect(anterior.startMonth, '2026-01');
        expect(anterior.endMonth, '2026-08');

        final novo = repository.docs.values.firstWhere((p) => p.id != 'plan-1');
        expect(novo.amount, 800);
        expect(novo.startMonth, '2026-09');
        expect(novo.endMonth, CategoryPlanningService.openEndMonth);
      },
    );

    test('editar o limite do próprio mês não cria um segundo documento', () async {
      final repository = _FakeFinanceRepository([
        _planning(amount: 500, startMonth: '2026-09'),
      ]);

      await _service(repository).setLimit(
        category: _mercado,
        amount: 800,
        month: '2026-09',
      );

      expect(repository.docs, hasLength(1));
      expect(repository.docs['plan-1']!.amount, 800);
      expect(repository.docs['plan-1']!.startMonth, '2026-09');
    });

    test('valor igual ao vigente não grava nada', () async {
      final repository = _FakeFinanceRepository([_planning(amount: 500)]);

      final changed = await _service(repository).setLimit(
        category: _mercado,
        amount: 500,
        month: '2026-09',
      );

      expect(changed, isFalse);
      expect(repository.docs['plan-1']!.endMonth,
          CategoryPlanningService.openEndMonth);
    });

    test('zerar encerra o vigente sem abrir outro', () async {
      final repository = _FakeFinanceRepository([
        _planning(amount: 500, startMonth: '2026-01'),
      ]);

      final service = _service(repository);
      final changed = await service.setLimit(
        category: _mercado,
        amount: 0,
        month: '2026-09',
      );

      expect(changed, isTrue);
      expect(repository.docs, hasLength(1));
      expect(repository.docs['plan-1']!.endMonth, '2026-08');
      expect(await service.plannings(month: '2026-09'), isEmpty);
    });

    test('zerar uma categoria sem limite não grava nada', () async {
      final repository = _FakeFinanceRepository();

      final changed = await _service(repository).setLimit(
        category: _mercado,
        amount: 0,
        month: '2026-09',
      );

      expect(changed, isFalse);
      expect(repository.docs, isEmpty);
    });
  });

  test(
    'a tela simples e a 50-30-20 produzem o mesmo documento para o mesmo limite',
    () async {
      const month = '2026-09';
      const vigente = [
        CategoryPlanningModel(
          id: 'plan-1',
          category: _mercado,
          amount: 500,
          startMonth: '2026-01',
          endMonth: CategoryPlanningService.openEndMonth,
        ),
      ];

      // Caminho da tela simples `/planning`: um limite por categoria.
      final simples = _FakeFinanceRepository(List.of(vigente));
      await _service(simples).setLimits(
        month: month,
        limits: const [(category: _mercado, amount: 800)],
      );

      // Caminho da 50-30-20: mesma categoria, mesmo mês, mesmo valor.
      final cinquenta = _FakeFinanceRepository(List.of(vigente));
      final categoryRepository = _FakeCategoryRepository(const [_mercado]);

      await Planning503020Service(
        planningService: _service(cinquenta),
        categoryService: CategoryService(
          workspaceId: 'ws-test',
          repository: categoryRepository,
        ),
        periodSummaryService: PeriodSummaryService(
          workspaceId: 'ws-test',
          repository: _UnusedPeriodSummaryRepository(),
        ),
      ).savePlanning(
        [
          CategoryPlanning503020Item(
            category: _mercado,
            generalAmount: 800,
            planningId: 'plan-1',
            isDirty: true,
          ),
        ],
        DateTime(2026, 9, 15),
      );

      // Mesma forma dos dois lados: o vigente encerrado em agosto e um novo
      // aberto em setembro.
      expect(_shape(simples), _shape(cinquenta));
      expect(_shape(simples), [
        (amount: 500.0, startMonth: '2026-01', endMonth: '2026-08'),
        (
          amount: 800.0,
          startMonth: '2026-09',
          endMonth: CategoryPlanningService.openEndMonth,
        ),
      ]);
      expect(
        categoryRepository.updated,
        isEmpty,
        reason: 'a pool não mudou, então a categoria não é reescrita',
      );
    },
  );
}

List<({double amount, String startMonth, String endMonth})> _shape(
  _FakeFinanceRepository repository,
) =>
    repository.docs.values
        .map(
          (planning) => (
            amount: planning.amount,
            startMonth: planning.startMonth,
            endMonth: planning.endMonth,
          ),
        )
        .toList()
      ..sort((a, b) => a.startMonth.compareTo(b.startMonth));

class _UnusedPeriodSummaryRepository implements IPeriodSummaryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
