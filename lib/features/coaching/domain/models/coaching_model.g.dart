// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coaching_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoachingModel _$CoachingModelFromJson(Map<String, dynamic> json) =>
    _CoachingModel(
      id: json['id'] as String,
      message: json['message'] as String,
      date: DateTime.parse(json['date'] as String),
      type: $enumDecode(_$CoachingTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$CoachingModelToJson(_CoachingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'date': instance.date.toIso8601String(),
      'type': _$CoachingTypeEnumMap[instance.type]!,
    };

const _$CoachingTypeEnumMap = {
  CoachingType.insight: 'insight',
  CoachingType.warning: 'warning',
  CoachingType.tip: 'tip',
};
