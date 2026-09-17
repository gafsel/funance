import 'package:flutter/material.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';

/// Ligação visual entre a transação do extrato e a do sistema.
///
/// Pintura pura: a linha (cheia ou tracejada) e o ícone no meio dizem, sem
/// texto, se o par está confirmado, sugerido ou desfeito.
class MatchConnectorWidget extends StatelessWidget {
  final ReconciliationMatchStatus status;
  final bool isLinked;

  const MatchConnectorWidget({
    super.key,
    required this.status,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLinked) {
      return const SizedBox(
        width: 60,
        child: Center(
          child: Icon(Icons.link_off, color: Colors.grey, size: 20),
        ),
      );
    }

    Color color;
    bool isDashed = false;
    IconData icon;

    switch (status) {
      case ReconciliationMatchStatus.matched:
        color = Colors.green;
        isDashed = false;
        icon = Icons.link;
        break;
      case ReconciliationMatchStatus.suggested:
        color = Colors.orange;
        isDashed = true;
        icon = Icons.link;
        break;
      case ReconciliationMatchStatus.ignored:
        color = Colors.red;
        isDashed = false;
        icon = Icons.link_off;
        break;
      case ReconciliationMatchStatus.unmatched:
        color = Colors.grey;
        isDashed = false;
        icon = Icons.link_off;
        break;
    }

    return SizedBox(
      width: 60,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(60, 40),
            painter: ConnectorPainter(
              color: color,
              isDashed: isDashed,
              hasCenterGap: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

class ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  final bool hasCenterGap;

  ConnectorPainter({
    required this.color,
    required this.isDashed,
    required this.hasCenterGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double y = size.height / 2;
    final double startX = 0;
    final double endX = size.width;

    if (hasCenterGap) {
      final double midX = size.width / 2;
      final double gap = 12.0;
      _drawLine(canvas, paint, startX, midX - gap, y);
      _drawLine(canvas, paint, midX + gap, endX, y);
    } else {
      _drawLine(canvas, paint, startX, endX, y);
    }
  }

  void _drawLine(Canvas canvas, Paint paint, double x1, double x2, double y) {
    if (!isDashed) {
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    } else {
      const double dashWidth = 4.0;
      const double dashSpace = 3.0;
      double currentX = x1;
      while (currentX < x2) {
        final double nextX = (currentX + dashWidth).clamp(x1, x2);
        canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
        currentX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDashed != isDashed ||
        oldDelegate.hasCenterGap != hasCenterGap;
  }
}
