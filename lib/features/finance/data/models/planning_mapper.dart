import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';

extension PlanningFirestoreX on DocumentSnapshot {
  PlanningModel toPlanningModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Planning data is null');

    return PlanningModel.fromJson({
      ...data,
      if (data['metadata'] is Map) ...data['metadata'] as Map<String, dynamic>,
      'id': id,
      if (data['start_date'] is Timestamp)
        'startDate': (data['start_date'] as Timestamp).toDate().toIso8601String(),
      if (data['end_date'] is Timestamp)
        'endDate': (data['end_date'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
