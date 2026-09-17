import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';

/// F-design/3 — a barra de pools e o rótulo que a migração tinha perdido.
///
/// A barra antiga do 50/30/20 escrevia a porcentagem real dentro de cada
/// faixa, e era a única forma de ler "gastei 62% no essencial" sem abrir o
/// detalhe: a legenda de baixo mostra o ALVO (50/30/20), não o que aconteceu.
/// Ao virar componente compartilhado o rótulo sumiu, e o cartão passou a
/// mostrar três cores sem número nenhum.
///
/// O rótulo voltou com um piso de 15% do trilho. O piso é o ponto delicado:
/// se ele valesse para qualquer faixa, um pool de 3% renderia um "3%" cortado
/// ao meio — um número pela metade mente mais do que a ausência dele. Estes
/// testes prendem as duas metades da regra: o que aparece na tela tem piso, o
/// que o leitor de tela ouve não tem.

Future<void> _pump(WidgetTester tester, Widget bar) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(child: SizedBox(width: 400, child: bar)),
      ),
    ),
  );
  await tester.pump();
}

/// A árvore de semântica só existe quando alguém a pede; sem isto
/// `bySemanticsLabel` não acharia nada e o teste de leitor de tela passaria a
/// ser um teste de nada.
///
/// O handle é fechado AQUI, e não num `addTearDown`: o framework confere se
/// sobrou handle aberto antes de rodar os tear downs, e um `addTearDown`
/// reprova o teste mesmo fazendo a coisa certa.
Future<void> comLeitorDeTela(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void main() {
  group('AppPoolBar — rótulo dentro do segmento', () {
    testWidgets('faixa larga carrega a porcentagem real', (tester) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.62, color: AppColors.pool50, label: '62%'),
            PoolSegment(fraction: 0.25, color: AppColors.pool30, label: '25%'),
            PoolSegment(fraction: 0.13, color: AppColors.pool20, label: '13%'),
          ],
        ),
      );

      expect(find.text('62%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('abaixo de 15% o número não entra cortado', (tester) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.62, color: AppColors.pool50, label: '62%'),
            PoolSegment(fraction: 0.25, color: AppColors.pool30, label: '25%'),
            PoolSegment(fraction: 0.13, color: AppColors.pool20, label: '13%'),
          ],
        ),
      );

      expect(
        find.text('13%'),
        findsNothing,
        reason:
            '13% do trilho não comporta o rótulo; meio número é pior do que '
            'nenhum',
      );
    });

    testWidgets('exatamente no piso o rótulo já aparece', (tester) async {
      await _pump(
        tester,
        AppPoolBar(
          height: 16,
          segments: [
            const PoolSegment(
              fraction: 0.85,
              color: AppColors.pool50,
              label: '85%',
            ),
            PoolSegment(
              fraction: AppPoolBar.labelThreshold,
              color: AppColors.pool20,
              label: '15%',
            ),
          ],
        ),
      );

      expect(find.text('15%'), findsOneWidget);
    });

    testWidgets('a tinta do rótulo segue a luminância da faixa', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            // Âmbar: 7.58:1 com tinta escura, 2.06:1 com tinta clara.
            PoolSegment(fraction: 0.5, color: AppColors.pool30, label: 'A'),
            // Violeta: é o caso contrário, 4.31:1 com tinta clara.
            PoolSegment(fraction: 0.5, color: AppColors.violet, label: 'B'),
          ],
        ),
      );

      expect(
        tester.widget<Text>(find.text('A')).style?.color,
        AppColors.inkLight,
        reason:
            'o corte por luminância dava tinta clara ao âmbar e derrubava o '
            'contraste para 2.06:1',
      );
      expect(
        tester.widget<Text>(find.text('B')).style?.color,
        AppColors.inkInverse,
        reason: 'e uma tinta fixa escura quebraria o violeta',
      );
    });
  });

  group('AppPoolBar — o que o leitor de tela ouve', () {
    testWidgets('anuncia TODAS as faixas, largas ou não', (tester) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const AppPoolBar(
            height: 16,
            semanticLabel: 'Distribuição do mês',
            segments: [
              PoolSegment(
                fraction: 0.62,
                color: AppColors.pool50,
                label: 'Essenciais 62%',
              ),
              PoolSegment(
                fraction: 0.25,
                color: AppColors.pool30,
                label: 'Conforto 25%',
              ),
              PoolSegment(
                fraction: 0.03,
                color: AppColors.pool20,
                label: 'Futuro 3%',
              ),
            ],
          ),
        );

        expect(
          find.bySemanticsLabel(
            'Distribuição do mês, Essenciais 62%, Conforto 25%, Futuro 3%',
          ),
          findsOneWidget,
          reason:
              'o piso é de desenho, não de dado: quem não enxerga a barra não '
              'pode perder o pool que ficou estreito',
        );
      });
    });

    testWidgets('faixa zerada não vira ruído no anúncio', (tester) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const AppPoolBar(
            height: 16,
            semanticLabel: 'Distribuição do mês',
            segments: [
              PoolSegment(fraction: 0.7, color: AppColors.pool50, label: '70%'),
              PoolSegment(fraction: 0, color: AppColors.pool30, label: '0%'),
              PoolSegment(fraction: 0.3, color: AppColors.pool20, label: '30%'),
            ],
          ),
        );

        expect(
          find.bySemanticsLabel('Distribuição do mês, 70%, 30%'),
          findsOneWidget,
        );
      });
    });

    testWidgets('sem rótulo nenhum, a barra não inventa semântica', (
      tester,
    ) async {
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
        tester.widget<Semantics>(find.byType(Semantics).first).properties.label,
        isNull,
      );
    });
  });

  group('AppPoolBar — o trilho', () {
    testWidgets('o que sobra fica com a cor de linha, não com a do pool', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.4, color: AppColors.pool50, label: '40%'),
          ],
        ),
      );

      // A faixa pintada ocupa 40% dos 400px; o resto é trilho vazio.
      final segmento = tester.getSize(
        find
            .ancestor(of: find.text('40%'), matching: find.byType(ColoredBox))
            .first,
      );

      expect(segmento.width, closeTo(160, 1));
    });

    testWidgets('fração infinita não derruba o build', (tester) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.5, color: AppColors.pool50, label: '50%'),
            // Divisão por zero lá em cima (renda zerada) chega como NaN.
            PoolSegment(fraction: double.nan, color: AppColors.pool30),
            PoolSegment(fraction: double.infinity, color: AppColors.pool20),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
