import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_missions_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scene_icons.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

import 'arena/arena_harness.dart';
import 'support/home_harness.dart';

/// A primeira aba é O JOGO — decisão 1 do dono.
///
/// O teste anterior (`home_v2_test`) prendia a ORDEM de sete blocos
/// empilhados numa rolagem. Não há mais ordem para prender: há uma cena que
/// ocupa a tela e uma coluna de ícones que abre o que era bloco. O que estes
/// testes guardam agora é a nova decisão inteira — o que ficou na tela, o
/// que saiu dela, e para onde cada coisa que saiu foi parar.

/// Sobe a cena com um punhado de dados típicos.
Future<void> _pump(
  WidgetTester tester, {
  bool comMissoes = false,
  int pendentes = 0,
  FinancialHealth? health,
  Size size = const Size(400, 800),
}) => pumpArena(
  tester,
  size: size,
  overrides: arenaOverrides(
    missions: comMissoes ? homeTypicalMissions() : const [],
    pendingAutomatic: homeTypicalPending(count: pendentes),
    health: health,
    lastInsight: homeTypicalInsight(),
  ),
);

void main() {
  group('a aba É a cena', () {
    testWidgets('placar, cena e rodapé mensal, nesta ordem', (tester) async {
      await _pump(tester);

      final placar = tester.getRect(find.byType(ArenaHud));
      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));
      final rodape = tester.getRect(
        find.byKey(const ValueKey('arena-footer-slot')),
      );

      expect(placar.bottom, lessThanOrEqualTo(cena.top));
      expect(cena.bottom, lessThanOrEqualTo(rodape.top));
      expect(find.byType(ArenaHpBar), findsNWidgets(2));
    });

    testWidgets('a cena toma o que sobra: nada de altura fixa de cartão', (
      tester,
    ) async {
      await _pump(tester, size: const Size(400, 800));

      final aba = tester.getRect(find.byType(ArenaTab));
      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));

      expect(
        cena.height,
        greaterThan(aba.height * 0.5),
        reason:
            'no cartão antigo a luta tinha 30% da altura da tela; agora ela '
            'é a tela',
      );
    });

    testWidgets('e a aba NÃO rola', (tester) async {
      await _pump(tester, comMissoes: true, pendentes: 35);

      expect(
        find.descendant(
          of: find.byType(ArenaTab),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
        reason:
            '"eliminando a necessidade de expandir": não existe mais um '
            'abaixo da dobra nesta aba, com dados típicos ou com 35 '
            'pendências',
      );
    });

    testWidgets('no desktop a ARENA INTEIRA fica centrada e com teto', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1300, 900));

      final placar = tester.getRect(find.byType(ArenaHud));

      expect(
        placar.width,
        lessThanOrEqualTo(arenaMaxSceneWidth),
        reason:
            'de borda a borda num monitor, a vida dos heróis e a do monstro '
            'ficam a mil pixels uma da outra e param de se enfrentar',
      );
      expect(placar.center.dx, closeTo(650, 8));
    });
  });

  group('o que saiu da Home', () {
    testWidgets('os seis blocos empilhados não estão mais na tela', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true, pendentes: 35);

      for (final bloco in const <Type>[
        // 3 — as pendências: viraram opção do FAB, com o contador
        AutomaticTransactionConsolidationWidget,
        // 4 — as missões: viraram a folha do pergaminho
        WeeklyMissionsView,
        // 5 — o coaching: virou o ícone do coach
        CoachingInsightCard,
        // 6 — a Bússola: virou o ícone da bússola
        CompassStripView,
        // 7 — a meta em destaque: virou ferramenta do FAB
        GoalsSection,
        // e o nível, que nunca deveria ter estado no corpo
        LevelBadge,
      ]) {
        expect(
          find.byType(bloco),
          findsNothing,
          reason: '$bloco continua desenhado na primeira aba',
        );
      }
    });
  });

  group('os ícones de jogo', () {
    testWidgets('três sempre, e o quarto só quando há pendência', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      expect(
        find.byType(ArenaSceneIcon),
        findsNWidgets(3),
        reason: 'missões, bússola e coach',
      );

      await _pump(tester, comMissoes: true, pendentes: 4);

      expect(find.byType(ArenaSceneIcon), findsNWidgets(4));
      expect(
        find.text('4'),
        findsOneWidget,
        reason:
            'o "sinal discreto na cena" da decisão 8: o card saiu, o aviso '
            'de que há pendências ficou',
      );
    });

    testWidgets('ficam na LATERAL, sem cobrir o placar nem o rodapé', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      final coluna = tester.getRect(find.byType(ArenaSceneIcons));
      final placar = tester.getRect(find.byType(ArenaHud));
      final rodape = tester.getRect(
        find.byKey(const ValueKey('arena-footer-slot')),
      );

      expect(coluna.top, greaterThanOrEqualTo(placar.bottom));
      expect(coluna.bottom, lessThanOrEqualTo(rodape.top));
      expect(
        coluna.width,
        lessThan(64),
        reason: 'a 400px, uma coluna mais larga que isto rouba o embate',
      );
    });

    testWidgets('o pergaminho conta "1/3"', (tester) async {
      await _pump(tester, comMissoes: true);

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('a bússola mostra a pontuação — e apaga sem índice', (
      tester,
    ) async {
      await _pump(
        tester,
        health: const FinancialHealth(score: 72, tier: FreedomTier.guardiao),
      );

      expect(find.text('72'), findsOneWidget);

      final bussola = tester.widget<ArenaSceneIcon>(
        find.byWidgetPredicate(
          (w) => w is ArenaSceneIcon && w.icon == Icons.explore_rounded,
        ),
      );
      expect(bussola.onTap, isNotNull);

      // Sem índice publicado (cofre novo, ou servidor que ainda não
      // calculou), o ícone continua na cena — apagado e sem toque. Sumir
      // deixaria o usuário sem explicação nenhuma.
      await _pump(tester);

      final semIndice = tester.widget<ArenaSceneIcon>(
        find.byWidgetPredicate(
          (w) => w is ArenaSceneIcon && w.icon == Icons.explore_rounded,
        ),
      );
      expect(semIndice.onTap, isNull);
      expect(semIndice.badge, isNull);
    });

    testWidgets('cada ícone se apresenta ao leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _pump(tester, comMissoes: true, pendentes: 4);

        for (final rotulo in const [
          'Missões Semanais',
          'Bússola da Liberdade',
          'Coach Financeiro',
          'Lançamentos Identificados',
        ]) {
          expect(
            find.bySemanticsLabel(rotulo),
            findsWidgets,
            reason: '"$rotulo" é um ícone mudo para quem não o vê',
          );
        }
      } finally {
        handle.dispose();
      }
    });
  });

  group('a folha das missões', () {
    testWidgets('abre com o MESMO conteúdo do bloco que saiu da Home', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is ArenaSceneIcon && w.icon == Icons.menu_book_rounded,
        ),
      );
      await arenaFrames(tester, count: 20);

      expect(find.byType(ArenaMissionsSheet), findsOneWidget);

      // "conteúdo e ações preservados": o cabeçalho que conta, uma linha por
      // missão com o progresso em número, e UM botão — o da missão em foco.
      expect(find.text('1 de 3 completadas'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('1/8'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MissionSummary),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
      expect(find.text('Abrir o 50-30-20'), findsOneWidget);
    });

    testWidgets('semana sem missão explica, em vez de abrir vazia', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is ArenaSceneIcon && w.icon == Icons.menu_book_rounded,
        ),
      );
      await arenaFrames(tester, count: 20);

      expect(find.byType(NoMissionsEmptyState), findsOneWidget);
    });
  });
}
