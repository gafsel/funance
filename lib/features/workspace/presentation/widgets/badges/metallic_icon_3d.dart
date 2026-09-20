import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_badge_palette.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 3D Metallic Emblem Icon
//
// Pintura pura: nada aqui sabe o que é um badge, só recebe cor, tier e se está
// desbloqueado. As três funções de cor são compartilhadas com
// `badge_shape_painter.dart`, que pinta a moldura em volta deste disco.
// ─────────────────────────────────────────────────────────────────────────────

Color toGrayscale(Color color) {
  final double luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
  return Color.fromARGB(
    (color.a * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
  );
}

Gradient makeGrayscale(Gradient gradient) {
  if (gradient is RadialGradient) {
    return RadialGradient(
      center: gradient.center,
      radius: gradient.radius,
      colors: gradient.colors.map(toGrayscale).toList(),
      stops: gradient.stops,
    );
  } else if (gradient is LinearGradient) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map(toGrayscale).toList(),
      stops: gradient.stops,
    );
  }
  return gradient;
}

Gradient metallicGradientForColor(Color baseColor) {
  final hsl = HSLColor.fromColor(baseColor);
  final lightColor = hsl
      .withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0))
      .toColor();
  final midColor = baseColor;
  final shadowColor = hsl
      .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
      .toColor();

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightColor, midColor, shadowColor],
  );
}

class MetallicIcon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isUnlocked;
  final BadgeTier tier;
  final int xpRewardValue;
  final Color themeColor;

  const MetallicIcon3D({
    super.key,
    required this.icon,
    required this.size,
    required this.isUnlocked,
    required this.tier,
    required this.xpRewardValue,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final double plateSize = size * 1.35;

    // Unlocked base colors and gradients
    Gradient activePlateGradient;
    Gradient activeIconGradient;
    Color activePlateBorderColor;

    if (tier == BadgeTier.advanced) {
      // Advanced: Platinum/Silver coin inside Gold Shield
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: AppBadgePalette.coinPlatinum,
        stops: [0.0, 0.25, 0.75, 1.0],
      );
      activePlateBorderColor = AppBadgePalette.coinRimGold;
      activeIconGradient = metallicGradientForColor(themeColor);
    } else if (xpRewardValue >= 75) {
      // Simple Silver Badge: Gold coin inside Silver Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: AppBadgePalette.coinGold,
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = AppBadgePalette.coinRimSilver;
      activeIconGradient = metallicGradientForColor(themeColor);
    } else {
      // Simple Bronze Badge: Silver/Steel coin inside Bronze Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: AppBadgePalette.coinSteel,
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = AppBadgePalette.coinRimBronze;
      activeIconGradient = metallicGradientForColor(themeColor);
    }

    Gradient plateGradient;
    Gradient iconGradient;
    Color plateBorderColor;

    if (isUnlocked) {
      plateGradient = activePlateGradient;
      iconGradient = activeIconGradient;
      plateBorderColor = activePlateBorderColor;
    } else {
      // Locked: Grayscale version of the coin & high-contrast icon
      plateGradient = makeGrayscale(activePlateGradient);
      // Use a dark slate gradient to stand out against the light/medium grayscale plate
      iconGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: AppBadgePalette.lockedIcon,
      );
      plateBorderColor = toGrayscale(activePlateBorderColor);
    }

    return Container(
      width: plateSize,
      height: plateSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: plateGradient,
        border: Border.all(color: plateBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppBadgePalette.shadow.withValues(
              alpha: isUnlocked ? 0.35 : 0.20,
            ),
            offset: const Offset(1, 1.5),
            blurRadius: 1.5,
          ),
          BoxShadow(
            color: AppBadgePalette.specular.withValues(
              alpha: isUnlocked ? 0.45 : 0.20,
            ),
            offset: const Offset(-0.75, -0.75),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // White highlights under the icon to create a debossed/engraved edge visibility when locked
            if (!isUnlocked)
              Transform.translate(
                offset: const Offset(-0.8, -0.8),
                child: Icon(
                  icon,
                  size: size,
                  color: AppBadgePalette.specular.withValues(alpha: 0.65),
                ),
              ),
            // Stamped drop shadow for the icon glyph
            Transform.translate(
              offset: const Offset(1.2, 1.2),
              child: Icon(
                icon,
                size: size,
                color: AppBadgePalette.shadow.withValues(
                  alpha: isUnlocked ? 0.45 : 0.50,
                ),
              ),
            ),
            // Metal icon stamp
            ShaderMask(
              shaderCallback: (bounds) => iconGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Icon(icon, size: size, color: AppBadgePalette.specular),
            ),
            // Specular glass glare reflection on top of the stamp (always visible)
            Opacity(
              opacity: isUnlocked ? 0.12 : 0.06,
              child: ClipPath(
                clipper: _CrescentClipper(),
                child: Container(
                  width: size,
                  height: size,
                  color: AppBadgePalette.specular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrescentClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(
      Rect.fromLTWH(
        -size.width * 0.15,
        -size.height * 0.15,
        size.width * 1.3,
        size.height * 0.7,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
