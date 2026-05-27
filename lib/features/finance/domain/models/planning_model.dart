import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'planning_model.g.dart';

enum PlanningType {
  @JsonValue('unique')
  unique,
  @JsonValue('recurrent')
  recurrent,
  @JsonValue('parcelado')
  parcelado,
}

@JsonSerializable(explicitToJson: true)
class PlanningModel {
  final String id;
  final CategoryModel category;
  final double amount;
  final PlanningType type;
  @JsonKey(name: 'installments_count')
  final int? installmentsCount;
  @JsonKey(name: 'startDate')
  final DateTime startDate;
  @JsonKey(name: 'endDate')
  final DateTime endDate;

  PlanningModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.type,
    this.installmentsCount,
    required this.startDate,
    required this.endDate,
  });

  factory PlanningModel.fromJson(Map<String, dynamic> json) => _$PlanningModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlanningModelToJson(this);

  factory PlanningModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Planning data is null');

    return PlanningModel.fromJson({
      ...data,
      'id': doc.id,
      'startDate': (data['start_date'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'endDate': (data['end_date'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
