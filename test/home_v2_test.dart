import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_strip_view.dart';
import 'package:funances/features/home/presentation/widgets/home/due_soon_strip.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
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

    /// M4 — a linha mostrava a barra e não o número. Numa missão de 8
    /// lançamentos cada passo movia 6 pixels: o progresso existia e não era
    /// legível, e "quanto falta" — metade do que uma missão comunica —
    /// ficava só na tela de detalhe.
    testWidgets('M4 — cada linha diz o progresso em número', (tester) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('1/8'), findsOneWidget);
    });

    testWidgets('M4 — e a barra tem largura para mover', (tester) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(missions: homeTypicalMissions()),
      );

      final barras = find.descendant(
        of: find.byType(MissionSummary),
        matching: find.byType(AppProgressBar),
      );

      expect(barras, findsNWidgets(3));
      for (final barra in barras.evaluate()) {
        expect(
          tester.getSize(find.byWidget(barra.widget)).width,
          greaterThanOrEqualTo(64),
          reason: 'com 48px, um passo de 1 em 8 move seis pixels',
        );
      }
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

    /// A1 — o bloco de pendências não tinha tamanho. O leitor grava uma por
    /// notificação de banco e ninguém consolida todo dia: medido no aparelho
    /// do dono, 35 pendências davam 3.050px e a Home inteira ia a 7,1
    /// rolagens. O defeito estava lá desde sempre e ficou invisível enquanto
    /// o parse derrubava a lista antes de ela desenhar.
    testWidgets('A1 — a Home mostra no máximo 3 pendências', (tester) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(pendingAutomatic: homeTypicalPending()),
      );

      expect(
        find.textContaining('COMPRA CARTAO'),
        findsNWidgets(3),
        reason: '35 pendências desenhadas eram 3.050px de Home',
      );
      expect(find.text('Ver as 35 pendências'), findsOneWidget);
    });

    /// Este teste prendia o comportamento ERRADO: com poucas pendências não
    /// havia botão nenhum, e como a linha compacta da Home só oferece
    /// "consolidar", ignorar e mover para outro cofre sumiam do app inteiro
    /// justamente no estado normal — ter poucas pendências.
    testWidgets('A1 — com duas, a porta para a tela cheia existe', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(
          pendingAutomatic: homeTypicalPending(count: 2),
        ),
      );

      expect(find.textContaining('COMPRA CARTAO'), findsNWidgets(2));
      expect(
        find.text('Ver todas'),
        findsOneWidget,
        reason:
            'com tudo à mostra o botão não promete um número que a pessoa já '
            'vê; ele promete o que a Home não tem, que são as outras ações',
      );
    });

    testWidgets('A1 — e o cabeçalho também é porta, com uma só', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(
          pendingAutomatic: homeTypicalPending(count: 1),
        ),
      );

      expect(
        find.ancestor(
          of: find.text('Lançamentos Identificados'),
          matching: find.byType(InkWell),
        ),
        findsWidgets,
        reason: 'o cabeçalho de um bloco resumido é a porta da tela completa',
      );
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
