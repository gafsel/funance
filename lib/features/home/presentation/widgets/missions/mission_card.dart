import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_labels.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// O cartão de uma missão semanal do servidor: tipo, XP, nome e progresso.
///
/// O tipo da missão vira ícone e cor em vez de texto de categoria porque o que
/// o usuário precisa distinguir num relance é o estado (aberta, cumprida,
/// perdida), não a taxonomia.
class MissionCard extends StatelessWidget {
  const MissionCard({required this.mission, super.key});

  final WeeklyMissionModel mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    final completed = mission.status.isCompleted;
    final failed = mission.status.isFailed;
    final accent = completed
        ? palette.successText
        : failed
        ? palette.dangerText
        : palette.tealText;

    // O caminho vem do DOCUMENTO, não de um `if` sobre o tipo da missão.
    // Antes só a missão de organização tinha botão, e ele levava sempre para
    // a conciliação — o catálogo já mandava o destino certo de cada uma e o
    // app o ignorava.
    final action = (completed || failed)
        ? null
        : missionActionLabel(l10n, mission.actionPath);

    return AppCard(
      // A missão cumprida ganha o aro dourado: é a única coisa neste cartão
      // que é conquista.
      rewarded: completed,
      borderColor: failed ? palette.dangerText.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : failed
                    ? Icons.cancel_rounded
                    : _iconOf(mission.type),
                size: 20,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _labelOf(l10n, mission.type),
                  style: theme.textTheme.labelMedium?.copyWith(color: accent),
                ),
              ),
              if (mission.xp > 0)
                StatusPill(
                  label: l10n.xpValue(mission.xp.toString()),
                  tone: StatusTone.reward,
                  dense: true,
                ),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            missionName(l10n, mission),
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
          if (mission.target > 0) ...[
            AppSpacing.gapSm,
            AppProgressBar(
              value: mission.completion,
              // `rewardText`, e não o ouro cheio: sobre papel claro o ouro dá
              // 1,22:1 contra o trilho e a barra da missão CUMPRIDA — a que
              // mais importa — era a única que não se via. O trilho sai
              // daqui, diluído da própria tinta.
              color: completed ? palette.rewardText : null,
              semanticLabel: _labelOf(l10n, mission.type),
            ),
            AppSpacing.gapXxs,
            Text(
              completed
                  ? l10n.journeyMissionDone
                  : l10n.journeyMissionProgress(
                      mission.displayProgress,
                      mission.target,
                    ),
              style: theme.textTheme.labelSmall?.copyWith(color: palette.ink2),
            ),
          ] else if (completed) ...[
            AppSpacing.gapXs,
            Text(
              l10n.journeyMissionDone,
              style: theme.textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
          if (action != null) ...[
            AppSpacing.gapXs,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(mission.actionPath!),
                icon: Icon(action.icon, size: 18),
                label: Text(action.label),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconOf(WeeklyMissionType type) => switch (type) {
    WeeklyMissionType.consistency => Icons.event_repeat_rounded,
    WeeklyMissionType.discipline => Icons.shield_moon_rounded,
    WeeklyMissionType.organization => Icons.fact_check_rounded,
    WeeklyMissionType.unknown => Icons.flag_rounded,
  };

  static String _labelOf(AppLocalizations l10n, WeeklyMissionType type) =>
      switch (type) {
        WeeklyMissionType.consistency => l10n.journeyMissionConsistency,
        WeeklyMissionType.discipline => l10n.journeyMissionDiscipline,
        WeeklyMissionType.organization => l10n.journeyMissionOrganization,
        WeeklyMissionType.unknown => l10n.journeyMissionOther,
      };
}
