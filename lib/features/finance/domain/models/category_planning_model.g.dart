// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_planning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryPlanningModel _$CategoryPlanningModelFromJson(
  Map<String, dynamic> json,
) => _CategoryPlanningModel(
  id: json['id'] as String,
  category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  amount: (json['amount'] as num).toDouble(),
  startMonth: json['startMonth'] as String,
  endMonth: json['endMonth'] as String,
);

Map<String, dynamic> _$CategoryPlanningModelToJson(
  _CategoryPlanningModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'category': instance.category.toJson(),
  'amount': instance.amount,
  'startMonth': instance.startMonth,
  'endMonth': instance.endMonth,
};
