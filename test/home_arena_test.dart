import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_missions_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_icon_glyphs.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scene_icons.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scrim.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/finance/presentation/widgets/automatic_transaction_consolidation_widget.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
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
  bool comBanner = false,
  Size size = const Size(400, 800),
}) => pumpArena(
  tester,
  size: size,
  overrides: arenaOverrides(
    missions: comMissoes ? homeTypicalMissions() : const [],
    pendingAutomatic: homeTypicalPending(count: pendentes),
    health: health,
    lastInsight: homeTypicalInsight(),
    extra: [
      // O placar da semana que fechou aparece UMA vez por semana, e nunca
      // num golden. Ele é a altura extra que o véu do topo ganha no pior
      // caso — e é por isso que o teste de não-sobreposição o liga.
      if (comBanner)
        ArenaViewProviders.lastWeekState.overrideWith(
          (ref) => AsyncValue<ArenaState>.data(
            arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
          ),
        ),
    ],
  ),
);

void main() {
  group('a cena é o FUNDO da aba', () {
    testWidgets('a arte vai de borda a borda, atrás de tudo', (tester) async {
      await _pump(tester);

      final aba = tester.getRect(find.byType(ArenaTab));
      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));

      expect(
        cena,
        aba,
        reason:
            '"deixe a animação tomar a tela toda": a cena deixou de dividir '
            'a altura com o placar e com o rodapé — eles flutuam por cima',
      );
    });

    testWidgets('placar e rodapé flutuam sobre ela, cada um no seu véu', (
      tester,
    ) async {
      await _pump(tester);

      final placar = tester.getRect(find.byType(ArenaHud));
      final rodape = tester.getRect(
        find.byKey(const ValueKey('arena-footer-slot')),
      );
      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));

      // Os dois estão DENTRO do retângulo da cena — é o que "por cima"
      // significa aqui.
      expect(cena.contains(placar.topLeft), isTrue);
      expect(cena.contains(rodape.bottomRight - const Offset(1, 1)), isTrue);
      expect(placar.bottom, lessThan(rodape.top));
      expect(find.byType(ArenaScrim), findsNWidgets(2));
      expect(find.byType(ArenaHpBar), findsNWidgets(2));
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

    testWidgets('no desktop o que se LÊ fica centrado e com teto', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1300, 900));

      final placar = tester.getRect(find.byType(ArenaHud));
      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));

      expect(
        cena.width,
        1300,
        reason: 'a ARTE é de borda a borda, inclusive num monitor',
      );
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

      // O cartão do coaching e a linha da Bússola não estão nesta lista
      // porque não existem mais: sem ninguém para renderizá-los, eles viraram
      // código morto e foram apagados. O que sobrou do coach são as AÇÕES
      // (`CoachingActions`), que o ícone da cena chama.
      for (final bloco in const <Type>[
        // 3 — as pendências: viraram opção do FAB, com o contador
        AutomaticTransactionConsolidationWidget,
        // 4 — as missões: viraram a folha do pergaminho
        WeeklyMissionsView,
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
    /// Acha um ícone da faixa pela FIGURA dele.
    Finder porGlifo(ArenaGlyph glyph) => find.byWidgetPredicate(
      (w) => w is ArenaSceneIcon && w.glyph == glyph,
    );

    testWidgets('são QUATRO, sempre — e o que não tem número apaga', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      expect(
        find.byType(ArenaSceneIcon),
        findsNWidgets(4),
        reason: 'pergaminho, bússola, coach e faísca',
      );

      // B9: a faísca NÃO some com zero pendências. Sumir reorganizava os
      // outros três a cada notificação que chegava ou era consolidada — um
      // pulo de layout no meio de uma cena parada.
      final faisca = tester.widget<ArenaSceneIcon>(porGlifo(ArenaGlyph.spark));
      expect(faisca.onTap, isNull);
      expect(faisca.value, isNull);
      expect(faisca.filled, isFalse);

      await _pump(tester, comMissoes: true, pendentes: 4);

      expect(find.byType(ArenaSceneIcon), findsNWidgets(4));
      expect(find.text('4'), findsOneWidget);
      expect(
        tester.widget<ArenaSceneIcon>(porGlifo(ArenaGlyph.spark)).onTap,
        isNotNull,
      );
    });

    testWidgets('a figura é desenhada em código, não é ícone do Material', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      expect(
        find.descendant(
          of: find.byType(ArenaSceneIcons),
          matching: find.byType(Icon),
        ),
        findsNothing,
        reason:
            'um pictograma do Material colado sobre pixel art de 16px é um '
            'adesivo de outro aplicativo em cima do jogo',
      );
      expect(find.byType(ArenaIconGlyph), findsNWidgets(4));
      expect(find.byType(ArenaIconRing), findsNWidgets(4));
    });

    /// E — o dono: *"os ícones da parte superior, troca pra um formato
    /// parecido com o dos ícones da parte de baixo (com o número do lado e o
    /// texto em baixo em telas grandes o suficiente)"*.
    ///
    /// Os dois grupos moram sobre a MESMA cena. Com duas montagens — número
    /// embaixo em cima, número ao lado embaixo — a tela lia como dois HUDs
    /// sobrepostos.
    testWidgets('no celular o número fica AO LADO da figura, e sem nome', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true, size: const Size(400, 800));

      final anel = tester.getRect(
        find.descendant(
          of: porGlifo(ArenaGlyph.scroll),
          matching: find.byType(ArenaIconRing),
        ),
      );
      final numero = tester.getRect(find.text('1/3'));

      // Ao lado: o número começa DEPOIS da figura e divide a mesma linha.
      expect(numero.left, greaterThanOrEqualTo(anel.right));
      expect(numero.center.dy, closeTo(anel.center.dy, 4));

      // Num celular, quatro rótulos a mais disputam os mesmos 400 px com
      // quatro números, e é o número que perde.
      expect(find.text('Missões'), findsNothing);
      expect(find.text('Bússola'), findsNothing);
    });

    testWidgets('do tablet para cima os quatro se apresentam', (tester) async {
      await _pump(tester, comMissoes: true, size: const Size(1300, 900));

      expect(find.text('Missões'), findsOneWidget);
      expect(find.text('Bússola'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Pendentes'), findsOneWidget);

      // O nome curto é do DESENHO; a semântica continua com o nome inteiro.
      expect(
        find.bySemanticsLabel('Bússola da Liberdade'),
        findsOneWidget,
        reason: 'a semântica não encolheu junto com a tela',
      );
    });

    testWidgets('o coach não inventa número onde não há contagem', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true, size: const Size(1300, 900));

      final coach = tester.widget<ArenaSceneIcon>(porGlifo(ArenaGlyph.coach));

      expect(coach.value, isNull);
      // E o nome dele continua lá: quem diz o estado é o anel.
      expect(find.text('Coach'), findsOneWidget);
    });

    /// As seis geometrias em que a aba tem de se comportar: do celular mais
    /// baixo que o app suporta ao monitor.
    const geometrias = <Size>[
      Size(400, 420),
      Size(360, 480),
      Size(400, 544),
      Size(400, 800),
      Size(800, 600),
      Size(1300, 900),
    ];

    /// A2 — o achado ALTO do QA: a coluna da rodada 1 cobria o mago a
    /// 400×544. A faixa livre acima dos bonecos depende da PROPORÇÃO da
    /// caixa, e um "no alto da lateral" não tem como acertá-la em toda
    /// altura.
    ///
    /// A rodada 3 mudou de mecanismo: a cena passou a RECEBER a altura do véu
    /// e a empurrar o cenário inteiro para baixo dele. Deixou de ser uma
    /// conta que o teste confere e virou uma regra que o layout impõe — e por
    /// isso o teste agora liga o banner de fechamento, que é a altura extra
    /// do pior caso.
    for (final tamanho in geometrias) {
      final nome = '${tamanho.width.toInt()}×${tamanho.height.toInt()}';

      testWidgets('a $nome nenhum ícone cobre um ator', (tester) async {
        await _pump(
          tester,
          comMissoes: true,
          pendentes: 4,
          comBanner: true,
          size: tamanho,
        );

        final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));
        final jogo = tester
            .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
            .game!;

        expect(
          find.byKey(const ValueKey('arena-week-closing')),
          findsOneWidget,
          reason: 'o pior caso é com o placar da semana passada na tela',
        );

        final faixaLivre = cena.top + jogo.safeTopBand;
        final icones = tester.getRect(find.byType(ArenaSceneIcons));

        expect(
          icones.bottom,
          lessThanOrEqualTo(faixaLivre),
          reason:
              'os ícones descem até ${icones.bottom.toStringAsFixed(0)}px e o '
              'topo do boneco mais alto está em '
              '${faixaLivre.toStringAsFixed(0)}px',
        );

        // E o placar, que está acima deles, também.
        expect(
          tester.getRect(find.byType(ArenaHud)).bottom,
          lessThanOrEqualTo(faixaLivre),
        );
      });

      /// N2 — proporção. O QA mediu 108px de parede contra 115px de monstro
      /// num celular e 123 contra 206 num monitor: uma aranha maior que a
      /// muralha atrás dela. Quem dá escala a uma cena é o boneco, e a parede
      /// tem de crescer com ele.
      testWidgets('a $nome a parede é maior que o bicho', (tester) async {
        await _pump(tester, comMissoes: true, size: tamanho);

        final jogo = tester
            .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
            .game!;

        final parede = jogo.wallPixels;
        final ator = jogo.tallestActorPixels;

        expect(
          parede,
          greaterThanOrEqualTo(ator * arenaWallToActor - 0.5),
          reason:
              'parede de ${parede.toStringAsFixed(0)}px contra um ator de '
              '${ator.toStringAsFixed(0)}px — a razão é '
              '${(parede / ator).toStringAsFixed(2)}, e o mínimo é '
              '$arenaWallToActor',
        );

        // E ela aparece INTEIRA abaixo do véu: os braseiros moram no pé da
        // parede, e na rodada 2 a banda de desvanecimento os comia.
        final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));
        final veu = tester.getRect(find.byType(ArenaScrim).first);

        expect(
          cena.top + jogo.topInset,
          greaterThanOrEqualTo(veu.bottom - 0.5),
          reason: 'a cena não sabe onde o véu termina',
        );
      });
    }

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
      expect(
        tester.widget<ArenaSceneIcon>(porGlifo(ArenaGlyph.compass)).onTap,
        isNotNull,
      );

      // Sem índice publicado (cofre novo, ou servidor que ainda não
      // calculou), o ícone continua na faixa — apagado e sem toque. Sumir
      // deixaria o usuário sem explicação nenhuma.
      await _pump(tester);

      final semIndice = tester.widget<ArenaSceneIcon>(
        porGlifo(ArenaGlyph.compass),
      );
      expect(semIndice.onTap, isNull);
      expect(semIndice.value, isNull);
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

  group('semana sem luta', () {
    testWidgets('o recado aparece, e as portas continuam na tela', (
      tester,
    ) async {
      // O cofre recém criado — sem conta e sem compromisso — é exatamente
      // quem mais precisa das portas, e era de quem elas sumiam: o recado
      // "a arena está vazia" vinha NO LUGAR da Arena inteira, levando junto o
      // rodapé mensal e a coluna de ícones.
      await pumpArena(
        tester,
        state: arenaTestState(
          initialBalance: 0,
          currentBalance: 0,
          commitments: const [],
          accounts: const [],
        ),
        overrides: arenaOverrides(
          state: arenaTestState(
            initialBalance: 0,
            currentBalance: 0,
            commitments: const [],
            accounts: const [],
          ),
          missions: homeTypicalMissions(),
        ),
      );

      expect(find.textContaining('a arena está vazia'), findsOneWidget);
      expect(find.byType(ArenaSceneIcon), findsNWidgets(4));
      expect(
        find.byKey(const ValueKey('arena-footer-slot')),
        findsOneWidget,
        reason: 'o HUD mensal fala do MÊS: ele não depende de haver luta',
      );
    });
  });

  group('a folha das missões', () {
    testWidgets('abre com o MESMO conteúdo do bloco que saiu da Home', (
      tester,
    ) async {
      await _pump(tester, comMissoes: true);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is ArenaSceneIcon && w.glyph == ArenaGlyph.scroll,
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
          (w) => w is ArenaSceneIcon && w.glyph == ArenaGlyph.scroll,
        ),
      );
      await arenaFrames(tester, count: 20);

      expect(find.byType(NoMissionsEmptyState), findsOneWidget);
    });
  });
}
