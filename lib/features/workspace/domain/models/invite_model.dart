import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_model.g.dart';

enum InviteStatus {
  pending,
  accepted,
  declined,
}

@JsonSerializable(explicitToJson: true)
class InviteModel {
  final String id;
  @JsonKey(name: 'workspace')
  final WorkspaceModel workspace;
  final String senderId;
  final String senderName;
  final String receiverEmail;
  final InviteStatus status;
  final DateTime createdAt;

  InviteModel({
    required this.id,
    required this.workspace,
    required this.senderId,
    required this.senderName,
    required this.receiverEmail,
    required this.status,
    required this.createdAt,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) => _$InviteModelFromJson(json);
  Map<String, dynamic> toJson() => _$InviteModelToJson(this);

  factory InviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Invite data is null');

    return InviteModel.fromJson({
      'status': 'pending',
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
