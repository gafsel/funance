// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanningModel _$PlanningModelFromJson(Map<String, dynamic> json) =>
    PlanningModel(
      id: json['id'] as String,
      category: CategoryModel.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$PlanningTypeEnumMap, json['type']),
      installmentsCount: (json['installments_count'] as num?)?.toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlanningModelToJson(PlanningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category.toJson(),
      'amount': instance.amount,
      'type': _$PlanningTypeEnumMap[instance.type]!,
      'installments_count': instance.installmentsCount,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$PlanningTypeEnumMap = {
  PlanningType.unique: 'unique',
  PlanningType.recurrent: 'recurrent',
  PlanningType.parcelado: 'parcelado',
};
