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
  totalDebit: (json['total_debit'] as num).toDouble(),
  totalCredit: (json['total_credit'] as num).toDouble(),
  plannedAmount: (json['planned_amount'] as num).toDouble(),
  actualAmount: (json['actual_amount'] as num).toDouble(),
  count: (json['count'] as num).toInt(),
  lastUpdate: DateTime.parse(json['last_update'] as String),
);

Map<String, dynamic> _$CategoryMonthSummaryModelToJson(
  _CategoryMonthSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'category': instance.category,
  'total_debit': instance.totalDebit,
  'total_credit': instance.totalCredit,
  'planned_amount': instance.plannedAmount,
  'actual_amount': instance.actualAmount,
  'count': instance.count,
  'last_update': instance.lastUpdate.toIso8601String(),
};
