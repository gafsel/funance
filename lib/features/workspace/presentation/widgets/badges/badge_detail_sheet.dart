import 'package:flutter/material.dart';
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
