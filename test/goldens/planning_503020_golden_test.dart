import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/controllers/planning_50_30_20_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/planning_50_30_20_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

import 'golden_support.dart';

/// F4.8 §5.5 — `_PoolWidget._buildPoolHeader` tinha 261 linhas de gráfico
/// desenhado à mão (barra de planejado, barra de real e a linha da meta em
/// `Positioned`). É o bloco mais sensível a um pixel fora do lugar do pacote
/// inteiro, e o único jeito honesto de conferir a extração é comparar a
/// imagem.
///
/// O mês é fixado em março/2026: o notifier nasce em `DateTime.now()` e a
/// `AppBar` escreve o mês por extenso — um golden que muda de "março de 2026"
/// para "setembro de 2026" quebraria sozinho, sem ninguém ter mexido na tela.

class _PlanejamentosFake with NaoUsado implements CategoryPlanningService {
  _PlanejamentosFake(this.itens);

  final List<CategoryPlanningModel> itens;

  @override
  Future<List<CategoryPlanningModel>> plannings({required String month}) async =>
      itens;
}

class _ResumoFake with NaoUsado implements PeriodSummaryService {
  _ResumoFake(this.categorias);

  final Map<String, PeriodSummaryCategoryModel> categorias;

  @override
  Stream<PeriodSummaryModel?> watchMonth(int year, int month) => Stream.value(
    PeriodSummaryModel.month(
      year: year,
      month: month,
      categories: categorias,
      lastUpdate: goldenToday,
    ),
  );
}

final _categorias = [
  goldenCategory(
    id: 'moradia',
    name: 'Moradia',
    icon: 'home',
    color: '#1565C0',
    allocation: CategoryAllocation.essential,
  ),
  goldenCategory(
    id: 'mercado',
    name: 'Mercado',
    icon: 'shopping_cart',
    color: '#2E7D32',
    allocation: CategoryAllocation.essential,
  ),
  goldenCategory(
    id: 'lazer',
    name: 'Lazer',
    icon: 'movie',
    color: '#C62828',
    allocation: CategoryAllocation.comfort,
  ),
  goldenCategory(
    id: 'aportes',
    name: 'Aportes',
    icon: 'savings',
    color: '#6A1B9A',
    allocation: CategoryAllocation.investment,
  ),
  goldenCategory(
    id: 'salario',
    name: 'Salário',
    icon: 'payments',
    color: '#00695C',
    type: CategoryType.income,
  ),
];

final _resumo = <String, PeriodSummaryCategoryModel>{
  'moradia': const PeriodSummaryCategoryModel(
    specificPlannedAmount: 1500,
    actualAmount: 1450,
  ),
  'mercado': const PeriodSummaryCategoryModel(
    specificPlannedAmount: 800,
    actualAmount: 920,
  ),
  'lazer': const PeriodSummaryCategoryModel(
    specificPlannedAmount: 300,
    actualAmount: 410,
  ),
  'aportes': const PeriodSummaryCategoryModel(
    specificPlannedAmount: 600,
    actualAmount: 600,
  ),
  'salario': const PeriodSummaryCategoryModel(
    specificPlannedAmount: 5000,
    actualAmount: 5000,
  ),
};

final _planejamentos = [
  CategoryPlanningModel(
    id: 'p-moradia',
    category: _categorias[0],
    amount: 1600,
    startMonth: '2026-03',
    endMonth: '2026-03',
  ),
  CategoryPlanningModel(
    id: 'p-lazer',
    category: _categorias[2],
    amount: 250,
    startMonth: '2026-03',
    endMonth: '2026-03',
  ),
];

Planning503020Service _service() => Planning503020Service(
  planningService: _PlanejamentosFake(_planejamentos),
  categoryService: CategoryService(
    workspaceId: 'ws-golden',
    repository: FakeCategoryRepository(categories: _categorias),
  ),
  periodSummaryService: _ResumoFake(_resumo),
);

/// Mesmo notifier de produção, com o mês fixado depois da assinatura: o
/// serviço falso ignora a data, então só a `AppBar` muda.
class _NotifierEmMarco extends Planning503020Notifier {
  _NotifierEmMarco({required super.planning503020Service}) {
    state = state.copyWith(date: DateTime(2026, 3));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    goldenApp(
      const Planning503020Screen(),
      brightness: brightness,
      overrides: goldenOverrides(
        categories: _categorias,
        extra: [
          FinanceViewProviders.planning503020Service.overrideWithValue(
            _service(),
          ),
          FinanceViewProviders.planning503020.overrideWith(
            (ref) => _NotifierEmMarco(planning503020Service: _service()),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('50-30-20 — três pools lado a lado (desktop)', (tester) async {
    await setGoldenSurface(tester, const Size(1400, 900));
    await _pump(tester);

    await expectLater(
      find.byType(Planning503020Screen),
      matchesGoldenFile('images/planning_503020_desktop.png'),
    );
  });

  testWidgets('50-30-20 — abas (mobile)', (tester) async {
    await setGoldenSurface(tester, const Size(760, 1000));
    await _pump(tester);

    await expectLater(
      find.byType(Planning503020Screen),
      matchesGoldenFile('images/planning_503020_mobile.png'),
    );
  });

  // M7 — as quatro telas grandes só tinham golden no tema CLARO: metade das
  // superfícies do app não tinha rede nenhuma, e foi justamente no escuro que
  // a auditoria achou o pior contraste de texto do projeto.
  testWidgets('50-30-20 — três pools lado a lado (desktop, escuro)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(1400, 900));
    await _pump(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(Planning503020Screen),
      matchesGoldenFile('images/planning_503020_desktop_escuro.png'),
    );
  });

  testWidgets('50-30-20 — abas (mobile, escuro)', (tester) async {
    await setGoldenSurface(tester, const Size(760, 1000));
    await _pump(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(Planning503020Screen),
      matchesGoldenFile('images/planning_503020_mobile_escuro.png'),
    );
  });
}
