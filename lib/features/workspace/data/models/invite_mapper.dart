import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';

extension InviteFirestoreX on DocumentSnapshot {
  InviteModel toInviteModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Invite data is null');

    return InviteModel.fromJson({
      'status': 'pending',
      ...data,
      'id': id,
      if (data['createdAt'] is Timestamp)
        'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      // Se workspace for um DocumentReference ou Map, precisaremos tratar
      // Mas assumindo que WorkspaceModel.fromJson cuida se for um map
    });
  }
}
