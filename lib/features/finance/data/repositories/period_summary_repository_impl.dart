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
  Stream<PeriodSummaryModel?> watchMonth(
    String workspaceId,
    int year,
    int month,
  ) {
    final id = "$year-${month.toString().padLeft(2, '0')}";
    return collection(workspaceId).doc(id).snapshots().map(
          (doc) => doc.exists ? doc.toPeriodSummaryModel() : null,
        );
  }

  @override
  Stream<PeriodSummaryModel?> watchYear(String workspaceId, int year) {
    final id = "$year";
    return collection(workspaceId).doc(id).snapshots().map(
          (doc) => doc.exists ? doc.toPeriodSummaryModel() : null,
        );
  }

  @override
  Stream<PeriodSummaryModel?> watchWeek(
    String workspaceId,
    int year,
    int week,
  ) {
    final id = "$year-W${week.toString().padLeft(2, '0')}";
    return collection(workspaceId).doc(id).snapshots().map(
          (doc) => doc.exists ? doc.toPeriodSummaryModel() : null,
        );
  }
}
