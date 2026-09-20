import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

extension WorkspaceFirestoreX on DocumentSnapshot {
  WorkspaceModel toWorkspaceModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Workspace data is null');

    return WorkspaceModel.fromJson({
      'type': 'personal',
      'members': [],
      ...data,
      'id': id,
      if (data['createdAt'] is Timestamp)
        'createdAt': (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['lastLevelUpAt'] is Timestamp)
        'lastLevelUpAt': (data['lastLevelUpAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
    });
  }
}
