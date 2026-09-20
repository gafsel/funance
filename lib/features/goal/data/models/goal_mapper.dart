import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';

extension GoalFirestoreX on DocumentSnapshot {
  GoalModel toGoalModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Goal data is null');

    return GoalModel.fromJson({
      'type': 'save_money',
      ...data,
      'id': id,
      if (data['startDate'] is Timestamp)
        'startDate': (data['startDate'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['start_date'] is Timestamp)
        'startDate': (data['start_date'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['deadline'] is Timestamp)
        'deadline': (data['deadline'] as Timestamp).toDate().toIso8601String(),
      // Desfecho escrito pelo servidor (ver functions/README.md, "Contrato:
      // meta ativa e desfecho").
      if (data['completedAt'] is Timestamp)
        'completedAt': (data['completedAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
      if (data['failedAt'] is Timestamp)
        'failedAt': (data['failedAt'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
