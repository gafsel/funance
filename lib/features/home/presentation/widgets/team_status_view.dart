import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/presentation/retry.dart';

class TeamStatusView extends ConsumerWidget {
  const TeamStatusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final missionAsync = ref.watch(MissionViewProviders.mission);

    return missionAsync.when(
      data: (mission) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (mission.planningMissions.isEmpty)
            _EmptyParty()
          else ...[
            _buildPartyStatusBar(context, mission),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final groups = ChallengeStatus.values.reversed.map(
                  (status) => (
                    status: status,
                    color: switch (status) {
                      ChallengeStatus.stable => AppColors.success,
                      ChallengeStatus.warning => Colors.orange,
                      ChallengeStatus.critical => AppColors.error,
                    },
                    label: switch (status) {
                      ChallengeStatus.stable => l10n.challengeStatusStable,
                      ChallengeStatus.warning => l10n.challengeStatusWarning,
                      ChallengeStatus.critical => l10n.challengeStatusCritical,
                    },
                    emoji: switch (status) {
                      ChallengeStatus.stable => '😊',
                      ChallengeStatus.warning => '😰',
                      ChallengeStatus.critical => '💀',
                    },
                    items: mission.planningMissions
                        .where((item) => item.status == status)
                        .toList(),
                  ),
                );

                return Column(
                  spacing: 16,
                  children: [
                    for (final group in groups) ...[
                      if (group.items.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: group.color.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: group.color.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 16,
                            children: [
                              Text(
                                "${group.emoji} ${group.label.toUpperCase()}",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: group.color,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final item in group.items)
                                    _buildChallengeCard(context, item),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
      loading: () => const SizedBox.shrink(),
      // Erro visível, com saída: antes o stream quebrado sumia com a seção
      // inteira e o usuário não tinha nem o que tentar.
      error: (e, st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ErrorView(
            message: l10n.partyErrorMessage,
            onRetry: () => Retry.missions(ref),
          ),
        ],
      ),
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
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 8,
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

    final isOverLimit = mission.progress > 1;
    final excess = mission.weeklyActualAmount - mission.weeklyPlannedAmount;
    final rest = mission.weeklyPlannedAmount - mission.weeklyActualAmount;

    return SizedBox(
      width: 70,
      child: Column(
        spacing: 8,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  value: mission.hp,
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: mission.category.color.asColor().withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.category.icon.asIcon(),
                    size: 24,
                    color: mission.category.color.asColor(),
                  ),
                ),
              ),
            ],
          ),
          Text(
            mission.category.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (isOverLimit) ...[
            _buildValueInfo(
              context,
              l10n.excess,
              excess.asCurrency(locale: locale),
              valueColor: AppColors.error,
            ),
          ] else ...[
            _buildValueInfo(
              context,
              l10n.rest,
              rest.asCurrency(locale: locale),
              valueColor: AppColors.deepTurquoise,
            ),
          ],
        ],
      ),
    );
  }
}

/// Sem nenhum limite de gastos, a equipe não tem desafio para enfrentar.
///
/// A seção inteira sumia nesse caso — o usuário via um buraco no lugar do time
/// e nada indicando o que fazer. Agora o vazio explica de onde vêm os desafios
/// e leva para a tela de limites.
class _EmptyParty extends StatelessWidget {
  const _EmptyParty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepTurquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepTurquoise.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 40,
            color: AppColors.deepTurquoise,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.partyEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.partyEmptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/planning?type=expense'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.partyEmptyButton),
          ),
        ],
      ),
    );
  }
}
