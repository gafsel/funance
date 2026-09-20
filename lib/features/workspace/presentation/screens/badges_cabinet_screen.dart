import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_grid.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/level_header_card.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/xp_sources_section.dart';
import 'package:funances/core/intro/intro_store.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/info_intro.dart';
import 'package:funances/core/widgets/section_header.dart';
import 'package:funances/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vitrine de conquistas
//
// O arquivo tinha 1588 linhas e 62% delas eram um mini design-system de
// emblemas metálicos — pintura que nunca falou sobre esta tela. Tudo isso
// mora agora em `presentation/widgets/badges/`, e o que sobrou aqui é o que a
// vitrine de fato é: ler o catálogo publicado pelo servidor e montar
// cabeçalho + seções.
// ─────────────────────────────────────────────────────────────────────────────

class BadgesCabinetScreen extends ConsumerWidget {
  const BadgesCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final workspace = workspaceState.currentWorkspace;
    final catalogAsync = ref.watch(BadgeCatalogProviders.catalog);

    if (workspace == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // A vitrine filtra pelo tipo do cofre: uma empresa não persegue "Regra de
    // Ouro" e uma casa não persegue "conciliar 100% do extrato". O que já foi
    // conquistado nunca some — ver `BadgeCatalog.forWorkspace`.
    final catalog = catalogAsync.valueOrNull?.forWorkspace(
      workspace.type,
      workspace.unlockedBadges,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamAchievementsTitle), elevation: 0),
      body: BadgesCabinetView(
        catalog: catalog,
        isLoading: catalogAsync.isLoading,
        workspaceName: workspace.name,
        level: workspace.level,
        xp: workspace.xp,
        // A vitrine conta a sequência de MISSÕES; a de planejamento ainda não
        // tem lugar na tela.
        weeklyStreaks: workspace.weeklyStreaks.missions,
        unlockedBadges: workspace.unlockedBadges,
      ),
    );
  }
}

/// Corpo da vitrine, separado da tela para poder ser montado num teste de
/// widget com um catálogo falso, sem Firebase.
class BadgesCabinetView extends ConsumerStatefulWidget {
  const BadgesCabinetView({
    super.key,
    required this.catalog,
    required this.isLoading,
    required this.workspaceName,
    required this.level,
    required this.xp,
    required this.weeklyStreaks,
    required this.unlockedBadges,
  });

  /// `null` enquanto o servidor não publicou `config/badges`.
  final BadgeCatalog? catalog;
  final bool isLoading;
  final String workspaceName;
  final int level;
  final int xp;
  final int weeklyStreaks;

  /// id do badge -> data de desbloqueio (ISO 8601).
  final Map<String, String> unlockedBadges;

  @override
  ConsumerState<BadgesCabinetView> createState() => _BadgesCabinetViewState();
}

class _BadgesCabinetViewState extends ConsumerState<BadgesCabinetView>
    with IntroPanelMixin<BadgesCabinetView> {
  @override
  String get introKey => IntroKeys.badgesXpSources;

  @override
  Widget buildIntroBody(BuildContext context) =>
      XpSourcesSection(sources: widget.catalog?.xpSources ?? const []);

  @override
  void initState() {
    super.initState();
    scheduleIntro();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = widget.catalog;

    if (catalog == null || catalog.badges.isEmpty) {
      if (widget.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _CatalogUnavailable(l10n: l10n);
    }

    final xpInLevel = catalog.xpInLevel(widget.level, widget.xp);
    final xpForNextLevel = catalog.xpToNextLevel(widget.level);
    final progressFraction = catalog.levelProgress(widget.level, widget.xp);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.allMd,
            child: LevelHeaderCard(
              workspaceName: widget.workspaceName,
              level: widget.level,
              xp: widget.xp,
              xpInLevel: xpInLevel,
              xpForNextLevel: xpForNextLevel,
              progressFraction: progressFraction,
              weeklyStreaks: widget.weeklyStreaks,
              unlockedCount: widget.unlockedBadges.keys
                  .where((id) => catalog.badges.any((b) => b.id == id))
                  .length,
              totalCount: catalog.badges.length,
              // A porta da explicação, no cabeçalho — e a explicação é a
              // lista de fontes de XP, que era a primeira coisa da tela.
              info: catalog.xpSources.isEmpty
                  ? null
                  : InfoIntroButton(
                      key: introAnchorKey,
                      label: l10n.badgesXpSourcesHowItWorks,
                      onPressed: openIntro,
                      onGame: true,
                    ),
            ),
          ),
        ),
        // "Como ganhar XP" saiu daqui. Ela vinha ANTES das conquistas — a
        // vitrine respondia "o que você já fez" sem nunca dizer o que rende
        // pontos —, e o preço era a tela inteira: a régua de XP empurrava os
        // emblemas para baixo da dobra em todo celular. O dono: *"a descrição
        // de como ganhar xp pode ser ocultada e mostrada apenas na primeira
        // vez que for aberto, como defini para os ícones do jogo"*. Ela
        // continua chegando — sozinha, na primeira visita —, e depois mora
        // atrás do ícone do cabeçalho.
        for (final category in catalog.categories) ...[
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final color = category == BadgeCategory.advanced
                    ? AppColors.goldDeep
                    : Theme.of(context).colorScheme.primary;
                final unlocked = catalog
                    .ofCategory(category)
                    .where(
                      (badge) => widget.unlockedBadges.containsKey(badge.id),
                    )
                    .length;

                return SectionHeader.withIcon(
                  icon: badgeCategoryIcon(category),
                  title: badgeCategoryLabel(l10n, category),
                  color: color,
                  trailing: SectionHeaderCounter(
                    label: '$unlocked / ${catalog.ofCategory(category).length}',
                    color: color,
                  ),
                );
              },
            ),
          ),
          BadgeGrid(
            badges: catalog.ofCategory(category),
            unlockedBadges: widget.unlockedBadges,
          ),
        ],
        const SliverToBoxAdapter(child: AppSpacing.gapXl),
      ],
    );
  }
}

class _CatalogUnavailable extends StatelessWidget {
  const _CatalogUnavailable({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => EmptyState.centered(
    icon: Icons.emoji_events_outlined,
    title: l10n.badgeCatalogUnavailableTitle,
    message: l10n.badgeCatalogUnavailableMessage,
    compact: true,
  );
}
