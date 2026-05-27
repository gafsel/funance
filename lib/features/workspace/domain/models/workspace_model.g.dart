// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceModel _$WorkspaceModelFromJson(Map<String, dynamic> json) =>
    WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$WorkspaceTypeEnumMap, json['type']),
      members: (json['members'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WorkspaceModelToJson(WorkspaceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$WorkspaceTypeEnumMap[instance.type]!,
      'members': instance.members,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$WorkspaceTypeEnumMap = {
  WorkspaceType.personal: 'personal',
  WorkspaceType.business: 'business',
};
