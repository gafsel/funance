import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

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
    
    // Level progress calculations
    final xpAcumuladoPrev = (300 * (pow(2, level - 1) - 1)).toInt();
    final xpAtual = xp - xpAcumuladoPrev;
    final xpDegrau = (300 * pow(2, level - 1)).toInt();
    final progressFraction = xpDegrau > 0 ? (xpAtual / xpDegrau).clamp(0.0, 1.0) : 0.0;
    
    final unlockedCount = workspace.unlockedBadges.length;

    return Semantics(
      label: l10n.levelIndicatorSemantics(level, unlockedCount),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.military_tech,
                        size: 11,
                        color: Colors.white,
                      ),
                      if (unlockedCount > 0) ...[
                        const SizedBox(width: 1),
                        Text(
                          '$unlockedCount',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
