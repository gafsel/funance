import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/installment_item.dart';

class WeeklyMissionsView extends ConsumerWidget {
  const WeeklyMissionsView({super.key});

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

        final isCompleted =
            mission.pendingInstallments.isEmpty &&
            mission.overdueInstallments.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyMissionsTitle,
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
              ],
            ),
            const SizedBox(height: 16),
            _buildOverallProgress(context, mission),
            const SizedBox(height: 24),

            if (isCompleted)
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
            if (mission.completedInstallments.isNotEmpty) ...[
              _buildCompletedSection(context, mission),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildOverallProgress(BuildContext context, MissionModel mission) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final progress = mission.progressPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.asPercent(locale: locale),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTurquoise,
                ),
              ),
              Text(
                l10n.weeklyMissionsProgress(
                  mission.completedInstallments.length.toString(),
                  (mission.pendingInstallments.length +
                          mission.overdueInstallments.length +
                          mission.completedInstallments.length)
                      .toString(),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.deepTurquoise.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.deepTurquoise),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSection(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final totalCompletedXp = mission.completedInstallments.fold(
      0.0,
      (sum, m) => sum + (m.installment.xp ?? m.earnedXp),
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
            totalCompletedXp.toInt().toString(),
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
