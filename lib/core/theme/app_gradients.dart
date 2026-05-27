import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  /// Gradiente radial para fundos, do centro mais claro (vibrantTeal) para as bordas mais escuras (deepTurquoise).
  static const RadialGradient backgroundGradient = RadialGradient(
    colors: [
      AppColors.vibrantTeal,
      AppColors.deepTurquoise,
    ],
    center: Alignment.center,
    radius: 0.8,
  );

  /// Gradiente linear para barras de progresso, do Verde Limão (início) para o Ciano Brilhante (final).
  static const LinearGradient progressGradient = LinearGradient(
    colors: [
      AppColors.limeGreen,
      AppColors.brightCyan,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Gradiente para botões de sucesso/destaque usando tons de Ouro.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      AppColors.successGold,
      AppColors.antiqueGold,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
