import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';

/// O anel de progresso dos ícones do rodapé.
///
/// Não é o `CircularProgressIndicator` do Material por três razões, e nenhuma
/// delas é gosto: ele não aceita cor de CALHA (o trilho vazio é sempre uma
/// versão translúcida da tinta, e sobre a superfície de jogo isso some), ele
/// desenha o traço com ponta reta e, com `value` fixo, ainda mantém um
/// `Ticker` vivo. Aqui o anel é um arco e nada mais.
class HudRing extends StatelessWidget {
  const HudRing({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    this.stroke = 3,
    this.child,
  });

  /// De 0 a 1. Quem passa de 1 já vem preso pelo domínio.
  final double progress;

  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          stroke: stroke,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trough = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.gameTrough;

    canvas.drawCircle(center, radius, trough);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Começa no topo e anda no sentido do relógio: é como um mostrador se
      // lê, e o rodapé inteiro depende de o usuário entender o anel sem
      // legenda.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

/// As quatro figuras do rodapé, desenhadas em código.
///
/// Elas não saem da folha do Kenney, e a razão é de leitura e não de
/// licença: os tiles são de 16 px com um cartão escuro embutido no próprio
/// sprite, e dentro de um anel de 30 px esse cartão vira um quadrado que
/// briga com o círculo. Poção, vila, ovo e gota são quatro formas simples —
/// desenhá-las custa menos que recortar um atlas e dá o que o atlas não dá:
/// a tinta muda com a classe, e a casca do ovo muda com a razão.
///
/// Toda cor vem de `AppColors` / `context.palette`; nenhuma decisão de tinta
/// é tomada aqui dentro.
class HudGlyph extends StatelessWidget {
  const HudGlyph({
    super.key,
    required this.slot,
    required this.color,
    required this.size,
    this.stage = 0,
    this.filled = true,
  });

  final HudSlot slot;
  final Color color;
  final double size;

  /// Só o ovo usa: 0 liso, 1 rachado, 2 prestes a eclodir.
  final int stage;

