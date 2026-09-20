import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_labels.dart';
import 'package:funances/features/home/presentation/widgets/missions/streak_badge.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// As missões da semana na Home, em uma linha cada.
///
/// A Home mostrava as três missões em CARTÃO — ícone, tipo, pílula de XP,
/// nome, barra, contador e botão, cada um com 120px — mais o XP da semana num
/// bloco próprio e o checklist inteiro da semana logo abaixo. Só o bloco de
/// missões media 1158px dos 1797px da tela: 65% de uma Home que já era três
/// rolagens e meia.
///
/// O resumo diz as mesmas três coisas que se lê de relance — qual é a missão,
/// quanto falta e quanto ela paga — em uma altura por missão. O cartão
/// completo, o XP da semana e o checklist continuam existindo, na tela
/// `/missions`, que abre pelo cabeçalho.
///
/// O CTA aparece UMA vez, na missão em foco: a primeira ainda aberta que tem
/// destino. Três botões empilhados numa Home é a mesma pergunta feita três
/// vezes, e nenhuma delas é "o que eu faço agora".
class MissionSummary extends ConsumerWidget {
  const MissionSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    final async = ref.watch(JourneyViewProviders.weeklyMissions);
    final missions = async.valueOrNull ?? const <WeeklyMissionModel>[];

    if (missions.isEmpty) {
      // Sem missão não há resumo: a linha some em vez de reservar altura para
      // dizer que não há nada. Quem quiser saber por quê encontra o aviso na
      // tela da semana.
      return const SizedBox.shrink();
    }

    final done = missions.where((m) => m.status.isCompleted).length;
    final focus = missions
        .where(
          (m) =>
              !m.status.isCompleted &&
              !m.status.isFailed &&
              missionActionPathIsAllowed(m.actionPath),
        )
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l10n.weeklyMissionsTitle,
            value: l10n.weeklyMissionsProgress('$done', '${missions.length}'),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: AppRadius.brSm,
                onTap: () => context.push('/missions'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.weeklyMissionsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.weeklyMissionsProgress(
                          '$done',
                          '${missions.length}',
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.ink2,
                        ),
                      ),
                      const Spacer(),
                      const StreakBadge(),
                      Icon(Icons.chevron_right, size: 20, color: palette.ink2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          for (final mission in missions)
            _MissionLine(mission: mission, l10n: l10n),
          if (focus != null) ...[
            AppSpacing.gapXxs,
            Align(
              alignment: Alignment.centerLeft,
              child: _FocusAction(mission: focus, l10n: l10n),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma missão, em uma altura: ícone de estado, nome, barra fina e XP.
class _MissionLine extends StatelessWidget {
  const _MissionLine({required this.mission, required this.l10n});

  /// Largura mínima da barra de uma linha.
  ///
  /// A barra tinha 48px e a linha não dizia o número. Numa missão de 8
  /// lançamentos, cada passo move a barra 6 pixels: o progresso existia e não
  /// era legível, e "quanto falta" — metade do que uma missão comunica —
  /// ficava só na tela de detalhe. Com 64px o passo mínimo é 8px, e o
  /// contador ao lado responde exato o que a barra só aproxima.
  static const double barWidth = 64;

  final WeeklyMissionModel mission;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final completed = mission.status.isCompleted;
    final failed = mission.status.isFailed;
    final accent = completed
        ? palette.successText
        : failed
        ? palette.dangerText
        : palette.tealText;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: missionName(l10n, mission),
      value: completed
          ? l10n.journeyMissionDone
          : l10n.journeyMissionProgress(
              mission.displayProgress,
              mission.target,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : failed
                  ? Icons.cancel_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: accent,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                missionName(l10n, mission),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: completed ? palette.ink2 : palette.ink,
                ),
              ),
            ),
            if (mission.target > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: _MissionLine.barWidth,
                child: AppProgressBar(
                  value: mission.completion,
                  size: AppProgressSize.thin,
                  color: completed ? palette.rewardText : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                l10n.missionProgressShort(
                  '${mission.displayProgress}',
                  '${mission.target}',
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.ink2,
                ),
              ),
            ],
            if (mission.xp > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.xpValue(mission.xp.toString()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.rewardText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// O único botão do bloco, na missão em foco.
class _FocusAction extends StatelessWidget {
  const _FocusAction({required this.mission, required this.l10n});

  final WeeklyMissionModel mission;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final action = missionActionLabel(l10n, mission.actionPath);
    if (action == null) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => context.push(mission.actionPath!),
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
