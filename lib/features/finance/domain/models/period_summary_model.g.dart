// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodSummaryCategoryModel _$PeriodSummaryCategoryModelFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryCategoryModel(
  generalPlannedAmount: (json['generalPlannedAmount'] as num?)?.toDouble() ?? 0,
  specificPlannedAmount:
      (json['specificPlannedAmount'] as num?)?.toDouble() ?? 0,
  actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$PeriodSummaryCategoryModelToJson(
  _PeriodSummaryCategoryModel instance,
) => <String, dynamic>{
  'generalPlannedAmount': instance.generalPlannedAmount,
  'specificPlannedAmount': instance.specificPlannedAmount,
  'actualAmount': instance.actualAmount,
};

_PeriodSummaryModelYear _$PeriodSummaryModelYearFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryModelYear(
  year: (json['year'] as num).toInt(),
  categories: (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      PeriodSummaryCategoryModel.fromJson(e as Map<String, dynamic>),
    ),
  ),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PeriodSummaryModelYearToJson(
  _PeriodSummaryModelYear instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'categories': instance.categories,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'runtimeType': instance.$type,
};

_PeriodSummaryModelMonth _$PeriodSummaryModelMonthFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryModelMonth(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  categories: (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      PeriodSummaryCategoryModel.fromJson(e as Map<String, dynamic>),
    ),
  ),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PeriodSummaryModelMonthToJson(
  _PeriodSummaryModelMonth instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'categories': instance.categories,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'runtimeType': instance.$type,
};

_PeriodSummaryModelWeek _$PeriodSummaryModelWeekFromJson(
  Map<String, dynamic> json,
) => _PeriodSummaryModelWeek(
  year: (json['year'] as num).toInt(),
  week: (json['week'] as num).toInt(),
  categories: (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      PeriodSummaryCategoryModel.fromJson(e as Map<String, dynamic>),
    ),
  ),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$PeriodSummaryModelWeekToJson(
  _PeriodSummaryModelWeek instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'week': instance.week,
  'categories': instance.categories,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'runtimeType': instance.$type,
};
