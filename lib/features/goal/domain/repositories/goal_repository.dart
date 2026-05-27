import '../models/goal_model.dart';

abstract class IGoalRepository {
  Future<List<GoalModel>> getGoals(String workspaceId);
  Future<void> addGoal(String workspaceId, GoalModel goal);
  Future<void> updateGoal(String workspaceId, GoalModel goal);
  Future<void> deleteGoal(String workspaceId, String goalId);
}
