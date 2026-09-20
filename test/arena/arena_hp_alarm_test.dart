import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';

import 'arena_harness.dart';

/// A barra vazia dos heróis PISCA em vermelho.
///
/// O dono: *"coloca a barra do herói piscando em vermelho indicando que ele
/// tá mal quando a barra estiver vazia… a barra vazia não chama muita
/// atenção, já uma barra piscando em vermelho chamaria e indicaria o
/// perigo"*.
///
/// Três coisas podem dar errado, e as três já deram em alguma barra de jogo:
///
/// 1. **o alarme não chegar aos pixels.** É o mesmo defeito que a hachura do
///    rombo teve: no código está escrito `danger` e na tela sai cinza;
/// 2. **o alarme tocar do lado errado.** A barra do MONSTRO também chega a
///    zero, e lá o zero é a melhor notícia da semana;
/// 3. **o ticker sobreviver.** O placar fica na tela a sessão inteira; um
///    controlador que continua pedindo quadro depois que a vida volta — ou
///    depois que o widget sai — é bateria gasta em pixel parado.

Widget _barra({required bool depleted, bool reduceMotion = false}) =>
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: AppColors.surfaceDeep,
        body: Center(
          child: RepaintBoundary(
            key: _chave,
            child: SizedBox(
              width: 160,
              height: 16,
              child: ArenaHpBar(
                ratio: depleted ? 0 : 0.7,
                depleted: depleted,
                color: AppColors.teal,
              ),
            ),
          ),
        ),
      ),
    );

final GlobalKey _chave = GlobalKey();

/// O maior `R − G` entre os pixels: "quanto o vermelho ganha do verde".
({int delta, int r, int g, int b}) _maisVermelho(ByteData pixels) {
  var melhor = (delta: -255, r: 0, g: 0, b: 0);

  for (var i = 0; i + 3 < pixels.lengthInBytes; i += 4) {
    final r = pixels.getUint8(i);
    final g = pixels.getUint8(i + 1);
    final b = pixels.getUint8(i + 2);
    if (pixels.getUint8(i + 3) < 250) continue;

    final delta = r - g;
    if (delta > melhor.delta) melhor = (delta: delta, r: r, g: g, b: b);
  }

  return melhor;
}

Future<ByteData> _pixels(WidgetTester tester) async {
  final boundary =
      _chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();

  return bytes!;
}

void main() {
  group('o alarme', () {
    testWidgets('a calha vazia chega VERMELHA à tela', (tester) async {
      late ({int delta, int r, int g, int b}) cor;

      await tester.runAsync(() async {
        await tester.pumpWidget(_barra(depleted: true));
        // No pico do pulso: meio segundo de ida.
        await tester.pump(const Duration(milliseconds: 500));
        cor = _maisVermelho(await _pixels(tester));
      });

      expect(
        cor.delta,
        greaterThan(40),
        reason:
            'a calha mediu R=${cor.r} G=${cor.g} B=${cor.b} — uma barra '
            'vazia que não fica vermelha é uma barra vazia',
      );
    });

    testWidgets('com vida, a calha continua escura e parada', (tester) async {
      late ({int delta, int r, int g, int b}) cor;

      await tester.runAsync(() async {
        await tester.pumpWidget(_barra(depleted: false));
        await tester.pump(const Duration(seconds: 1));
        cor = _maisVermelho(await _pixels(tester));
      });

      expect(cor.delta, lessThanOrEqualTo(40));
    });
  });

  group('o ticker', () {
    testWidgets('só pede quadro quando a vida acabou', (tester) async {
      await tester.pumpWidget(_barra(depleted: false));
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_barra(depleted: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('a vida voltando, o alarme para', (tester) async {
      await tester.pumpWidget(_barra(depleted: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(_barra(depleted: false));
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('o alarme morre junto com a barra', (tester) async {
      await tester.pumpWidget(_barra(depleted: true));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('"reduzir movimento" troca o pulso por vermelho fixo', (
      tester,
    ) async {
      await tester.pumpWidget(_barra(depleted: true, reduceMotion: true));
      await tester.pumpAndSettle();

      // Nada se mexe...
      expect(tester.binding.hasScheduledFrame, isFalse);

      // ...e mesmo assim a calha é vermelha: sem pulso, quem carrega o
      // alarme é a cor cheia e o contorno mais grosso.
      late ({int delta, int r, int g, int b}) cor;
      await tester.runAsync(() async {
        cor = _maisVermelho(await _pixels(tester));
      });

      expect(cor.delta, greaterThan(40));
    });
  });

  group('de que lado o alarme toca', () {
    testWidgets('herói sem caixa acende; monstro derrotado, não', (
      tester,
    ) async {
      // Caixa em zero contra um domingo de R$ 5.200: a barra dos heróis
      // esvazia. O monstro deste estado está pago — barra dele também em
      // zero, e lá isso é vitória.
      await pumpArena(
        tester,
        state: arenaTestState(
          currentBalance: 0,
          commitments: [arenaTestCommitment(paid: true)],
        ),
      );

      final barras = tester
          .widgetList<ArenaHpBar>(find.byType(ArenaHpBar))
          .toList();

      expect(barras.length, 2);
      expect(barras.first.depleted, isTrue, reason: 'heróis');
      expect(barras.last.depleted, isFalse, reason: 'monstro');
    });

    testWidgets('a semântica diz o perigo ANTES do saldo', (tester) async {
      await pumpArena(
        tester,
        state: arenaTestState(
          currentBalance: 0,
          commitments: [arenaTestCommitment(paid: true)],
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('^Vida dos heróis esgotada, perigo.')),
        findsOneWidget,
      );
    });

    testWidgets('com caixa, ninguém acende', (tester) async {
      await pumpArena(tester, state: arenaTestState());

      for (final barra in tester.widgetList<ArenaHpBar>(
        find.byType(ArenaHpBar),
      )) {
        expect(barra.depleted, isFalse);
      }

      expect(find.byType(ArenaHud), findsOneWidget);
    });
  });
}
