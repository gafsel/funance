import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/screens/arena_screen.dart';

import '../goldens/golden_support.dart';
import 'arena_harness.dart';

/// A Arena, desenhada.
///
/// A POC existe para ser SENTIDA, e não há como revisar "parece um jogo?" num
/// diff de texto. Estes quatro quadros são as capturas do relatório e, de
/// quebra, a rede que pega a cena abrindo preta — o defeito mais provável de
/// um `GameWidget` e o mais fácil de não notar.
///
/// Os ícones do Material saem como quadrados vazios, como em todos os goldens
/// deste projeto: a fonte de ícone mora no cache do SDK e não no repositório.
/// Ver `golden_support.dart`.

/// Monta a Arena num tamanho fixo e espera a folha de sprites decodificar.
Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  ArenaState? state,
  ThemeData? theme,
}) async {
  await setGoldenSurface(tester, size);

  await tester.runAsync(() async {
    await tester.pumpWidget(arenaApp(state ?? arenaTestState(), theme: theme));
    // `Duration.zero`: o quadro acontece SEM andar o relógio falso. É o que
    // torna a captura determinística — quantos quadros o jogo viveu antes de
    // a folha chegar passa a não importar, e só os quadros contados depois do
    // carregamento é que movem a respiração dos bonecos. Com `30ms` aqui, a
    // mesma captura saía diferente conforme a máquina decodificasse o PNG
    // mais rápido ou mais devagar.
    for (var i = 0; i < 20; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });

  // Quadros CONTADOS, e sempre os mesmos: a respiração dos bonecos é função
  // do tempo acumulado, então "quantos quadros" faz parte da captura.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('arena — celular, semana em aberto', (tester) async {
    await _pump(tester, size: const Size(390, 780));
    await expectLater(
      find.byType(ArenaScreen),
      matchesGoldenFile('images/arena_celular.png'),
    );
  });

  testWidgets('arena — celular, monstro enfurecido e herói exausto', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 780),
      state: arenaTestState(
        liquidBalance: 900,
        overdueAmount: 640,
        installmentsInitial: 2020,
        installmentsRemaining: 2020,
        invoiceAmount: 2340,
      ),
    );
    await expectLater(
      find.byType(ArenaScreen),
      matchesGoldenFile('images/arena_enfurecido.png'),
    );
  });

  testWidgets('arena — celular, monstro fugiu ferido', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 780),
      state: arenaTestState(
        installmentsRemaining: 0,
        budgetRemaining: 210,
        healedThisWeek: 4200,
        pending: const [],
      ),
    );
    await expectLater(
      find.byType(ArenaScreen),
      matchesGoldenFile('images/arena_fugiu.png'),
    );
  });

  testWidgets('arena — janela larga, tema escuro', (tester) async {
    await _pump(
      tester,
      size: const Size(1100, 720),
      theme: AppTheme.dark,
      state: arenaTestState(extraMembers: 2, invoiceAmount: 780),
    );
    await expectLater(
      find.byType(ArenaScreen),
      matchesGoldenFile('images/arena_desktop_escuro.png'),
    );
  });
}
