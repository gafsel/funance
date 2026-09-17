import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_shape_painter.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Formas dos emblemas
//
// Cada grupo simples tem uma silhueta própria (círculo, octógono, losango,
// hexágono, estrela de 8 pontas) e o tier avançado é um escudo. `getOffsetY`
// corrige a centralização ÓPTICA: numa forma que afina embaixo, o ícone
// centralizado geometricamente parece baixo demais.
// ─────────────────────────────────────────────────────────────────────────────

class BadgeShapeWidget extends StatelessWidget {
  final double size;
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final Widget child;

  const BadgeShapeWidget({
    super.key,
    required this.size,
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final offsetY = getOffsetY(tier, group, size);

    return CustomPaint(
      size: Size(size, size),
      painter: BadgeShapePainter(
        tier: tier,
        group: group,
        isUnlocked: isUnlocked,
        xpRewardValue: xpRewardValue,
        theme: Theme.of(context),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: SizedBox(
              width: size * 0.55,
              height: size * 0.55,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

double getOffsetY(BadgeTier tier, SimpleBadgeGroup? group, double size) {
  if (tier == BadgeTier.advanced) {
    // Shield narrows down at the bottom; offset icon slightly up for optical centering
    return -size * 0.095;
  }
  if (group == SimpleBadgeGroup.savings) {
    // Diamond narrows down at bottom, let's offset it slightly up
    return -size * 0.04;
  }
  if (group == SimpleBadgeGroup.goals) {
    // Hexagon has top/bottom points, let's offset slightly up
    return -size * 0.02;
  }
  // Other shapes (circle, octagon, star) might need a tiny upward offset to counteract the shadow drop
  return -size * 0.015;
}

Path getShapePath(Size size, BadgeTier tier, SimpleBadgeGroup? group, double margin) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  if (tier == BadgeTier.advanced) {
    final left = margin;
    final top = margin;
    final right = w - margin;
    final bottom = h - margin;
    final width = right - left;
    final height = bottom - top;

    // Shield path with margin inset
    path.moveTo(left + width * 0.5, top);
    path.quadraticBezierTo(left + width * 0.8, top + height * 0.05, right, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.95, top + height * 0.6, left + width * 0.5, bottom);
    path.quadraticBezierTo(left + width * 0.05, top + height * 0.6, left, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.2, top + height * 0.05, left + width * 0.5, top);
    path.close();
    return path;
  }

  switch (group) {
    case SimpleBadgeGroup.firstSteps:
      // Circle
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
      break;
    case SimpleBadgeGroup.consistency:
      // Octagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final offset = width * 0.28;

      path.moveTo(left + offset, top);
      path.lineTo(right - offset, top);
      path.lineTo(right, top + offset);
      path.lineTo(right, bottom - offset);
      path.lineTo(right - offset, bottom);
      path.lineTo(left + offset, bottom);
      path.lineTo(left, bottom - offset);
      path.lineTo(left, top + offset);
      path.close();
      break;
    case SimpleBadgeGroup.savings:
      // Diamond
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.5);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.5);
      path.close();
      break;
    case SimpleBadgeGroup.goals:
      // Hexagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.25);
      path.lineTo(right, top + height * 0.75);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.75);
      path.lineTo(left, top + height * 0.25);
      path.close();
      break;
    case SimpleBadgeGroup.team:
      // 8-pointed star
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;
      final cx = left + width / 2;
      final cy = top + height / 2;
      final outerRadius = width / 2;
      final innerRadius = width / 2.8;
      const points = 8;
      const angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = i % 2 == 0 ? outerRadius : innerRadius;
        final currAngle = i * angle - pi / 2;
        final x = cx + r * cos(currAngle);
        final y = cy + r * sin(currAngle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      break;
    default:
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
  }

  return path;
}
