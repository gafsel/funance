import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/data/models/period_summary_mapper.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';

class PeriodSummaryRepositoryImpl implements IPeriodSummaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference collection(String workspaceId) {
    return _firestore.collection("workspaces/$workspaceId/period_summaries");
  }

  @override
  Stream<List<PeriodSummaryModel>> watchMonth(
    String workspaceId,
    int year,
    int month,
  ) {
    return collection(workspaceId)
        .where("year", isEqualTo: year)
        .where("month", isEqualTo: month)
        .orderBy("category.name")
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => doc.toPeriodSummaryModel()).toList(),
        );
  }

  @override
  Stream<List<PeriodSummaryModel>> watchYear(String workspaceId, int year) {
    return collection(workspaceId)
        .where("year", isEqualTo: year)
        .orderBy("category.name")
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => doc.toPeriodSummaryModel()).toList(),
        );
  }

  @override
  Stream<List<PeriodSummaryModel>> watchWeek(
      String workspaceId, int year, int week) {
    return collection(workspaceId)
        .where("year", isEqualTo: year)
        .where("week", isEqualTo: week)
        .orderBy("category.name")
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => doc.toPeriodSummaryModel()).toList(),
        );
  }
}
