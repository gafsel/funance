import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';

extension CoachingFirestoreX on DocumentSnapshot {
  CoachingModel toCoachingModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Coaching data is null');

    return CoachingModel.fromJson(CoachingMapper.fromMap(data, id: id));
  }
}

class CoachingMapper {
  static Map<String, dynamic> fromMap(Map<dynamic, dynamic> data, {String? id}) {
    final map = Map<String, dynamic>.from(data);

    if (id != null) {
      map['id'] = id;
    }

    if (map['date'] is Timestamp) {
      map['date'] = (map['date'] as Timestamp).toDate().toIso8601String();
    }

    if (map['slides'] != null && map['slides'] is List) {
      map['slides'] = (map['slides'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return map;
  }
}
