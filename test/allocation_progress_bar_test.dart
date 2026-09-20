import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/planning/allocation_progress_bar.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

import 'goldens/golden_support.dart';

/// Item 7 — os rótulos da barra de pool se montavam um sobre o outro.
///
/// A versão anterior desenhava planejado, real e meta como ÁREAS sobrepostas
/// na mesma barra, cada uma com o número pendurado embaixo da própria ponta.
/// Com o planejado em 12% e o real em 17% os dois rótulos caíam quase no
/// mesmo x e se sobrepunham letra sobre letra — o golden congelou "1720%".
///
/// Estes testes MEDEM as caixas de texto e cobram que elas não se
/// intersectem. É a única forma de prender sobreposição: nenhum
/// `findsOneWidget` nota que dois textos ocupam o mesmo pixel.

Future<void> _pump(
  WidgetTester tester, {
  required double planned,
  required double actual,
  required bool isOver,
  double width = 320,
}) async {
  await setGoldenSurface(tester, Size(width, 400));
  await tester.pumpWidget(
    goldenApp(
      Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: const AllocationProgressBar(
              allocation: CategoryAllocation.comfort,
            ),
          ),
        ),
      ),
      overrides: goldenOverrides(
        extra: [
          FinanceViewProviders.planning503020AllocationProgress(
            CategoryAllocation.comfort,
          ).overrideWithValue(
            CategoryAllocationProgressModel(
              currentTotal: 0,
              currentActual: 0,
              idealValue: 0,
              currentPercentage: planned,
              actualPercentage: actual,
              isWithinRange: !isOver,
              isOver: isOver,
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Rect> _caixasDeTexto(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => tester.getRect(find.byWidget(t)))
    .toList(growable: false);

void main() {
  testWidgets('os três números não se sobrepõem, nem com barras curtas', (
    tester,
  ) async {
    // O caso do golden: planejado e real quase no mesmo ponto.
    await _pump(tester, planned: 0.12, actual: 0.17, isOver: false);

    final caixas = _caixasDeTexto(tester);
    expect(caixas, hasLength(3));

    for (var i = 0; i < caixas.length; i++) {
      for (var j = i + 1; j < caixas.length; j++) {
        expect(
          caixas[i].overlaps(caixas[j]),
          isFalse,
          reason:
              'os rótulos ${i + 1} e ${j + 1} ocupam o mesmo espaço — era '
              'assim que "12,0%" e "17,0%" viravam "1720%"',
        );
      }
    }
  });

  testWidgets('e nem quando tudo está no zero', (tester) async {
    await _pump(tester, planned: 0, actual: 0, isOver: false);

    final caixas = _caixasDeTexto(tester);
    for (var i = 0; i < caixas.length; i++) {
      for (var j = i + 1; j < caixas.length; j++) {
        expect(caixas[i].overlaps(caixas[j]), isFalse);
      }
    }
  });

  testWidgets('a barra é a do design system, com o trilho derivado', (
    tester,
  ) async {
    await _pump(tester, planned: 0.4, actual: 0.35, isOver: false);

    final barra = tester.widget<AppProgressBar>(find.byType(AppProgressBar));

    expect(
      barra.color,
      AppPalette.light.successText,
      reason:
          'a barra era feita à mão, com `AnimatedContainer` e decoração '
          'própria',
    );

    final razao = AppColors.contrastRatio(
      barra.color!,
      Color.alphaBlend(
        AppProgressBar.trackFor(barra.color!),
        AppColors.paperLight,
      ),
    );
    expect(razao, greaterThanOrEqualTo(3));
  });

  testWidgets('estourado, a barra vira tinta de erro', (tester) async {
    await _pump(tester, planned: 0.4, actual: 0.9, isOver: true);

    expect(
      tester.widget<AppProgressBar>(find.byType(AppProgressBar)).color,
      AppPalette.light.dangerText,
    );
  });

  testWidgets('os marcadores ficam FORA da barra, um acima e um abaixo', (
    tester,
  ) async {
    await _pump(tester, planned: 0.3, actual: 0.3, isOver: false);

    final barra = tester.getRect(find.byType(AppProgressBar));
    final planejado = tester.getRect(find.byIcon(Icons.arrow_drop_down));
    final meta = tester.getRect(find.byIcon(Icons.arrow_drop_up));

    expect(
      planejado.center.dy,
      lessThan(barra.center.dy),
      reason: 'marcador sobre a barra é lavagem sobre lavagem, nunca 3:1',
    );
    expect(meta.center.dy, greaterThan(barra.center.dy));
    expect(
      planejado.overlaps(meta),
      isFalse,
      reason: 'dois marcadores em linhas diferentes não têm como colidir',
    );
  });

  testWidgets('fração absurda é presa na ponta, não sai da barra', (
    tester,
  ) async {
    await _pump(tester, planned: 3.5, actual: 0.5, isOver: true);

    final barra = tester.getRect(find.byType(AppProgressBar));
    final planejado = tester.getRect(find.byIcon(Icons.arrow_drop_down));

    expect(planejado.center.dx, lessThanOrEqualTo(barra.right));
    expect(planejado.center.dx, greaterThanOrEqualTo(barra.left));
  });
}
