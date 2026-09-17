import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class WorkspaceLevelIndicator extends ConsumerWidget {
  const WorkspaceLevelIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref.watch(WorkspaceViewProviders.gamification);

    if (workspace.workspaceId == null) {
      return const SizedBox.shrink();
    }

    final level = workspace.level;
    final xp = workspace.xp;

    // A régua de XP por nível vem do backend (`config/badges.levelThresholds`).
    // Antes esta tela reimplementava a inversa de `calculateLevel` — e a tela
    // de conquistas reimplementava outra vez. Sem catálogo publicado a barra
    // fica vazia, em vez de mostrar um progresso calculado por uma fórmula que
    // o servidor pode ter mudado.
    final catalog = ref.watch(BadgeCatalogProviders.catalog).valueOrNull;
    final progressFraction = catalog?.levelProgress(level, xp) ?? 0.0;

    final unlockedCount = workspace.unlockedBadges.length;
    final theme = Theme.of(context);

    return Semantics(
      label: l10n.levelIndicatorSemantics(level, unlockedCount),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => context.push('/workspace/badges'),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progressFraction,
                      strokeWidth: 3.5,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      '$level',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: GestureDetector(
                onTap: () => context.push('/workspace/badges'),
                child: Container(
                  padding: AppSpacing.allXxs,
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.military_tech,
                        size: 11,
                        color: AppColors.inkInverse,
                      ),
                      if (unlockedCount > 0) ...[
                        // Fio óptico abaixo da escala de 4pt: separa o ícone
                        // do número dentro de um selo de 11px.
                        const SizedBox(width: 1),
                        Text(
                          '$unlockedCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkInverse,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    ),
  );
}
}
