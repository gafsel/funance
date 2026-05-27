// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_month_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanningMonthSummaryModel _$PlanningMonthSummaryModelFromJson(
  Map<String, dynamic> json,
) => PlanningMonthSummaryModel(
  id: json['id'] as String,
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  plannedAmount: (json['plannedAmount'] as num).toDouble(),
  actualAmount: (json['actualAmount'] as num).toDouble(),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
);

Map<String, dynamic> _$PlanningMonthSummaryModelToJson(
  PlanningMonthSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'plannedAmount': instance.plannedAmount,
  'actualAmount': instance.actualAmount,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
};
