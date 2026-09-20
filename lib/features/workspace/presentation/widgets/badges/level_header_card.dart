import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Cartão de nível do workspace: nome, nível, contador de emblemas, barra de
/// XP e a sequência semanal.
///
/// Nada é calculado aqui — `xpInLevel`, `xpToNextLevel` e `levelProgress` saem
/// da tabela publicada pelo servidor.
class LevelHeaderCard extends StatelessWidget {
  const LevelHeaderCard({
    super.key,
    required this.workspaceName,
    required this.level,
    required this.xp,
    required this.xpInLevel,
    required this.xpForNextLevel,
    required this.progressFraction,
    required this.weeklyStreaks,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String workspaceName;
  final int level;
  final int xp;
  final int xpInLevel;
  final int xpForNextLevel;
  final double progressFraction;
  final int weeklyStreaks;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return AppCard.game(
      padding: AppSpacing.allLg,
      // `Builder` porque o tema escuro do bloco de jogo só existe abaixo do
      // `AppCard`: sem ele, o conteúdo leria a tinta da tela clara.
      child: Builder(builder: _content),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.workspaceLabel(workspaceName),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.ink2,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    l10n.levelLabel(level),
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            StatusPill(
              icon: Icons.military_tech,
              tone: StatusTone.reward,
              // O cartão é `AppCard.game`: a pílula está sobre superfície de
              // jogo, e ali a tinta do tom não alcança o piso de texto.
              onGame: true,
              label: l10n.badgeCatalogTotal(unlockedCount, totalCount),
            ),
          ],
        ),
        AppSpacing.gapLg,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$xpInLevel / $xpForNextLevel XP',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              l10n.totalXpLabel(xp.toString()),
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
            ),
          ],
        ),
        AppSpacing.gapXs,
        AppProgressBar.reward(
          value: progressFraction,
          size: AppProgressSize.thick,
          semanticLabel: l10n.levelLabel(level),
        ),
        if (weeklyStreaks > 0) ...[
          AppSpacing.gapMd,
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.warning),
              AppSpacing.gapXs,
              Text(
                weeklyStreaks == 1
                    ? l10n.weeklyStreaksLabelSingular
                    : l10n.weeklyStreaksLabelPlural(weeklyStreaks),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
