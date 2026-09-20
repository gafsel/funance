import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';

import '../arena/hud_harness.dart';
import 'golden_support.dart';

/// As quatro folhas do HUD mensal — claro e escuro.
///
/// Elas concentram três decisões que são PINTURA e por isso não quebram teste
/// nenhum quando somem:
///
/// 1. o ícone do cabeçalho, que repete o da faixa no MESMO estado — anel,
///    tinta e, no ovo, o estágio da casca. É o que liga o toque ao que ele
///    abriu;
/// 2. a barra de HP de cada aldeão, que mostra a queda sem precisar da
///    palavra "morto": quem estourou fica com a calha inteira à mostra;
/// 3. a mini explicação em três frases, com a primeira em tinta principal e
///    as outras duas em tinta secundária. A hierarquia ali é a diferença
///    entre "leia isto" e "três parágrafos cinzas".
///
/// A folha da GOTA também é a única captura do estado sem receita prevista —
/// o aviso âmbar que substitui a classe quando o servidor ainda não sabe
/// quanto o usuário ganha.

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  required int indice,
  HudState? hud,
}) async {
  await loadAppFonts();

  await pumpHudFooter(
    tester,
    hud: hud,
    size: const Size(400, 900),
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
  );

  await tester.tap(find.byType(HudGlyph).at(indice));
  await tester.pumpAndSettle();
}

void main() {
  final folhas = <({String nome, int indice, String chave})>[
    (nome: 'hud_pocao', indice: 0, chave: 'hud-sheet-potion'),
    (nome: 'hud_vila', indice: 1, chave: 'hud-sheet-village'),
    (nome: 'hud_ovo', indice: 2, chave: 'hud-sheet-egg'),
    (nome: 'hud_gota', indice: 3, chave: 'hud-sheet-drop'),
  ];

  for (final folha in folhas) {
    for (final tema in Brightness.values) {
      final sufixo = tema == Brightness.dark ? '_escuro' : '';

      testWidgets('golden — ${folha.nome}$sufixo', (tester) async {
        await _pump(tester, brightness: tema, indice: folha.indice);

        await expectLater(
          find.byKey(ValueKey(folha.chave)),
          matchesGoldenFile('images/${folha.nome}$sufixo.png'),
        );
      });
    }
  }

  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — hud_sem_receita$sufixo', (tester) async {
      await _pump(
        tester,
        brightness: tema,
        indice: 3,
        hud: hudTestState(income: null),
      );

      await expectLater(
        find.byKey(const ValueKey('hud-sheet-drop')),
        matchesGoldenFile('images/hud_sem_receita$sufixo.png'),
      );
    });
  }
}
