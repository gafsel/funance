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
/// O rótulo voltou com um piso, e o piso é o ponto delicado: se ele valesse
/// para qualquer faixa, um pool de 3% renderia um "3%" cortado ao meio — um
/// número pela metade mente mais do que a ausência dele.
///
/// M5: o piso era uma FRAÇÃO do trilho (15%), e fração não é largura. 15% de
/// uma barra de 200px são 30 pixels, onde "62%" não cabe; 8% de uma barra de
/// 900px são 72, onde caberia com folga. O mesmo número dizia sim e não para
/// a mesma situação dependendo do tamanho da tela. Agora o piso é a largura
/// medida do segmento, e o texto também é medido — um rótulo longo não é mais
/// cortado em silêncio por um `TextOverflow.clip`.
///
/// Estes testes prendem as duas metades da regra: o que aparece na tela tem
/// piso, o que o leitor de tela ouve não tem.

Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  double width = 400,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: bar),
        ),
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

    testWidgets('faixa estreita DEMAIS não entra cortada', (tester) async {
      // 6% de 400px são 24 pixels: abaixo do piso de 40.
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            PoolSegment(fraction: 0.62, color: AppColors.pool50, label: '62%'),
            PoolSegment(fraction: 0.32, color: AppColors.pool30, label: '32%'),
            PoolSegment(fraction: 0.06, color: AppColors.pool20, label: '6%'),
          ],
        ),
      );

      expect(
        find.text('6%'),
        findsNothing,
        reason: 'meio número é pior do que nenhum',
      );
    });

    testWidgets('M5 — a MESMA fração cabe numa barra larga e não numa curta', (
      tester,
    ) async {
      const barra = AppPoolBar(
        height: 16,
        segments: [
          PoolSegment(fraction: 0.88, color: AppColors.pool50, label: '88%'),
          PoolSegment(fraction: 0.12, color: AppColors.pool20, label: '12%'),
        ],
      );

      // 12% de 200px = 24 pixels: não cabe.
      await _pump(tester, barra, width: 200);
      expect(find.text('12%'), findsNothing);

      // 12% de 900px = 108 pixels: cabe com folga. Com o piso em fração, os
      // dois casos respondiam a mesma coisa.
      await _pump(tester, barra, width: 900);
      expect(find.text('12%'), findsOneWidget);
    });

    testWidgets('M5 — rótulo longo não é cortado em silêncio', (tester) async {
      await _pump(
        tester,
        const AppPoolBar(
          height: 16,
          segments: [
            // 20% de 400px são 80 pixels: passa do piso de 40, mas não
            // comporta "Essenciais 62%".
            PoolSegment(
              fraction: 0.2,
              color: AppColors.pool50,
              label: 'Essenciais 62%',
            ),
            PoolSegment(fraction: 0.8, color: AppColors.pool30, label: '80%'),
          ],
        ),
      );

      expect(
        find.text('Essenciais 62%'),
        findsNothing,
        reason:
            'o piso de largura sozinho deixava passar; o `TextOverflow.clip` '
            'transformava o rótulo em "Essencia"',
      );
      expect(find.text('80%'), findsOneWidget);
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
