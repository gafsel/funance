import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:go_router/go_router.dart';

/// O selo de nível do cofre, ligado aos providers.
///
/// Substitui o `WorkspaceLevelIndicator`, que desenhava a MESMA informação de
/// outro jeito — um anel de progresso de 44px com o número no meio e uma
/// medalha pendurada no canto — enquanto o corpo da Home já mostrava o nível
/// num `LevelBadge`. Eram dois desenhos do mesmo dado na mesma tela, e nenhum
/// dos dois usava o componente do design system.
///
/// Existe em UM lugar por tela: na `AppBar` no mobile, no `NavigationRail` no
/// desktop. A identidade do cofre — nome, tipo e nível — mora na barra, e não
/// no corpo: o corpo é para o que muda por dia.
class WorkspaceLevelBadge extends ConsumerWidget {
  const WorkspaceLevelBadge({super.key, this.onGame = false});

  /// `true` quando o selo está sobre uma superfície de jogo (o rail).
  final bool onGame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gamification = ref.watch(WorkspaceViewProviders.gamification);

    if (gamification.workspaceId == null) return const SizedBox.shrink();

    // A régua de XP por nível vem do backend
    // (`config/badges.levelThresholds`). Sem catálogo publicado a barra fica
    // vazia, em vez de mostrar um progresso calculado por uma fórmula que o
    // servidor pode ter mudado.
    final progress =
        ref
            .watch(BadgeCatalogProviders.catalog)
            .valueOrNull
            ?.levelProgress(gamification.level, gamification.xp) ??
        0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LevelBadge(
        level: gamification.level,
        progress: progress,
        label: l10n.levelBadgeShort(gamification.level),
        semanticLabel: l10n.levelBadgeSemantics(
          gamification.level,
          (progress * 100).round(),
        ),
        onGame: onGame,
        onTap: () => context.push('/workspace/badges'),
      ),
    );
  }
}
