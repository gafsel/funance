// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanningSuggestions _$PlanningSuggestionsFromJson(Map<String, dynamic> json) =>
    _PlanningSuggestions(
      plannings:
          (json['plannings'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CategoryPlanningModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      goals:
          (json['goals'] as List<dynamic>?)
              ?.map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlanningSuggestionsToJson(
  _PlanningSuggestions instance,
) => <String, dynamic>{
  'plannings': instance.plannings,
  'goals': instance.goals,
};
