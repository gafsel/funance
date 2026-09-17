import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/controllers/planning_50_30_20_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// F4.5 (QA) — o `listen` do 50-30-20 não tinha `onError`: a falha do stream
/// sumia, `isLoading` ficava `true` para sempre e a tela desenhava as três
/// pools vazias, como se o usuário não tivesse planejado nada.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _CategoriasQueFalham with _NaoUsado implements ICategoryRepository {
  _CategoriasQueFalham({required this.falha});

  bool falha;
  int leituras = 0;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    leituras++;
    if (falha) {
      return Stream<List<CategoryModel>>.error(
        Exception('sem rede'),
        StackTrace.current,
      );
    }
    return Stream.value(const <CategoryModel>[]);
  }
}

class _PlanejamentosVazios with _NaoUsado implements CategoryPlanningService {
  @override
  Future<List<CategoryPlanningModel>> plannings({required String month}) async =>
      const [];
}

class _ResumoVazio with _NaoUsado implements PeriodSummaryService {
  @override
  Stream<PeriodSummaryModel?> watchMonth(int year, int month) =>
      Stream.value(null);
}

void main() {
  Planning503020Notifier notifierCom(_CategoriasQueFalham categorias) {
    return Planning503020Notifier(
      planning503020Service: Planning503020Service(
        planningService: _PlanejamentosVazios(),
        categoryService: CategoryService(
          workspaceId: 'w1',
          repository: categorias,
        ),
        periodSummaryService: _ResumoVazio(),
      ),
    );
  }

  test('falha na leitura vira erro no estado, e não pools vazias', () async {
    final categorias = _CategoriasQueFalham(falha: true);
    final notifier = notifierCom(categorias);
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.error, isNotNull);
    // E o carregamento TERMINOU: um spinner eterno também não é resposta.
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.items, isEmpty);
  });

  test('retry reassina a leitura e limpa o erro quando a rede volta', () async {
    final categorias = _CategoriasQueFalham(falha: true);
    final notifier = notifierCom(categorias);
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.error, isNotNull);
    expect(categorias.leituras, 1);

    categorias.falha = false;
    notifier.retry();
    await Future<void>.delayed(Duration.zero);

    expect(categorias.leituras, 2);
    expect(notifier.state.error, isNull);
    expect(notifier.state.isLoading, isFalse);
  });
}
