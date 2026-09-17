import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
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
    final l10n = context.l10n;

    final completed = mission.status.isCompleted;
    final failed = mission.status.isFailed;
    final accent = completed
        ? AppColors.success
        : failed
        ? AppColors.error
        : AppColors.deepTurquoise;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _labelOf(l10n, mission.type),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (mission.xp > 0)
                Text(
                  l10n.xpValue(mission.xp.toString()),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.successGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(mission.name, style: theme.textTheme.bodyMedium),
          if (mission.target > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: mission.completion,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: accent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
            const SizedBox(height: 6),
            Text(
              completed
                  ? l10n.journeyMissionDone
                  : l10n.journeyMissionProgress(
                      mission.displayProgress,
                      mission.target,
                    ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (completed) ...[
            const SizedBox(height: 8),
            Text(
              l10n.journeyMissionDone,
              style: theme.textTheme.labelSmall?.copyWith(color: accent),
            ),
          ],
          // A missão de ORGANIZAÇÃO é a de pôr a casa em ordem, e conciliar o
          // extrato é o caminho mais curto para isso — mas a conciliação
          // morava escondida dentro da tela de uma conta. Enquanto a missão
          // estiver aberta, ela traz o caminho junto.
          if (mission.type == WeeklyMissionType.organization &&
              !completed &&
              !failed) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/reconciliation'),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(l10n.reconciliationMissionCta),
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
