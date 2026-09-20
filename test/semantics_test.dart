import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/compass_strip.dart';
import 'package:funances/core/widgets/section_header.dart';

/// M6 — o que o leitor de tela encontra.
///
/// Três buracos, todos do mesmo tipo: o widget desenhava a informação e não a
/// DECLARAVA. Quem enxerga lê a hierarquia pelo tamanho da fonte, entende que
/// a linha abre porque tem uma seta, e associa a barra ao nome que está do
/// lado. Nada disso chega pela árvore de semântica sozinho.

/// A árvore de semântica só existe quando alguém a pede. O handle é fechado
/// aqui, e não num `addTearDown`: o framework confere handles abertos ANTES
/// de rodar os tear downs, e reprovaria o teste mesmo fazendo a coisa certa.
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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

/// `true` quando o nó que contém [finder] está marcado como cabeçalho.
bool _ehCabecalho(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).flagsCollection.isHeader;

void main() {
  group('SectionHeader', () {
    for (final caso in <String, SectionHeader>{
      'label': const SectionHeader.label('Preferências'),
      'withIcon': const SectionHeader.withIcon(
        title: 'Preferências',
        icon: Icons.tune,
      ),
      'sheet': const SectionHeader.sheet(
        title: 'Preferências',
        subtitle: 'som e vibração',
        icon: Icons.tune,
      ),
    }.entries) {
      testWidgets('M6 — ${caso.key} é um CABEÇALHO', (tester) async {
        await comLeitorDeTela(tester, () async {
          await _pump(tester, caso.value);

          expect(
            _ehCabecalho(
              tester,
              find.text(
                caso.key == 'label' ? 'PREFERÊNCIAS' : 'Preferências',
              ),
            ),
            isTrue,
            reason:
                'os gestos de "próximo cabeçalho" não encontravam nada: o app '
                'inteiro tinha zero nós de cabeçalho, e uma tela de '
                'configurações se lia como um texto corrido',
          );
        });
      });
    }

    testWidgets('o contador não vira cabeçalho junto', (tester) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const SectionHeader.withIcon(
            title: 'Emblemas',
            icon: Icons.emoji_events,
            trailing: SectionHeaderCounter(label: '3 / 12'),
          ),
        );

        expect(_ehCabecalho(tester, find.text('Emblemas')), isTrue);
        expect(
          _ehCabecalho(tester, find.text('3 / 12')),
          isFalse,
          reason: 'o contador é dado do cabeçalho, não um cabeçalho novo',
        );
      });
    });
  });

  group('CompassStrip', () {
    testWidgets('M6 — anuncia que é um botão, e se está aberta', (
      tester,
    ) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const SizedBox(
            width: 380,
            child: CompassStrip(
              title: 'Bússola',
              score: 48,
              tierLabel: 'Estrategista',
              components: [],
            ),
          ),
        );

        final fechada = tester.getSemantics(
          find.bySemanticsLabel('Bússola').first,
        );

        expect(fechada.flagsCollection.isButton, isTrue);
        expect(
          fechada.flagsCollection.isExpanded.toBoolOrNull(),
          isFalse,
          reason:
              'o estado precisa EXISTIR e estar fechado: quem não enxerga a '
              'seta não sabe se há mais embaixo',
        );
        expect(fechada.value, contains('48'));
        expect(fechada.value, contains('Estrategista'));
      });
    });

    testWidgets('M6 — e o estado muda ao abrir', (tester) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const SizedBox(
            width: 380,
            child: CompassStrip(
              title: 'Bússola',
              score: 48,
              tierLabel: 'Estrategista',
              initiallyExpanded: true,
              components: [],
            ),
          ),
        );

        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Bússola').first)
              .flagsCollection
              .isExpanded
              .toBoolOrNull(),
          isTrue,
        );
      });
    });
  });

  group('AppProgressBar', () {
    testWidgets('M6 — com rótulo, é UM nó que diz o nome e a fração', (
      tester,
    ) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const SizedBox(
            width: 200,
            child: AppProgressBar(
              value: 0.62,
              semanticLabel: 'Moradia',
              animate: false,
            ),
          ),
        );

        final node = tester.getSemantics(find.bySemanticsLabel('Moradia'));

        expect(node.label, 'Moradia');
        expect(node.value, '62%');
      });
    });

    testWidgets('M6 — sem rótulo, a barra não acrescenta ruído', (
      tester,
    ) async {
      await comLeitorDeTela(tester, () async {
        await _pump(
          tester,
          const SizedBox(
            width: 200,
            child: AppProgressBar(value: 0.62, animate: false),
          ),
        );

        expect(
          find.bySemanticsLabel('62%'),
          findsNothing,
          reason:
              'uma barra decorativa dentro de um bloco que já se descreve só '
              'acrescentaria um "62%" solto no meio da leitura',
        );
      });
    });
  });
}
