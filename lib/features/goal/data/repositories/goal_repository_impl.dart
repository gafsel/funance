import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/features/goal/data/models/goal_mapper.dart';

import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';

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
  Stream<List<GoalModel>> watchGoals(String workspaceId) {
    return _getCollection(workspaceId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.toGoalModel()).toList(),
        );
  }

  @override
  Future<Written<GoalModel>> addGoal(String workspaceId, GoalModel goal) async {
    try {
      final data = goal.toJson();
      data.remove('id');
      // O DESFECHO é do servidor: as rules negam a escrita destes campos pelo
      // cliente, e enviar qualquer um deles (mesmo como null) derrubaria a
      // gravação inteira.
      data.removeWhere(
        (key, _) => const {'outcome', 'completedAt', 'failedAt'}.contains(key),
      );
      data['deadline'] = Timestamp.fromDate(goal.deadline);
      data['startDate'] = Timestamp.fromDate(goal.startDate);
      // O id real é o gerado pelo Firestore. Devolver `goal.id` (vazio na
      // criação) fazia o segundo salvamento do mesmo formulário cair num
      // update com doc("").
      // `doc()` gera o id localmente; o `add()` que havia aqui só
      // devolvia a referência depois da resposta do servidor, e offline
      // isso nunca chegava.
      final doc = _getCollection(workspaceId).doc();
      final WriteOutcome outcome = await settleWrite(
        doc.set(data),
        entity: WriteEntity.goal,
      );

      return (value: goal.copyWith(id: doc.id), outcome: outcome);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<WriteOutcome> updateGoal(String workspaceId, GoalModel goal) async {
    try {
      final data = goal.toJson();
      data.remove('id');
      // Ver `addGoal`: o desfecho pertence ao servidor.
      data.removeWhere(
        (key, _) => const {'outcome', 'completedAt', 'failedAt'}.contains(key),
      );
      data['deadline'] = Timestamp.fromDate(goal.deadline);
      data['startDate'] = Timestamp.fromDate(goal.startDate);
      return await settleWrite(
        _getCollection(workspaceId).doc(goal.id).update(data),
        entity: WriteEntity.goal,
      );
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
      await settleWrite(
        _getCollection(workspaceId).doc(goalId).update({'isDeleted': true}),
        entity: WriteEntity.goal,
      );
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
