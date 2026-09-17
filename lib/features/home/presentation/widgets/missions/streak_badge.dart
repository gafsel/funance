import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// Streak de semanas perfeitas, inline no título — visível sem ocupar espaço
/// extra, e só quando existe streak.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(
      WorkspaceViewProviders.gamification.select((g) => g.weeklyStreaks),
    );
    if (streak <= 0) return const SizedBox.shrink();

    return Tooltip(
      message: context.l10n.journeyStreakWeeks(streak),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.coralOrange,
            size: 18,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.coralOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
