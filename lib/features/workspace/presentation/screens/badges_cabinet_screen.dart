import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Apresentação
//
// O CATÁLOGO (ids, nomes, XP, descrições, categorias) e a tabela de XP por
// nível vêm do backend, em `config/badges`. Antes eram espelhados à mão neste
// arquivo — 67 entradas com o XP como string e as descrições nos ARB — e o
// nível era recalculado aqui com a inversa de `calculateLevel`. Cada badge novo
// no servidor exigia lembrar de editar este arquivo, e ninguém lembrava.
//
// O que sobra aqui é só aparência: qual `IconData` corresponde ao nome do ícone
// (o Flutter precisa de constantes para o tree-shaking de ícones) e qual cor
// cada seção usa.
// ─────────────────────────────────────────────────────────────────────────────

enum BadgeTier { advanced, simple }

enum SimpleBadgeGroup { firstSteps, consistency, savings, goals, team }

/// Nome do ícone (como o servidor publica) -> `IconData`.
///
/// Não pode ser `IconData(codePoint)` dinâmico: com `--tree-shake-icons` (o
/// padrão em release) um ícone que não aparece como constante no código é
/// removido do font e vira um quadrado vazio.
const Map<String, IconData> _badgeIcons = {
  'rocket_launch': Icons.rocket_launch,
  'account_balance': Icons.account_balance,
  'add_circle': Icons.add_circle,
  'assignment': Icons.assignment,
  'point_of_sale': Icons.point_of_sale,
  'fact_check': Icons.fact_check,
  'workspace_premium': Icons.workspace_premium,
  'bolt': Icons.bolt,
  'savings': Icons.savings,
  'military_tech': Icons.military_tech,
  'stars': Icons.stars,
  'check_circle': Icons.check_circle,
  'pie_chart': Icons.pie_chart,
  'trending_up': Icons.trending_up,
  'content_cut': Icons.content_cut,
  'groups': Icons.groups,
  'calendar_month': Icons.calendar_month,
  'label': Icons.label,
  'event_note': Icons.event_note,
  'flag': Icons.flag,
  'person_add': Icons.person_add,
  'verified': Icons.verified,
  'south_east': Icons.south_east,
  'north_west': Icons.north_west,
  'swap_horiz': Icons.swap_horiz,
  'edit': Icons.edit,
  'calendar_today': Icons.calendar_today,
  'flash_on': Icons.flash_on,
  'emoji_events': Icons.emoji_events,
  'date_range': Icons.date_range,
  'account_balance_wallet': Icons.account_balance_wallet,
  'dashboard': Icons.dashboard,
  'business_center': Icons.business_center,
  'category': Icons.category,
  'workspaces': Icons.workspaces,
  'radio_button_checked': Icons.radio_button_checked,
  'payments': Icons.payments,
  'grain': Icons.grain,
  'receipt_long': Icons.receipt_long,
  'balance': Icons.balance,
  'donut_small': Icons.donut_small,
  'donut_large': Icons.donut_large,
  'percent': Icons.percent,
  'monetization_on': Icons.monetization_on,
  'credit_score': Icons.credit_score,
  'looks_two': Icons.looks_two,
  'looks_3': Icons.looks_3,
  'timer': Icons.timer,
  'offline_bolt': Icons.offline_bolt,
  'dynamic_feed': Icons.dynamic_feed,
  'public': Icons.public,
  'add_card': Icons.add_card,
  'free_cancellation': Icons.free_cancellation,
  'link': Icons.link,
  'group_add': Icons.group_add,
  'refresh': Icons.refresh,
  'sync_alt': Icons.sync_alt,
  'task_alt': Icons.task_alt,
  'sports_score': Icons.sports_score,
  'event_available': Icons.event_available,
  'repeat': Icons.repeat,
  'cake': Icons.cake,
  'waving_hand': Icons.waving_hand,
  'star': Icons.star,
};

