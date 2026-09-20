import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/widgets/arena_heroes_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/presentation/game/arena_actors.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';

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

    testWidgets('o herói 0 é o da ESQUERDA — a ordem do placar', (
      tester,
    ) async {
      // O placar escreve `state.heroes` na ordem da lista, separada por
      // ponto: "Gabriel · Ana". Enquanto a cena desenhava o índice 0 à
      // direita, o nome e o boneco trocavam de dono — e com o seletor de
      // avatar liberando bonecos repetidos, o anel do segundo membro passava
      // a apontar para a pessoa errada.
      await pumpArena(
        tester,
        state: arenaTestState().copyWith(
          heroes: const [
            ArenaHero(userId: 'u1', name: 'Gabriel', skin: HeroSkin.smith),
            ArenaHero(
              userId: 'u2',
              name: 'Ana',
              skin: HeroSkin.smith,
              duplicate: true,
            ),
          ],
        ),
      );

      final jogo = tester
          .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
          .game!;

      expect(jogo.heroes, hasLength(2));
      expect(
        jogo.heroes.first.position.x,
        lessThan(jogo.heroes.last.position.x),
        reason: 'o primeiro nome do placar é o boneco da esquerda',
      );

      // E o distintivo continua no SEGUNDO da lista, que agora é o da
      // direita.
      expect(jogo.heroes.first.duplicate, isFalse);
      expect(jogo.heroes.last.duplicate, isTrue);

      // O nome do placar é o mesmo texto, na mesma ordem.
      expect(find.text('Gabriel · Ana'), findsOneWidget);
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

    testWidgets('a barra dos heróis mostra "atual / inicial", compacto', (
      tester,
    ) async {
      await pumpArena(tester);

      // Decisão 13 do dono: no placar o dinheiro é referência lúdica, não
      // extrato. R\$ 3.980,00 vira "R\$ 4k" e R\$ 5.200,00 vira "R\$ 5,2k";
      // os centavos exatos estão na folha das contas, a um toque daqui.
      expect(find.textContaining('4k'), findsWidgets);
      expect(find.textContaining('5,2k'), findsWidgets);
      expect(
        find.textContaining('3.980'),
        findsNothing,
        reason: 'o número de extrato saiu da barra',
      );
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
      final state = arenaTestState(
        commitments: [
          arenaTestCommitment(
            id: 'cartao',
            description: 'Cartão',
            amount: 640,
            dayOffset: -9,
            overdue: true,
          ),
          arenaTestCommitment(),
          arenaTestCommitment(
            id: 'luz',
            description: 'Luz',
            amount: 180,
            dayOffset: 2,
          ),
        ],
      );

      await pumpArena(tester, state: state);

      // O selo carrega o NÚMERO, não a palavra: a 400px o texto completo
      // saía cortado em "Enfureci…", que não informa nada. Quem diz
      // que o bicho está enfurecido é a cara dele — a skin de demônio — e a
      // cor de perigo do selo.
      expect(find.textContaining('atrasado'), findsOneWidget);
      expect(find.textContaining('640'), findsWidgets);
      expect(state.monsterSkin, MonsterSkin.demon);
    });

    /// A1 — o achado ALTO do QA, que nenhuma captura de estado pega.
    ///
    /// O `ColorEffect` do Flame ESCREVE em `paint.colorFilter` a cada quadro
    /// e, no fim, deixa lá o filtro da cor de origem com opacidade zero. Ele
    /// não restaura o que havia antes. Quando o monstro morria AO VIVO, o
    /// susto branco entrava por cima do cinza de cadáver e, ao terminar,
    /// deixava um filtro transparente no lugar dele: o bicho ficava deitado,
    /// com o X, e **em cor cheia** até a semana seguinte.
    ///
    /// Quem abria a Home numa semana já vencida via o cadáver certo; quem
    /// assistia à morte via o errado — que é o pior dos dois casos, porque é
    /// o momento em que a pessoa está olhando.
    testWidgets('A1 — morrer AO VIVO deixa o cadáver cinza, não colorido', (
      tester,
    ) async {
      final vivo = arenaTestState();
      final morto = arenaTestState(
        commitments: [arenaTestCommitment(paid: true)],
      );

      // A cena lê um `Provider`, que não se escreve de fora. A fonte
      // mutável entra por baixo dele: é o que deixa a semana FECHAR com a
      // tela montada, que é o caminho do defeito.
      final fonte = StateProvider<ArenaState>((ref) => vivo);
      final container = ProviderContainer(
        overrides: arenaOverrides(
          extra: [
            ArenaViewProviders.state.overrideWith(
              (ref) => AsyncValue<ArenaState>.data(ref.watch(fonte)),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              localizationsDelegates: arenaLocalizationDelegates,
              supportedLocales: arenaSupportedLocales,
              locale: const Locale('pt'),
              home: const Scaffold(body: ArenaTab()),
            ),
          ),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(Duration.zero);
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      });
      await arenaFrames(tester);

      final jogo = tester
          .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
          .game!;

      expect(jogo.monster!.isFallen, isFalse, reason: 'ele começa de pé');

      // A semana fecha COM a cena na frente: é o caminho que dispara o susto.
      container.read(fonte.notifier).state = morto;
      await tester.pump();

      // Tempo de sobra para o `ColorEffect` do susto terminar (0,08 + 0,12,
      // duas vezes).
      await arenaFrames(tester, count: 40);

      expect(jogo.monster!.isFallen, isTrue);
      expect(
        jogo.monster!.paint.colorFilter,
        MonsterActor.corpseFilter,
        reason:
            'o susto terminou e deixou o filtro dele no lugar do cinza: o '
            'bicho está deitado, com o X, e em cor cheia',
      );
      expect(find.text('Derrotado'), findsOneWidget);
    });

    testWidgets('monstro sem vida vira "Derrotado"', (tester) async {
      await pumpArena(
        tester,
        state: arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
      );

      expect(find.text('Derrotado'), findsOneWidget);
    });

    testWidgets('o rombo tem selo, do lado dos heróis', (tester) async {
      // O retrato real do domingo: R\$ 3.115,02 em caixa contra R\$ 12.122,33
      // de compromisso. A barra está CHEIA — nada saiu ainda — e sem o selo a
      // cena dizia "tudo bem" com nove mil reais de rombo na frente.
      await pumpArena(
        tester,
        state: arenaTestState(
          initialBalance: 3115.02,
          currentBalance: 3115.02,
          commitments: [
            arenaTestCommitment(
              id: 'fatura',
              description: 'Fatura Cartão Nubank',
              amount: 8300.55,
              dayOffset: -3,
              overdue: true,
            ),
            arenaTestCommitment(
              id: 'emprestimo',
              description: 'Pagamento de empréstimo',
              amount: 3811.78,
              dayOffset: 2,
            ),
            arenaTestCommitment(
              id: 'c6',
              description: 'Segurança C6',
              amount: 10,
              dayOffset: -4,
              overdue: true,
            ),
          ],
        ),
      );

      // Sem o "R\$" na busca: o formatador usa espaço não separável entre o
      // símbolo e o número, e um teste que casa com o espaço comum falha por
      // um caractere invisível. O selo também é compacto (decisão 13): a
      // 400px "Falta R\$ 9.007,31 em caixa" saía cortado, e um selo cortado
      // não informa nada.
      expect(find.textContaining('9k'), findsWidgets);
      expect(find.textContaining('em caixa'), findsOneWidget);

      final barra = tester.widget<ArenaHpBar>(find.byType(ArenaHpBar).first);
      expect(barra.ratio, 1, reason: 'a barra está cheia');
      expect(barra.pressed, isTrue, reason: 'e mesmo assim é o pior estado');
      expect(barra.committedRatio, 1, reason: 'a hachura satura');
    });

    testWidgets('caixa que cobre os compromissos não tem selo de rombo', (
      tester,
    ) async {
      await pumpArena(tester);

      expect(find.textContaining('em caixa'), findsNothing);
      expect(
        tester.widget<ArenaHpBar>(find.byType(ArenaHpBar).first).pressed,
        isFalse,
      );
    });

    /// Achado de game design #4 do QA: com o caixa NEGATIVO a barra ficava
    /// coberta de hachura de ponta a ponta, e o olho lê uma barra cheia de
    /// vermelho como vida cheia. Era o retrato real do cofre naquele dia —
    /// −R\$ 6.361,92 em caixa — e a Arena dizia que estava tudo no lugar.
    ///
    /// Uma barra vazia é uma barra vazia. A hachura nunca passa da vida que
    /// existe, e quem conta o tamanho do buraco é o selo, que traz o número.
    testWidgets('saldo negativo é barra VAZIA, e o selo diz de quanto', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(initialBalance: -6361.92, currentBalance: -6361.92),
      );

      final barra = tester.widget<ArenaHpBar>(find.byType(ArenaHpBar).first);

      expect(barra.ratio, 0, reason: 'não sobrou vida nenhuma');
      expect(
        barra.committedRatio,
        0,
        reason:
            'a hachura cobria a barra inteira e lia como "vida cheia" — ela '
            'nunca passa do que existe',
      );
      expect(barra.pressed, isTrue);

      // O número do buraco, no lugar da palavra "Exausto": com a barra
      // vazia, a palavra sozinha não diz de quanto é.
      expect(find.textContaining('7,7k'), findsWidgets);
      expect(find.textContaining('em caixa'), findsOneWidget);
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

    testWidgets('a fatura paga pela metade mostra quanto falta', (
      tester,
    ) async {
      // O caso real: Cartão Inter, R\$ 12.130,09 cobrados, R\$ 1.000 pagos.
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'inter',
              description: 'Fatura do Cartão Inter',
              amount: 12130.09,
              partial: 1000,
              dayOffset: 2,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      // Sem o "R\$" nas buscas: o formatador usa espaço não separável entre o
      // símbolo e o número, e um teste que casa com o espaço comum falha por
      // um caractere invisível.
      expect(find.textContaining('1.000,00 de'), findsOneWidget);
      expect(find.textContaining('12.130,09'), findsWidgets);
      expect(find.textContaining('11.130,09'), findsWidgets);

      // Meia espada: houve golpe, e o bicho continua de pé. A inteira ali
      // contaria a mesma mentira que a barra contava.
      final marcas = tester.widgetList<SwordMark>(find.byType(SwordMark));
      expect(marcas.length, 1);
      expect(marcas.single.half, isTrue);

      // NÃO há botão. A parcela está com status `paid` na base, e o caminho
      // de quitação do app (`TransactionPaymentSheet`) é para quitar o que
      // está pendente — reabri-lo sobre uma parcela já paga é um fluxo que
      // esta POC não verificou e não vai fingir que existe. O que a folha
      // promete aqui é a LEITURA correta; pagar o resto continua sendo pela
      // edição do lançamento.
      expect(find.text('Confirmar pago'), findsNothing);
    });

    testWidgets('resíduo de centavos: espada inteira e texto discreto', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'c6',
              description: 'Fatura Cartão C6',
              amount: 3942.04,
              partial: 3942.00,
              dayOffset: 2,
            ),
          ],
        ),
      );

      expect(
        find.text('Derrotado'),
        findsOneWidget,
        reason: 'quatro centavos de arredondamento não mantêm o bicho vivo',
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(
        tester.widgetList<SwordMark>(find.byType(SwordMark)).single.half,
        isFalse,
        reason: 'a linha caiu: espada inteira',
      );
      expect(find.textContaining('de resíduo'), findsOneWidget);
      expect(find.textContaining('0,04'), findsWidgets);
      expect(find.textContaining('de R\$ 3.942,04'), findsNothing);
    });

    testWidgets('a linha parcial oferece ajustar o pagamento', (tester) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'inter',
              description: 'Fatura do Cartão Inter',
              amount: 12130.09,
              partial: 1000,
              dayOffset: 2,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      await tester.tap(find.byKey(const ValueKey('arena-adjust-payment')));
      await arenaFrames(tester, count: 20);

      expect(find.text('editar lançamento'), findsOneWidget);
    });

    testWidgets('pagar a mais aparece na linha, não na barra', (tester) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(
              id: 'f',
              description: 'Fatura',
              amount: 286.21,
              partial: 296.61,
              dayOffset: 2,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.textContaining('acima do previsto'), findsOneWidget);
      expect(
        tester.widgetList<SwordMark>(find.byType(SwordMark)).single.half,
        isFalse,
        reason: 'o compromisso caiu: a espada é inteira',
      );
    });

    testWidgets('golpe agendado tem relógio, data e nenhum botão', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
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

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.textContaining('Agendado'), findsOneWidget);
      expect(
        find.byType(SwordMark),
        findsNothing,
        reason: 'o golpe está marcado, não dado — a espada mentiria',
      );
      expect(
        find.text('Confirmar pago'),
        findsNothing,
        reason: 'já está pago; não há o que confirmar',
      );
    });

    testWidgets('o agendado NÃO desconta do monstro hoje', (tester) async {
      final state = arenaTestState(
        commitments: [
          arenaTestCommitment(
            id: 'seguro',
            description: 'Segurança C6',
            amount: 29.90,
            dayOffset: 2,
            scheduled: true,
          ),
        ],
      );

      expect(state.monsterHp, 29.90);
      expect(state.monsterMaxHp, 29.90);
      expect(state.struckCount, 0);
    });

    testWidgets('vencida DENTRO da semana e pendente vai para o topo', (
      tester,
    ) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          commitments: [
            arenaTestCommitment(id: 'hoje', description: 'Aluguel'),
            arenaTestCommitment(
              id: 'segunda',
              description: 'Luz',
              amount: 180,
              dayOffset: -2,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).last);
      await arenaFrames(tester);

      // A lista já vem ordenada pela calculadora; aqui o que se guarda é o
      // DESTAQUE: atraso da semana lê igual a atraso antigo.
      expect(find.textContaining('Atrasado'), findsOneWidget);
      expect(
        find.textContaining('Enfurecido'),
        findsNothing,
        reason: 'enfurecer é privilégio do atraso de semanas anteriores',
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

    testWidgets('no rombo o rodapé diz "falta em caixa", e explica', (
      tester,
    ) async {
      // "Livre −R\$ 9.007,31" é uma contradição em dois caracteres. E um
      // rombo sem culpado manda a pessoa procurar sozinha em quatro telas.
      await pumpArena(
        tester,
        state: arenaTestState(
          initialBalance: 3115.02,
          currentBalance: 3115.02,
          commitments: [
            arenaTestCommitment(
              id: 'fatura',
              description: 'Fatura Cartão Nubank',
              amount: 8300.55,
              dayOffset: -3,
              overdue: true,
            ),
            arenaTestCommitment(
              id: 'emprestimo',
              description: 'Pagamento de empréstimo',
              amount: 3811.78,
              dayOffset: 2,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(ArenaHpBar).first);
      await arenaFrames(tester);

      expect(find.text('Falta em caixa'), findsOneWidget);
      expect(find.text('Livre'), findsNothing);
      // O número é positivo: falta se mede para cima. (8.300,55 + 3.811,78
      // de compromisso contra 3.115,02 em caixa.)
      expect(find.textContaining('8.997,31'), findsWidgets);
      expect(find.textContaining('-8.997,31'), findsNothing);

      final causa = find.byKey(const ValueKey('arena-shortfall-cause'));
      expect(causa, findsOneWidget);
      expect(find.textContaining('Fatura Cartão Nubank'), findsWidgets);
      expect(find.textContaining('vencido há 3 dias'), findsOneWidget);
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

    testWidgets('a cena tem semântica: a luta não é um retângulo mudo', (
      tester,
    ) async {
      await pumpArena(tester);

      expect(find.bySemanticsLabel(RegExp('A luta da semana')), findsOneWidget);
    });

    testWidgets('no desktop a ARTE estica e o PLACAR fica centrado', (
      tester,
    ) async {
      // Inverteu com o full-bleed. A cena virou o fundo da aba e vai de
      // borda a borda mesmo num monitor; o teto de largura ficou com os
      // overlays — esticado, o placar deixa a vida dos heróis e a do monstro
      // a mil pixels uma da outra, e elas param de se enfrentar.
      await pumpArena(tester, size: const Size(1300, 900));

      final cena = tester.getRect(find.byType(GameWidget<ArenaGame>));
      final placar = tester.getRect(find.byType(ArenaHud));

      expect(cena.width, 1300);
      expect(placar.width, lessThanOrEqualTo(arenaMaxSceneWidth));
      expect(placar.center.dx, closeTo(650, 8));
    });

    testWidgets('o pé da cena já tem a faixa reservada do HUD mensal', (
      tester,
    ) async {
      await pumpArena(tester);

      final slot = find.byKey(const ValueKey('arena-footer-slot'));
      expect(
        slot,
        findsOneWidget,
        reason:
            'a faixa está vazia de propósito: o HUD de escopo mensal chega no '
            'próximo pacote, e reservar a altura agora evita que ele '
            'reorganize a cena, a altura da Home e os goldens de uma vez',
      );
      expect(tester.getSize(slot).height, 56);
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
          commitments: const [],
          accounts: const [],
        ),
      );

      expect(find.byType(GameWidget<ArenaGame>), findsNothing);
      expect(find.textContaining('a arena está vazia'), findsOneWidget);
    });
  });
}
