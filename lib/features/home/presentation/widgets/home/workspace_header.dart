import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_type_badge.dart';
import 'package:go_router/go_router.dart';

/// O cabeçalho da Jornada: de quem é o cofre, de que tipo ele é, e em que
/// nível está.
///
/// A Home antiga dedicava um bloco inteiro ao nível, que muda uma vez por mês.
/// A regra nova é que o que muda por dia ocupa o corpo e o que muda por mês
/// vira selo — então o nível cabe numa linha, junto do nome.
class WorkspaceHeader extends ConsumerWidget {
  const WorkspaceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    final workspace = ref.watch(
      WorkspaceViewProviders.workspace.select(
        (state) => state.currentWorkspace,
      ),
    );
    final gamification = ref.watch(WorkspaceViewProviders.gamification);
    final catalog = ref.watch(BadgeCatalogProviders.catalog).valueOrNull;

    if (workspace == null) return const SizedBox.shrink();

    final progress =
        catalog?.levelProgress(gamification.level, gamification.xp) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayOr(workspace.name, l10n.unnamedWorkspace),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                  ),
                ),
                AppSpacing.gapXxs,
                WorkspaceTypeBadge(type: workspace.type),
              ],
            ),
          ),
          AppSpacing.gapXs,
          LevelBadge(
            level: gamification.level,
            progress: progress,
            label: l10n.levelBadgeShort(gamification.level),
            semanticLabel: l10n.levelBadgeSemantics(
              gamification.level,
              (progress * 100).round(),
            ),
            onTap: () => context.push('/workspace/badges'),
          ),
        ],
      ),
    );
  }
}
