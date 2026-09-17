import 'package:funances/core/firestore/offline_write.dart';

import '../models/goal_model.dart';

abstract class IGoalRepository {
  Future<List<GoalModel>> getGoals(String workspaceId);
  Stream<List<GoalModel>> watchGoals(String workspaceId);
  Future<Written<GoalModel>> addGoal(String workspaceId, GoalModel goal);
  Future<WriteOutcome> updateGoal(String workspaceId, GoalModel goal);
  Future<void> deleteGoal(String workspaceId, String goalId);
}
