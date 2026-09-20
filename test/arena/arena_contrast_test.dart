import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scrim.dart';

/// A barra de vida é uma INFORMAÇÃO, e ela é feita só de cor.
///
/// Na rodada 1 a calha era o mesmo `surfaceDeep` do bloco. O efeito: uma
/// barra quase vazia não tinha onde terminar — "o monstro está com 5% de
/// vida" lia igual a "não há barra nenhuma aqui", e a pessoa só descobria a
/// diferença lendo o número ao lado, que é exatamente o que a barra existe
/// para dispensar.
///
/// As duas adjacências que carregam a informação:
///
/// 1. **calha × o que está atrás dela** — onde a barra começa e termina;
/// 2. **preenchimento × calha** — quanto dela está cheia.
///
/// O limite é 3:1, o mínimo do WCAG para componente de interface.
///
/// ## Por que quem delimita a barra é a MOLDURA, e não a calha
///
/// A leitura óbvia seria "clareie a calha até ela se separar do fundo". A
/// conta diz que isso não fecha, e o teste no fim deste arquivo a repete a
/// cada execução: o violeta do monstro é ESCURO (luminância 0,18). Com a
/// calha clara o bastante para se separar do fundo profundo, o violeta some
/// DENTRO dela; com a calha escura o bastante para o violeta aparecer, a
/// calha some no fundo. O melhor que dá para conseguir dos dois lados ao
/// mesmo tempo é 2,67 — e isso só para o teal, que é claro.
///
/// A saída é a de qualquer jogo de luta: um QUADRO claro em volta do HP. A
/// moldura se separa do fundo, a calha se separa da moldura, e o
/// preenchimento se separa da calha. Três adjacências, todas acima de 3:1.

/// Luminância relativa do WCAG 2.
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);

  return (lighter + 0.05) / (darker + 0.05);
}

/// Uma cor com opacidade, desenhada SOBRE outra.
///
/// É a conta que o `ColoredBox` do véu faz na tela, refeita aqui: o teste
/// precisa da cor RESULTANTE para medir contraste contra ela.
Color _over(Color top, Color bottom) {
  final a = top.a;
  return Color.from(
    alpha: 1,
    red: top.r * a + bottom.r * (1 - a),
    green: top.g * a + bottom.g * (1 - a),
    blue: top.b * a + bottom.b * (1 - a),
  );
}

void main() {
  const limite = 3.0;

  /// O véu do HUD sobre a cena — o pedido do dono da segunda rodada.
  ///
  /// A cena virou o FUNDO da aba inteira, e o placar, a faixa de ícones e o
  /// HUD mensal passaram a flutuar sobre ela. Sobre o quê, exatamente, não dá
  /// para saber: parede de tijolo cinza, areia clara, um braseiro laranja, um
  /// demônio vermelho — a arte muda com a luta e com o tamanho da tela.
  ///
  /// O que dá para saber é o PIOR CASO. O véu é uma chapa de `surfaceDeep`
  /// com opacidade fixa; quanto mais clara a arte por baixo, mais clara a
  /// chapa resultante, e menos contraste ela dá ao texto claro por cima. O
  /// pior caso é o branco puro, e é contra ele que estes testes medem.
  ///
  /// O limite aqui é 4,5:1 — texto, e não componente.
  group('o véu do HUD sobre a cena', () {
    const textoLimite = 4.5;

    // O extremo claro e o extremo escuro do que a arte pode ser.
    final extremos = <String, Color>{
      'arte branca': const Color(0xFFFFFFFF),
      'arte preta': const Color(0xFF000000),
    };

    for (final tinta in <String, Color>{
      'tinta principal': AppColors.inkInverse,
      'tinta secundária': AppColors.inkInverse2,
    }.entries) {
      for (final arte in extremos.entries) {
        test('${tinta.key} sobre o véu, com ${arte.key}', () {
          final chapa = _over(ArenaScrim.cover, arte.value);
          final razao = _contrast(tinta.value, chapa);

          expect(
            razao,
            greaterThanOrEqualTo(textoLimite),
            reason:
                '${razao.toStringAsFixed(2)}:1 — se o véu afinar, o placar '
                'deixa de ser legível sobre a cena',
          );
        });
      }
    }

    test('e o dourado dos números do HUD também', () {
      // O ouro é a tinta dos valores que sobem na cena e do selo de vitória.
      final chapa = _over(ArenaScrim.cover, const Color(0xFFFFFFFF));
      final razao = _contrast(AppColors.gold, chapa);

      expect(razao, greaterThanOrEqualTo(textoLimite), reason: '$razao:1');
    });
  });

  test('a moldura se separa do bloco atrás dela', () {
    final razao = _contrast(AppColors.gameFrame, AppColors.surfaceDeep);

    expect(
      razao,
      greaterThanOrEqualTo(limite),
      reason:
          'a moldura mede ${razao.toStringAsFixed(2)}:1 contra o fundo; é ela '
          'que diz ONDE a barra está quando a vida acaba',
    );
  });

  test('a calha se separa da moldura que a cerca', () {
    final razao = _contrast(AppColors.gameTrough, AppColors.gameFrame);

    expect(razao, greaterThanOrEqualTo(limite), reason: '$razao:1');
  });

  test('o preenchimento dos heróis se separa da calha', () {
    final razao = _contrast(AppColors.teal, AppColors.gameTrough);

    expect(razao, greaterThanOrEqualTo(limite), reason: '$razao:1');
  });

  test('o preenchimento do monstro se separa da calha', () {
    // O violeta é o caso difícil: ele é escuro, e é ele que decide que a
    // calha tem de ser mais escura ainda.
    final razao = _contrast(AppColors.violet, AppColors.gameTrough);

    expect(razao, greaterThanOrEqualTo(limite), reason: '$razao:1');
  });

  test('o transbordo verde também se separa da calha', () {
    for (final verde in <Color>[AppColors.success, AppColors.successInkDark]) {
      expect(
        _contrast(verde, AppColors.gameTrough),
        greaterThanOrEqualTo(limite),
      );
    }
  });

  test('a barra em perigo (vermelho) também se separa da calha', () {
    // O vermelho é o dano-fantasma E a barra do herói exausto.
    for (final vermelho in <Color>[AppColors.danger, AppColors.dangerInkDark]) {
      expect(
        _contrast(vermelho, AppColors.gameTrough),
        greaterThanOrEqualTo(limite),
      );
    }
  });

  test('o número sobre o bloco continua legível', () {
    // Texto: o limite é 4,5:1, e não 3:1.
    expect(
      _contrast(AppColors.inkInverse, AppColors.surfaceDeep),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('a conta que obriga a moldura continua verdadeira', () {
    // Se alguém clarear o violeta do monstro, a moldura pode deixar de ser
    // necessária — e é aqui que essa descoberta acontece, em vez de numa
    // captura seis meses depois.
    //
    // Para uma calha CLARA funcionar sem moldura, ela precisaria se separar
    // do fundo (luminância ≥ 0,1876) e o violeta precisaria se separar dela
    // (luminância da calha ≤ 0,0275). As duas exigências não se encontram.
    const violeta = AppColors.violet;
    final tetoParaOVioleta = (_luminance(violeta) + 0.05) / 3 - 0.05;
    final pisoParaOFundo =
        (_luminance(AppColors.surfaceDeep) + 0.05) * 3 - 0.05;

    expect(
      tetoParaOVioleta,
      lessThan(pisoParaOFundo),
      reason:
          'se esta desigualdade se inverter, dá para ter uma calha clara sem '
          'moldura — e aí a moldura vira enfeite, não informação',
    );
  });
}
