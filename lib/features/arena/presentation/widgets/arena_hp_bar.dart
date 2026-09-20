import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Barra de vida de jogo de luta: preenchimento animado, **dano fantasma** e
/// uma faixa hachurada para o que está comprometido.
///
/// Por que em Flutter e não dentro do Flame: a barra precisa de texto
/// traduzido, de moeda formatada, de toque com área de alvo decente e dos
/// tokens do design system. Tudo isso o Flame faria à mão e pior.
///
/// O "dano fantasma" é a faixa VERMELHA que desce atrasada. Uma barra que só
/// encolhe informa o valor novo; a faixa que fica para trás por meio segundo
/// informa o TAMANHO DA MORDIDA, que é a coisa que o jogador quer sentir. É a
/// mesma leitura do Street Fighter, e é de lá que ela vem.
///
/// [mirrored] espelha tudo: o preenchimento cresce da direita para a
/// esquerda, o chanfro fica na ponta esquerda e o conteúdo alinha à direita.
/// É assim que a barra do monstro se opõe à dos heróis em vez de repeti-la.
class ArenaHpBar extends StatelessWidget {
  const ArenaHpBar({
    super.key,
    required this.ratio,
    required this.color,
    this.committedRatio = 0,
    this.mirrored = false,
    this.overflowing = false,
    this.height = _height,
  });

  /// Fração preenchida, 0..1.
  final double ratio;

  /// Fração hachurada, contada a partir da ponta CHEIA da barra: é a parte do
  /// que se tem que já tem dono.
  final double committedRatio;

  final Color color;

  /// Espelhada (a barra do monstro).
  final bool mirrored;

  /// A vida passou do máximo (receita acima do que saiu). A barra fica cheia
  /// e troca de cor — "overheal", o verde que diz que a semana está no azul.
  final bool overflowing;

  final double height;

  static const double _height = 14;

  /// Quanto a ponta interna é chanfrada, em pixels. Dá às duas barras o
  /// bico que as faz se enfrentarem no centro.
  static const double chamfer = 10;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduce = AppDurations.reduceMotion(context);
    final fill = overflowing ? palette.successText : color;

    // O chanfro é cortado no espaço do FILHO e só depois espelhado: assim o
    // bico fica sempre na ponta voltada para o centro, com um clipper só.
    return Transform.flip(
      flipX: mirrored,
      child: ClipPath(
        clipper: const _ChamferClipper(),
        child: SizedBox(
          height: height,
          // `StackFit.expand` é obrigatório, não estilo: num `Stack` frouxo
          // o `FractionallySizedBox` recebe altura nenhuma, e o `ColoredBox`
          // dentro dele não tem tamanho próprio — a barra desenhava com
          // ZERO de altura e a tela mostrava só a calha escura, com os
          // números certos ao lado.
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.surfaceDeep),
              // 1. O fantasma: mesma fração, mas com atraso e mais devagar.
              //    Fica POR BAIXO do preenchimento, então só aparece no
              //    rastro do que encolheu.
              _Fill(
                ratio: ratio,
                color: palette.dangerText,
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 900),
                curve: const Interval(0.45, 1, curve: Curves.easeOut),
              ),
              _Fill(
                ratio: ratio,
                color: fill,
                duration: AppDurations.respectingMotion(
                  context,
                  AppDurations.celebrate,
                ),
                curve: AppDurations.curve,
              ),
              // 2. A faixa comprometida: hachura, e não uma cor chapada.
              //    Cor chapada leria como "outra vida"; a hachura lê como
              //    "reservado". Ela mora na ponta CHEIA da barra porque o
              //    que tem dono é a primeira coisa que sai.
              if (committedRatio > 0)
                _CommittedBand(
                  extent: committedRatio,
                  color: palette.onGame2,
                  duration: AppDurations.respectingMotion(
                    context,
                    AppDurations.celebrate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O bico da ponta interna.
///
/// O corte é sempre na DIREITA do filho; o `Transform.flip` de quem usa a
/// barra é que o leva para a esquerda na barra do monstro. Um clipper só, e o
/// bico sempre voltado para o centro.
class _ChamferClipper extends CustomClipper<Path> {
  const _ChamferClipper();

  @override
  Path getClip(Size size) {
    final cut = ArenaHpBar.chamfer.clamp(0.0, size.width / 2);

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_ChamferClipper oldClipper) => false;
}

class _Fill extends StatelessWidget {
  const _Fill({
    required this.ratio,
    required this.color,
    required this.duration,
    required this.curve,
  });

  final double ratio;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: ratio.clamp(0.0, 1.0)),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// A faixa hachurada do que está comprometido, ancorada no COMEÇO da barra.
class _CommittedBand extends StatelessWidget {
  const _CommittedBand({
    required this.extent,
    required this.color,
    required this.duration,
  });

  final double extent;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: extent.clamp(0.0, 1.0)),
      duration: duration,
      curve: AppDurations.curve,
      // `heightFactor: 1` é obrigatório: um `Align` entrega restrição frouxa
      // ao filho, e sem a fração de altura a cadeia colapsa para zero — a
      // faixa some sem erro nenhum, que foi exatamente o que aconteceu.
      builder: (context, value, child) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          heightFactor: 1,
          child: CustomPaint(
            painter: _HatchPainter(color),
            // Um `CustomPaint` sem filho prefere `Size.zero`; o filho
            // expandido é o que o faz ocupar a faixa inteira.
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);

  final Color color;

  /// Distância entre traços. Fixa em pontos lógicos de propósito: uma hachura
  /// proporcional à largura muda de densidade conforme o valor, e aí ela
  /// passa a parecer uma informação — que não é.
  static const double step = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.surfaceDeep.withValues(alpha: 0.45),
    );

    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}

/// O marcador redondo do centro: o relógio da luta.
///
/// No Street Fighter é o tempo que resta no round. Aqui é o dia da semana —
/// "4/7", quarta-feira — porque é a mesma informação: quanto ainda dá para
/// reagir antes de o placar fechar.
class ArenaDayMarker extends StatelessWidget {
  const ArenaDayMarker({
    super.key,
    required this.label,
    required this.semanticsLabel,
    this.diameter = 40,
  });

  final String label;
  final String semanticsLabel;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Semantics(
      label: semanticsLabel,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDeep,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: FittedBox(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.onGame,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