/// Ícone do badge; um nome desconhecido (badge novo, app antigo) vira um troféu
/// genérico em vez de sumir da vitrine.
IconData badgeIconFor(String iconName) =>
    _badgeIcons[iconName] ?? Icons.emoji_events;

/// Paleta por seção. A cor de cada badge é escolhida de forma determinística
/// pelo id, para dar variedade sem manter uma lista de 67 cores à mão.
const Map<BadgeCategory, List<Color>> _categoryPalettes = {
  BadgeCategory.advanced: [
    Color(0xFF7E57C2),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFF9A825),
    Color(0xFFD81B60),
  ],
  BadgeCategory.firstSteps: [
    Color(0xFF7C4DFF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
  ],
  BadgeCategory.consistency: [
    Color(0xFFFDD835),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFF0288D1),
  ],
  BadgeCategory.savings: [
    Color(0xFFF57C00),
    Color(0xFF26C6DA),
    Color(0xFFE91E63),
    Color(0xFF43A047),
  ],
  BadgeCategory.goals: [
    Color(0xFF5C6BC0),
    Color(0xFF8E24AA),
    Color(0xFFE64A19),
    Color(0xFF0097A7),
  ],
  BadgeCategory.team: [
    Color(0xFF039BE5),
    Color(0xFF00796B),
    Color(0xFF558B2F),
    Color(0xFF7B1FA2),
  ],
  BadgeCategory.unknown: [Color(0xFF78909C)],
};

Color badgeColorFor(BadgeCatalogItem badge) {
  final palette =
      _categoryPalettes[badge.category] ??
      _categoryPalettes[BadgeCategory.unknown]!;
  var hash = 0;
  for (final unit in badge.id.codeUnits) {
    hash = (hash + unit) % 997;
  }
  return palette[hash % palette.length];
}

BadgeTier badgeTierFor(BadgeCategory category) =>
    category == BadgeCategory.advanced ? BadgeTier.advanced : BadgeTier.simple;

SimpleBadgeGroup simpleGroupFor(BadgeCategory category) => switch (category) {
  BadgeCategory.firstSteps => SimpleBadgeGroup.firstSteps,
  BadgeCategory.consistency => SimpleBadgeGroup.consistency,
  BadgeCategory.savings => SimpleBadgeGroup.savings,
  BadgeCategory.goals => SimpleBadgeGroup.goals,
  BadgeCategory.team ||
  BadgeCategory.advanced ||
  BadgeCategory.unknown => SimpleBadgeGroup.team,
};

String badgeCategoryLabel(AppLocalizations l10n, BadgeCategory category) =>
    switch (category) {
      BadgeCategory.advanced => l10n.badgeCategoryAdvanced,
      BadgeCategory.firstSteps => l10n.badgeCategoryFirstSteps,
      BadgeCategory.consistency => l10n.badgeCategoryConsistency,
      BadgeCategory.savings => l10n.badgeCategorySavings,
      BadgeCategory.goals => l10n.badgeCategoryGoals,
      BadgeCategory.team || BadgeCategory.unknown => l10n.badgeCategoryTeam,
    };

IconData badgeCategoryIcon(BadgeCategory category) =>
    category == BadgeCategory.advanced ? Icons.workspace_premium : Icons.star;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
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

    final catalog = catalogAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamAchievementsTitle), elevation: 0),
      body: BadgesCabinetView(
        catalog: catalog,
        isLoading: catalogAsync.isLoading,
        workspaceName: workspace.name,
        level: workspace.level,
        xp: workspace.xp,
        weeklyStreaks: workspace.weeklyStreaks,
        unlockedBadges: workspace.unlockedBadges,
      ),
    );
  }
}

