import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import '../../domain/models/category_planning_model.dart';
import '../../domain/repositories/planning_repository.dart';

class PlanningRepositoryImpl implements IPlanningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _getWorkspaceDoc(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId);
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
}
