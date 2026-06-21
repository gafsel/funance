import 'package:funances/features/goal/domain/repositories/goal_milestone_repository.dart';

class GoalMilestoneService {
  final IGoalMilestoneRepository repository;

  GoalMilestoneService({required this.repository});

  Future<int> getLastCelebratedMilestone(String goalId) async {
    return await repository.getLastCelebratedMilestone(goalId);
  }

  Future<void> saveCelebratedMilestone(String goalId, int milestone) async {
    await repository.saveCelebratedMilestone(goalId, milestone);
  }

  Future<void> cleanupMilestones(Set<String> activeGoalIds) async {
    await repository.cleanupMilestones(activeGoalIds);
  }
}
