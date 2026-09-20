import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/installment_item.dart';
import 'package:funances/features/home/presentation/widgets/missions/no_missions_empty_state.dart';
import 'package:funances/features/home/presentation/widgets/missions/success_empty_state.dart';

/// O que vence nesta semana: pendentes, atrasadas e já pagas.
class WeekChecklist extends ConsumerWidget {
  const WeekChecklist({super.key});

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
              const NoMissionsEmptyState()
            else if (isCompleted)
              const SuccessEmptyState()
            else ...[
              if (mission.overdueInstallments.isNotEmpty) ...[
                Text(
                  l10n.overdueMissions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: context.palette.dangerText,
                  ),
                ),
                AppSpacing.gapSm,
                ...mission.overdueInstallments.map(
                  (inst) => InstallmentItem(installmentInfo: inst),
                ),
                AppSpacing.gapLg,
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
                AppSpacing.gapLg,
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
          // "Erro inesperado" era a única coisa que este erro não era: sem
          // rede, o texto agora fala em conexão.
          Expanded(child: Text(errorMessageFor(context, e))),
          TextButton(
            onPressed: () => Retry.missions(ref),
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
      data: theme.copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.completedMissions, style: theme.textTheme.titleMedium),
        subtitle: Text(
          l10n.completedMissionsSummary(
            mission.completedInstallments.length,
            totalCompletedXp.round().toString(),
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.palette.ink,
          ),
        ),
        children: mission.completedInstallments
            .map((inst) => InstallmentItem(installmentInfo: inst))
            .toList(),
      ),
    );
  }
}
