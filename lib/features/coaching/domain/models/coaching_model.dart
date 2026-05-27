import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coaching_model.g.dart';

enum CoachingType {
  @JsonValue('insight')
  insight,
  @JsonValue('warning')
  warning,
  @JsonValue('tip')
  tip,
}

@JsonSerializable()
class CoachingModel {
  final String id;
  final String message;
  final DateTime date;
  final CoachingType type;

  CoachingModel({
    required this.id,
    required this.message,
    required this.date,
    required this.type,
  });

  factory CoachingModel.fromJson(Map<String, dynamic> json) => _$CoachingModelFromJson(json);
  Map<String, dynamic> toJson() => _$CoachingModelToJson(this);

  factory CoachingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachingModel.fromJson({
      ...data,
      'id': doc.id,
      'date': (data['date'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
