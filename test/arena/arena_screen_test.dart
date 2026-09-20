import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/widgets/arena_heroes_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';

import 'arena_harness.dart';

/// A cena e o placar, montados de verdade.
///
/// O que estes testes guardam é o que uma captura NÃO prova: que as duas
/// barras leem lados opostos, que a folha do monstro lista os pagos com a
/// marca do golpe e os pendentes com botão, que a ordem é a do jogo, e que
/// tocar em cada metade abre a folha certa.
void main() {
  group('o placar', () {
    testWidgets('a cena monta e o jogo carrega a folha de sprites', (
      tester,
    ) async {
      await pumpArena(tester);

      expect(find.byType(GameWidget<ArenaGame>), findsOneWidget);

      final game = tester
          .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
          .game!;

      expect(game.isSceneReady, isTrue, reason: 'o monstro entrou na cena');
      expect(tester.takeException(), isNull);
    });

    testWidgets('são DUAS barras: heróis à esquerda, monstro à direita', (
      tester,
    ) async {
      await pumpArena(tester);

      final bars = find.byType(ArenaHpBar);
      expect(bars, findsNWidgets(2));

      final heroes = tester.getCenter(bars.first);
      final monster = tester.getCenter(bars.last);

      expect(
        heroes.dx,
        lessThan(monster.dx),
        reason: 'a leitura do jogo de luta: quem é quem se lê pela posição',
      );

      // A do monstro é a espelhada — é isso que faz as duas se enfrentarem
      // em vez de repetirem o mesmo gesto.
      expect(tester.widget<ArenaHpBar>(bars.first).mirrored, isFalse);
      expect(tester.widget<ArenaHpBar>(bars.last).mirrored, isTrue);
    });

    testWidgets('a barra dos heróis mostra "atual / inicial"', (tester) async {
      await pumpArena(tester);

      expect(find.textContaining('3.980'), findsWidgets);
      expect(find.textContaining('5.200'), findsWidgets);
    });

    testWidgets('a hachura do comprometido é a vida do monstro', (
      tester,
    ) async {
      await pumpArena(tester);

      final heroBar = tester.widget<ArenaHpBar>(find.byType(ArenaHpBar).first);
      final state = arenaTestState();

      expect(heroBar.committedRatio, state.committedRatio);
      expect(state.committed, state.monsterHp);
    });

    testWidgets('o marcador central mostra o dia da semana', (tester) async {
      await pumpArena(tester);

      expect(find.byType(ArenaHud), findsOneWidget);
      expect(find.byType(ArenaDayMarker), findsOneWidget);
      // Quarta-feira é o quarto dia de sete.
      expect(find.text('4/7'), findsOneWidget);
    });

    testWidgets('os nomes dos membros ficam do lado dos heróis', (
      tester,
    ) async {
      await pumpArena(tester);

      expect(find.text('Gabriel · Ana'), findsOneWidget);
      expect(find.text('Aranha'), findsOneWidget);
    });

    testWidgets('receita acima do que saiu vira transbordo verde', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(initialBalance: 3000, currentBalance: 3200),
      );

      final heroBar = tester.widget<ArenaHpBar>(find.byType(ArenaHpBar).first);
      expect(heroBar.overflowing, isTrue);
      expect(heroBar.ratio, 1);
      expect(find.textContaining('acima de domingo'), findsOneWidget);
    });

    testWidgets('atraso enfurece e o selo diz quanto', (tester) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          overdueAmount: 640,
          commitmentsInitial: 2020,
          commitmentsRemaining: 2020,
        ),
      );

      expect(find.textContaining('Enfurecido'), findsOneWidget);
      expect(find.textContaining('640'), findsWidgets);
    });

    testWidgets('monstro sem vida vira "Derrotado"', (tester) async {
      await pumpArena(tester, state: arenaTestState(commitmentsRemaining: 0));

      expect(find.text('Derrotado'), findsOneWidget);
    });

    testWidgets('saldo negativo deixa os heróis exaustos', (tester) async {
      await pumpArena(tester, state: arenaTestState(currentBalance: -120));

      expect(find.text('Exausto'), findsOneWidget);
    });
  });

  group('detalhe do monstro', () {
    testWidgets('tocar na barra do monstro abre a folha', (tester) async {
      await pumpArena(tester);

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.byType(ArenaMonsterSheet), findsOneWidget);
      expect(find.text('Compromissos da semana'), findsOneWidget);
    });

    testWidgets('lista TODOS: os pagos com a marca, os pendentes com botão', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitmentsRemaining: 180,
          commitments: [
            arenaTestCommitment(
              id: 'luz',
              description: 'Luz',
              amount: 180,
              dayOffset: 2,
            ),
            arenaTestCommitment(paid: true),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      // O pago continua na lista: sumir com ele faria a soma da folha
      // divergir do HP inicial da barra.
      expect(find.text('Aluguel'), findsOneWidget);
      expect(find.text('Luz'), findsOneWidget);

      // A marca do golpe: a espada desenhada.
      expect(find.byType(SwordMark), findsOneWidget);

      // Um botão, do pendente. O pago não tem o que confirmar.
      expect(find.text('Confirmar pago'), findsOneWidget);

      final pago = tester.widget<Text>(find.text('Aluguel'));
      expect(
        pago.style?.decoration,
        TextDecoration.lineThrough,
        reason: 'o texto riscado é a outra metade da marca',
      );
    });

    testWidgets('a ordem é atrasados, hoje, resto — e os pagos no fim', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'atrasado',
              description: 'Cartão',
              amount: 640,
              dayOffset: -9,
              overdue: true,
            ),
            arenaTestCommitment(id: 'hoje', description: 'Aluguel'),
            arenaTestCommitment(
              id: 'sexta',
              description: 'Internet',
              amount: 99,
              dayOffset: 2,
            ),
            arenaTestCommitment(
              id: 'pago',
              description: 'Academia',
              amount: 120,
              dayOffset: -1,
              paid: true,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      double y(String label) => tester.getTopLeft(find.text(label)).dy;

      expect(y('Cartão'), lessThan(y('Aluguel')));
      expect(y('Aluguel'), lessThan(y('Internet')));
      expect(y('Internet'), lessThan(y('Academia')));
    });

    testWidgets('"próximo golpe" mostra o que vence hoje e amanhã', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(id: 'hoje', description: 'Aluguel'),
            arenaTestCommitment(
              id: 'amanha',
              description: 'Luz',
              amount: 180,
              dayOffset: 1,
            ),
            arenaTestCommitment(
              id: 'sabado',
              description: 'Internet',
              amount: 99,
              dayOffset: 3,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.byKey(const ValueKey('arena-next-blow')), findsOneWidget);
      expect(find.textContaining('Próximo golpe: 2'), findsOneWidget);
    });

    testWidgets('sem nada vencendo, a faixa de próximo golpe some', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'sabado',
              description: 'Internet',
              amount: 99,
              dayOffset: 3,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.byKey(const ValueKey('arena-next-blow')), findsNothing);
    });

    testWidgets('no cofre de empresa são "contas a pagar"', (tester) async {
      await pumpArena(tester, isBusiness: true);

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.text('Contas a pagar da semana'), findsOneWidget);
      expect(find.text('Compromissos da semana'), findsNothing);
    });
  });

  group('detalhe dos heróis', () {
    testWidgets('tocar na barra dos heróis abre as contas', (tester) async {
      await pumpArena(tester);

      await tester.tap(find.byType(ArenaHpBar).first);
      await arenaFrames(tester);

      expect(find.byType(ArenaHeroesSheet), findsOneWidget);
      expect(find.text('Nubank'), findsOneWidget);
      expect(find.text('Tesouro'), findsOneWidget);
    });

    testWidgets('cada conta mostra início → atual e a diferença', (
      tester,
    ) async {
      await pumpArena(tester);

      await tester.tap(find.byType(ArenaHpBar).first);
      await arenaFrames(tester);

      expect(find.textContaining('→'), findsNWidgets(2));
      // Nubank caiu R$ 1.100; Tesouro caiu R$ 120.
      expect(find.textContaining('1.100'), findsOneWidget);
      expect(find.textContaining('120'), findsWidgets);
    });

    testWidgets('o rodapé fecha a conta: vida, comprometido e livre', (
      tester,
    ) async {
      await pumpArena(tester);

      await tester.tap(find.byType(ArenaHpBar).first);
      await arenaFrames(tester);

      expect(find.text('Vida'), findsOneWidget);
      expect(find.text('Comprometido'), findsOneWidget);
      // O "quanto sobra" do cabeçalho antigo da Jornada: 3.980 − 1.380.
      expect(find.text('Livre'), findsOneWidget);
      expect(find.textContaining('2.600'), findsOneWidget);
    });
  });

  group('a cena', () {
    testWidgets('cabe num celular de 400px sem estourar', (tester) async {
      await pumpArena(tester, size: const Size(400, 800));

      expect(tester.takeException(), isNull);
    });

    testWidgets('e num desktop de 1300px', (tester) async {
      await pumpArena(tester, size: const Size(1300, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(ArenaHpBar), findsNWidgets(2));
    });

    testWidgets('"reduzir movimento" não quebra nada', (tester) async {
      await pumpArena(tester, reduceMotion: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(GameWidget<ArenaGame>), findsOneWidget);
    });

    testWidgets('semana vazia diz que está vazia, em vez de desenhar zeros', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          initialBalance: 0,
          currentBalance: 0,
          commitmentsInitial: 0,
          commitmentsRemaining: 0,
          commitments: const [],
          accounts: const [],
        ),
      );

      expect(find.byType(GameWidget<ArenaGame>), findsNothing);
      expect(find.textContaining('a arena está vazia'), findsOneWidget);
    });
  });
}
