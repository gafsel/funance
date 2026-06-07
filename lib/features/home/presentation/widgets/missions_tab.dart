import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/controller/mission_controller.dart';
import 'package:funances/features/home/presentation/widgets/accounts_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MissionsTab extends ConsumerStatefulWidget {
  const MissionsTab({super.key});

  @override
  ConsumerState<MissionsTab> createState() => _MissionsTabState();
}

class _MissionsTabState extends ConsumerState<MissionsTab> {
  late ConfettiController _confettiController;
  double? _lastXp;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final missionAsync = ref.watch(missionProvider);

    missionAsync.whenData((mission) {
      if (_lastXp != null && mission.currentXp > _lastXp!) {
        // Se o XP aumentou, solta confete
        _confettiController.play();
      }
      _lastXp = mission.currentXp;
    });

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 1000;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLargeScreen ? 1200 : 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 120.0,
                  ),
                  child: SafeArea(
                    child: missionAsync.when(
                      data: (mission) {
                        if (mission.planningMissions.isEmpty &&
                            mission.pendingInstallments.isEmpty &&
                            mission.overdueInstallments.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        // Se cumpriu tudo (e havia algo a cumprir)
                        final allCompleted =
                            mission.planningMissions.every(
                                  (m) => m.progress >= 1 && m.isAdherent,
                                ) &&
                                mission.pendingInstallments.isEmpty &&
                                mission.overdueInstallments.isEmpty;

                        Widget content;
                        if (allCompleted &&
                            mission.planningMissions.isNotEmpty) {
                          content = Column(
                            children: [
                              _buildEmptyState(context, isSuccess: true),
                              const SizedBox(height: 24),
                              _buildMissionContent(context, mission),
                            ],
                          );
                        } else {
                          content = _buildMissionContent(context, mission);
                        }

                        if (isLargeScreen) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildWeeklyMissions(context, mission),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildTeamContent(context, mission),
                                    const SizedBox(height: 32),
                                    const Divider(),
                                    const SizedBox(height: 32),
                                    const AccountsView(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            content,
                            const SizedBox(height: 32),
                            const AccountsView(),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, st) {
                        print(e.toString());
                        print(st.toString());

                        return Center(child: Text(e.toString()));
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isSuccess = false}) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 100,
            color: isSuccess ? Colors.amber : theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSuccess ? l10n.weeklyMissionsSuccess : l10n.weeklyMissionsNone,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSuccess
                ? l10n.weeklyMissionsSuccessDesc
                : l10n.weeklyMissionsNoneDesc,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPartyStatusBar(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;

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

    final localeStr = Localizations.localeOf(context).toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyMissions(BuildContext context, MissionModel mission) {
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
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.weeklyMissions,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              periodString,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOverallProgress(context, mission),
        const SizedBox(height: 24),

        // Atrasados
        if (mission.overdueInstallments.isNotEmpty) ...[
          Text(
            l10n.overdueMissions,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          ...mission.overdueInstallments.map(
            (inst) => _buildInstallmentItem(context, inst),
          ),
          const SizedBox(height: 24),
        ],

        // Pendentes
        if (mission.pendingInstallments.isNotEmpty) ...[
          Text(
            l10n.pendingMissions,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...mission.pendingInstallments.map(
            (inst) => _buildInstallmentItem(context, inst),
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

  Widget _buildTeamContent(BuildContext context, MissionModel mission) {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 140,
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
          ),
        ],
      ],
    );
  }

  Widget _buildMissionContent(BuildContext context, MissionModel mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyMissions(context, mission),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        _buildTeamContent(context, mission),
      ],
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
            .map((inst) => _buildInstallmentItem(context, inst))
            .toList(),
      ),
    );
  }

  Widget _buildOverallProgress(BuildContext context, MissionModel mission) {
    final l10n = context.l10n;
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
                l10n.percentage((progress * 100).toInt().toString()),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.deepTurquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.xpProgress(
                  mission.currentXp.toInt().toString(),
                  mission.totalXp.toInt().toString(),
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
            const SizedBox(height: 8),
            Text(
              l10n.spentOfWeeklyPlanning(
                mission.weeklyActualAmount.asCurrency(locale: locale),
                mission.weeklyPlannedAmount.asCurrency(locale: locale),
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningMission(BuildContext context, PlanningMission mission) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;

    final isOverLimit = mission.progress > 1;
    final isLoss = !mission.isAdherent && mission.progress > 0;
    final isGaining = mission.isAdherent && mission.progress > 0;
    final displayXp = mission.earnedXp;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mission.category.icon.asIcon(),
                size: 16,
                color: mission.category.color.asColor(),
              ),
              const SizedBox(width: 8),
              Text(mission.category.name, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                l10n.xpValue(displayXp.toInt().toString()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: displayXp < 0 ? AppColors.error : AppColors.success,
                  fontWeight: displayXp < 0 ? FontWeight.bold : null,
                ),
              ),
              const SizedBox(width: 8),
              if (isLoss)
                Icon(
                  Icons.sentiment_very_dissatisfied,
                  size: 24,
                  color: AppColors.error,
                )
              else if (isGaining && mission.progress >= 0.8)
                const Icon(
                  Icons.sentiment_very_satisfied,
                  size: 24,
                  color: AppColors.success,
                )
              else
                Icon(
                  Icons.sentiment_neutral,
                  size: 24,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: mission.progress > 1 ? 1 : mission.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: mission.category.color.asColor().withValues(
              alpha: 0.1,
            ),
            valueColor: AlwaysStoppedAnimation(
              isLoss
                  ? theme.colorScheme.error
                  : mission.category.color.asColor(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.spentOfWeeklyPlanning(
                  mission.weeklyActualAmount.asCurrency(locale: locale),
                  mission.weeklyPlannedAmount.asCurrency(locale: locale),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOverLimit ? theme.colorScheme.error : null,
                ),
              ),
              if (isOverLimit)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(
    BuildContext context,
    InstallmentMission mission,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final inst = mission.installment;

    final isCompleted =
        inst.status == InstallmentStatus.settled ||
        inst.status == InstallmentStatus.paid;
    final isSuccess = mission.earnedXp > 0;
    final displayXp = isCompleted
        ? (inst.xp ?? mission.earnedXp)
        : mission.xpValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () =>
            context.push('/transactions/form', extra: {'installment': inst}),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: inst.isInvoice
                    ? AppColors.error
                    : inst.type == OrderType.transfer
                    ? AppColors.brightCyan
                    : inst.category?.color.asColor().withValues(alpha: 0.1) ??
                          Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                inst.isInvoice
                    ? Icons.credit_card
                    : inst.type == OrderType.transfer
                    ? Icons.swap_horiz
                    : inst.category?.icon.asIcon() ?? Icons.category,
                size: 20,
                color: inst.category?.color.asColor() ?? Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inst.description, style: theme.textTheme.bodyMedium),
                  Text(
                    DateFormat.E(
                      context.locale.toString(),
                    ).format(inst.referenceDate),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  inst.referenceAmount.asCurrency(locale: context.locale),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.xpValue(displayXp.toInt().toString()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted
                            ? isSuccess
                                  ? AppColors.success
                                  : AppColors.error
                            : theme.colorScheme.outline,
                        fontWeight: isCompleted ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 20,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: theme.colorScheme.outline,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
