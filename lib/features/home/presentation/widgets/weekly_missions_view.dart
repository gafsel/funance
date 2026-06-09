import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/widgets/installment_item.dart';

class WeeklyMissionsView extends StatelessWidget {
  final MissionModel mission;

  const WeeklyMissionsView({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final periodString = l10n.dateRange(
      mission.startDate.formated("dd/MM"),
      mission.endDate.formated("dd/MM"),
    );

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

        // Realizados (Expansível)
        if (mission.completedInstallments.isNotEmpty) ...[
          _buildCompletedSection(context, mission),
        ],
      ],
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
