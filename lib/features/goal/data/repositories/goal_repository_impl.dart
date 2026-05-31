import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/goal/data/models/goal_mapper.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class GoalRepositoryImpl implements IGoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('goals');
  }

  @override
  Future<List<GoalModel>> getGoals(String workspaceId) async {
    try {
      final snapshot = await _getCollection(
        workspaceId,
      ).where('isDeleted', isEqualTo: false).get();
      return snapshot.docs.map((doc) => doc.toGoalModel()).toList();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<GoalModel> addGoal(String workspaceId, GoalModel goal) async {
    try {
      final data = goal.toJson();
      data.remove('id');
      data['deadline'] = Timestamp.fromDate(goal.deadline);
      data['startDate'] = Timestamp.fromDate(goal.startDate);
      final doc = await _getCollection(workspaceId).add(data);
      return goal.copyWith(id: goal.id);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateGoal(String workspaceId, GoalModel goal) async {
    try {
      final data = goal.toJson();
      data.remove('id');
      data['deadline'] = Timestamp.fromDate(goal.deadline);
      data['startDate'] = Timestamp.fromDate(goal.startDate);
      await _getCollection(workspaceId).doc(goal.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteGoal(String workspaceId, String goalId) async {
    try {
      await _getCollection(workspaceId).doc(goalId).update({'isDeleted': true});
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