/// Corpo da vitrine, separado da tela para poder ser montado num teste de
/// widget com um catálogo falso, sem Firebase.
class BadgesCabinetView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = this.catalog;

    if (catalog == null || catalog.badges.isEmpty) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _CatalogUnavailable(l10n: l10n);
    }

    final xpInLevel = catalog.xpInLevel(level, xp);
    final xpForNextLevel = catalog.xpToNextLevel(level);
    final progressFraction = catalog.levelProgress(level, xp);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _LevelHeaderCard(
              workspaceName: workspaceName,
              level: level,
              xp: xp,
              xpInLevel: xpInLevel,
              xpForNextLevel: xpForNextLevel,
              progressFraction: progressFraction,
              weeklyStreaks: weeklyStreaks,
              unlockedCount: unlockedBadges.keys
                  .where((id) => catalog.badges.any((b) => b.id == id))
                  .length,
              totalCount: catalog.badges.length,
            ),
          ),
        ),
        // Como ganhar XP vem ANTES das conquistas: a vitrine respondia "o que
        // você já fez" sem nunca dizer o que rende pontos, e a régua estava
        // só na cabeça de quem escreveu o backend.
        if (catalog.xpSources.isNotEmpty)
          SliverToBoxAdapter(child: _XpSourcesSection(sources: catalog.xpSources)),
        for (final category in catalog.categories) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: badgeCategoryIcon(category),
              label: badgeCategoryLabel(l10n, category),
              unlocked: catalog
                  .ofCategory(category)
                  .where((badge) => unlockedBadges.containsKey(badge.id))
                  .length,
              total: catalog.ofCategory(category).length,
              color: category == BadgeCategory.advanced
                  ? Colors.amber.shade700
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          _BadgeGrid(
            badges: catalog.ofCategory(category),
            unlockedBadges: unlockedBadges,
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _CatalogUnavailable extends StatelessWidget {
  const _CatalogUnavailable({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.badgeCatalogUnavailableTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.badgeCatalogUnavailableMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelHeaderCard extends StatelessWidget {
  const _LevelHeaderCard({
    required this.workspaceName,
    required this.level,
    required this.xp,
    required this.xpInLevel,
    required this.xpForNextLevel,
    required this.progressFraction,
    required this.weeklyStreaks,
    required this.unlockedCount,
    required this.totalCount,
  });

  final String workspaceName;
  final int level;
  final int xp;
  final int xpInLevel;
  final int xpForNextLevel;
  final double progressFraction;
  final int weeklyStreaks;
  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.workspaceLabel(workspaceName),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.levelLabel(level),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        l10n.badgeCatalogTotal(unlockedCount, totalCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$xpInLevel / $xpForNextLevel XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  l10n.totalXpLabel(xp.toString()),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressFraction,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 12,
              ),
            ),
            if (weeklyStreaks > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    weeklyStreaks == 1
                        ? l10n.weeklyStreaksLabelSingular
                        : l10n.weeklyStreaksLabelPlural(weeklyStreaks),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.unlockedBadges});

  final List<BadgeCatalogItem> badges;
  final Map<String, String> unlockedBadges;

  @override
  Widget build(BuildContext context) {
    final isAdvanced =
        badges.isNotEmpty && badges.first.category == BadgeCategory.advanced;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isAdvanced ? 130 : 68,
          mainAxisSpacing: isAdvanced ? 16 : 12,
          crossAxisSpacing: isAdvanced ? 16 : 12,
          childAspectRatio: isAdvanced ? 0.85 : 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final badge = badges[index];
          final unlockDateStr = unlockedBadges[badge.id];
          final isUnlocked = unlockDateStr != null;

          void openDetail() =>
              showBadgeDetail(context, badge, unlockDateStr);

          return isAdvanced
              ? _AdvancedBadgeCard(
                  badge: badge,
                  isUnlocked: isUnlocked,
                  onTap: openDetail,
                )
              : _SimpleBadgeChip(
                  badge: badge,
                  isUnlocked: isUnlocked,
                  onTap: openDetail,
                );
        }, childCount: badges.length),
      ),
    );
  }
}

