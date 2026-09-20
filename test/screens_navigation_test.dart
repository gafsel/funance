import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/presentation/screens/automatic_transactions_screen.dart';
import 'package:funances/features/goal/presentation/screen/goals_screen.dart';
import 'package:funances/features/home/presentation/screens/missions_screen.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_card.dart';
import 'package:funances/features/home/presentation/widgets/missions/week_checklist.dart';
import 'package:funances/features/home/presentation/widgets/missions/weekly_xp.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scene_icons.dart';

import 'arena/arena_harness.dart';
import 'support/home_harness.dart';

/// M3 — as telas que a Home passou a abrir.
///
/// A Home v2 ficou curta porque três blocos saíram dela: a semana de missões,
/// a lista de metas e a fila de pendências. Cada um virou uma tela, e uma tela
/// tem duas obrigações que um bloco não tinha: ser ALCANÇÁVEL a partir de
/// onde ela estava, e ter saída quando se chega nela por fora — um deep link,
/// uma notificação, um refresh na web. Sem histórico, `Navigator.pop` não tem
/// para onde ir e o botão de voltar vira um botão morto.

Future<void> _pump(
  WidgetTester tester, {
  required String em,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    homeRouterApp(
      overrides: overrides.isEmpty ? homeOverrides() : overrides,
      router: homeRouter(initialLocation: em),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// A primeira aba — que é a CENA — dentro do router de teste.
///
/// `runAsync` porque a folha de sprites do Flame é decodificada pelo relógio
/// de verdade: sem ela a cena nunca termina de montar e os ícones da lateral
/// não existem.
Future<void> _pumpCena(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      homeRouterApp(
        overrides: overrides,
        router: homeRouter(initialLocation: '/jornada'),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  });

  await arenaFrames(tester);
}

/// Toca num ícone da lateral da cena pelo pictograma dele.
Future<void> _tocarIcone(WidgetTester tester, IconData icone) async {
  await tester.tap(
    find.byWidgetPredicate((w) => w is ArenaSceneIcon && w.icon == icone),
  );
  await arenaFrames(tester, count: 20);
}

void main() {
  group('MissionsScreen', () {
    testWidgets('abre pelo pergaminho da cena, passando pela folha', (
      tester,
    ) async {
      // O caminho inteiro da decisão 7: o bloco de missões virou um ícone na
      // lateral da cena; o ícone abre a folha com o MESMO resumo que estava
      // na Home; e o cabeçalho do resumo continua sendo a porta da semana.
      await _pumpCena(
        tester,
        overrides: arenaOverrides(missions: homeTypicalMissions()),
      );

      expect(find.byType(MissionsScreen), findsNothing);

      await _tocarIcone(tester, Icons.menu_book_rounded);
      await tester.tap(find.text('Missões Semanais'));
      await arenaFrames(tester, count: 20);

      expect(
        find.byType(MissionsScreen),
        findsOneWidget,
        reason:
            'sem esta porta, o checklist e o XP da semana saíram da Home '
            'para lugar nenhum',
      );
    });

    testWidgets('tem o que saiu da Home: cartões, XP e checklist', (
      tester,
    ) async {
      await _pump(
        tester,
        em: '/missions',
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(find.byType(MissionCard), findsNWidgets(3));
      expect(find.byType(WeeklyXp), findsOneWidget);
      expect(find.byType(WeekChecklist), findsOneWidget);
    });
  });

  group('a saída de quem chega por fora', () {
    for (final tela in const {
      '/missions': MissionsScreen,
      '/goals': GoalsScreen,
      '/automatic-transactions': AutomaticTransactionsScreen,
    }.entries) {
      testWidgets('M3 — $tela volta para a raiz sem histórico', (tester) async {
        await _pump(tester, em: tela.key);

        expect(find.byType(tela.value), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(
          find.text('a raiz do app'),
          findsOneWidget,
          reason:
              'sem histórico o `pop` não tem para onde ir, e o botão de '
              'voltar vira um botão morto',
        );
        expect(find.byType(tela.value), findsNothing);
      });
    }

    testWidgets('e com histórico, volta para de onde veio', (tester) async {
      await _pumpCena(
        tester,
        overrides: arenaOverrides(missions: homeTypicalMissions()),
      );

      await _tocarIcone(tester, Icons.menu_book_rounded);
      await tester.tap(find.text('Missões Semanais'));
      await arenaFrames(tester, count: 20);
      expect(find.byType(MissionsScreen), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await arenaFrames(tester, count: 20);

      expect(
        find.text('a raiz do app'),
        findsNothing,
        reason: 'a cena é de onde veio; a raiz seria um salto para trás',
      );
      expect(find.byType(MissionsScreen), findsNothing);
    });
  });

  group('AutomaticTransactionsScreen', () {
    testWidgets('B3 — lista TODAS, com ignorar e mover', (tester) async {
      await _pump(
        tester,
        em: '/automatic-transactions',
        overrides: homeOverrides(
          pendingAutomatic: homeTypicalPending(count: 5),
          outroCofre: true,
        ),
      );

      expect(
        find.textContaining('COMPRA CARTAO'),
        findsNWidgets(5),
        reason: 'a Home mostra três; a tela é onde estão as outras',
      );

      // As duas ações que a linha compacta da Home NÃO tem, e que eram o
      // motivo de a tela precisar de uma porta.
      expect(find.text('Ignorar'), findsNWidgets(5));
      expect(find.byIcon(Icons.swap_horiz), findsNWidgets(5));
      expect(find.text('Cadastrar'), findsNWidgets(5));
    });

    testWidgets('B3 — sem um segundo cofre, mover não é oferecido', (
      tester,
    ) async {
      await _pump(
        tester,
        em: '/automatic-transactions',
        overrides: homeOverrides(pendingAutomatic: homeTypicalPending(count: 2)),
      );

      expect(find.text('Ignorar'), findsNWidgets(2));
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
    });
  });

  /// Decisão 8 do dono: *"os lançamentos identificados podem ser uma opção
  /// extra do fab? como podemos retirar o card gigante da tela e ainda deixar
  /// o cadastro desses lançamentos fácil?"*
  ///
  /// O card saiu da Home, e a triagem ganhou DUAS portas: a principal é o
  /// botão de lançar, que está em todas as telas principais; a discreta é o
  /// ícone com o contador na lateral da cena. As metas, que perderam o bloco
  /// da Home na mesma mudança, ficaram na grade de estratégia do mesmo botão.
  group('as portas que saíram para o FAB', () {
    testWidgets('a opção "Lançamentos Identificados" abre a triagem', (
      tester,
    ) async {
      await _pump(
        tester,
        em: '/',
        overrides: homeOverrides(pendingAutomatic: homeTypicalPending()),
      );

      expect(find.byType(AutomaticTransactionsScreen), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.text('35'),
        findsOneWidget,
        reason: 'a opção leva o contador de pendências no canto do ícone',
      );

      await tester.tap(find.text('Lançamentos Identificados'));
      await tester.pumpAndSettle();

      expect(find.byType(AutomaticTransactionsScreen), findsOneWidget);
      expect(find.textContaining('COMPRA CARTAO'), findsNWidgets(35));
    });

    testWidgets('e a ferramenta "Metas" abre a lista', (tester) async {
      await _pump(
        tester,
        em: '/',
        overrides: homeOverrides(goals: homeTwoGoals()),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metas'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('Reserva de emergência'), findsOneWidget);
      expect(find.text('Trocar de carro'), findsOneWidget);
    });

    testWidgets('o ícone da cena é a porta discreta da mesma triagem', (
      tester,
    ) async {
      await _pumpCena(
        tester,
        overrides: arenaOverrides(
          pendingAutomatic: homeTypicalPending(count: 2),
        ),
      );

      expect(find.byType(AutomaticTransactionsScreen), findsNothing);

      await _tocarIcone(tester, Icons.auto_awesome);

      expect(find.byType(AutomaticTransactionsScreen), findsOneWidget);
    });
  });
}
