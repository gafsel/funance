import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/arena_week_closing.dart';

/// O placar da semana que fechou.
///
/// Uma semana de jogo sem placar é uma semana sem fim: a barra zera no
/// domingo e o que aconteceu some junto. Este é o único lugar em que o app
/// diz "a semana passada terminou assim" — monstro derrotado ou escapado,
/// quantos compromissos de quantos, e com quanto os heróis chegaram no
/// sábado.
///
/// Aparece **uma vez** e é dispensável. Um aviso que volta todo dia deixa de
/// ser aviso no terceiro dia, e é por isso que ele grava o que já foi visto.
class ArenaWeekClosingBanner extends ConsumerWidget {
  const ArenaWeekClosingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(ArenaWeekClosingProviders.shouldShow)) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(ArenaViewProviders.lastWeekState).valueOrNull;

    // Sem luta nenhuma na semana passada não há placar: um "0 de 0" é pior
    // que silêncio. E enquanto os números não chegam, nada aparece — um
    // esqueleto no topo da Home pesaria mais do que a informação promete.
    if (state == null || state.commitmentsCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;
    final venceu = state.isDefeated;

    return Padding(
      key: const ValueKey('arena-week-closing'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.gameTrough,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: venceu ? AppColors.gold : AppColors.gameFrame,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              venceu ? Icons.emoji_events : Icons.flag_outlined,
              size: 18,
              color: venceu ? AppColors.gold : AppColors.inkInverse2,
            ),
            AppSpacing.gapXs,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venceu
                        ? l10n.arenaClosingWon
                        : l10n.arenaClosingLost(
                            state.monsterHp.asCurrency(locale: locale),
                          ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: venceu ? AppColors.gold : AppColors.inkInverse,
                    ),
                  ),
                  Text(
                    l10n.arenaClosingScore(
                      state.struckCount,
                      state.commitmentsCount,
                      state.currentBalance.asCurrency(locale: locale),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.inkInverse2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('arena-week-closing-dismiss'),
              tooltip: l10n.closeButton,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.inkInverse2,
              ),
              onPressed: () => ref
                  .read(ArenaWeekClosingProviders.seen.notifier)
                  .markSeen(ref.read(ArenaWeekClosingProviders.lastWeekId)),
            ),
          ],
        ),
      ),
    );
  }
}
