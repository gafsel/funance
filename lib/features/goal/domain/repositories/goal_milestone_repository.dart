abstract class IGoalMilestoneRepository {
  Future<int> getLastCelebratedMilestone(String goalId);
  Future<void> saveCelebratedMilestone(String goalId, int milestone);
  Future<void> cleanupMilestones(Set<String> activeGoalIds);
}
