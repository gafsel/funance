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
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastLevelUpAt: json['lastLevelUpAt'] == null
          ? null
          : DateTime.parse(json['lastLevelUpAt'] as String),
      unlockedBadges:
          (json['unlockedBadges'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      weeklyStreaks: (json['weeklyStreaks'] as num?)?.toInt() ?? 0,
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
  'xp': instance.xp,
  'level': instance.level,
  'lastLevelUpAt': instance.lastLevelUpAt?.toIso8601String(),
  'unlockedBadges': instance.unlockedBadges,
  'onboardingCompleted': instance.onboardingCompleted,
  'weeklyStreaks': instance.weeklyStreaks,
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
