import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/models/hack_model.dart';

extension CoachingFirestoreX on DocumentSnapshot {
  CoachingModel toCoachingModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Coaching data is null');

    return CoachingModel.fromJson({
      ...data,
      'id': id,
      if (data['date'] is Timestamp)
        'date': (data['date'] as Timestamp).toDate().toIso8601String(),
    });
  }
}

extension HackFirestoreX on DocumentSnapshot {
  HackModel toHackModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Hack data is null');

    return HackModel.fromJson({
      ...data,
      'id': id,
    });
  }
}
