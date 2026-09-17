import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_detail_sheet.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_shape.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/metallic_icon_3d.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Grade de emblemas de uma seção.
///
/// O tier decide a grade inteira: avançado é cartão com nome embaixo (130px),
/// simples é só a peça com tooltip (68px). É um sliver porque a vitrine é um
/// `CustomScrollView` — uma grade por seção, todas no mesmo scroll.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({
    super.key,
    required this.badges,
    required this.unlockedBadges,
  });

  final List<BadgeCatalogItem> badges;
  final Map<String, String> unlockedBadges;

  @override
  Widget build(BuildContext context) {
    final isAdvanced =
        badges.isNotEmpty && badges.first.category == BadgeCategory.advanced;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isAdvanced ? 130 : 68,
          mainAxisSpacing: isAdvanced ? AppSpacing.md : AppSpacing.sm,
          crossAxisSpacing: isAdvanced ? AppSpacing.md : AppSpacing.sm,
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
    final theme = Theme.of(context);
    final palette = context.palette;

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
          AppSpacing.gapXs,
          Expanded(
            child: Text(
              badge.nameIn(AppLocalizations.of(context)!.localeName),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUnlocked ? palette.ink : palette.ink3,
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
