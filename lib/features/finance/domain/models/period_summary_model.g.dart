// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodSummaryModelYear _$PeriodSummaryModelYearFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryModelYear(
  year: (json['year'] as num).toInt(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  generalPlannedAmount: (json['generalPlannedAmount'] as num?)?.toDouble() ?? 0,
  specificPlannedAmount: (json['specificPlannedAmount'] as num).toDouble(),
  actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0,
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PeriodSummaryModelYearToJson(
  _PeriodSummaryModelYear instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'category': instance.category,
  'generalPlannedAmount': instance.generalPlannedAmount,
  'specificPlannedAmount': instance.specificPlannedAmount,
  'actualAmount': instance.actualAmount,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'runtimeType': instance.$type,
};

_PeriodSummaryModelMonth _$PeriodSummaryModelMonthFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryModelMonth(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  generalPlannedAmount: (json['generalPlannedAmount'] as num?)?.toDouble() ?? 0,
  specificPlannedAmount: (json['specificPlannedAmount'] as num).toDouble(),
  actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0,
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PeriodSummaryModelMonthToJson(
  _PeriodSummaryModelMonth instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'category': instance.category,
  'generalPlannedAmount': instance.generalPlannedAmount,
  'specificPlannedAmount': instance.specificPlannedAmount,
  'actualAmount': instance.actualAmount,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'runtimeType': instance.$type,
};
