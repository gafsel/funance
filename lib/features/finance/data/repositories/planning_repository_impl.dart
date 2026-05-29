import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/finance/data/models/category_planning_mapper.dart';
import '../../domain/models/category_planning_model.dart';
import '../../domain/repositories/planning_repository.dart';

class PlanningRepositoryImpl implements IPlanningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
  }

  @override
  Stream<List<CategoryPlanningModel>> watchPlannings(
    String workspaceId, {
    required int month,
    required int year,
  }) {
    final monthParsed = '$year-${month.toString().padLeft(2, '0')}';

    return _getWorkspaceDoc(workspaceId)
        .collection('category_planning')
        .where('endMonth', isGreaterThanOrEqualTo: monthParsed)
        .where('startMonth', isLessThanOrEqualTo: monthParsed)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.toCategoryPlanningModel())
              .toList(),
        );
  }

  @override
  Future<void> addPlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    try {
      final data = planning.toJson();
      data.remove('id');
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning').add(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updatePlanning(
    String workspaceId,
    CategoryPlanningModel planning,
  ) async {
    try {
      final data = planning.toJson();
      data.remove('id');
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning').doc(planning.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deletePlanning(String workspaceId, String planningId) async {
    try {
      await _getWorkspaceDoc(
        workspaceId,
      ).collection('category_planning').doc(planningId).delete();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
