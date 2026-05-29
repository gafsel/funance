// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_month_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryMonthSummaryModel _$CategoryMonthSummaryModelFromJson(
  Map<String, dynamic> json,
) => _CategoryMonthSummaryModel(
  id: json['id'] as String,
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  totalDebit: (json['totalDebit'] as num).toDouble(),
  totalCredit: (json['totalCredit'] as num).toDouble(),
  plannedAmount: (json['plannedAmount'] as num).toDouble(),
  actualAmount: (json['actualAmount'] as num).toDouble(),
  count: (json['count'] as num).toInt(),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
);

Map<String, dynamic> _$CategoryMonthSummaryModelToJson(
  _CategoryMonthSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'category': instance.category,
  'totalDebit': instance.totalDebit,
  'totalCredit': instance.totalCredit,
  'plannedAmount': instance.plannedAmount,
  'actualAmount': instance.actualAmount,
  'count': instance.count,
  'lastUpdate': instance.lastUpdate.toIso8601String(),
};
