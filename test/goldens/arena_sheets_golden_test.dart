import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/widgets/arena_heroes_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';

import '../arena/arena_harness.dart';
import 'golden_support.dart';

/// As duas folhas da Arena — claro e escuro.
///
/// A folha do monstro carrega a decisão visual mais frágil do pacote: a marca
/// do golpe. Ela é feita de QUATRO coisas ao mesmo tempo — a espada desenhada,
/// o corte diagonal por cima da linha, o texto riscado e a cor apagada — e
/// qualquer uma delas pode sumir sozinha num refactor sem quebrar teste
/// nenhum, porque as quatro são pintura. Um PNG é a única rede possível.
///
/// A folha dos heróis guarda a outra: a seta de "saldo de domingo → saldo de
/// agora", que é a semana inteira em um caractere.

Future<void> _pumpSheet(
  WidgetTester tester, {
  required Brightness brightness,
  required bool monstro,
}) async {
  await loadAppFonts();

  await pumpArena(
    tester,
    size: const Size(400, 800),
    theme: brightness == Brightness.dark ? AppTheme.dark : null,
    state: arenaTestState(
      commitmentsInitial: 2140,
      commitmentsRemaining: 820,
      overdueAmount: 640,
      commitments: [
        arenaTestCommitment(
          id: 'cartao',
          description: 'Fatura do cartão',
          amount: 640,
          dayOffset: -9,
          overdue: true,
        ),
        arenaTestCommitment(id: 'hoje', description: 'Aluguel'),
        arenaTestCommitment(
          id: 'internet',
          description: 'Internet',
          amount: 180,
          dayOffset: 2,
        ),
        arenaTestCommitment(
          id: 'academia',
          description: 'Academia',
          amount: 120,
          dayOffset: -1,
          paid: true,
        ),
      ],
    ),
  );

  await tester.tap(
    monstro ? find.byType(ArenaHpBar).last : find.byType(ArenaHpBar).first,
  );
  await arenaFrames(tester, count: 12);
}

void main() {
  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — detalhe do monstro$sufixo', (tester) async {
      await _pumpSheet(tester, brightness: tema, monstro: true);

      await expectLater(
        find.byType(ArenaMonsterSheet),
        matchesGoldenFile('images/arena_monstro$sufixo.png'),
      );
    });

    testWidgets('golden — detalhe dos heróis$sufixo', (tester) async {
      await _pumpSheet(tester, brightness: tema, monstro: false);

      await expectLater(
        find.byType(ArenaHeroesSheet),
        matchesGoldenFile('images/arena_herois$sufixo.png'),
      );
    });
  }
}
