import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_month_summary_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CategoryMonthSummaryModel {
  final String id;
  final int year;
  final int month;
  @JsonKey(name: 'category')
  final CategoryModel category;
  @JsonKey(name: 'totalDebit')
  final double totalDebit;
  @JsonKey(name: 'totalCredit')
  final double totalCredit;
  @JsonKey(name: 'plannedAmount')
  final double plannedAmount;
  @JsonKey(name: 'actualAmount')
  final double actualAmount;
  final int count;
  @JsonKey(name: 'lastUpdate')
  final DateTime lastUpdate;

  CategoryMonthSummaryModel({
    required this.id,
    required this.year,
    required this.month,
    required this.category,
    required this.totalDebit,
    required this.totalCredit,
    required this.plannedAmount,
    required this.actualAmount,
    required this.count,
    required this.lastUpdate,
  });

  factory CategoryMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$CategoryMonthSummaryModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryMonthSummaryModelToJson(this);

  factory CategoryMonthSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('CategoryMonthSummary data is null');

    return CategoryMonthSummaryModel.fromJson({
      ...data,
      'id': doc.id,
      'totalDebit': (data['total_debit'] ?? data['totalDebit'] ?? 0.0).toDouble(),
      'totalCredit': (data['total_credit'] ?? data['totalCredit'] ?? 0.0).toDouble(),
      'plannedAmount': (data['planned_amount'] ?? data['plannedAmount'] ?? 0.0).toDouble(),
      'actualAmount': (data['actual_amount'] ?? data['actualAmount'] ?? 0.0).toDouble(),
      'lastUpdate': (data['last_update'] as Timestamp? ?? data['lastUpdate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
