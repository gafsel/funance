import 'package:funances/features/goal/data/repositories/goal_feasibility_repository_impl.dart';
import 'package:funances/features/goal/domain/models/goal_feasibility_model.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';

class GoalFeasibilityService {
  final String workspaceId;
  final GoalFeasibilityRepository repository;

  GoalFeasibilityService({required this.workspaceId, required this.repository});

  Future<GoalFeasibilityModel> analyze(GoalFormState state) async {
    return await repository.analyze(workspaceId, state);
  }
}
