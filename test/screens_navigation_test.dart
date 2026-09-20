import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/presentation/screens/automatic_transactions_screen.dart';
import 'package:funances/features/goal/presentation/screen/goals_screen.dart';
import 'package:funances/features/home/presentation/screens/missions_screen.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_card.dart';
import 'package:funances/features/home/presentation/widgets/missions/week_checklist.dart';
import 'package:funances/features/home/presentation/widgets/missions/weekly_xp.dart';

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

void main() {
  group('MissionsScreen', () {
    testWidgets('abre pelo cabeçalho do resumo da Home', (tester) async {
      await _pump(
        tester,
        em: '/jornada',
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(find.byType(MissionsScreen), findsNothing);

      await tester.tap(find.text('Missões Semanais'));
      await tester.pumpAndSettle();

      expect(
        find.byType(MissionsScreen),
        findsOneWidget,
        reason:
            'o resumo é a porta: sem ela, o checklist e o XP da semana '
            'saíram da Home para lugar nenhum',
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
      await _pump(
        tester,
        em: '/jornada',
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      await tester.tap(find.text('Missões Semanais'));
      await tester.pumpAndSettle();
      expect(find.byType(MissionsScreen), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.text('a raiz do app'),
        findsNothing,
        reason: 'a Jornada é de onde veio; a raiz seria um salto para trás',
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

  group('as portas da Home', () {
    testWidgets('B3 — "Ver as N pendências" abre a tela cheia', (
      tester,
    ) async {
      await _pump(
        tester,
        em: '/jornada',
        overrides: homeOverrides(pendingAutomatic: homeTypicalPending()),
      );

      expect(find.byType(AutomaticTransactionsScreen), findsNothing);

      await tester.tap(find.text('Ver as 35 pendências'));
      await tester.pumpAndSettle();

      expect(find.byType(AutomaticTransactionsScreen), findsOneWidget);
      expect(find.textContaining('COMPRA CARTAO'), findsNWidgets(35));
    });

    testWidgets('B3 — o cabeçalho das pendências abre a mesma tela', (
      tester,
    ) async {
      await _pump(
        tester,
        em: '/jornada',
        overrides: homeOverrides(
          pendingAutomatic: homeTypicalPending(count: 2),
        ),
      );

      await tester.tap(find.text('Lançamentos Identificados'));
      await tester.pumpAndSettle();

      expect(find.byType(AutomaticTransactionsScreen), findsOneWidget);
    });

    testWidgets('B3 — "Ver as N metas" abre a lista de metas', (tester) async {
      await _pump(
        tester,
        em: '/jornada',
        overrides: homeOverrides(goals: homeTwoGoals()),
      );

      expect(find.byType(GoalsScreen), findsNothing);

      await tester.tap(find.text('Ver as 2 metas'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('Reserva de emergência'), findsOneWidget);
      expect(find.text('Trocar de carro'), findsOneWidget);
    });
  });
}
