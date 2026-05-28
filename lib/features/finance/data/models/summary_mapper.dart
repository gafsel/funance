import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/category_month_summary_model.dart';
import 'package:funances/features/finance/domain/models/planning_month_summary_model.dart';

extension CategoryMonthSummaryFirestoreX on DocumentSnapshot {
  CategoryMonthSummaryModel toCategoryMonthSummaryModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('CategoryMonthSummary data is null');

    return CategoryMonthSummaryModel.fromJson({
      ...data,
      'id': id,
      if (data['last_update'] is Timestamp)
        'last_update': (data['last_update'] as Timestamp).toDate().toIso8601String(),
      if (data['lastUpdate'] is Timestamp)
        'last_update': (data['lastUpdate'] as Timestamp).toDate().toIso8601String(),
    });
  }
}

extension PlanningMonthSummaryFirestoreX on DocumentSnapshot {
  PlanningMonthSummaryModel toPlanningMonthSummaryModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('PlanningMonthSummary data is null');

    return PlanningMonthSummaryModel.fromJson({
      ...data,
      'id': id,
      if (data['last_update'] is Timestamp)
        'last_update': (data['last_update'] as Timestamp).toDate().toIso8601String(),
      if (data['lastUpdate'] is Timestamp)
        'last_update': (data['lastUpdate'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
