import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Os gradientes da identidade. São quatro, e cada um tem um lugar.
abstract final class AppGradients {
  /// Fundo de herói: splash, login, onboarding, cabeçalho de detalhe. É o
  /// cofre visto de dentro — mais claro no centro, fechando nas bordas.
  static const RadialGradient background = RadialGradient(
    colors: [AppColors.surfaceRaised, AppColors.surfaceDeep],
    center: Alignment.topCenter,
    radius: 1.1,
  );

  /// Bloco de jogo sobre papel: a faixa escura que carrega XP, nível, missão
  /// ou meta dentro de uma tela clara.
  static const LinearGradient game = LinearGradient(
    colors: [AppColors.surfaceDefault, AppColors.surfaceDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Preenchimento de barra de progresso: verde no começo, teal no fim.
  /// Quem está no início da barra não recebe a cor da chegada.
  static const LinearGradient progress = LinearGradient(
    colors: [AppColors.progressStart, AppColors.progressEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Ouro: recompensa, botão de celebração, moeda, aro de conquista.
  static const LinearGradient gold = LinearGradient(
    colors: [AppColors.gold, AppColors.goldDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Apelidos legados (removidos ao fim do pacote wp/design) ---

  static const RadialGradient backgroundGradient = background;
  static const LinearGradient progressGradient = progress;
  static const LinearGradient goldGradient = gold;
  static const LinearGradient turquoiseBlue = game;
}
