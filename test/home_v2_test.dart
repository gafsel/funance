import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/home/due_soon_strip.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/team_status_view.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';

import 'support/home_harness.dart';

/// D1, D2, D3 e A7 — a Home v2.
///
/// A ordem dos blocos é a decisão principal desta tela e nunca teve teste:
/// qualquer refactor podia trocar o que aparece primeiro sem que nada
/// quebrasse. Estes testes prendem a ordem e a ausência do que foi retirado.
///
/// A Home antiga abria pelo cabeçalho do cofre — nome, tipo e nível, os três
/// já escritos na `AppBar` logo acima — e o nível ainda aparecia DUAS vezes:
/// no anel do `WorkspaceLevelIndicator`, na barra, e no `LevelBadge`, no
/// corpo. Depois vinham a Bússola, o coaching em cartão de 120px, as missões,
/// a Party e a lista COMPLETA de metas.

/// A posição vertical de um bloco na tela.
double _topo(WidgetTester tester, Type tipo) =>
    tester.getTopLeft(find.byType(tipo).first).dy;

void main() {
  group('a ordem dos blocos', () {
    testWidgets('é a da pergunta "o que eu preciso saber agora?"', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(
          installments: [homeInstallment(dueDate: homeToday)],
          missions: homeTypicalMissions(),
          goals: homeTypicalGoals(),
          // Todos os blocos presentes: a ordem só se afirma entre coisas que
          // existem, e um bloco ausente tem altura zero.
          pendingAutomatic: homeTypicalPending(),
        ),
      );

      // Na ordem em que devem aparecer, de cima para baixo.
      const esperada = <Type>[
        // 2 — quanto sobra no mês (o 1 é o toast, que vem por cima)
        JourneyHeader,
        // 3 — o que vence hoje e amanhã
        DueSoonStrip,
        // 4 — as pendências que expiram
        AutomaticTransactionConsolidationWidget,
        // 5 — as missões da semana
        WeeklyMissionsView,
        // 6 — o empurrão, em uma linha
        CoachingInsightCard,
        // 7 — a linha da Bússola
        CompassStripView,
        // 8 — uma meta em destaque
        GoalsSection,
      ];

      final posicoes = [
        for (final tipo in esperada) (tipo, _topo(tester, tipo)),
      ];

      // `greaterThan` ESTRITO, e não `greaterThanOrEqualTo`: com o
      // "ou igual", dois blocos de altura zero — ou um bloco que sumiu —
      // passavam empatados, e o teste dizia sim para uma Home sem eles. Cada
      // bloco tem de estar ABAIXO do anterior, o que só é verdade se os dois
      // existirem e ocuparem espaço.
      for (var i = 1; i < posicoes.length; i++) {
        expect(
          posicoes[i].$2,
          greaterThan(posicoes[i - 1].$2),
          reason:
              '${posicoes[i].$1} não está abaixo de ${posicoes[i - 1].$1}; a '
              'ordem é: ${esperada.join(' → ')}',
        );
      }
    });

    testWidgets('"quanto sobra" é o primeiro bloco da tela', (tester) async {
      await pumpHome(tester, const JourneyTab(), overrides: homeOverrides());

      final topo = _topo(tester, JourneyHeader);

      for (final outro in const [
        DueSoonStrip,
        WeeklyMissionsView,
        CoachingInsightCard,
        CompassStripView,
        GoalsSection,
      ]) {
        expect(
          topo,
          lessThan(_topo(tester, outro)),
          reason:
              'a Home abria pelo cabeçalho do cofre, que não muda de um dia '
              'para o outro',
        );
      }
    });
  });

  group('o que saiu da Home', () {
    testWidgets('A7 — o nível NÃO aparece no corpo', (tester) async {
      await pumpHome(tester, const JourneyTab(), overrides: homeOverrides());

      expect(
        find.byType(LevelBadge),
        findsNothing,
        reason:
            'a identidade do cofre — nome, tipo e nível — mora na AppBar; o '
            'corpo repetia os três e o nível ainda vinha em dois desenhos '
            'diferentes',
      );
    });

    testWidgets('D2 — a Party foi para a Visão Geral', (tester) async {
      await pumpHome(tester, const JourneyTab(), overrides: homeOverrides());

      expect(find.byType(TeamStatusView), findsNothing);
    });

    testWidgets('D2 — o checklist da semana saiu para /missions', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(
        find.byType(WeekChecklist),
        findsNothing,
        reason:
            'são 516px de LISTA: quem abre o app para saber o que fazer hoje '
            'precisa saber que ela existe, não precisa dela aberta',
      );
      expect(find.byType(MissionCard), findsNothing);
      expect(
        find.byType(MissionSummary),
        findsOneWidget,
        reason: 'no lugar ficou o resumo de uma linha por missão',
      );
    });

    testWidgets('D2 — o resumo tem UM botão, o da missão em foco', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(
        find.descendant(
          of: find.byType(MissionSummary),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
        reason:
            'três botões empilhados é a mesma pergunta feita três vezes, e '
            'nenhuma delas é "o que eu faço agora"',
      );
      // A missão em foco é a primeira AINDA ABERTA com destino — não a
      // primeira da lista, que está cumprida.
      expect(find.text('Abrir o 50-30-20'), findsOneWidget);
    });

    testWidgets('D2 — o cabeçalho conta quantas foram e abre a semana', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(find.text('1 de 3 completadas'), findsOneWidget);
    });

    testWidgets('D2 — o coaching ocupa UMA linha, não um cartão', (
      tester,
    ) async {
      await pumpHome(tester, const JourneyTab(), overrides: homeOverrides());

      final altura = tester.getSize(find.byType(CoachingInsightCard)).height;

      expect(
        altura,
        lessThan(72),
        reason:
            'o cartão de coaching reservava 120px fixos — e mais que isso '
            'quando não havia análise, porque o convite tem título, parágrafo '
            'e botão',
      );
    });
  });

  group('DueSoonStrip', () {
    testWidgets('D3 — soma o que vence hoje e amanhã', (tester) async {
      await pumpHome(
        tester,
        const DueSoonStrip(initiallyExpanded: true),
        overrides: homeOverrides(
          installments: [
            homeInstallment(
              id: 'a',
              description: 'Aluguel',
              amount: 1800,
              dueDate: homeToday,
            ),
            homeInstallment(
              id: 'b',
              description: 'Luz',
              amount: 210,
              dueDate: homeToday.add(const Duration(days: 1)),
            ),
            // Fora da janela: não entra nem na soma nem na lista.
            homeInstallment(
              id: 'c',
              description: 'Internet',
              amount: 99,
              dueDate: homeToday.add(const Duration(days: 5)),
            ),
          ],
        ),
      );

      expect(find.text('Vence hoje e amanhã'), findsOneWidget);
      expect(find.text('Aluguel'), findsOneWidget);
      expect(find.text('Luz'), findsOneWidget);
      expect(find.text('Internet'), findsNothing);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);
    });

    testWidgets('sem nada vencendo, a linha SOME', (tester) async {
      await pumpHome(
        tester,
        const DueSoonStrip(),
        overrides: homeOverrides(
          installments: [
            homeInstallment(dueDate: homeToday.add(const Duration(days: 9))),
          ],
        ),
      );

      expect(
        find.text('Vence hoje e amanhã'),
        findsNothing,
        reason:
            'um bloco que diz "nada vence" todo dia gasta a única coisa que a '
            'Home não tem sobrando, que é altura',
      );
    });

    testWidgets('parcela JÁ PAGA não vira compromisso', (tester) async {
      await pumpHome(
        tester,
        const DueSoonStrip(),
        overrides: homeOverrides(
          installments: [
            homeInstallment(dueDate: homeToday, status: InstallmentStatus.paid),
          ],
        ),
      );

      expect(find.text('Vence hoje e amanhã'), findsNothing);
    });
  });
}
