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

  group('HP é dinheiro POSITIVO em conta', () {
    /// A regra do dono: *"HP do herói = dinheiro positivo em conta; barra =
    /// saldo início da semana (max) / saldo atual"*.
    ///
    /// A conta antiga (`atual / inicial`) tinha um buraco que o QA da Home
    /// já tinha visto: com os DOIS negativos ela dá 1, e a barra aparecia
    /// CHEIA para quem está no vermelho — dois negativos se cancelando numa
    /// boa notícia.
    for (final caso
        in <({
          String nome,
          double inicial,
          double atual,
          double ratio,
          bool pisca,
        })>[
          // O rombo REAL do cofre no dia do QA.
          (
            nome: 'rombo: começou e continua devendo',
            inicial: -6361.92,
            atual: -6361.92,
            ratio: 0,
            pisca: true,
          ),
          (
            nome: 'sem caixa: zerou no meio da semana',
            inicial: 5200,
            atual: 0,
            ratio: 0,
            pisca: true,
          ),
          (
            nome: 'começou com caixa e furou',
            inicial: 5200,
            atual: -1200,
            ratio: 0,
            pisca: true,
          ),
          // Régua zero: 50 sobre 0 não é infinito — é cheio.
          (
            nome: 'começou devendo e virou o caixa',
            inicial: -900,
            atual: 50,
            ratio: 1,
            pisca: false,
          ),
          (
            nome: 'semana comum',
            inicial: 5200,
            atual: 2600,
            ratio: 0.5,
            pisca: false,
          ),
        ]) {
      test(caso.nome, () {
        final state = arenaTestState(
          initialBalance: caso.inicial,
          currentBalance: caso.atual,
        );

        expect(state.heroHpRatio, closeTo(caso.ratio, 0.001));
        expect(state.heroHp <= 0, caso.pisca, reason: 'pisca?');
        // A barra NUNCA passa de 100%.
        expect(state.heroHpRatio, lessThanOrEqualTo(1));
      });
    }

    test('sem vida não há o que reservar: a hachura some', () {
      final rombo = arenaTestState(
        initialBalance: -6361.92,
        currentBalance: -6361.92,
      );

      expect(rombo.committed, greaterThan(0), reason: 'há compromisso');
      expect(rombo.committedRatio, 0);
    });

    test('o selo do rombo continua com o número', () {
      final rombo = arenaTestState(
        initialBalance: -6361.92,
        currentBalance: -6361.92,
      );

      expect(rombo.isPressed, isTrue);
      expect(rombo.shortfall, greaterThan(0));
    });
  });

  group('de que lado o alarme toca', () {
    testWidgets('o ROMBO acende, e a barra dele está vazia', (tester) async {
      // O retrato real do cofre no dia do QA: começou a semana devendo e
      // continua devendo. Era aqui que a barra aparecia CHEIA.
      await pumpArena(
        tester,
        state: arenaTestState(
          initialBalance: -6361.92,
          currentBalance: -6361.92,
        ),
      );

      final herois = tester.widgetList<ArenaHpBar>(find.byType(ArenaHpBar)).first;

      expect(herois.depleted, isTrue);
      expect(herois.ratio, 0);
      expect(herois.committedRatio, 0, reason: 'sem vida, sem hachura');
    });

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
