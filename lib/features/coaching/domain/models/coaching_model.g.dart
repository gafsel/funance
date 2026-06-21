// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coaching_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SlideModel _$SlideModelFromJson(Map<String, dynamic> json) => _SlideModel(
  title: json['title'] as String,
  message: json['message'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
  secondaryColor: json['secondaryColor'] as String?,
  icons:
      (json['icons'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  animationType: json['animationType'] as String?,
  actionLabel: json['actionLabel'] as String?,
  actionPath: json['actionPath'] as String?,
);

Map<String, dynamic> _$SlideModelToJson(_SlideModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'icon': instance.icon,
      'color': instance.color,
      'secondaryColor': instance.secondaryColor,
      'icons': instance.icons,
      'animationType': instance.animationType,
      'actionLabel': instance.actionLabel,
      'actionPath': instance.actionPath,
    };

_CoachingModel _$CoachingModelFromJson(Map<String, dynamic> json) =>
    _CoachingModel(
      id: json['id'] as String,
      message: json['message'] as String,
      summary: json['summary'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: $enumDecode(_$CoachingTypeEnumMap, json['type']),
      slides:
          (json['slides'] as List<dynamic>?)
              ?.map((e) => SlideModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CoachingModelToJson(_CoachingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'summary': instance.summary,
      'date': instance.date.toIso8601String(),
      'type': _$CoachingTypeEnumMap[instance.type]!,
      'slides': instance.slides.map((e) => e.toJson()).toList(),
    };

const _$CoachingTypeEnumMap = {
  CoachingType.insight: 'insight',
  CoachingType.warning: 'warning',
  CoachingType.tip: 'tip',
};
