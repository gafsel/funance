import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';

extension PeriodSummaryMapper on DocumentSnapshot {
  PeriodSummaryModel toPeriodSummaryModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('PeriodSummaryModel data is null');

    return PeriodSummaryModel.fromJson({
      ...data,
      'id': id,
      if (data['lastUpdate'] is Timestamp)
        'lastUpdate': (data['lastUpdate'] as Timestamp)
            .toDate()
            .toIso8601String(),
    });
  }
}
