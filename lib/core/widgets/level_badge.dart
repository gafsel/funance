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
    // O escudo e a barra de XP são OURO sobre um fundo de ouro a 14%. Sobre
    // papel claro isso dá 1,52:1 — o emblema do nível desaparecia na própria
    // pílula, e a barrinha de XP (1,22:1 contra o trilho) não existia de
    // fato. Sobre superfície de jogo o ouro vivo continua certo, com 5,83:1;
    // sobre papel, quem escreve "é jogo" é `rewardText`.
    final reward = onGame ? AppColors.gold : palette.rewardText;

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
        // `center` e não `stretch`: o selo é montado dentro de `Row`s sem
        // `Expanded` (o cabeçalho da Jornada, a barra de topo), e ali
        // `stretch` pede largura infinita e derruba o layout. A largura do
        // selo é a do seu conteúdo — que é o que "selo compacto" quer dizer.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_outlined, size: 14, color: reward),
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
              child: AppProgressBar(
                value: progress,
                size: AppProgressSize.thin,
                color: reward,
                trackColor: reward.withValues(alpha: 0.24),
              ),
            ),
          ],
        ],
      ),
    );

    // Um nó só: "Nível 7 do cofre, 40% para o próximo" é uma frase. Sem
    // `container`, o rótulo se mistura ao do que estiver em volta.
    return Semantics(
      container: true,
      excludeSemantics: semanticLabel != null,
      label: semanticLabel,
      button: onTap != null,
      onTap: onTap,
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
