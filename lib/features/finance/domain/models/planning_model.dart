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
  final Map<String, dynamic>? metadata;

  PlanningModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.type,
    this.installmentsCount,
    required this.startDate,
    required this.endDate,
    this.metadata,
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

  PlanningModel copyWith({
    String? id,
    CategoryModel? category,
    double? amount,
    PlanningType? type,
    int? installmentsCount,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) {
    return PlanningModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
    );
  }
}
