import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/widgets/empty_state.dart';

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
          Text(l10n.partyTitle, style: theme.textTheme.titleMedium),
          AppSpacing.gapSm,
          if (mission.planningMissions.isEmpty)
            _EmptyParty()
          else ...[
            _buildPartyStatusBar(context, mission),
            AppSpacing.gapLg,
            // Era um `LayoutBuilder` que abria o builder e nunca lia
            // `constraints`: reconstruía os grupos a cada mudança de tamanho
            // sem usar a informação para nada.
            _buildChallengeGroups(context, mission),
          ],
        ],
      ),
      loading: () => const SizedBox.shrink(),
      // Erro visível, com saída: antes o stream quebrado sumia com a seção
      // inteira e o usuário não tinha nem o que tentar.
      error: (e, st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.partyTitle, style: theme.textTheme.titleMedium),
          AppSpacing.gapSm,
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
    final palette = context.palette;

    final color = switch (mission.partyStatus) {
      PartyStatus.healthy => palette.successText,
      PartyStatus.strained => palette.warningText,
      PartyStatus.defeated => palette.dangerText,
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

    return AppCard(
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: theme.textTheme.displayLarge),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Row(
                      children: [
                        Text(
                          l10n.partyHpLabel,
                          style: theme.textTheme.labelSmall,
                        ),
                        const Spacer(),
                        Text(
                          '${(mission.partyHp * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapXxs,
                    AppProgressBar(
                      value: mission.partyHp,
                      size: AppProgressSize.thick,
                      color: color,
                      trackColor: color.withValues(alpha: 0.1),
                      semanticLabel: l10n.partyHpLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              _buildValueInfo(context, l10n.planned, mission.totalPlannedAmount),
              AppSpacing.gapMd,
              _buildValueInfo(
                context,
                l10n.actual,
                mission.totalActualAmount,
                valueColor: isOverBudget ? palette.dangerText : null,
              ),
              if (isOverBudget) ...[
                AppSpacing.gapMd,
                _buildValueInfo(
                  context,
                  l10n.excess,
                  excess,
                  showSign: true,
                  valueColor: palette.dangerText,
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
    double value, {
    Color? valueColor,
    bool showSign = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.palette.ink2,
          ),
        ),
        MoneyText(
          value,
          showSign: showSign,
          style: theme.textTheme.labelMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }

  /// Os desafios do time, agrupados por status (crítico primeiro).
  Widget _buildChallengeGroups(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = context.palette;

    final groups = ChallengeStatus.values.reversed.map(
      (status) => (
        status: status,
        color: switch (status) {
          ChallengeStatus.stable => palette.successText,
          ChallengeStatus.warning => palette.warningText,
          ChallengeStatus.critical => palette.dangerText,
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
      spacing: AppSpacing.md,
      children: [
        for (final group in groups) ...[
          if (group.items.isNotEmpty) ...[
            AppCard(
              padding: AppSpacing.allSm,
              borderColor: group.color.withValues(alpha: 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "${group.emoji} ${group.label.toUpperCase()}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: group.color,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
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
  }

  Widget _buildChallengeCard(BuildContext context, PlanningMission mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = context.palette;

    final color = switch (mission.status) {
      ChallengeStatus.stable => palette.successText,
      ChallengeStatus.warning => palette.warningText,
      ChallengeStatus.critical => palette.dangerText,
    };

    final isOverLimit = mission.progress > 1;
    final excess = mission.weeklyActualAmount - mission.weeklyPlannedAmount;
    final rest = mission.weeklyPlannedAmount - mission.weeklyActualAmount;

    return SizedBox(
      width: 70,
      child: Column(
        spacing: AppSpacing.xs,
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
                  padding: AppSpacing.allXxs,
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
            style: theme.textTheme.labelSmall,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (isOverLimit) ...[
            _buildValueInfo(
              context,
              l10n.excess,
              excess,
              valueColor: palette.dangerText,
            ),
          ] else ...[
            _buildValueInfo(context, l10n.rest, rest, valueColor: palette.ink),
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
    final l10n = context.l10n;

    return EmptyState.card(
      icon: Icons.shield_outlined,
      title: l10n.partyEmptyTitle,
      message: l10n.partyEmptyMessage,
      padding: AppSpacing.allMd,
      action: FilledButton.icon(
        onPressed: () => context.push('/planning?type=expense'),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.partyEmptyButton),
      ),
    );
  }
}
