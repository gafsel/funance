import 'package:flutter/material.dart';

/// Sparkline do índice. Sem biblioteca nova: são seis pontos e uma linha.
class SparklinePainter extends CustomPainter {
  SparklinePainter({required this.scores, required this.color});

  final List<double> scores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    // Escala fixa de 0 a 100: o índice tem faixa conhecida, e escalar pelo
    // mínimo e máximo dos pontos transformaria uma oscilação de dois pontos
    // num gráfico dramático.
    double x(int i) => size.width * (i / (scores.length - 1));
    double y(double score) => size.height * (1 - (score / 100).clamp(0.0, 1.0));

    final path = Path()..moveTo(x(0), y(scores.first));
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
    }

    final fill = Path.from(path)
      ..lineTo(x(scores.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();

    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      Offset(x(scores.length - 1), y(scores.last)),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) =>
      oldDelegate.color != color || !_sameScores(oldDelegate.scores, scores);

  static bool _sameScores(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
