// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_feasibility_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoalFeasibilityModel _$GoalFeasibilityModelFromJson(
  Map<String, dynamic> json,
) => _GoalFeasibilityModel(
  status: $enumDecode(_$GoalFeasibilityStatusEnumMap, json['status']),
  reason: json['reason'] as String,
  suggestion: json['suggestion'] as String,
);

Map<String, dynamic> _$GoalFeasibilityModelToJson(
  _GoalFeasibilityModel instance,
) => <String, dynamic>{
  'status': _$GoalFeasibilityStatusEnumMap[instance.status]!,
  'reason': instance.reason,
  'suggestion': instance.suggestion,
};

const _$GoalFeasibilityStatusEnumMap = {
  GoalFeasibilityStatus.feasible: 'feasible',
  GoalFeasibilityStatus.challenging: 'challenging',
  GoalFeasibilityStatus.unrealistic: 'unrealistic',
};
