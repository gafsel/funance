import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_shape.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/metallic_icon_3d.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Detalhe de um emblema, em folha modal.
///
/// Mostra o mesmo emblema da vitrine em tamanho grande e SEMPRE desbloqueado:
/// quem abre um bloqueado está olhando o que ainda vai ganhar, e um disco
/// cinza não conta isso. O estado real aparece na tarja "bloqueado".
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
    builder: (context) {
      final theme = Theme.of(context);
      final palette = context.palette;

      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            AppSpacing.gapMd,
            // A cor da categoria é DADO (vem do catálogo), então continua
            // entrando como cor explícita da pílula.
            StatusPill(
              label: badgeCategoryLabel(l10n, badge.category),
              color: color,
              dense: true,
            ),
            AppSpacing.gapXs,
            Text(
              badge.nameIn(l10n.localeName),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            AppSpacing.gapXxs,
            StatusPill(
              label: isUnlocked ? l10n.badgeUnlockedLabel : l10n.badgeLockedLabel,
              tone: isUnlocked ? StatusTone.ok : StatusTone.warning,
            ),
            AppSpacing.gapMd,
            Text(
              badge.descriptionIn(l10n.localeName),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
            ),
            AppSpacing.gapLg,
            const Divider(),
            AppSpacing.gapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      l10n.badgeRewardLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      '+${badge.xpReward} XP',
                      style: theme.textTheme.titleLarge?.copyWith(color: color),
                    ),
                  ],
                ),
                if (isUnlocked && unlockDate != null)
                  Column(
                    children: [
                      Text(
                        l10n.badgeUnlockedAtLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.ink2,
                        ),
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(unlockDate.toLocal()),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
