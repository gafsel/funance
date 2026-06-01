// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkspaceModel _$WorkspaceModelFromJson(Map<String, dynamic> json) =>
    _WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$WorkspaceTypeEnumMap, json['type']),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastOnboardingStep: $enumDecodeNullable(
        _$OnboardingStepsEnumMap,
        json['lastOnboardingStep'],
      ),
    );

Map<String, dynamic> _$WorkspaceModelToJson(
  _WorkspaceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$WorkspaceTypeEnumMap[instance.type]!,
  'members': instance.members,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastOnboardingStep': _$OnboardingStepsEnumMap[instance.lastOnboardingStep],
};

const _$WorkspaceTypeEnumMap = {
  WorkspaceType.personal: 'personal',
  WorkspaceType.business: 'business',
};

const _$OnboardingStepsEnumMap = {
  OnboardingSteps.type: 'type',
  OnboardingSteps.name: 'name',
  OnboardingSteps.accounts: 'accounts',
  OnboardingSteps.planning: 'planning',
  OnboardingSteps.invites: 'invites',
  OnboardingSteps.success: 'success',
  OnboardingSteps.done: 'done',
};
