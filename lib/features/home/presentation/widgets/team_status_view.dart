import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';

class TeamStatusView extends StatelessWidget {
  final MissionModel mission;

  const TeamStatusView({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.partyTeamTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (mission.planningMissions.isNotEmpty) ...[
          _buildPartyStatusBar(context, mission),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 800) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 500) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: mission.planningMissions.length,
                itemBuilder: (context, index) {
                  return _buildChallengeCard(
                    context,
                    mission.planningMissions[index],
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPartyStatusBar(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final localeStr = context.locale;

    final color = switch (mission.partyStatus) {
      PartyStatus.healthy => AppColors.success,
      PartyStatus.strained => Colors.orange,
      PartyStatus.defeated => AppColors.error,
    };

    final statusText = switch (mission.partyStatus) {
      PartyStatus.healthy => l10n.partyStatusHealthy,
      PartyStatus.strained => l10n.partyStatusStrained,
      PartyStatus.defeated => l10n.partyStatusDefeated,
    };

    final emoji = switch (mission.partyStatus) {
      PartyStatus.healthy => '😊',
      PartyStatus.strained => '😰',
      PartyStatus.defeated => '💀',
    };

    final isOverBudget = mission.totalActualAmount > mission.totalPlannedAmount;
    final excess = isOverBudget
        ? mission.totalActualAmount - mission.totalPlannedAmount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          l10n.partyHpLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(mission.partyHp * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: mission.partyHp,
                        minHeight: 12,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildValueInfo(
                context,
                l10n.planned,
                mission.totalPlannedAmount.asCurrency(locale: localeStr),
              ),
              const SizedBox(width: 16),
              _buildValueInfo(
                context,
                l10n.actual,
                mission.totalActualAmount.asCurrency(locale: localeStr),
                valueColor: isOverBudget ? AppColors.error : null,
              ),
              if (isOverBudget) ...[
                const SizedBox(width: 16),
                _buildValueInfo(
                  context,
                  l10n.excess,
                  '+${excess.asCurrency(locale: localeStr)}',
                  valueColor: AppColors.error,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueInfo(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, PlanningMission mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;

    final color = switch (mission.status) {
      ChallengeStatus.stable => AppColors.success,
      ChallengeStatus.warning => Colors.orange,
      ChallengeStatus.critical => AppColors.error,
    };

    final emoji = switch (mission.status) {
      ChallengeStatus.stable => '😊',
      ChallengeStatus.warning => '😰',
      ChallengeStatus.critical => '💀',
    };

    final isOverLimit = mission.progress > 1;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: mission.category.color.asColor().withValues(
                          alpha: 0.1,
                        ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.category.icon.asIcon(),
                    size: 16,
                    color: mission.category.color.asColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mission.category.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildValueInfo(
                  context,
                  l10n.planned,
                  mission.weeklyPlannedAmount.asCurrency(locale: locale),
                ),
                const SizedBox(width: 8),
                _buildValueInfo(
                  context,
                  l10n.actual,
                  mission.weeklyActualAmount.asCurrency(locale: locale),
                  valueColor: isOverLimit ? AppColors.error : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hpLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (isOverLimit)
                  Text(
                    l10n.overBudgetAmount(
                      (mission.weeklyActualAmount - mission.weeklyPlannedAmount)
                          .asCurrency(locale: locale),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '${(mission.hp * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mission.hp,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
