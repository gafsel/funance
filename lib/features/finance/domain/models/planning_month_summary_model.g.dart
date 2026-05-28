// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_month_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanningMonthSummaryModel _$PlanningMonthSummaryModelFromJson(
  Map<String, dynamic> json,
) => _PlanningMonthSummaryModel(
  id: json['id'] as String,
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  plannedAmount: (json['planned_amount'] as num).toDouble(),
  actualAmount: (json['actual_amount'] as num).toDouble(),
  lastUpdate: DateTime.parse(json['last_update'] as String),
);

Map<String, dynamic> _$PlanningMonthSummaryModelToJson(
  _PlanningMonthSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'planned_amount': instance.plannedAmount,
  'actual_amount': instance.actualAmount,
  'last_update': instance.lastUpdate.toIso8601String(),
};
