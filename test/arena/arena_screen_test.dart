import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';

import 'arena_harness.dart';

/// A cena monta, os números aparecem e os três toques levam a algum lugar.
///
/// Um `GameWidget` que não monta falha em SILÊNCIO: o Flame engole a exceção
/// do `onLoad` e a tela fica preta. Num POC que existe para ser sentida, tela
/// preta é o pior defeito possível — e o mais fácil de não notar numa revisão
/// de código.

/// Monta a Arena e ESPERA a folha de sprites decodificar.
///
/// O `runAsync` não é firula: decodificar um PNG é trabalho real da engine, e
/// o relógio falso do `flutter_test` nunca entrega o resultado do codec. Sem
/// ele o `onLoad` fica pendente para sempre, a cena não monta e o teste
/// "passa" olhando para um `GameWidget` vazio.
Future<void> pumpArena(
  WidgetTester tester, {
  ArenaState? state,
  Size size = const Size(420, 860),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(arenaApp(state ?? arenaTestState()));
    // Quadro falso + espera REAL, alternados: o quadro deixa o `GameWidget`
    // pedir o carregamento, e a espera é o único jeito de o codec de imagem
    // — que roda fora do relógio falso — devolver a folha.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  });

  await frames(tester);
}

/// Alguns quadros, com tempo, em vez de `pumpAndSettle`.
///
/// Um `GameWidget` NUNCA assenta: o laço do Flame agenda um quadro atrás do
/// outro para sempre, e `pumpAndSettle` estoura o tempo em vez de esperar a
/// animação que interessa. Quadros contados são o que serve aqui.
Future<void> frames(WidgetTester tester, {int count = 8}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('a cena monta e o jogo carrega a folha de sprites', (
    tester,
  ) async {
    await pumpArena(tester);

    expect(find.byType(GameWidget<ArenaGame>), findsOneWidget);

    final game = tester
        .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
        .game!;

    expect(game.isLoaded, isTrue, reason: 'o onLoad precisa ter terminado');
    expect(
      game.isSceneReady,
      isTrue,
      reason: 'sem monstro não há cena — e o Flame não reclamaria',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('as duas barras mostram vida do herói e do monstro', (
    tester,
  ) async {
    await pumpArena(tester);

    expect(find.byType(ArenaHpBar), findsNWidgets(2));

    // Herói = 5.000 de caixa − 1.930 comprometido. Monstro = 1.930.
    expect(find.textContaining('3.070'), findsOneWidget);
    expect(find.textContaining('1.930'), findsOneWidget);
  });

  testWidgets('tocar na barra de vida abre o planejamento', (tester) async {
    await pumpArena(tester);

    await tester.tap(find.byType(ArenaHpBar).first);
    await frames(tester);

    expect(find.text('plano'), findsOneWidget);
  });

  testWidgets('tocar na barra do monstro abre a folha de parcelas', (
    tester,
  ) async {
    await pumpArena(tester);

    await tester.tap(find.byType(ArenaHpBar).last);
    await frames(tester);

    expect(find.byType(ArenaMonsterSheet), findsOneWidget);
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('Luz'), findsOneWidget);
    expect(find.text('Confirmar pago'), findsNWidgets(2));
  });

  testWidgets('o monstro enfurecido carrega a cicatriz do atraso', (
    tester,
  ) async {
    await pumpArena(tester, state: arenaTestState(overdueAmount: 640));

    expect(find.textContaining('Enfurecido'), findsOneWidget);
    expect(find.textContaining('640'), findsOneWidget);
  });

  testWidgets('sem parcela pendente o monstro aparece como fugido', (
    tester,
  ) async {
    await pumpArena(
      tester,
      state: arenaTestState(installmentsRemaining: 0, pending: const []),
    );

    expect(find.text('Fugiu ferido'), findsOneWidget);
  });

  testWidgets('semana sem nada: estado vazio em vez de arena deserta', (
    tester,
  ) async {
    await pumpArena(
      tester,
      state: arenaTestState(
        liquidBalance: 0,
        installmentsInitial: 0,
        installmentsRemaining: 0,
        budgetInitial: 0,
        budgetRemaining: 0,
        pending: const [],
      ),
    );

    expect(find.byType(GameWidget<ArenaGame>), findsNothing);
    expect(find.textContaining('arena está vazia'), findsOneWidget);
  });

  testWidgets('a cena cabe numa janela larga sem estourar o layout', (
    tester,
  ) async {
    await pumpArena(tester, size: const Size(1280, 800));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameWidget<ArenaGame>), findsOneWidget);
  });
}
