import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';

/// A hachura do ROMBO tem de chegar VERMELHA à tela.
///
/// O defeito que este teste existe para impedir não aparece no código: lá
/// está escrito `palette.dangerText`, e quem lê acredita. Ele aparece só nos
/// pixels. A hachura normal é um traço a 50% sobre um véu escuro a 50% sobre
/// o preenchimento — três camadas translúcidas que somam para o cinza, que é
/// exatamente o que ela quer dizer ("reservado"). No rombo a cor É a
/// informação, e o mesmo empilhamento comia o vermelho: o golden media
/// **#4A4544**, cinza puro, sem sinal nenhum de perigo.
///
/// A conta que o teste faz é a mais simples que distingue as duas coisas: o
/// canal vermelho tem de ganhar do verde por uma margem que o olho reconheça.
/// Quarenta pontos separa "vermelho" de "cinza-amarelado" com folga — o cinza
/// do defeito tinha diferença de CINCO (0x4A − 0x45).

/// O maior `R − G` entre os pixels da imagem.
///
/// Só a diferença interessa: o valor absoluto muda com o tema, com a
/// opacidade e com o que está por baixo, mas "quanto o vermelho ganha do
/// verde" é a pergunta de cor que a hachura precisa responder.
({int delta, int r, int g, int b}) _maisVermelho(ByteData pixels) {
  var melhor = (delta: -255, r: 0, g: 0, b: 0);

  for (var i = 0; i + 3 < pixels.lengthInBytes; i += 4) {
    final r = pixels.getUint8(i);
    final g = pixels.getUint8(i + 1);
    final b = pixels.getUint8(i + 2);
    final a = pixels.getUint8(i + 3);
    if (a < 250) continue;

    final delta = r - g;
    if (delta > melhor.delta) melhor = (delta: delta, r: r, g: g, b: b);
  }

  return melhor;
}

Future<ByteData> _pixels(WidgetTester tester, {required bool pressed}) async {
  final chave = GlobalKey();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.surfaceDeep,
        body: Center(
          child: RepaintBoundary(
            key: chave,
            child: SizedBox(
              width: 160,
              height: 16,
              child: ArenaHpBar(
                // Barra CHEIA com a faixa comprometida cobrindo tudo: é o
                // retrato do rombo — R$ 3.115,02 em caixa contra R$ 12.122,33
                // de compromisso, no domingo.
                ratio: 1,
                committedRatio: 1,
                pressed: pressed,
                color: AppColors.teal,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // As barras animam; sem deixar a animação terminar, a captura pega a faixa
  // no meio do caminho.
  await tester.pump(const Duration(seconds: 2));

  final boundary =
      chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();

  return bytes!;
}

void main() {
  testWidgets('a hachura do rombo chega vermelha à tela', (tester) async {
    late ({int delta, int r, int g, int b}) cor;

    await tester.runAsync(() async {
      final bytes = await _pixels(tester, pressed: true);
      cor = _maisVermelho(bytes);
    });

    debugPrint(
      'ROMBO — pixel mais vermelho: '
      'R=${cor.r} G=${cor.g} B=${cor.b} (R−G=${cor.delta})',
    );

    expect(
      cor.delta,
      greaterThan(40),
      reason:
          'a hachura mediu R=${cor.r} G=${cor.g} B=${cor.b}. O defeito que '
          'isto guarda pintava #4A4544 — cinza, com R−G de cinco — porque o '
          'traço a 50% sobre o véu escuro a 50% cancelava o vermelho',
    );
  });

  testWidgets('a hachura NORMAL continua cinza, e é para ser', (tester) async {
    // A outra metade da afirmação. "Comprometido" é reserva, não perigo: se
    // esta também virasse vermelha, o rombo perderia o contraste que o
    // distingue de uma semana comum.
    late ({int delta, int r, int g, int b}) cor;

    await tester.runAsync(() async {
      final bytes = await _pixels(tester, pressed: false);
      cor = _maisVermelho(bytes);
    });

    debugPrint(
      'RESERVA — pixel mais vermelho: '
      'R=${cor.r} G=${cor.g} B=${cor.b} (R−G=${cor.delta})',
    );

    expect(
      cor.delta,
      lessThanOrEqualTo(40),
      reason: 'a faixa de comprometido não é um alarme',
    );
  });
}
