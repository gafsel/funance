import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_shape.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/metallic_icon_3d.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pintura da moldura do emblema
//
// Sete camadas, nesta ordem: sombra projetada, aura (só desbloqueado),
// preenchimento, raios de fundo, anel interno, borda chanfrada e o brilho de
// domo. Trocar a ordem muda o resultado, então elas ficam juntas num arquivo
// só — não é código que se lê em pedaços.
// ─────────────────────────────────────────────────────────────────────────────

class BadgeShapePainter extends CustomPainter {
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final ThemeData theme;

  const BadgeShapePainter({
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = tier == BadgeTier.advanced ? 3.5 : 2.5;
    final margin = strokeWidth / 2;
    final path = getShapePath(size, tier, group, margin);
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 1. Drop Shadow (3D Depth)
    final shadowPath = getShapePath(size, tier, group, margin);
    canvas.save();
    canvas.translate(0, tier == BadgeTier.advanced ? 4.0 : 2.5);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isUnlocked ? 0.35 : 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, tier == BadgeTier.advanced ? 6 : 4);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // 2. Glowaura (Glow Aura for Unlocked)
    if (isUnlocked) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

      if (tier == BadgeTier.advanced) {
        glowPaint.color = const Color(0xFFFFA000).withValues(alpha: 0.5);
      } else if (xpRewardValue >= 75) {
        glowPaint.color = const Color(0xFFB0BEC5).withValues(alpha: 0.3);
      } else {
        glowPaint.color = const Color(0xFFD84315).withValues(alpha: 0.3);
      }
      canvas.drawPath(path, glowPaint);
    }

    // 3. Main Fill Gradient
    final paint = Paint()..style = PaintingStyle.fill;

    // Active/Unlocked Gradients
    Gradient activeGradient;
    if (tier == BadgeTier.advanced) {
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [
          Color(0xFFFFFDE7), // Specular light highlight
          Color(0xFFFFD54F), // Gold body
          Color(0xFFFF8F00), // Deep Amber
          Color(0xFFD97706), // Golden shade shadow
        ],
        stops: [0.0, 0.45, 0.85, 1.0],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // specular white
          Color(0xFFECEFF1), // light silver
          Color(0xFF90A4AE), // medium steel silver
          Color(0xFF475569), // dark shadow grey
        ],
        stops: [0.0, 0.35, 0.8, 1.0],
      );
    } else {
      // Bronze
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFEDD5), // copper flare highlight
          Color(0xFFEA580C), // rich copper body
          Color(0xFF9A3412), // medium bronze
          Color(0xFF451A03), // shadow bronze/brown
        ],
        stops: [0.0, 0.3, 0.8, 1.0],
      );
    }

    if (isUnlocked) {
      paint.shader = activeGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Locked: Grayscale version of the shape gradient
      paint.shader = makeGrayscale(activeGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }

    canvas.drawPath(path, paint);

    // 4. Background Starburst Rays (Painted for both, but faded when locked)
    canvas.save();
    canvas.clipPath(path);

    final raysPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.22 : 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = tier == BadgeTier.advanced ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    final r = w * 0.8;
    const rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = i * pi / (rayCount / 2);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        raysPaint,
      );
    }
    canvas.restore();

    // 5. Inner Framing Ring (Concentric Track)
    canvas.save();
    canvas.clipPath(path);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Color activeRingColor = tier == BadgeTier.advanced
        ? const Color(0xFFFFE082)
        : Colors.white;
    final double ringAlpha = tier == BadgeTier.advanced ? 0.35 : 0.18;

    ringPaint.color = isUnlocked
        ? activeRingColor.withValues(alpha: ringAlpha)
        : toGrayscale(activeRingColor).withValues(alpha: ringAlpha * 0.5);

    if (tier == BadgeTier.advanced) {
      canvas.drawCircle(Offset(cx, cy), w * 0.28, ringPaint);
    } else {
      canvas.drawCircle(Offset(cx, cy), w * 0.25, ringPaint);
    }

    canvas.restore();

    // 6. Beveled Outer Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Gradient activeBorderGradient;
    if (tier == BadgeTier.advanced) {
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9C4), // White gold glow reflection
          Color(0xFFFFD54F), // Golden frame
          Color(0xFFFF8F00), // Amber border
          Color(0xFFE65100), // Dark gold shadow
        ],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // pure reflection
          Color(0xFFCFD8DC), // grey steel
          Color(0xFF78909C), // silver edge
          Color(0xFF37474F), // shadow grey
        ],
      );
    } else {
      // Bronze
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE0B2), // bronze flare
          Color(0xFFD84315), // copper border
          Color(0xFF5D4037), // brown edge
          Color(0xFF2D1510), // shadow bronze
        ],
      );
    }

    if (isUnlocked) {
      borderPaint.shader = activeBorderGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Grayscale border
      borderPaint.shader = makeGrayscale(activeBorderGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawPath(path, borderPaint);

    // 7. Glossy Dome Highlight (Always active to give it a glassy look even when locked!)
    canvas.save();
    canvas.clipPath(path);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.35 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));

    canvas.drawOval(
      Rect.fromLTWH(-w * 0.1, -h * 0.15, w * 1.2, h * 0.55),
      reflectionPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
