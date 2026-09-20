import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// As quatro figuras dos ícones da CENA, desenhadas em código.
///
/// Elas nasceram como `Icon(Icons.menu_book_rounded)` e companhia, e o QA
/// reprovou pelo motivo certo: um pictograma do Material, com o traço fino e
/// a curva perfeita do Material, colado sobre pixel art de 16px é um adesivo
/// de outro aplicativo em cima do jogo. O rodapé mensal já tinha resolvido
/// isso para poção, vila, ovo e gota — este arquivo é a mesma decisão para
/// pergaminho, bússola, coach e faísca.
///
/// **Por que não reusar `hud_glyph.dart`.** O vocabulário é copiado de lá de
/// propósito, e não importado: aquele arquivo é de outro pacote em voo, e uma
/// dependência nova entre os dois viraria conflito no merge. O que se copia é
/// pequeno e estável — traço proporcional ao lado, junta redonda, calha em
/// [AppColors.gameTrough], moldura em [AppColors.gameFrame], e nenhuma
/// decisão de tinta tomada aqui dentro.
enum ArenaGlyph {
  /// As missões da semana.
  scroll,

  /// A Bússola da Liberdade.
  compass,

  /// O coach — um balão de fala com cara.
  coach,

  /// Os lançamentos que o leitor de notificação identificou.
  spark,
}

/// Uma figura da cena, num quadrado de [size].
class ArenaIconGlyph extends StatelessWidget {
  const ArenaIconGlyph({
    super.key,
    required this.glyph,
    required this.color,
    required this.size,
    this.filled = true,
  });

  final ArenaGlyph glyph;
  final Color color;
  final double size;

  /// Figura cheia ou só contorno. Contorno é o estado APAGADO: o ícone existe,
  /// mas não tem o que mostrar agora.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArenaGlyphPainter(glyph: glyph, color: color, filled: filled),
      ),
    );
  }
}

class _ArenaGlyphPainter extends CustomPainter {
  const _ArenaGlyphPainter({
    required this.glyph,
    required this.color,
    required this.filled,
  });

  final ArenaGlyph glyph;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.1
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (glyph) {
      case ArenaGlyph.scroll:
        _scroll(canvas, size, paint);
      case ArenaGlyph.compass:
        _compass(canvas, size, paint);
      case ArenaGlyph.coach:
        _coach(canvas, size, paint);
      case ArenaGlyph.spark:
        _spark(canvas, size, paint);
    }
  }

  /// Um pergaminho: a folha entre dois rolos.
  ///
  /// Os rolos são SEMPRE cheios, como a rolha da poção: um contorno de rolo
  /// vira dois riscos soltos nas pontas e o pergaminho deixa de ler como
  /// pergaminho. O que muda com [filled] é a folha do meio.
  void _scroll(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTRB(w * 0.26, h * 0.24, w * 0.74, h * 0.76), paint);

    final rolo = Paint()
      ..color = color
      ..isAntiAlias = true;

    for (final y in <double>[h * 0.14, h * 0.74]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, y, w * 0.76, h * 0.12),
          Radius.circular(h * 0.06),
        ),
        rolo,
      );
    }

    // As linhas escritas só no pergaminho cheio: dentro de um oco elas
    // flutuariam no ar.
    if (!filled) return;

    final escrita = Paint()
      ..color = AppColors.gameTrough
      ..strokeWidth = h * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.36, h * 0.40),
      Offset(w * 0.64, h * 0.40),
      escrita,
    );
    canvas.drawLine(
      Offset(w * 0.36, h * 0.56),
      Offset(w * 0.56, h * 0.56),
      escrita,
    );
  }

  /// Uma bússola: o aro e a agulha de dois gumes.
  ///
  /// A agulha é o que a faz ser bússola e não uma moeda: dois triângulos que
  /// se tocam no centro, o do norte na tinta e o do sul na calha. A 20px, um
  /// aro sozinho é um círculo.
  void _compass(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = size.shortestSide * 0.40;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.1
        ..isAntiAlias = true,
    );

    if (!filled) return;

    // A agulha aponta para nordeste: na diagonal ela ocupa o dobro do
    // diâmetro em pixels úteis, e o olho lê "apontando" em vez de "parada".
    const angle = -math.pi / 4;
    final tip = Offset(
      center.dx + math.cos(angle) * r * 0.72,
      center.dy + math.sin(angle) * r * 0.72,
    );
    final tail = Offset(
      center.dx - math.cos(angle) * r * 0.72,
      center.dy - math.sin(angle) * r * 0.72,
    );
    final left = Offset(
      center.dx + math.cos(angle + math.pi / 2) * r * 0.26,
      center.dy + math.sin(angle + math.pi / 2) * r * 0.26,
    );
    final right = Offset(
      center.dx - math.cos(angle + math.pi / 2) * r * 0.26,
      center.dy - math.sin(angle + math.pi / 2) * r * 0.26,
    );

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      Path()
        ..moveTo(tail.dx, tail.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()
        ..color = AppColors.gameTrough
        ..isAntiAlias = true,
    );
  }

  /// O coach: um balão de fala com dois olhos.
  ///
  /// Balão e não cabeça: o que o coach entrega é uma FALA, e um rosto sozinho
  /// num HUD lê como "perfil do usuário". Os olhos dentro do balão são o que
  /// o fazem parecer um bicho falando em vez de uma caixa de texto.
  void _coach(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final balao = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.10, h * 0.16, w * 0.90, h * 0.70),
      Radius.circular(h * 0.22),
    );

    canvas.drawRRect(balao, paint);

    // O rabinho: um triângulo que desce da barriga esquerda. É ele que
    // transforma um retângulo arredondado em fala.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.64)
        ..lineTo(w * 0.28, h * 0.92)
        ..lineTo(w * 0.52, h * 0.66)
        ..close(),
      paint,
    );

    if (!filled) return;

    final olho = Paint()
      ..color = AppColors.gameTrough
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(w * 0.37, h * 0.42), w * 0.085, olho);
    canvas.drawCircle(Offset(w * 0.63, h * 0.42), w * 0.085, olho);
  }

  /// Uma faísca: a estrela de quatro pontas côncava, mais uma centelha.
  ///
  /// É o mesmo desenho que o app já usa para "o leitor de notificação achou
  /// algo", e o côncavo é o que separa uma faísca de uma estrela de xerife.
  void _spark(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    Path estrela(Offset c, double r) {
      final k = r * 0.30;
      return Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
        ..close();
    }

    canvas.drawPath(estrela(Offset(w * 0.44, h * 0.48), w * 0.36), paint);

    // A centelha menor é o que dá movimento: uma faísca só, centrada, parece
    // um losango.
    canvas.drawPath(
      estrela(Offset(w * 0.80, h * 0.80), w * 0.17),
      Paint()
        ..color = color
        ..style = paint.style
        ..strokeWidth = paint.strokeWidth * 0.8
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_ArenaGlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.filled != filled;
}

/// O anel de progresso dos ícones da cena.
///
/// Mesmo desenho do anel do rodapé mensal — arco do topo no sentido do
/// relógio, calha em [AppColors.gameTrough], ponta redonda —, escrito aqui
/// porque o arquivo de lá é de outro pacote em voo. São trinta linhas; uma
/// dependência cruzada entre dois pacotes abertos custa mais.
class ArenaIconRing extends StatelessWidget {
  const ArenaIconRing({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    this.stroke = 2.5,
    this.child,
  });

  /// De 0 a 1. Zero desenha só a calha — é o anel de quem não tem fração
  /// nenhuma para mostrar (o coach, as pendências).
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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.gameTrough,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
