import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/installment_item.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// As missões da semana — as do SERVIDOR — e o checklist do que vence nela.
///
/// F2.4: havia dois sistemas de missão. O do servidor (`weekly_missions`,
/// com nome gerado por IA, alvo, progresso e XP de verdade) nunca aparecia na
/// tela; o do cliente inventava missões a partir das parcelas e um XP que
/// ninguém creditava. Agora só o do servidor é "missão"; as parcelas da
/// semana são o checklist, sem XP fabricado.
class WeeklyMissionsView extends ConsumerWidget {
  const WeeklyMissionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.weeklyMissionsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _StreakBadge(),
          ],
        ),
        const SizedBox(height: 16),
        const _WeeklyXpBar(),
        const SizedBox(height: 24),
        const _ServerMissions(),
        const SizedBox(height: 32),
        const _WeekChecklist(),
      ],
    );
  }
}

/// Streak de semanas perfeitas, inline no título — visível sem ocupar espaço
/// extra, e só quando existe streak.
class _StreakBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(
      WorkspaceViewProviders.gamification.select((g) => g.weeklyStreaks),
    );
    if (streak <= 0) return const SizedBox.shrink();

    return Tooltip(
      message: context.l10n.journeyStreakWeeks(streak),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.coralOrange,
            size: 18,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.coralOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP da semana, direto do `weekly_xp` do servidor.
///
/// A barra usa como teto o XP que as missões da semana pagam: é o único
/// denominador que o servidor publica. Sem missões publicadas, mostra o número
/// sem barra em vez de uma porcentagem sobre um total inventado.
class _WeeklyXpBar extends ConsumerWidget {
  const _WeeklyXpBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final xpAsync = ref.watch(JourneyViewProviders.weeklyXp);
    final missions =
        ref.watch(JourneyViewProviders.weeklyMissions).valueOrNull ??
        const <WeeklyMissionModel>[];

    final missionXp = missions.fold<int>(0, (sum, m) => sum + m.xp);
    final xp = xpAsync.valueOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                xp == null
                    ? l10n.journeyWeeklyXpEmpty
                    : l10n.xpValue(xp.round().toString()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTurquoise,
                ),
              ),
              if (missionXp > 0)
                Text(
                  l10n.journeyWeeklyXpGoal(missionXp.toString()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (missionXp > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ((xp ?? 0) / missionXp).clamp(0.0, 1.0),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: AppColors.deepTurquoise.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(
                AppColors.deepTurquoise,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// As três missões que o servidor gerou para a semana corrente.
class _ServerMissions extends ConsumerWidget {
  const _ServerMissions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(JourneyViewProviders.weeklyMissions);

    // Erro de leitura degrada para o mesmo aviso de "ainda não chegou": para
    // quem usa o app, uma regra do Firestore que ainda não foi publicada e um
    // cron que ainda não rodou são a mesma coisa — não há nada para fazer.
    final missions = async.valueOrNull ?? const <WeeklyMissionModel>[];

    if (missions.isEmpty) {
      if (async.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _MissionsSoon(l10n: l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mission in missions) ...[
          _MissionCard(mission: mission),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MissionsSoon extends StatelessWidget {
  const _MissionsSoon({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.deepTurquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.deepTurquoise.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 40,
            color: AppColors.deepTurquoise,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.journeyMissionsSoonTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.journeyMissionsSoonMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

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

/// O que vence nesta semana: pendentes, atrasadas e já pagas.
class _WeekChecklist extends ConsumerWidget {
  const _WeekChecklist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final missionAsync = ref.watch(MissionViewProviders.mission);

    return missionAsync.when(
      data: (mission) {
        final periodString = l10n.dateRange(
          mission.startDate.formated("dd/MM"),
          mission.endDate.formated("dd/MM"),
        );

        final hasAnyActivity = mission.totalCount > 0;

        // Só celebra quando havia itens e todos foram concluídos; uma semana
        // sem nenhuma atividade mostra um convite, não uma parabenização.
        final isCompleted =
            hasAnyActivity &&
            mission.pendingInstallments.isEmpty &&
            mission.overdueInstallments.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.journeyChecklistTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      periodString,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (hasAnyActivity)
                  Text(
                    l10n.weeklyMissionsProgress(
                      mission.completedCount.toString(),
                      mission.totalCount.toString(),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasAnyActivity)
              _NoMissionsEmptyState()
            else if (isCompleted)
              _SuccessEmptyState()
            else ...[
              if (mission.overdueInstallments.isNotEmpty) ...[
                Text(
                  l10n.overdueMissions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                ...mission.overdueInstallments.map(
                  (inst) => InstallmentItem(installmentInfo: inst),
                ),
                const SizedBox(height: 24),
              ],

              if (mission.pendingInstallments.isNotEmpty) ...[
                Text(
                  l10n.pendingMissions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...mission.pendingInstallments.map(
                  (inst) => InstallmentItem(installmentInfo: inst),
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Realizados (Expansível)
            if (mission.completedInstallments.isNotEmpty)
              _buildCompletedSection(context, mission),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.errorUnknown)),
          TextButton(
            onPressed: () => ref.invalidate(MissionViewProviders.mission),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSection(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Soma o XP que o SERVIDOR gravou em cada parcela. Parcela sem XP no
    // documento não entra na conta — antes o app somava um valor default e
    // apresentava o resultado como se fosse o que foi creditado.
    final totalCompletedXp = mission.completedInstallments.fold<double>(
      0,
      (sum, m) => sum + (m.installment.xp ?? 0),
    );

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.completedMissions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          l10n.completedMissionsSummary(
            mission.completedInstallments.length,
            totalCompletedXp.round().toString(),
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.deepTurquoise,
          ),
        ),
        children: mission.completedInstallments
            .map((inst) => InstallmentItem(installmentInfo: inst))
            .toList(),
      ),
    );
  }
}

class _SuccessEmptyState extends StatefulWidget {
  @override
  State<_SuccessEmptyState> createState() => _SuccessEmptyStateState();
}

class _SuccessEmptyStateState extends State<_SuccessEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingIcon> _icons = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final List<IconData> iconOptions = [
      Icons.star,
      Icons.favorite,
      Icons.celebration,
      Icons.auto_awesome,
      Icons.savings,
      Icons.rocket_launch,
      Icons.workspace_premium,
    ];

    for (int i = 0; i < 20; i++) {
      _icons.add(
        _FloatingIcon(
          icon: iconOptions[_random.nextInt(iconOptions.length)],
          color: [
            AppColors.deepTurquoise,
            AppColors.vibrantTeal,
            AppColors.successGold,
            AppColors.antiqueGold,
            Colors.pinkAccent,
          ][_random.nextInt(5)],
          size: 12.0 + _random.nextDouble() * 20.0,
          speed: 0.3 + _random.nextDouble() * 0.7,
          xRelative: _random.nextDouble(),
          yRelative: _random.nextDouble(),
          delay: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.deepTurquoise.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.deepTurquoise.withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      children: _icons.map((floating) {
                        // Animação individual baseada no delay e velocidade
                        final localProgress =
                            (_controller.value + floating.delay) % 1.0;

                        final x = floating.xRelative * constraints.maxWidth;
                        // Inicia de baixo (150) e vai para cima (-50)
                        final y = (1.0 - localProgress) * 200 - 25;

                        // Opacidade: fade in rápido no início, fade out no final
                        double opacity = 0.0;
                        if (localProgress < 0.2) {
                          opacity = localProgress / 0.2;
                        } else if (localProgress > 0.8) {
                          opacity = (1.0 - localProgress) / 0.2;
                        } else {
                          opacity = 1.0;
                        }

                        return Positioned(
                          left: x,
                          top: y,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Icon(
                              floating.icon,
                              color: floating.color.withValues(alpha: 0.5),
                              size: floating.size,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    size: 64,
                    color: AppColors.deepTurquoise,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.weeklyMissionsSuccessTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTurquoise,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.weeklyMissionsSuccessMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final Color color;
  final double size;
  final double speed;
  final double xRelative;
  final double yRelative;
  final double delay;

  _FloatingIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.speed,
    required this.xRelative,
    required this.yRelative,
    required this.delay,
  });
}

class _NoMissionsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.deepTurquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.deepTurquoise.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.flag_outlined,
            size: 40,
            color: AppColors.deepTurquoise,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.weeklyMissionsNone,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.weeklyMissionsNoneDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
