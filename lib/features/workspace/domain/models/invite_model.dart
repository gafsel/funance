import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_model.freezed.dart';
part 'invite_model.g.dart';

enum InviteStatus {
  pending,
  accepted,
  declined,
}

@freezed
sealed class InviteModel with _$InviteModel {
  const InviteModel._();

  @JsonSerializable(explicitToJson: true)
  const factory InviteModel({
    required String id,
    @JsonKey(name: 'workspace') required WorkspaceModel workspace,
    required String senderId,
    required String senderName,
    required String receiverEmail,
    required InviteStatus status,
    required DateTime createdAt,
  }) = _InviteModel;

  factory InviteModel.fromJson(Map<String, dynamic> json) => _$InviteModelFromJson(json);

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
