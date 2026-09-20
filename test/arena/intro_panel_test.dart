import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/intro/intro_store.dart';
import 'package:funances/core/widgets/info_intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hud_harness.dart';

/// A explicação das folhas do HUD: uma aula na primeira vez, e um ícone nas
/// outras.
///
/// O dono descreveu o problema com precisão: *"a descrição ocupa muito espaço
/// e o que importa fica espremido num scroll na parte de baixo da tela"*. A
/// correção tem duas metades, e as duas podem quebrar sozinhas:
///
/// 1. **a explicação sai do corpo.** O que a folha mostra ao abrir são os
///    DADOS. Um teste de posição guarda isso, porque um texto de volta ao
///    meio do caminho não quebra nada que se pareça com um erro;
/// 2. **mas ela continua chegando.** Uma explicação que só existe atrás de um
///    ícone é uma explicação que ninguém lê. A primeira abertura de cada
///    folha a mostra sozinha — e a segunda, não.

/// O painel de explicação está na tela?
Finder get _painel => find.byKey(const ValueKey('intro-panel'));

/// Fecha a folha do HUD.
///
/// Pelo `Navigator`, e não por um toque no alto da tela: a folha da vila tem
/// dezoito aldeões e ocupa a tela inteira num celular — não sobra barreira
/// para tocar, e o teste passaria a medir a altura da folha em vez do que ele
/// quer medir. O toque FORA tem teste próprio, na folha da poção, que é curta.
Future<void> _fecharFolha(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

Future<bool?> _marcado(String intro) async =>
    (await SharedPreferences.getInstance()).getBool(IntroStore.keyFor(intro));

void main() {
  group('a memória do aparelho', () {
    test('sem marca, a folha nunca foi apresentada', () async {
      SharedPreferences.setMockInitialValues({});
      final store = IntroStore();

      expect(await store.wasSeen(IntroKeys.hudPotion), isFalse);
    });

    test('a marca é por SLOT: ler sobre a poção não ensina a vila', () async {
      SharedPreferences.setMockInitialValues({});
      final store = IntroStore();

      await store.markSeen(IntroKeys.hudPotion);

      expect(await store.wasSeen(IntroKeys.hudPotion), isTrue);
      expect(await store.wasSeen(IntroKeys.hudVillage), isFalse);
      expect(await store.wasSeen(IntroKeys.hudEgg), isFalse);
      expect(await store.wasSeen(IntroKeys.hudDrop), isFalse);
    });

    test('"rever as explicações" apaga as quatro de uma vez', () async {
      // O método existe para a opção de configurações que o dono ainda não
      // pediu. Ele é testado agora porque uma porta que ninguém abre é uma
      // porta que enferruja: quando a opção chegar, ela não vai inventar uma
      // segunda forma de apagar as chaves.
      SharedPreferences.setMockInitialValues({
        for (final intro in IntroKeys.all) IntroStore.keyFor(intro): true,
      });
      final store = IntroStore();

      await store.showAgain();

      for (final intro in IntroKeys.all) {
        expect(await store.wasSeen(intro), isFalse, reason: intro);
      }
    });
  });

  group('a primeira abertura de cada folha', () {
    testWidgets('mostra a explicação sozinha, e grava que mostrou', (
      tester,
    ) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        introSeen: false,
      );

      await openHudSheet(tester, 0);

      expect(_painel, findsOneWidget);
      expect(
        find.textContaining('capital que trabalha por você'),
        findsOneWidget,
      );

      // A marca só é gravada quando o painel FECHA: enquanto ele está na
      // tela, ninguém leu nada ainda.
      expect(await _marcado(IntroKeys.hudPotion), isNull);

      await tester.tap(find.byKey(const ValueKey('intro-panel-got-it')));
      await tester.pumpAndSettle();

      expect(_painel, findsNothing);
      expect(await _marcado(IntroKeys.hudPotion), isTrue);
    });

    testWidgets('tocar FORA do painel também conta como lido', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        introSeen: false,
      );

      await openHudSheet(tester, 0);
      expect(_painel, findsOneWidget);

      // Quem fecha por fora fechou porque já leu — ou porque não quer ler.
      // Nos dois casos, insistir na próxima abertura é castigo.
      await tester.tapAt(const Offset(200, 4));
      await tester.pumpAndSettle();

      expect(_painel, findsNothing);
      expect(await _marcado(IntroKeys.hudPotion), isTrue);
    });

    testWidgets('na SEGUNDA vez a folha abre direto nos dados', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        introSeen: false,
      );

      await openHudSheet(tester, 0);
      await tester.tap(find.byKey(const ValueKey('intro-panel-got-it')));
      await tester.pumpAndSettle();
      await _fecharFolha(tester);

      await openHudSheet(tester, 0);

      expect(_painel, findsNothing);
      expect(find.text('Cofrinho Disney'), findsOneWidget);
    });

    testWidgets('as quatro folhas se apresentam por conta própria', (
      tester,
    ) async {
      // Quatro assuntos, quatro marcas: quem leu o que a poção é continua
      // sem saber o que um aldeão é.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        introSeen: false,
      );

      await openHudSheet(tester, 0);
      expect(_painel, findsOneWidget, reason: 'poção');
      await tester.tap(find.byKey(const ValueKey('intro-panel-got-it')));
      await tester.pumpAndSettle();
      await _fecharFolha(tester);

      await openHudSheet(tester, 1);
      expect(_painel, findsOneWidget, reason: 'vila');
      expect(find.textContaining('Cada categoria com orçamento'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('intro-panel-got-it')));
      await tester.pumpAndSettle();
      await _fecharFolha(tester);

      expect(await _marcado(IntroKeys.hudPotion), isTrue);
      expect(await _marcado(IntroKeys.hudVillage), isTrue);
      // As duas que ninguém abriu continuam devendo a aula.
      expect(await _marcado(IntroKeys.hudEgg), isNull);
      expect(await _marcado(IntroKeys.hudDrop), isNull);

      await openHudSheet(tester, 2);
      expect(_painel, findsOneWidget, reason: 'incubados');
    });

    testWidgets('no modo empresa a aula é a da empresa', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        isBusiness: true,
        introSeen: false,
      );

      await openHudSheet(tester, 1);

      expect(_painel, findsOneWidget);
      expect(find.textContaining('Cada centro de custo'), findsOneWidget);
      expect(find.textContaining('limite por centro de custo'), findsOneWidget);
      expect(find.textContaining('Cada categoria com orçamento'), findsNothing);
    });

    testWidgets('"reduzir movimento" não impede a aula, e nada fica se '
        'mexendo depois dela', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        reduceMotion: true,
        introSeen: false,
      );

      await openHudSheet(tester, 3);

      expect(_painel, findsOneWidget);
      // Nem a folha nem o painel animam por conta própria: se algum deles
      // tivesse ganhado um movimento de enfeite, ele pediria quadro aqui.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('o ícone de informação', () {
    testWidgets('abre a mesma explicação, quantas vezes o usuário quiser', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await openHudSheet(tester, 0);
      expect(_painel, findsNothing);

      await openHudExplanation(tester);
      expect(_painel, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('intro-panel-got-it')));
      await tester.pumpAndSettle();

      await openHudExplanation(tester);
      expect(_painel, findsOneWidget);
    });

    testWidgets('diz de QUAL folha ele é a explicação', (tester) async {
      // Um "i" solto não diz nada a quem usa leitor de tela. O rótulo é a
      // frase inteira, e é o mesmo texto do tooltip.
      await pumpHudFooter(tester, size: const Size(400, 900));

      await openHudSheet(tester, 2);

      expect(
        find.bySemanticsLabel('Como funcionam os Monstros incubados'),
        findsOneWidget,
      );
    });
  });

  group('o que importa vem primeiro', () {
    testWidgets('os dados começam no alto da folha, sem texto na frente', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 800));

      await openHudSheet(tester, 0);

      // Nenhum dos três parágrafos está no corpo da folha.
      expect(
        find.textContaining('capital que trabalha por você'),
        findsNothing,
      );

      final folha = tester.getRect(find.byKey(const ValueKey('hud-sheet-potion')));
      final conta = tester.getRect(find.text('Cofrinho Disney'));

      // A medida é do topo da FOLHA até o primeiro dado, e não do topo da
      // tela: a folha é modal e encosta no pé da janela, e comparar a altura
      // absoluta de duas camadas modais diferentes não diz nada. Do topo da
      // folha até aqui cabem o cabeçalho, o chip de meses de pé e a nota de
      // receita — cerca de 165 px. Os três parágrafos que moravam no meio
      // do caminho somavam, sozinhos, mais de 400 px em 400 de largura: se
      // algum deles voltar, esta conta estoura de longe.
      expect(
        conta.top - folha.top,
        lessThan(200),
        reason:
            'algum texto voltou a se meter entre o número e a primeira linha '
            '— era exatamente a queixa do dono',
      );
      expect(conta.bottom, lessThanOrEqualTo(800), reason: 'abaixo da dobra');
    });
  });

  group('desktop', () {
    testWidgets('a explicação é um balão ancorado no ícone, e não uma folha', (
      tester,
    ) async {
      await pumpHudFooter(
        tester,
        size: const Size(1300, 900),
        compact: false,
        introSeen: false,
      );

      await openHudSheet(tester, 0);

      expect(_painel, findsOneWidget);

      // Uma SÓ folha modal na tela: a do HUD. Numa janela de 1300 px um
      // segundo painel subindo do pé deixaria o ícone que o abriu a meia
      // tela de distância do que ele abriu.
      expect(find.byType(BottomSheet), findsOneWidget);

      final icone = tester.getRect(find.byType(InfoIntroButton));
      final balao = tester.getRect(_painel);

      // Encostado no ícone: embaixo dele quando cabe, em cima quando não
      // cabe. O que o teste guarda é a VIZINHANÇA — um balão que nasce longe
      // do gatilho perde a relação de causa e efeito que ele existe para ter.
      final colado =
          (balao.top - icone.bottom).abs() < 24 ||
          (icone.top - balao.bottom).abs() < 24;

      expect(colado, isTrue, reason: 'balão $balao, ícone $icone');
      expect(balao.right, closeTo(icone.right, 1));
      expect(balao.width, lessThanOrEqualTo(420));
    });

    testWidgets('no celular ela é uma folha sobre a folha', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        introSeen: false,
      );

      await openHudSheet(tester, 0);

      expect(_painel, findsOneWidget);
      // Duas folhas: a do HUD, embaixo, e a explicação por cima dela. O
      // scroll da primeira não se mexe.
      expect(find.byType(BottomSheet), findsNWidgets(2));
    });
  });
}
