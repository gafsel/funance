import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'planning_month_summary_model.g.dart';

@JsonSerializable()
class PlanningMonthSummaryModel {
  final String id;
  final int year;
  final int month;
  @JsonKey(name: 'plannedAmount')
  final double plannedAmount;
  @JsonKey(name: 'actualAmount')
  final double actualAmount;
  @JsonKey(name: 'lastUpdate')
  final DateTime lastUpdate;

  PlanningMonthSummaryModel({
    required this.id,
    required this.year,
    required this.month,
    required this.plannedAmount,
    required this.actualAmount,
    required this.lastUpdate,
  });

  factory PlanningMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$PlanningMonthSummaryModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlanningMonthSummaryModelToJson(this);

  factory PlanningMonthSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Summary data is null');

    return PlanningMonthSummaryModel.fromJson({
      ...data,
      'id': doc.id,
      'plannedAmount': (data['planned_amount'] ?? data['plannedAmount'] ?? 0.0).toDouble(),
      'actualAmount': (data['actual_amount'] ?? data['actualAmount'] ?? 0.0).toDouble(),
      'lastUpdate': (data['last_update'] as Timestamp? ?? data['lastUpdate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  double get progress => plannedAmount > 0 ? actualAmount / plannedAmount : 0.0;
}
