import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';

/// As quatro figuras do rodapé têm de ser QUATRO figuras.
///
/// Na primeira rodada o ovo e a gota eram a mesma silhueta — bico em cima,
/// barriga embaixo — em duas cores. A 30 px, num pé de tela, isso não é "duas
/// figuras parecidas": é uma figura só, e o usuário que aprendeu a ler a gota
/// passa a achar que tem duas dívidas.
///
/// O defeito não aparece no código (são dois `Path` diferentes, com números
/// diferentes) nem num golden que ninguém amplia. Ele aparece na MÁSCARA: que
/// fração dos pixels de uma figura a outra também pinta.
///
/// E há uma segunda afirmação aqui: a casca do ovo é VERDE mesmo quando o
/// anel em volta dele está vermelho. Ovo e anel foram separados de propósito
/// — quem mede o tamanho da dívida é o anel — e um ovo que também mudasse de
/// cor perderia, justo no estágio em que mais importa, a única coisa que o
/// identifica de relance.
///
/// A terceira é do pacote de conteúdo: as duas figuras ganharam MIOLO sem
/// ganhar silhueta nova. O veneno tem caveira, o monstro incubado
/// aparece por dentro da casca no último estágio — e nada disso pode mexer
/// nos contornos, senão a distinção que as três primeiras afirmações
/// protegem se perde por outro caminho.

const double _lado = 30;

/// Os pixels pintados da figura: `true` onde há tinta opaca.
Future<List<bool>> _mascara(
  WidgetTester tester,
  HudSlot slot, {
  Color color = AppColors.success,
  int stage = 0,
  bool filled = true,
}) async {
  final bytes = await _pixels(
    tester,
    slot,
    color: color,
    stage: stage,
    filled: filled,
  );

  return _mascaraDe(bytes);
}

List<bool> _mascaraDe(ByteData bytes) => [
  for (var i = 0; i + 3 < bytes.lengthInBytes; i += 4)
    bytes.getUint8(i + 3) >= 128,
];

Future<ByteData> _pixels(
  WidgetTester tester,
  HudSlot slot, {
  required Color color,
  required int stage,
  required bool filled,
}) async {
  final chave = GlobalKey();

  await tester.pumpWidget(
    // Sem Scaffold e sem fundo: a figura é capturada sobre o transparente,
    // que é o que permite ler a SILHUETA em vez da cor do que está atrás.
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: chave,
          child: HudGlyph(
            slot: slot,
            color: color,
            size: _lado,
            stage: stage,
            filled: filled,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();

  return bytes!;
}

/// A fração de pixels em que as duas máscaras DISCORDAM, sobre a união delas.
///
/// É a distância de Jaccard: 0 são a mesma figura, 1 são figuras que não se
/// tocam em pixel nenhum.
double _distancia(List<bool> a, List<bool> b) {
  var uniao = 0;
  var diferenca = 0;

  for (var i = 0; i < a.length; i++) {
    if (a[i] || b[i]) uniao++;
    if (a[i] != b[i]) diferenca++;
  }

  return uniao == 0 ? 0 : diferenca / uniao;
}

/// Quantos pixels opacos têm EXATAMENTE esta cor.
///
/// É como se prova que uma figura foi escavada: a caveira do veneno e o corpo
/// do monstro são pintados com a cor da calha, e contar essa cor é contar o
/// buraco. Uma tolerância pequena cobre a suavização das bordas.
int _contaCor(ByteData pixels, Color alvo, {int? ateLinha}) {
  final r = (alvo.r * 255).round();
  final g = (alvo.g * 255).round();
  final b = (alvo.b * 255).round();
  final limite = ateLinha == null
      ? pixels.lengthInBytes
      : ateLinha * _lado.toInt() * 4;
  var n = 0;

  for (var i = 0; i + 3 < limite; i += 4) {
    if (pixels.getUint8(i + 3) < 250) continue;
    if ((pixels.getUint8(i) - r).abs() > 6) continue;
    if ((pixels.getUint8(i + 1) - g).abs() > 6) continue;
    if ((pixels.getUint8(i + 2) - b).abs() > 6) continue;
    n++;
  }

  return n;
}

/// A cor média dos pixels opacos.
({int r, int g, int b}) _corMedia(ByteData pixels) {
  var r = 0, g = 0, b = 0, n = 0;

  for (var i = 0; i + 3 < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i + 3) < 250) continue;
    r += pixels.getUint8(i);
    g += pixels.getUint8(i + 1);
    b += pixels.getUint8(i + 2);
    n++;
  }

  return n == 0 ? (r: 0, g: 0, b: 0) : (r: r ~/ n, g: g ~/ n, b: b ~/ n);
}

