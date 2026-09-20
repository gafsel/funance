import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
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

import 'goldens/golden_support.dart';

/// A1 / D5 — a aba aberta do 50-30-20 no tema claro.
///
/// A aba selecionada é pintada com `surfaceDeep`, a "pasta" escura que dá a
/// cara de fichário à tela. O conteúdo dela continuava lendo a paleta CLARA:
/// o rótulo saía em `ink` sobre fundo escuro — 1,23:1, praticamente
/// invisível — e o ícone de status em `successInk`/`dangerInk`, 2,02:1 e
/// 1,23:1, abaixo do piso de 3:1 de elemento gráfico. Era a aba ABERTA, a
/// única que interessa, a única ilegível. Foi o que o dono descreveu como
/// "no tema claro a fonte do 50-30-20 está errada".
///
/// Os dois primeiros testes afirmam a razão de contraste em vez de comparar
/// com a constante: assim continuam valendo quando alguém ajustar o
/// hexadecimal.

class _PlanejamentosFake with NaoUsado implements CategoryPlanningService {
  @override
  Future<List<CategoryPlanningModel>> plannings({required String month}) async =>
      const [];
}

class _ResumoFake with NaoUsado implements PeriodSummaryService {
  @override
  Stream<PeriodSummaryModel?> watchMonth(int year, int month) => Stream.value(
    PeriodSummaryModel.month(
      year: year,
      month: month,
      categories: const {
        // Essencial estourado: o ícone de estouro é o pior caso de contraste.
        'moradia': PeriodSummaryCategoryModel(
          specificPlannedAmount: 1000,
          actualAmount: 1800,
        ),
        'lazer': PeriodSummaryCategoryModel(
          specificPlannedAmount: 400,
          actualAmount: 200,
        ),
      },
      lastUpdate: goldenToday,
    ),
  );
}

final _categorias = [
  goldenCategory(id: 'moradia', name: 'Moradia'),
  goldenCategory(
    id: 'lazer',
    name: 'Lazer',
    allocation: CategoryAllocation.comfort,
  ),
  goldenCategory(
    id: 'aportes',
    name: 'Aportes',
    allocation: CategoryAllocation.investment,
  ),
];

Planning503020Service _service() => Planning503020Service(
  planningService: _PlanejamentosFake(),
  categoryService: CategoryService(
    workspaceId: 'ws',
    repository: FakeCategoryRepository(categories: _categorias),
  ),
  periodSummaryService: _ResumoFake(),
);

class _NotifierEmMarco extends Planning503020Notifier {
  _NotifierEmMarco({required super.planning503020Service}) {
    state = state.copyWith(date: DateTime(2026, 3));
  }
}

Future<void> _pumpMobile(WidgetTester tester) async {
  await setGoldenSurface(tester, const Size(760, 1000));
  await tester.pumpWidget(
    goldenApp(
      const Planning503020Screen(),
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

/// O estilo com que um texto foi REALMENTE desenhado, herança resolvida.
TextStyle _pintado(WidgetTester tester, String texto) {
  final paragraph =
      tester.renderObject(find.text(texto).first) as RenderParagraph;
  return paragraph.text.style!;
}

void main() {
  testWidgets('A1 — o rótulo da aba aberta se lê sobre a pasta escura', (
    tester,
  ) async {
    await _pumpMobile(tester);

    final cor = _pintado(tester, 'Essencial').color!;

    expect(
      AppColors.contrastRatio(cor, AppColors.surfaceDeep),
      greaterThanOrEqualTo(4.5),
      reason: 'a aba aberta escrevia em tinta de papel sobre a pasta escura',
    );
    expect(cor, AppColors.inkInverse);
  });

  testWidgets('A1 — a aba fechada continua legível sobre o papel', (
    tester,
  ) async {
    await _pumpMobile(tester);

    final cor = _pintado(tester, 'Conforto').color!;

    expect(
      AppColors.contrastRatio(cor, AppColors.paperLight),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('A1 — o sinal de estouro da aba aberta chega aos 3:1', (
    tester,
  ) async {
    await _pumpMobile(tester);

    final aviso = tester.widget<Icon>(
      find
          .descendant(
            of: find.byType(Tab).first,
            matching: find.byIcon(Icons.warning),
          )
          .first,
    );

    expect(
      AppColors.contrastRatio(aviso.color!, AppColors.surfaceDeep),
      greaterThanOrEqualTo(3),
      reason:
          'elemento gráfico tem piso de 3:1; `dangerInk` sobre a pasta dava '
          '1,23:1',
    );
  });

  testWidgets('D5 — a aba usa a tipografia de aba do design system', (
    tester,
  ) async {
    await _pumpMobile(tester);

    final estilo = _pintado(tester, 'Essencial');

    expect(
      estilo.fontFamily,
      'Inter',
      reason: 'rótulo de aba é texto, não display',
    );
    expect(
      estilo.fontSize,
      14,
      reason:
          'a tela escrevia as abas em `bodySmall` (12/peso 400) enquanto o '
          'resto do app usa `labelLarge`; de longe lia como outra fonte',
    );
    expect(estilo.fontWeight, FontWeight.w600);
  });

  testWidgets('D5 — o mês na AppBar é display, e é Fredoka', (tester) async {
    await _pumpMobile(tester);

    expect(_pintado(tester, '03/2026').fontFamily, 'Fredoka');
  });
}
