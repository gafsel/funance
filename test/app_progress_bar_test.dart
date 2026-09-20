import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';

/// B1 — a barra que não pintava.
///
/// O preenchimento era um filho SOLTO de um `Stack`: recebia constraints
/// frouxas e terminava num `DecoratedBox` sem filho, que se dimensiona pelo
/// menor tamanho possível. Resultado: altura zero. Toda barra de progresso do
/// app — missão, meta, XP, nível, categoria — desenhava só o trilho, e os
/// goldens gravaram a barra vazia como se fosse o desenho certo.
///
/// Por isso estes testes MEDEM a área pintada em vez de procurar o widget na
/// árvore: `findsOneWidget` passava antes e depois da correção. O que separa
/// o defeito do conserto é `getSize(...).height > 0`.

Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  double width = 400,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: bar)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Size _fill(WidgetTester tester) =>
    tester.getSize(find.byKey(AppProgressBar.fillKey));

void main() {
  group('AppProgressBar — o preenchimento tem área', () {
    for (final size in AppProgressSize.values) {
      testWidgets('${size.name}: o pintado tem a altura da barra', (
        tester,
      ) async {
        await _pump(
          tester,
          AppProgressBar(value: 0.5, size: size, animate: false),
        );

        expect(
          _fill(tester).height,
          size.height,
          reason:
              'o preenchimento vinha com altura 0 e a barra mostrava só o '
              'trilho',
        );
      });
    }

    testWidgets('a largura pintada segue a fração', (tester) async {
      await _pump(
        tester,
        const AppProgressBar(value: 0.25, animate: false),
      );

      expect(_fill(tester).width, closeTo(100, 0.5));
    });

    testWidgets('valor acima de 1 enche a barra, não estoura o trilho', (
      tester,
    ) async {
      await _pump(tester, const AppProgressBar(value: 1.8, animate: false));

      expect(_fill(tester).width, closeTo(400, 0.5));
    });

    testWidgets('NaN não vira barra cheia nem exceção', (tester) async {
      await _pump(
        tester,
        AppProgressBar(value: double.nan, animate: false),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(AppProgressBar.fillKey),
        findsNothing,
        reason: 'fração zero não pinta retângulo nenhum',
      );
    });

    testWidgets('a barra animada termina com a área certa', (tester) async {
      await _pump(tester, const AppProgressBar(value: 0.75));

      expect(_fill(tester).height, AppProgressSize.medium.height);
      expect(_fill(tester).width, closeTo(300, 0.5));
    });

    testWidgets('a barra de recompensa também pinta', (tester) async {
      await _pump(
        tester,
        const AppProgressBar.reward(
          value: 0.4,
          size: AppProgressSize.thick,
        ),
      );

      expect(_fill(tester).height, AppProgressSize.thick.height);
      expect(_fill(tester).width, closeTo(160, 0.5));
    });
  });

  group('AppPoolBar — as faixas têm área', () {
    /// As faixas pintadas, na ordem da linha. O trilho de fundo é o primeiro
    /// `ColoredBox` da pilha e fica de fora.
    List<Size> faixas(WidgetTester tester) => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .skip(1)
        .map((box) => tester.getSize(find.byWidget(box)))
        .toList(growable: false);

    testWidgets('faixa SEM rótulo ocupa a altura inteira', (tester) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.5, color: AppColors.pool50),
            PoolSegment(fraction: 0.5, color: AppColors.pool30),
          ],
        ),
      );

      expect(
        faixas(tester).map((s) => s.height),
        everyElement(16.0),
        reason:
            'sem rótulo a faixa era um ColoredBox sem filho: altura zero, '
            'barra invisível',
      );
    });

    testWidgets('com rótulo a altura é a da barra, não a do texto', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 24,
          segments: [
            PoolSegment(fraction: 0.6, color: AppColors.pool50, label: '60%'),
            PoolSegment(fraction: 0.4, color: AppColors.pool30, label: '40%'),
          ],
        ),
      );

      expect(faixas(tester).map((s) => s.height), everyElement(24.0));
    });

    testWidgets('um pool minúsculo continua sendo um fio visível', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 12,
          segments: [
            PoolSegment(fraction: 0.9995, color: AppColors.pool50),
            // 0,05% arredondava para flex 0 e a faixa sumia.
            PoolSegment(fraction: 0.0005, color: AppColors.pool20),
          ],
        ),
      );

      final larguras = faixas(tester).map((s) => s.width).toList();
      expect(larguras.last, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  /// Item 6 — a barra desenhava e ninguém via ONDE ela terminava.
  ///
  /// O trilho era sempre a cor de linha do tema, uma cinza pálida, e a tinta
  /// de uma barra colorida costuma ser clara também: ouro sobre `lineLight`
  /// dá 1,22:1. A barra da missão CUMPRIDA — a que mais importa — era a
  /// única que não se via. O mesmo valia para o gradiente padrão, que é a
  /// versão para fundo escuro e vivia sobre papel claro.
  group('o preenchimento se separa do trilho', () {
    const piso = 3.0;

    void exige(String oque, Color fill, Color track, Color superficie) {
      final razao = AppColors.contrastRatio(
        fill,
        Color.alphaBlend(track, superficie),
      );
      expect(
        razao,
        greaterThanOrEqualTo(piso),
        reason: '$oque: ${razao.toStringAsFixed(2)}:1, piso $piso:1',
      );
    }

    for (final entry in {
      'claro': AppPalette.light,
      'escuro': AppPalette.dark,
    }.entries) {
      final palette = entry.value;

      test('${entry.key}: cada tinta do tema contra o próprio trilho', () {
        final tintas = {
          'recompensa': palette.rewardText,
          'sucesso': palette.successText,
          'erro': palette.dangerText,
          'aviso': palette.warningText,
          'teal': palette.tealText,
          'tinta secundária': palette.ink2,
        };

        tintas.forEach((nome, tinta) {
          for (final superficie in [palette.paper, palette.paper2]) {
            exige(
              '$nome em ${entry.key}',
              tinta,
              AppProgressBar.trackFor(tinta),
              superficie,
            );
          }
        });
      });

      test('${entry.key}: o gradiente padrão contra a cor de linha', () {
        for (final ponta in palette.progressGradient.colors) {
          exige(
            'ponta do gradiente em ${entry.key}',
            ponta,
            palette.line,
            palette.paper,
          );
        }
      });
    }

    testWidgets('a barra colorida NÃO usa a cor de linha como trilho', (
      tester,
    ) async {
      await _pump(
        tester,
        AppProgressBar(
          value: 0.5,
          color: AppPalette.light.rewardText,
          animate: false,
        ),
      );

      final trilho = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(AppProgressBar),
          matching: find.byType(ColoredBox),
        ),
      );

      expect(trilho.color, AppProgressBar.trackFor(AppPalette.light.rewardText));
      expect(trilho.color, isNot(AppColors.lineLight));
    });

    testWidgets('um trilho pedido por quem chama continua mandando', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppProgressBar(
          value: 0.5,
          color: AppColors.violet,
          trackColor: AppColors.lineLight,
          animate: false,
        ),
      );

      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(AppProgressBar),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        AppColors.lineLight,
      );
    });
  });
}