void main() {
  testWidgets('a 30 px as quatro figuras são quatro silhuetas', (tester) async {
    late Map<HudSlot, List<bool>> mascaras;

    await tester.runAsync(() async {
      mascaras = {
        for (final slot in HudSlot.values) slot: await _mascara(tester, slot),
      };
    });

    for (final slot in HudSlot.values) {
      final pintados = mascaras[slot]!.where((p) => p).length;
      expect(
        pintados,
        greaterThan(60),
        reason: '$slot mal apareceu na captura ($pintados pixels)',
      );
    }

    final pares = <(HudSlot, HudSlot)>[
      for (var i = 0; i < HudSlot.values.length; i++)
        for (var j = i + 1; j < HudSlot.values.length; j++)
          (HudSlot.values[i], HudSlot.values[j]),
    ];

    for (final (a, b) in pares) {
      final distancia = _distancia(mascaras[a]!, mascaras[b]!);

      debugPrint(
        'SILHUETA — ${a.name} × ${b.name}: '
        '${(distancia * 100).toStringAsFixed(1)}% de discordância',
      );

      expect(
        distancia,
        greaterThan(0.25),
        reason:
            '${a.name} e ${b.name} pintam quase os mesmos pixels. Foi assim '
            'que o ovo e a gota nasceram: dois caminhos diferentes no código, '
            'a mesma figura na tela',
      );
    }
  });

  testWidgets('o ovo é verde mesmo com o anel vermelho', (tester) async {
    late ({int r, int g, int b}) cor;

    await tester.runAsync(() async {
      // `AppColors.danger` é a tinta que o ANEL recebe quando as faturas já
      // valem um mês inteiro de receita. A casca ignora esse argumento.
      final bytes = await _pixels(
        tester,
        HudSlot.egg,
        color: AppColors.danger,
        stage: 2,
        filled: true,
      );
      cor = _corMedia(bytes);
    });

    debugPrint('OVO — cor média: R=${cor.r} G=${cor.g} B=${cor.b}');

    expect(
      cor.g,
      greaterThan(cor.r),
      reason:
          'a casca mediu R=${cor.r} G=${cor.g} B=${cor.b}: o ovo pintou com a '
          'tinta do anel em vez da própria',
    );
  });

  testWidgets('a gota, essa sim, é violeta', (tester) async {
    // A outra metade: a gota CONTINUA obedecendo à cor que recebe. Só o ovo
    // tem casca própria.
    late ({int r, int g, int b}) cor;

    await tester.runAsync(() async {
      final bytes = await _pixels(
        tester,
        HudSlot.drop,
        color: AppColors.violet,
        stage: 0,
        filled: true,
      );
      cor = _corMedia(bytes);
    });

    expect(cor.b, greaterThan(cor.g));
  });

  testWidgets('o veneno tem caveira: o miolo é escavado, não liso', (
    tester,
  ) async {
    // O dono disse que dívida é VENENO, e uma gota lisa dizia "água". A
    // caveira e a bolha são buracos na tinta — pixels da cor da calha
    // DENTRO da silhueta. Sem eles a figura volta a ser uma gota d'água, e
    // nenhum teste de contorno perceberia.
    late int escavados;
    late int noBico;

    await tester.runAsync(() async {
      final bytes = await _pixels(
        tester,
        HudSlot.drop,
        color: AppColors.violet,
        stage: 0,
        filled: true,
      );

      escavados = _contaCor(bytes, AppColors.gameTrough);
      // O terço de cima é o BICO, e é ele que faz a gota ser uma gota. Um
      // buraco ali quebra a ponta e a figura deixa de se distinguir das
      // outras três — que é o defeito que este arquivo inteiro existe para
      // impedir.
      noBico = _contaCor(bytes, AppColors.gameTrough, ateLinha: _lado ~/ 3);
    });

    debugPrint('VENENO — $escavados pixels escavados, $noBico deles no bico');

    expect(
      escavados,
      greaterThan(40),
      reason:
          'a gota voltou a ser lisa: sem a caveira ela lê como água, '
          'e o nome do ícone passou a ser Veneno',
    );
    expect(
      noBico,
      0,
      reason: 'a escavação subiu para o bico e quebrou a ponta da gota',
    );
  });

  testWidgets('o monstro aparece na casca no último estágio', (tester) async {
    // O estágio 2 era um olho entreaberto. O dono pediu o MONSTRO — o bicho
    // que o cartão está fortalecendo —, e a diferença entre um olho e um
    // corpo com chifres se mede em área.
    late int rachado;
    late int eclodindo;

    await tester.runAsync(() async {
      rachado = _contaCor(
        await _pixels(
          tester,
          HudSlot.egg,
          color: AppColors.success,
          stage: 1,
          filled: true,
        ),
        AppColors.gameTrough,
      );
      eclodindo = _contaCor(
        await _pixels(
          tester,
          HudSlot.egg,
          color: AppColors.success,
          stage: 2,
          filled: true,
        ),
        AppColors.gameTrough,
      );
    });

    debugPrint('MONSTRO — calha: estágio 1 = $rachado, estágio 2 = $eclodindo');

    // O corpo do bicho é muito maior que as duas rachaduras a mais que o
    // estágio 2 desenha: o dobro é um piso folgado para "apareceu um bicho".
    expect(
      eclodindo,
      greaterThan(rachado * 2),
      reason:
          'o estágio 2 desenhou só mais uma rachadura: o monstro não está '
          'dentro da casca',
    );
  });

  testWidgets('a casca muda a cada estágio, e a silhueta não', (tester) async {
    late List<ByteData> estagios;

    await tester.runAsync(() async {
      estagios = [
        for (var stage = 0; stage < 3; stage++)
          await _pixels(
            tester,
            HudSlot.egg,
            color: AppColors.success,
            stage: stage,
            filled: true,
          ),
      ];
    });

    // A comparação é de PIXEL, e não de máscara: a rachadura é desenhada com
    // a cor da calha, que é opaca, e por isso ela não abre buraco nenhum na
    // silhueta. Ela muda a tinta do miolo, e é só aí que dá para vê-la.
    int diferentes(ByteData a, ByteData b) {
      var n = 0;
      for (var i = 0; i < a.lengthInBytes; i += 4) {
        if (a.getUint32(i) != b.getUint32(i)) n++;
      }
      return n;
    }

    final liso = _mascaraDe(estagios[0]);

    for (var stage = 1; stage < 3; stage++) {
      expect(
        diferentes(estagios[0], estagios[stage]),
        greaterThan(20),
        reason: 'o estágio $stage pinta a mesma casca do estágio 0',
      );

      // E a forma continua a mesma: o ovo racha, não se deforma.
      expect(
        _distancia(liso, _mascaraDe(estagios[stage])),
        lessThan(0.05),
        reason: 'o ovo mudou de silhueta ao rachar',
      );
    }

    // O estágio 2 acrescenta o olho ao que o 1 já tinha.
    expect(diferentes(estagios[1], estagios[2]), greaterThan(20));
  });
}
