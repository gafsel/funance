import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/home/presentation/provider.dart';

/// XP da semana, direto do `weekly_xp` do servidor.
///
/// SEM barra e SEM teto. Uma versão anterior desenhava uma barra com o
/// `weekly_xp` no numerador e a soma do `rewardXp` das missões no
/// denominador, mas o servidor nunca soma os dois: `weekly_xp` recebe só o XP
/// das parcelas (`FinanceService.updateWeeklyTotalXp`) e o XP das missões é
/// creditado em `workspaces.xp`
/// (`GamificationRepository.completeMissionAndAwardXp`). Completar as três
/// missões não movia aquela barra um milímetro, e o rótulo afirmava uma
/// relação que não existe. Cada missão mostra o próprio progresso e o próprio
/// XP logo abaixo; aqui fica só o número da semana, com o rótulo dizendo de
/// onde ele vem.
class WeeklyXp extends ConsumerWidget {
  const WeeklyXp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final xp = ref.watch(JourneyViewProviders.weeklyXp).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.successGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  l10n.journeyWeeklyXpCaption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
