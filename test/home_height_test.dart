import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';

import 'arena/arena_harness.dart';
import 'arena/hud_harness.dart';
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
Future<void> _pumpTelaReal(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      homeApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const HomeScreen(),
        ),
        overrides: arenaOverrides(
          missions: homeTypicalMissions(),
          pendingAutomatic: homeTypicalPending(),
          lastInsight: homeTypicalInsight(),
          extra: [
            // O rodapé mensal só desenha as quatro figuras quando tem
            // números: sem isto a faixa fica vazia e o teste do entalhe
            // mediria o nada.
            HudViewProviders.state.overrideWith(
              (ref) => AsyncValue<HudState>.data(hudTestState()),
            ),
          ],
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

  /// M3 — o botão de lançar invadia o HUD mensal.
  ///
  /// O QA mediu: `Rect(172,708→228,764)` do FAB contra `0,680→400,736` da
  /// faixa — 28px de ovo e de vila escondidos atrás do círculo dourado. O
  /// botão não sai do lugar (é a ação que o app existe para receber, e a
  /// decisão do dono é que ele fica na barra de todas as telas principais);
  /// quem cede é a faixa, com um vão no meio.
  // 1,6 é o topo da escala de texto do sistema. N5 do QA: o rodapé mensal
  // estourava por 0,78px ali — a listra amarela e preta atravessando a faixa
  // por causa de menos de um pixel.
  for (final escala in const <double>[1, 1.3, 1.6]) {
    testWidgets('M3 — o FAB não cobre nenhum slot do HUD (texto ×$escala)', (
      tester,
    ) async {
      await _pumpTelaReal(tester, const Size(400, 800), textScale: escala);

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final slots = find.byType(HudGlyph);

      expect(slots, findsNWidgets(4), reason: 'poção, vila, ovo e gota');

      for (final slot in slots.evaluate()) {
        final figura = tester.getRect(find.byWidget(slot.widget));
        expect(
          figura.overlaps(fab),
          isFalse,
          reason:
              'a figura em $figura fica atrás do botão em $fab; o vão do '
              'entalhe não deu conta',
        );
      }
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

  testWidgets('num monitor a ARTE estica, e o que se lê não', (tester) async {
    // Inverteu com o full-bleed: a cena passou a ser o fundo da aba e vai de
    // borda a borda mesmo num monitor; o teto de largura ficou com os
    // overlays, que são o que se lê.
    await _pumpTelaReal(tester, const Size(1300, 900));

    expect(
      tester.getSize(find.byType(ArenaView)).width,
      greaterThan(arenaMaxSceneWidth),
    );
    expect(
      tester.getSize(find.byType(ArenaHud)).width,
      lessThanOrEqualTo(arenaMaxSceneWidth),
    );
  });
}
