// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InviteModel _$InviteModelFromJson(Map<String, dynamic> json) => _InviteModel(
  id: json['id'] as String,
  workspace: WorkspaceModel.fromJson(json['workspace'] as Map<String, dynamic>),
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  receiverEmail: json['receiverEmail'] as String,
  status: $enumDecode(_$InviteStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InviteModelToJson(_InviteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workspace': instance.workspace.toJson(),
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'receiverEmail': instance.receiverEmail,
      'status': _$InviteStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$InviteStatusEnumMap = {
  InviteStatus.pending: 'pending',
  InviteStatus.accepted: 'accepted',
  InviteStatus.declined: 'declined',
};
