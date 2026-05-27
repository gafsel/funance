import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements IGoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId).collection('goals');
  }

  @override
  Future<List<GoalModel>> getGoals(String workspaceId) async {
    final snapshot = await _getCollection(workspaceId)
        .where('isDeleted', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => GoalModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> addGoal(String workspaceId, GoalModel goal) async {
    final data = goal.toJson();
    data.remove('id');
    data['deadline'] = Timestamp.fromDate(goal.deadline);
    await _getCollection(workspaceId).add(data);
  }

  @override
  Future<void> updateGoal(String workspaceId, GoalModel goal) async {
    final data = goal.toJson();
    data.remove('id');
    data['deadline'] = Timestamp.fromDate(goal.deadline);
    await _getCollection(workspaceId).doc(goal.id).update(data);
  }

  @override
  Future<void> deleteGoal(String workspaceId, String goalId) async {
    await _getCollection(workspaceId).doc(goalId).update({'isDeleted': true});
  }
}
