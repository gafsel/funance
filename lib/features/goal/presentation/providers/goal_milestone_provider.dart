import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';

class GoalMilestoneNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<int?> checkMilestoneAndCelebrate({
    required GoalModel goal,
    required double progressPercent,
    required List<GoalModel> allGoals,
  }) async {
    final service = ref.read(GoalDomainProvider.milestoneService);

    // Clean up lazy
    final activeIds = allGoals.map((g) => g.id).toSet();
    await service.cleanupMilestones(activeIds);

    // Check new milestone
    final lastCelebrated = await service.getLastCelebratedMilestone(goal.id);
    final currentPct = (progressPercent * 100).floor();

    const milestones = [25, 50, 75, 100];
    int? newMilestone;
    for (final m in milestones) {
      if (currentPct >= m && m > lastCelebrated) {
        newMilestone = m;
      }
    }

    if (newMilestone != null) {
      await service.saveCelebratedMilestone(goal.id, newMilestone);
      return newMilestone;
    }
    return null;
  }
}