void showBadgeDetail(
  BuildContext context,
  BadgeCatalogItem badge,
  String? unlockDateStr,
) {
  final l10n = AppLocalizations.of(context)!;
  final isUnlocked = unlockDateStr != null;
  final tier = badgeTierFor(badge.category);
  final color = badgeColorFor(badge);
  DateTime? unlockDate;
  if (unlockDateStr != null) {
    try {
      unlockDate = DateTime.parse(unlockDateStr);
    } catch (_) {}
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          BadgeShapeWidget(
            size: 96,
            tier: tier,
            group: tier == BadgeTier.simple
                ? simpleGroupFor(badge.category)
                : null,
            isUnlocked: true,
            xpRewardValue: badge.xpReward,
            child: MetallicIcon3D(
              icon: badgeIconFor(badge.icon),
              size: 40,
              isUnlocked: true,
              tier: tier,
              xpRewardValue: badge.xpReward,
              themeColor: color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeCategoryLabel(l10n, badge.category),
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            badge.nameIn(l10n.localeName),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isUnlocked ? l10n.badgeUnlockedLabel : l10n.badgeLockedLabel,
              style: TextStyle(
                color: isUnlocked ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            badge.descriptionIn(l10n.localeName),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    l10n.badgeRewardLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${badge.xpReward} XP',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              if (isUnlocked && unlockDate != null)
                Column(
                  children: [
                    Text(
                      l10n.badgeUnlockedAtLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(unlockDate.toLocal()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
/// "Como ganhar XP", lida de `config/badges.xpSources`.
///
/// Sem a lista publicada a seção some inteira: um título sozinho seria pior do
/// que a ausência, e uma tabela escrita no app repetiria o erro que o catálogo
/// de badges já tinha custado.
class _XpSourcesSection extends StatelessWidget {
  const _XpSourcesSection({required this.sources});

  final List<XpSource> sources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final color = Colors.amber.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bolt, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.xpSourcesTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.nameIn(locale),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (source.descriptionIn(locale).isNotEmpty)
                              Text(
                                source.descriptionIn(locale),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.xpValue(source.xp.toString()),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int unlocked;
  final int total;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$unlocked / $total',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedBadgeCard extends StatelessWidget {
  final BadgeCatalogItem badge;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _AdvancedBadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BadgeShapeWidget(
            size: 72,
            tier: BadgeTier.advanced,
            isUnlocked: isUnlocked,
            xpRewardValue: badge.xpReward,
            child: MetallicIcon3D(
              icon: badgeIconFor(badge.icon),
              size: 30,
              isUnlocked: isUnlocked,
              tier: BadgeTier.advanced,
              xpRewardValue: badge.xpReward,
              themeColor: badgeColorFor(badge),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              badge.nameIn(AppLocalizations.of(context)!.localeName),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBadgeChip extends StatelessWidget {
  final BadgeCatalogItem badge;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _SimpleBadgeChip({
    required this.badge,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: badge.nameIn(AppLocalizations.of(context)!.localeName),
        child: BadgeShapeWidget(
          size: 48,
          tier: BadgeTier.simple,
          group: simpleGroupFor(badge.category),
          isUnlocked: isUnlocked,
          xpRewardValue: badge.xpReward,
          child: MetallicIcon3D(
            icon: badgeIconFor(badge.icon),
            size: 20,
            isUnlocked: isUnlocked,
            tier: BadgeTier.simple,
            xpRewardValue: badge.xpReward,
            themeColor: badgeColorFor(badge),
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// 3D Metallic Emblem Icon
// ─────────────────────────────────────────────────────────────────────────────

Color _toGrayscale(Color color) {
  final double luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
  return Color.fromARGB(
    (color.a * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
  );
}

Gradient _makeGrayscale(Gradient gradient) {
  if (gradient is RadialGradient) {
    return RadialGradient(
      center: gradient.center,
      radius: gradient.radius,
      colors: gradient.colors.map(_toGrayscale).toList(),
      stops: gradient.stops,
    );
  } else if (gradient is LinearGradient) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map(_toGrayscale).toList(),
      stops: gradient.stops,
    );
  }
  return gradient;
}

Gradient _getMetallicGradientForColor(Color baseColor) {
  final hsl = HSLColor.fromColor(baseColor);
  final lightColor = hsl.withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0)).toColor();
  final midColor = baseColor;
  final shadowColor = hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      lightColor,
      midColor,
      shadowColor,
    ],
  );
}

class MetallicIcon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isUnlocked;
  final BadgeTier tier;
  final int xpRewardValue;
  final Color themeColor;

  const MetallicIcon3D({
    super.key,
    required this.icon,
    required this.size,
    required this.isUnlocked,
    required this.tier,
    required this.xpRewardValue,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final double plateSize = size * 1.35;

    // Unlocked base colors and gradients
    Gradient activePlateGradient;
    Gradient activeIconGradient;
    Color activePlateBorderColor;

    if (tier == BadgeTier.advanced) {
      // Advanced: Platinum/Silver coin inside Gold Shield
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // Specular shine
          Color(0xFFF1F5F9), // Platinum silver
          Color(0xFF94A3B8), // Slate silver
          Color(0xFF475569), // Steel shadow
        ],
        stops: [0.0, 0.25, 0.75, 1.0],
      );
      activePlateBorderColor = const Color(0xFFFFD54F); // Gold border to frame the coin
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    } else if (xpRewardValue >= 75) {
      // Simple Silver Badge: Gold coin inside Silver Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFDF0), // gold highlight
          Color(0xFFFBBF24), // gold body
          Color(0xFFCA8A04), // medium gold
          Color(0xFF713F12), // dark gold shadow
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = const Color(0xFFCBD5E1); // Silver border
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    } else {
      // Simple Bronze Badge: Silver/Steel coin inside Bronze Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // specular white
          Color(0xFFECEFF1), // silver
          Color(0xFF90A4AE), // medium steel
          Color(0xFF37474F), // dark steel shadow
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = const Color(0xFFC2410C); // Bronze/Copper border
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    }

    Gradient plateGradient;
    Gradient iconGradient;
    Color plateBorderColor;

    if (isUnlocked) {
      plateGradient = activePlateGradient;
      iconGradient = activeIconGradient;
      plateBorderColor = activePlateBorderColor;
    } else {
      // Locked: Grayscale version of the coin & high-contrast icon
      plateGradient = _makeGrayscale(activePlateGradient);
      // Use a dark slate gradient to stand out against the light/medium grayscale plate
      iconGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF475569), // Slate 600
          Color(0xFF0F172A), // Slate 900 (very dark charcoal)
        ],
      );
      plateBorderColor = _toGrayscale(activePlateBorderColor);
    }

    return Container(
      width: plateSize,
      height: plateSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: plateGradient,
        border: Border.all(
          color: plateBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUnlocked ? 0.35 : 0.20),
            offset: const Offset(1, 1.5),
            blurRadius: 1.5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isUnlocked ? 0.45 : 0.20),
            offset: const Offset(-0.75, -0.75),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // White highlights under the icon to create a debossed/engraved edge visibility when locked
            if (!isUnlocked)
              Transform.translate(
                offset: const Offset(-0.8, -0.8),
                child: Icon(
                  icon,
                  size: size,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            // Stamped drop shadow for the icon glyph
            Transform.translate(
              offset: const Offset(1.2, 1.2),
              child: Icon(
                icon,
                size: size,
                color: Colors.black.withValues(alpha: isUnlocked ? 0.45 : 0.50),
              ),
            ),
            // Metal icon stamp
            ShaderMask(
              shaderCallback: (bounds) => iconGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Icon(
                icon,
                size: size,
                color: Colors.white,
              ),
            ),
            // Specular glass glare reflection on top of the stamp (always visible)
            Opacity(
              opacity: isUnlocked ? 0.12 : 0.06,
              child: ClipPath(
                clipper: _CrescentClipper(),
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrescentClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(-size.width * 0.15, -size.height * 0.15, size.width * 1.3, size.height * 0.7));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Badge Shapes & Painters
// ─────────────────────────────────────────────────────────────────────────────

class BadgeShapeWidget extends StatelessWidget {
  final double size;
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final Widget child;

  const BadgeShapeWidget({
    super.key,
    required this.size,
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final offsetY = getOffsetY(tier, group, size);

    return CustomPaint(
      size: Size(size, size),
      painter: _BadgeShapePainter(
        tier: tier,
        group: group,
        isUnlocked: isUnlocked,
        xpRewardValue: xpRewardValue,
        theme: Theme.of(context),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: SizedBox(
              width: size * 0.55,
              height: size * 0.55,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeShapePainter extends CustomPainter {
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final ThemeData theme;

  const _BadgeShapePainter({
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = tier == BadgeTier.advanced ? 3.5 : 2.5;
    final margin = strokeWidth / 2;
    final path = getShapePath(size, tier, group, margin);
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 1. Drop Shadow (3D Depth)
    final shadowPath = getShapePath(size, tier, group, margin);
    canvas.save();
    canvas.translate(0, tier == BadgeTier.advanced ? 4.0 : 2.5);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isUnlocked ? 0.35 : 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, tier == BadgeTier.advanced ? 6 : 4);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // 2. Glowaura (Glow Aura for Unlocked)
    if (isUnlocked) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

      if (tier == BadgeTier.advanced) {
        glowPaint.color = const Color(0xFFFFA000).withValues(alpha: 0.5);
      } else if (xpRewardValue >= 75) {
        glowPaint.color = const Color(0xFFB0BEC5).withValues(alpha: 0.3);
      } else {
        glowPaint.color = const Color(0xFFD84315).withValues(alpha: 0.3);
      }
      canvas.drawPath(path, glowPaint);
    }

    // 3. Main Fill Gradient
    final paint = Paint()..style = PaintingStyle.fill;

    // Active/Unlocked Gradients
    Gradient activeGradient;
    if (tier == BadgeTier.advanced) {
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [
          Color(0xFFFFFDE7), // Specular light highlight
          Color(0xFFFFD54F), // Gold body
          Color(0xFFFF8F00), // Deep Amber
          Color(0xFFD97706), // Golden shade shadow
        ],
        stops: [0.0, 0.45, 0.85, 1.0],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // specular white
          Color(0xFFECEFF1), // light silver
          Color(0xFF90A4AE), // medium steel silver
          Color(0xFF475569), // dark shadow grey
        ],
        stops: [0.0, 0.35, 0.8, 1.0],
      );
    } else {
      // Bronze
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFEDD5), // copper flare highlight
          Color(0xFFEA580C), // rich copper body
          Color(0xFF9A3412), // medium bronze
          Color(0xFF451A03), // shadow bronze/brown
        ],
        stops: [0.0, 0.3, 0.8, 1.0],
      );
    }

    if (isUnlocked) {
      paint.shader = activeGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Locked: Grayscale version of the shape gradient
      paint.shader = _makeGrayscale(activeGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }

    canvas.drawPath(path, paint);

    // 4. Background Starburst Rays (Painted for both, but faded when locked)
    canvas.save();
    canvas.clipPath(path);

    final raysPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.22 : 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = tier == BadgeTier.advanced ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    final r = w * 0.8;
    const rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = i * pi / (rayCount / 2);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        raysPaint,
      );
    }
    canvas.restore();

    // 5. Inner Framing Ring (Concentric Track)
    canvas.save();
    canvas.clipPath(path);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Color activeRingColor = tier == BadgeTier.advanced
        ? const Color(0xFFFFE082)
        : Colors.white;
    final double ringAlpha = tier == BadgeTier.advanced ? 0.35 : 0.18;

    ringPaint.color = isUnlocked
        ? activeRingColor.withValues(alpha: ringAlpha)
        : _toGrayscale(activeRingColor).withValues(alpha: ringAlpha * 0.5);

    if (tier == BadgeTier.advanced) {
      canvas.drawCircle(Offset(cx, cy), w * 0.28, ringPaint);
    } else {
      canvas.drawCircle(Offset(cx, cy), w * 0.25, ringPaint);
    }

    canvas.restore();

    // 6. Beveled Outer Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Gradient activeBorderGradient;
    if (tier == BadgeTier.advanced) {
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9C4), // White gold glow reflection
          Color(0xFFFFD54F), // Golden frame
          Color(0xFFFF8F00), // Amber border
          Color(0xFFE65100), // Dark gold shadow
        ],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // pure reflection
          Color(0xFFCFD8DC), // grey steel
          Color(0xFF78909C), // silver edge
          Color(0xFF37474F), // shadow grey
        ],
      );
    } else {
      // Bronze
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE0B2), // bronze flare
          Color(0xFFD84315), // copper border
          Color(0xFF5D4037), // brown edge
          Color(0xFF2D1510), // shadow bronze
        ],
      );
    }

    if (isUnlocked) {
      borderPaint.shader = activeBorderGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Grayscale border
      borderPaint.shader = _makeGrayscale(activeBorderGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawPath(path, borderPaint);

    // 7. Glossy Dome Highlight (Always active to give it a glassy look even when locked!)
    canvas.save();
    canvas.clipPath(path);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.35 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));

    canvas.drawOval(
      Rect.fromLTWH(-w * 0.1, -h * 0.15, w * 1.2, h * 0.55),
      reflectionPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

double getOffsetY(BadgeTier tier, SimpleBadgeGroup? group, double size) {
  if (tier == BadgeTier.advanced) {
    // Shield narrows down at the bottom; offset icon slightly up for optical centering
    return -size * 0.095;
  }
  if (group == SimpleBadgeGroup.savings) {
    // Diamond narrows down at bottom, let's offset it slightly up
    return -size * 0.04;
  }
  if (group == SimpleBadgeGroup.goals) {
    // Hexagon has top/bottom points, let's offset slightly up
    return -size * 0.02;
  }
  // Other shapes (circle, octagon, star) might need a tiny upward offset to counteract the shadow drop
  return -size * 0.015;
}

Path getShapePath(Size size, BadgeTier tier, SimpleBadgeGroup? group, double margin) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  if (tier == BadgeTier.advanced) {
    final left = margin;
    final top = margin;
    final right = w - margin;
    final bottom = h - margin;
    final width = right - left;
    final height = bottom - top;

    // Shield path with margin inset
    path.moveTo(left + width * 0.5, top);
    path.quadraticBezierTo(left + width * 0.8, top + height * 0.05, right, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.95, top + height * 0.6, left + width * 0.5, bottom);
    path.quadraticBezierTo(left + width * 0.05, top + height * 0.6, left, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.2, top + height * 0.05, left + width * 0.5, top);
    path.close();
    return path;
  }

  switch (group) {
    case SimpleBadgeGroup.firstSteps:
      // Circle
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
      break;
    case SimpleBadgeGroup.consistency:
      // Octagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final offset = width * 0.28;

      path.moveTo(left + offset, top);
      path.lineTo(right - offset, top);
      path.lineTo(right, top + offset);
      path.lineTo(right, bottom - offset);
      path.lineTo(right - offset, bottom);
      path.lineTo(left + offset, bottom);
      path.lineTo(left, bottom - offset);
      path.lineTo(left, top + offset);
      path.close();
      break;
    case SimpleBadgeGroup.savings:
      // Diamond
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.5);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.5);
      path.close();
      break;
    case SimpleBadgeGroup.goals:
      // Hexagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.25);
      path.lineTo(right, top + height * 0.75);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.75);
      path.lineTo(left, top + height * 0.25);
      path.close();
      break;
    case SimpleBadgeGroup.team:
      // 8-pointed star
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;
      final cx = left + width / 2;
      final cy = top + height / 2;
      final outerRadius = width / 2;
      final innerRadius = width / 2.8;
      const points = 8;
      const angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = i % 2 == 0 ? outerRadius : innerRadius;
        final currAngle = i * angle - pi / 2;
        final x = cx + r * cos(currAngle);
        final y = cy + r * sin(currAngle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      break;
    default:
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
  }

  return path;
}
