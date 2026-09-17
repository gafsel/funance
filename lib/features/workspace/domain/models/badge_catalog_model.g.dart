// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_catalog_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BadgeCatalogItem _$BadgeCatalogItemFromJson(Map<String, dynamic> json) =>
    _BadgeCatalogItem(
      id: json['id'] as String,
      name: json['name'] == null
          ? const <String, String>{}
          : localizedText(json['name']),
      icon: json['icon'] as String? ?? '',
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      category:
          $enumDecodeNullable(
            _$BadgeCategoryEnumMap,
            json['category'],
            unknownValue: BadgeCategory.unknown,
          ) ??
          BadgeCategory.unknown,
      description: json['description'] == null
          ? const <String, String>{}
          : localizedText(json['description']),
    );

Map<String, dynamic> _$BadgeCatalogItemToJson(_BadgeCatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'xpReward': instance.xpReward,
      'category': _$BadgeCategoryEnumMap[instance.category]!,
      'description': instance.description,
    };

const _$BadgeCategoryEnumMap = {
  BadgeCategory.advanced: 'advanced',
  BadgeCategory.firstSteps: 'first_steps',
  BadgeCategory.consistency: 'consistency',
  BadgeCategory.savings: 'savings',
  BadgeCategory.goals: 'goals',
  BadgeCategory.team: 'team',
  BadgeCategory.unknown: 'unknown',
};

_XpSource _$XpSourceFromJson(Map<String, dynamic> json) => _XpSource(
  id: json['id'] as String,
  name: json['name'] == null
      ? const <String, String>{}
      : localizedText(json['name']),
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  description: json['description'] == null
      ? const <String, String>{}
      : localizedText(json['description']),
);

Map<String, dynamic> _$XpSourceToJson(_XpSource instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'xp': instance.xp,
  'description': instance.description,
};

_BadgeCatalog _$BadgeCatalogFromJson(Map<String, dynamic> json) =>
    _BadgeCatalog(
      version: json['version'] as String? ?? '',
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeCatalogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BadgeCatalogItem>[],
      levelThresholds:
          (json['levelThresholds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      xpSources:
          (json['xpSources'] as List<dynamic>?)
              ?.map((e) => XpSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <XpSource>[],
    );

Map<String, dynamic> _$BadgeCatalogToJson(_BadgeCatalog instance) =>
    <String, dynamic>{
      'version': instance.version,
      'badges': instance.badges,
      'levelThresholds': instance.levelThresholds,
      'xpSources': instance.xpSources,
    };
