import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';

import 'arena/arena_harness.dart';
import 'support/home_harness.dart';

/// D2 — a Home tem de caber. Agora ela cabe por CONSTRUÇÃO.
///
/// "A Home está longa demais" foi a segunda coisa que o dono disse sobre o
/// APK. A rodada anterior atacou isso cortando e resumindo blocos, e o teto
/// que este arquivo media era de DUAS telas — com dados típicos ela chegava a
/// 1.477px a 400px de largura, 2,7 viewports.
///
/// A decisão 1 tirou a pergunta do caminho: a primeira aba é a cena do jogo,
/// e a cena ocupa o que sobra entre o placar e o rodapé mensal. Não há mais
/// acúmulo possível — nenhum bloco novo pode empurrar outro para fora da
/// tela, porque não há bloco nenhum. O que este arquivo mede, então, mudou de
/// pergunta: não é mais "cabe em quantas telas?", é **"cabe em UMA, sem
/// rolagem e sem estourar?"**.
///
/// Ele mede na tela REAL (`HomeScreen`), e não só na aba: é a `AppBar`, a
/// barra inferior e o botão de lançar que comem o viewport, e foi medindo só
/// a aba que a rodada anterior viu 1,5 telas enquanto o aparelho mostrava
/// 7,1.

/// Monta a tela inteira e deixa a folha de sprites carregar.
///
/// O `runAsync` não é detalhe: o `decodeImageFromList` do Flame depende do
/// relógio de verdade, e o relógio falso do `flutter_test` nunca entrega o
/// resultado do codec.
Future<void> _pumpTelaReal(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      homeApp(
        const HomeScreen(),
        overrides: arenaOverrides(
          missions: homeTypicalMissions(),
          pendingAutomatic: homeTypicalPending(),
          lastInsight: homeTypicalInsight(),
        ),
      ),
    );

    for (var i = 0; i < 12; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  });

  await arenaFrames(tester);
}

void main() {
  for (final tamanho in const <Size>[
    // o celular do dono, e a altura de viewport que a rodada anterior media
    Size(400, 800),
    Size(400, 544),
    // tablet em pé e desktop
    Size(800, 600),
    Size(1300, 900),
  ]) {
    final nome = '${tamanho.width.toInt()}×${tamanho.height.toInt()}';

    testWidgets('D2 — a Home cabe em UMA tela a $nome', (tester) async {
      await _pumpTelaReal(tester, tamanho);

      final aba = tester.getSize(find.byType(ArenaTab));
      final viewport = tester.getSize(find.byType(TabBarView));

      expect(
        aba.height,
        lessThanOrEqualTo(viewport.height + 0.5),
        reason:
            'a aba mede ${aba.height.toStringAsFixed(0)}px num viewport de '
            '${viewport.height.toStringAsFixed(0)}px',
      );

      expect(
        find.descendant(
          of: find.byType(ArenaTab),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
        reason: 'a cena preenche; não há o que rolar',
      );

      // Um `RenderFlex` estourado vira exceção no `pump`. É a rede que pega o
      // caso em que o placar, a cena e o rodapé somados passam da altura —
      // exatamente o que aconteceria numa tela muito baixa.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o rodapé mensal fica ACIMA da barra inferior', (tester) async {
    // Era o que `extendBody: true` escondia: o corpo se estendia por baixo da
    // barra, e os quatro ícones do HUD mensal — a última linha da cena —
    // ficavam atrás dela.
    await _pumpTelaReal(tester, const Size(400, 800));

    final rodape = tester.getRect(
      find.byKey(const ValueKey('arena-footer-slot')),
    );
    final barra = tester.getRect(find.byType(BottomAppBar));

    expect(rodape.bottom, lessThanOrEqualTo(barra.top + 0.5));
  });

  testWidgets('num monitor a Arena não estica de borda a borda', (
    tester,
  ) async {
    await _pumpTelaReal(tester, const Size(1300, 900));

    final cena = tester.getSize(find.byType(ArenaView));

    expect(cena.width, lessThanOrEqualTo(arenaMaxSceneWidth));
  });
}
