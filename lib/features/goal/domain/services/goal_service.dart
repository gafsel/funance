import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';

class GoalService {
  final String workspaceId;
  final IGoalRepository repository;

  GoalService({required this.workspaceId, required this.repository});

  Future<GoalModel> addGoal(GoalModel goal) async {
    return await repository.addGoal(workspaceId, goal);
  }

  Stream<List<GoalModel>> watchGoals() {
    return repository.watchGoals(workspaceId);
  }

  Future<void> updateGoal(GoalModel goal) async {
    await repository.updateGoal(workspaceId, goal);
  }

  Future<void> deleteGoal(String goalId) async {
    await repository.deleteGoal(workspaceId, goalId);
  }
}
