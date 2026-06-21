import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/features/goal/domain/models/goal_feasibility_model.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';

class GoalFeasibilityRepository {
  final _functions = FirebaseFunctions.instance;

  Future<GoalFeasibilityModel> analyze(
    String workspaceId,
    GoalFormState state,
  ) async {
    final callable = _functions.httpsCallable('analyzeGoalFeasibility');

    final deadlineDays = state.deadline.difference(state.startDate).inDays;
    final months = (deadlineDays / 30).ceil().clamp(1, 999);
    final monthlyRequired = months > 0
        ? (state.targetAmount - state.currentAmount) / months
        : 0.0;

    final result = await callable.call({
      'workspaceId': workspaceId,
      'goalPayload': {
        'name': state.name,
        'targetAmount': state.targetAmount,
        'currentAmount': state.currentAmount,
        'deadlineDays': deadlineDays,
        'monthlyRequired': monthlyRequired,
        'type': state.type.name,
      },
    });

    final data = Map<String, dynamic>.from(result.data as Map);

    return GoalFeasibilityModel(
      status: GoalFeasibilityStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'challenging'),
        orElse: () => GoalFeasibilityStatus.challenging,
      ),
      reason: data['reason'] as String? ?? '',
      suggestion: data['suggestion'] as String? ?? '',
    );
  }
}
