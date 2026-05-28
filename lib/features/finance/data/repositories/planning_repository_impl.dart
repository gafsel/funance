import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/planning_model.dart';
import '../../domain/models/planning_month_summary_model.dart';
import '../../domain/repositories/planning_repository.dart';

class PlanningRepositoryImpl implements IPlanningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
  }

  @override
  Future<List<PlanningModel>> getPlannings(String workspaceId, {DateTime? startDate, DateTime? endDate}) async {
    Query query = _getWorkspaceDoc(workspaceId).collection('plannings');

    // Queremos todos os planejamentos que impactam o período informado.
    // Firestore limita range filters a um único campo; então aplicamos um filtro por
    // start_date <= endDate e fazemos o pós-filtro por end_date >= startDate.
    DateTime? periodStart = startDate != null ? DateTime(startDate.year, startDate.month, startDate.day) : null;
    DateTime? periodEnd = endDate != null ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999) : null;

    if (periodEnd != null) {
      query = query.where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd));
    }

    final snapshot = await query.get();
    final items = snapshot.docs.map((doc) => PlanningModel.fromFirestore(doc)).toList();

    if (periodStart != null) {
      return items.where((p) => p.endDate.isAfter(periodStart.subtract(const Duration(milliseconds: 1))) || p.endDate.isAtSameMomentAs(periodStart)).toList();
    }
    return items;
  }

  @override
  Stream<List<PlanningModel>> watchPlannings(String workspaceId, {required DateTime startDate, required DateTime endDate}) {
    final periodStart = DateTime(startDate.year, startDate.month, startDate.day);
    final periodEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    // start_date <= periodEnd, pós-filtra por end_date >= periodStart
    final query = _getWorkspaceDoc(workspaceId)
        .collection('plannings')
        .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd));

    return query.snapshots().map((snapshot) {
      final all = snapshot.docs.map((doc) => PlanningModel.fromFirestore(doc)).toList();
      return all.where((p) => p.endDate.isAfter(periodStart.subtract(const Duration(milliseconds: 1))) || p.endDate.isAtSameMomentAs(periodStart)).toList();
    });
  }

  @override
  Future<void> addPlanning(String workspaceId, PlanningModel planning) async {
    final data = planning.toJson();
    data.remove('id');
    data['start_date'] = Timestamp.fromDate(planning.startDate);
    data['end_date'] = Timestamp.fromDate(planning.endDate);
    await _getWorkspaceDoc(workspaceId).collection('plannings').add(data);
  }

  @override
  Future<void> updatePlanning(String workspaceId, PlanningModel planning) async {
    final data = planning.toJson();
    data.remove('id');
    data['start_date'] = Timestamp.fromDate(planning.startDate);
    data['end_date'] = Timestamp.fromDate(planning.endDate);
    await _getWorkspaceDoc(workspaceId).collection('plannings').doc(planning.id).update(data);
  }

  @override
  Future<void> deletePlanning(String workspaceId, String planningId) async {
    await _getWorkspaceDoc(workspaceId).collection('plannings').doc(planningId).delete();
  }

  @override
  Future<PlanningMonthSummaryModel?> getPlanningSummary(
    String workspaceId,
    String planningId,
    int year,
    int month,
  ) async {
    final docId = '$year-${month.toString().padLeft(2, '0')}';
    final doc = await _getWorkspaceDoc(workspaceId)
        .collection('plannings')
        .doc(planningId)
        .collection('summaries')
        .doc(docId)
        .get();

    if (!doc.exists) return null;
    return PlanningMonthSummaryModel.fromFirestore(doc);
  }

  @override
  Stream<PlanningMonthSummaryModel?> watchPlanningSummary(
    String workspaceId,
    String planningId,
    int year,
    int month,
  ) {
    final docId = '$year-${month.toString().padLeft(2, '0')}';
    return _getWorkspaceDoc(workspaceId)
        .collection('plannings')
        .doc(planningId)
        .collection('summaries')
        .doc(docId)
        .snapshots()
        .map((doc) => doc.exists ? PlanningMonthSummaryModel.fromFirestore(doc) : null);
  }
}
