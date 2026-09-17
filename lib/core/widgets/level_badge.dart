import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_progress_bar.dart';

/// O selo de nível do cofre.
///
/// O nível e o XP são **do workspace**, nunca de um membro: a Equipe joga
/// junto. O selo diz isso pela forma — é um emblema só, no cabeçalho do
/// workspace, e não um avatar por pessoa.
///
/// Substitui o bloco grande de nível da Home. A regra nova é que o que muda
/// por mês vira selo e o que muda por dia ocupa o corpo: o nível é mensal, e
/// por isso cabe em 88×40 com uma barrinha de XP embaixo.
///
/// Widget puro: quem liga aos providers é a camada de feature.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    required this.progress,
    required this.label,
    this.semanticLabel,
    this.onTap,
    this.showProgress = true,
    this.onGame = false,
  });

  /// Nível corrente do workspace.
  final int level;

  /// Fração de 0 a 1 do XP dentro do nível.
  final double progress;

  /// Texto curto do selo — "Nv 7".
  final String label;

  final String? semanticLabel;
  final VoidCallback? onTap;

  /// `false` esconde a mini barra: para quando o selo está dentro de uma
  /// linha já cheia.
  final bool showProgress;

  /// `true` quando o selo está pousado sobre uma superfície de jogo (escura)
  /// e precisa da tinta clara em qualquer tema.
  final bool onGame;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = onGame ? palette.onGame : palette.ink;

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: onGame ? 0.16 : 0.14),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_moon_outlined,
                size: 14,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: AppTypography.counter(
                  ink,
                ).copyWith(fontSize: 14, height: 18 / 14),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 3),
            SizedBox(
              width: 56,
              child: AppProgressBar.reward(
                value: progress,
                size: AppProgressSize.thin,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.brPill,
                child: content,
              ),
            ),
    );
  }
}
