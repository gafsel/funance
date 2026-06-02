import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
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
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 120.0,
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyMissions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    missionAsync.when(
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

                        if (allCompleted &&
                            mission.planningMissions.isNotEmpty) {
                          return Column(
                            children: [
                              _buildEmptyState(context, isSuccess: true),
                              const SizedBox(height: 24),
                              _buildMissionContent(context, mission),
                            ],
                          );
                        }

                        return _buildMissionContent(context, mission);
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text(e.toString())),
                    ),
                    const SizedBox(height: 32),
                    const AccountsView(),
                  ],
                ),
              ),
            ),
          ),
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

  Widget _buildMissionContent(BuildContext context, MissionModel mission) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');
    final periodString = l10n.dateRange(
      dateFormat.format(mission.startDate),
      dateFormat.format(mission.endDate),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          periodString,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Barra de Progresso Geral
        _buildOverallProgress(context, mission),
        const SizedBox(height: 24),

        // 1. Installments Primeiro
        // Atrasados
        if (mission.overdueInstallments.isNotEmpty) ...[
          Text(
            l10n.overdueMissions,
            style: theme.textTheme.titleMedium?.copyWith(
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...mission.pendingInstallments.map(
            (inst) => _buildInstallmentItem(context, inst),
          ),
          const SizedBox(height: 24),
        ],

        // Metas da Semana (Plannings)
        if (mission.planningMissions.isNotEmpty) ...[
          Text(
            l10n.weeklyGoal,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...mission.planningMissions.map(
            (p) => _buildPlanningMission(context, p),
          ),
          const SizedBox(height: 24),
        ],

        // Realizados (Expansível)
        if (mission.completedInstallments.isNotEmpty)
          _buildCompletedSection(context, mission),
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
                mission.summary.category.icon.asIcon(),
                size: 16,
                color: mission.summary.category.color.asColor(),
              ),
              const SizedBox(width: 8),
              Text(
                mission.summary.category.name,
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                l10n.xpValue(displayXp.toInt().toString()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: displayXp < 0
                      ? AppColors.error
                      : AppColors.success,
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
            backgroundColor: mission.summary.category.color
                .asColor()
                .withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              isLoss
                  ? theme.colorScheme.error
                  : mission.summary.category.color.asColor(),
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
                color:
                    inst.category?.color.asColor().withValues(alpha: 0.1) ??
                    Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                inst.category?.icon.asIcon() ?? Icons.category,
                size: 20,
                color: inst.category?.color.asColor() ?? Colors.grey,
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
                            ? displayXp < mission.xpValue
                                  ? AppColors.error
                                  : AppColors.success
                            : theme.colorScheme.outline,
                        fontWeight: displayXp != mission.xpValue && isCompleted
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      Icon(
                        displayXp >= mission.xpValue
                            ? Icons.sentiment_very_satisfied
                            : Icons.sentiment_very_dissatisfied,
                        size: 24,
                        color: displayXp >= mission.xpValue
                            ? AppColors.success
                            : AppColors.error,
                      )
                    else
                      Icon(
                        Icons.sentiment_neutral,
                        size: 24,
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
