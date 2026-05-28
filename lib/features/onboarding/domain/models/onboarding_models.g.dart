// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedFinanceData _$ExtractedFinanceDataFromJson(
  Map<String, dynamic> json,
) => ExtractedFinanceData(
  transactions: (json['transactions'] as List<dynamic>)
      .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  planningSuggestions: (json['planningSuggestions'] as List<dynamic>)
      .map((e) => PlanningModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  initialBalance: (json['initialBalance'] as num).toDouble(),
  initialDate: json['initialDate'] == null
      ? null
      : DateTime.parse(json['initialDate'] as String),
);

Map<String, dynamic> _$ExtractedFinanceDataToJson(
  ExtractedFinanceData instance,
) => <String, dynamic>{
  'transactions': instance.transactions.map((e) => e.toJson()).toList(),
  'planningSuggestions': instance.planningSuggestions
      .map((e) => e.toJson())
      .toList(),
  'initialBalance': instance.initialBalance,
  'initialDate': instance.initialDate?.toIso8601String(),
};
