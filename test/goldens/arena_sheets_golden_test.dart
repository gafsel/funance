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
    // Os totais do cabeçalho saem da LISTA (ver `arenaTestState`): o golden
    // antigo fotografava um cabeçalho que não batia com as linhas embaixo.
    state: arenaTestState(
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
        // Débito automático já marcado para sexta: golpe agendado.
        arenaTestCommitment(
          id: 'seguro',
          description: 'Segurança C6',
          amount: 29.90,
          dayOffset: 2,
          scheduled: true,
        ),
      ],
    ),
  );

  await tester.tap(
    monstro ? find.byType(ArenaHpBar).last : find.byType(ArenaHpBar).first,
  );
  await arenaFrames(tester, count: 12);
}

/// A semana com uma fatura paga PELA METADE.
///
/// O caso real que reprovou a rodada 3: "Fatura [Gabriel] Cartão Inter",
/// R\$ 12.130,09 cobrados e R\$ 1.000 pagos. A linha carrega três decisões que
/// só existem em pixel — a meia espada, o "R\$ 1.000,00 de R\$ 12.130,09 —
/// falta R\$ 11.130,09" e o link de ajustar — e nenhuma delas tinha captura.
Future<void> _pumpParcial(
  WidgetTester tester, {
  required Brightness brightness,
}) async {
  await loadAppFonts();

  await pumpArena(
    tester,
    size: const Size(400, 800),
    theme: brightness == Brightness.dark ? AppTheme.dark : null,
    state: arenaTestState(
      commitments: [
        arenaTestCommitment(
          id: 'inter',
          description: 'Fatura [Gabriel] Cartão Inter',
          amount: 12130.09,
          partial: 1000,
          dayOffset: 2,
        ),
        arenaTestCommitment(
          id: 'c6',
          description: 'Fatura [Bárbara] Cartão C6',
          amount: 3942.04,
          partial: 3942.00,
          dayOffset: 3,
        ),
        arenaTestCommitment(
          id: 'luz',
          description: 'Luz',
          amount: 180,
          dayOffset: 4,
        ),
      ],
    ),
  );

  await tester.tap(find.byType(ArenaHpBar).last);
  await arenaFrames(tester, count: 12);
}

void main() {
  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — fatura paga pela metade$sufixo', (tester) async {
      await _pumpParcial(tester, brightness: tema);

      await expectLater(
        find.byType(ArenaMonsterSheet),
        matchesGoldenFile('images/arena_monstro_parcial$sufixo.png'),
      );
    });
  }

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