  /// Figura cheia ou só contorno. A poção vazia e a gota sem dívida são
  /// contorno: elas existem, mas não têm o que mostrar.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(
          slot: slot,
          color: color,
          stage: stage,
          filled: filled,
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.slot,
    required this.color,
    required this.stage,
    required this.filled,
  });

  final HudSlot slot;
  final Color color;
  final int stage;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.1
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (slot) {
      case HudSlot.potion:
        _potion(canvas, size, paint);
      case HudSlot.village:
        _village(canvas, size, paint);
      case HudSlot.egg:
        _egg(canvas, size, paint);
      case HudSlot.drop:
        _drop(canvas, size, paint);
    }
  }

  /// Um frasco: gargalo estreito, rolha e bojo redondo.
  void _potion(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final body = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.40, h * 0.42)
      ..cubicTo(w * 0.14, h * 0.56, w * 0.18, h * 0.92, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.82, h * 0.92, w * 0.86, h * 0.56, w * 0.60, h * 0.42)
      ..lineTo(w * 0.60, h * 0.30)
      ..close();

    canvas.drawPath(body, paint);

    // A rolha é sempre cheia: um contorno de rolha vira um risco solto.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.12, w * 0.28, h * 0.16),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = color,
    );
  }

  /// Uma vila: a casa maior com telhado e a torre ao lado.
  void _village(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final house = Path()
      ..moveTo(w * 0.12, h * 0.52)
      ..lineTo(w * 0.40, h * 0.28)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.68, h * 0.86)
      ..lineTo(w * 0.12, h * 0.86)
      ..close();

    canvas.drawPath(house, paint);

    final tower = Path()
      ..moveTo(w * 0.70, h * 0.44)
      ..lineTo(w * 0.82, h * 0.30)
      ..lineTo(w * 0.94, h * 0.44)
      ..lineTo(w * 0.94, h * 0.86)
      ..lineTo(w * 0.70, h * 0.86)
      ..close();

    canvas.drawPath(tower, paint);
  }

  /// O OVO das faturas: oval, verde e medonho.
  ///
  /// Ele nasceu com a MESMA silhueta da gota — bico em cima, barriga embaixo
  /// — e a 30 px os dois ícones eram a mesma figura em duas cores. A gota
  /// ficou com o bico, que é o que faz uma gota ser uma gota; o ovo virou um
  /// oval sem ponta, mais largo embaixo, na proporção de um ovo de verdade
  /// (0,77 de largura para 1 de altura).
  ///
  /// A casca é SEMPRE verde ([AppColors.gameEggShell]), qualquer que seja a
  /// razão: quem muda de tinta com o tamanho da dívida é o ANEL em volta. Um
  /// ovo que também mudasse de cor perderia, justo no estágio em que mais
  /// importa, a única coisa que o identifica de relance.
  ///
  /// O que muda com o estágio é a CASCA, e a progressão é uma história:
  /// liso (0), rachado (1), rachado com um olho entreaberto olhando de volta
  /// (2). As manchas existem nos três — elas são o que faz o verde parecer
  /// doente em vez de saudável.
  void _egg(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final shell = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..cubicTo(w * 0.72, h * 0.10, w * 0.84, h * 0.32, w * 0.84, h * 0.56)
      ..cubicTo(w * 0.84, h * 0.82, w * 0.69, h * 0.96, w * 0.50, h * 0.96)
      ..cubicTo(w * 0.31, h * 0.96, w * 0.16, h * 0.82, w * 0.16, h * 0.56)
      ..cubicTo(w * 0.16, h * 0.32, w * 0.28, h * 0.10, w * 0.50, h * 0.08)
      ..close();

    final casca = Paint()
      ..color = AppColors.gameEggShell
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(shell, casca);

    // Ovo VAZIO (nenhuma fatura prevista) é só o contorno: manchas e olho
    // dentro de um oco seriam sujeira flutuando no ar.
    if (paint.style != PaintingStyle.fill) return;

    // Tudo o que vem daqui para baixo mora DENTRO da casca. Sem o recorte, a
    // mancha de baixo escorre para fora da silhueta e o ovo ganha uma
    // rebarba que, no tamanho da faixa, lê como um quinto ícone.
    canvas.save();
    canvas.clipPath(shell);

    final mancha = Paint()
      ..color = AppColors.gameEggSpot
      ..isAntiAlias = true;

    _blob(canvas, Offset(w * 0.34, h * 0.42), w * 0.11, h * 0.09, mancha);
    _blob(canvas, Offset(w * 0.64, h * 0.30), w * 0.08, h * 0.06, mancha);
    _blob(canvas, Offset(w * 0.62, h * 0.80), w * 0.09, h * 0.07, mancha);

    if (stage > 0) {
      // A rachadura é desenhada com a calha das barras de vida: ela precisa
      // ler como um VAZIO na casca, e um vazio é da cor do buraco, não de uma
      // segunda tinta.
      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * (stage >= 2 ? 0.08 : 0.06)
        ..strokeJoin = StrokeJoin.miter
        ..color = AppColors.gameTrough;

      if (stage >= 2) {
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.18, h * 0.46)
            ..lineTo(w * 0.32, h * 0.34)
            ..lineTo(w * 0.44, h * 0.48)
            ..lineTo(w * 0.58, h * 0.32)
            ..lineTo(w * 0.74, h * 0.44),
          crack,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.28, h * 0.90)
            ..lineTo(w * 0.40, h * 0.81)
            ..lineTo(w * 0.50, h * 0.91),
          crack,
        );
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.28, h * 0.50)
            ..lineTo(w * 0.42, h * 0.40)
            ..lineTo(w * 0.52, h * 0.54)
            ..lineTo(w * 0.68, h * 0.42),
          crack,
        );
      }
    }

    // O olho só no último estágio: as faturas já valem um mês inteiro de
    // receita, e é quando o ovo deixa de ser um objeto e passa a ser alguém.
    if (stage >= 2) _eggEye(canvas, size);

    canvas.restore();
  }

  /// Um olho entreaberto: a fenda escura e, dentro dela, a pupila.
  void _eggEye(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fenda = Path()
      ..moveTo(w * 0.30, h * 0.645)
      ..quadraticBezierTo(w * 0.50, h * 0.53, w * 0.70, h * 0.645)
      ..quadraticBezierTo(w * 0.50, h * 0.735, w * 0.30, h * 0.645)
      ..close();

    canvas.drawPath(fenda, Paint()..color = AppColors.gameTrough);

    // A pupila é vermelha, e é a única coisa vermelha do ovo: a 20 px ela é
    // um ponto, e um ponto vermelho dentro de um verde doente é o que faz o
    // olho ser um OLHO e não mais uma mancha.
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.638),
      w * 0.058,
      Paint()..color = AppColors.danger,
    );
  }

  /// Uma mancha irregular. Não é um círculo nem uma elipse de propósito: três
  /// elipses na casca leem como bolinhas desenhadas, e o ovo precisa parecer
  /// sujo, não pontilhado.
  void _blob(Canvas canvas, Offset c, double rx, double ry, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - ry)
      ..cubicTo(
        c.dx + rx,
        c.dy - ry * 0.7,
        c.dx + rx * 0.85,
        c.dy + ry * 0.75,
        c.dx + rx * 0.1,
        c.dy + ry,
      )
      ..cubicTo(
        c.dx - rx * 0.8,
        c.dy + ry * 1.15,
        c.dx - rx,
        c.dy + ry * 0.2,
        c.dx - rx * 0.72,
        c.dy - ry * 0.55,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  /// Uma gota: bico em cima, barriga embaixo.
  void _drop(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final drop = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..cubicTo(w * 0.50, h * 0.36, w * 0.88, h * 0.48, w * 0.88, h * 0.66)
      ..cubicTo(w * 0.88, h * 0.86, w * 0.72, h * 0.96, w * 0.50, h * 0.96)
      ..cubicTo(w * 0.28, h * 0.96, w * 0.12, h * 0.86, w * 0.12, h * 0.66)
      ..cubicTo(w * 0.12, h * 0.48, w * 0.50, h * 0.36, w * 0.50, h * 0.08)
      ..close();

    canvas.drawPath(drop, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.slot != slot ||
      old.color != color ||
      old.stage != stage ||
      old.filled != filled;
}
