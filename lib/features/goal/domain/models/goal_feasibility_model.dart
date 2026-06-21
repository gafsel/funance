import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_feasibility_model.freezed.dart';
part 'goal_feasibility_model.g.dart';

enum GoalFeasibilityStatus { feasible, challenging, unrealistic }

@freezed
sealed class GoalFeasibilityModel with _$GoalFeasibilityModel {
  const factory GoalFeasibilityModel({
    required GoalFeasibilityStatus status,
    required String reason,
    required String suggestion,
  }) = _GoalFeasibilityModel;

  factory GoalFeasibilityModel.fromJson(Map<String, dynamic> json) =>
      _$GoalFeasibilityModelFromJson(json);
}
