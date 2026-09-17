import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/features/goal/data/models/goal_mapper.dart';

import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';


/// Monta o que o cliente pode gravar numa meta.
///
/// Dois campos NÃO passam por aqui, e não é convenção: as rules os negam.
/// `outcome`/`completedAt`/`failedAt` são o veredito do servidor — enviar
/// qualquer um deles, mesmo `null`, derruba a gravação inteira. E
/// `currentAmount` é o progresso que o servidor calcula (pagamentos, realizado
/// da categoria, saldo do cofrinho, amortização da dívida): na criação vai
/// sempre zero, porque as rules exigem o campo; na edição não vai, porque o
/// `update()` só toca o que recebe e reenviar o número que a tela leu ao abrir
/// faria uma simples troca de nome apagar o progresso do dia.
@visibleForTesting
Map<String, dynamic> buildGoalWriteData(GoalModel goal, {required bool creation}) {
  final data = goal.toJson();
  data.remove('id');
  data.removeWhere(
    (key, _) => const {
      'outcome',
      'completedAt',
      'failedAt',
      'currentAmount',
    }.contains(key),
  );
  if (creation) data['currentAmount'] = 0.0;
  data['deadline'] = Timestamp.fromDate(goal.deadline);
  data['startDate'] = Timestamp.fromDate(goal.startDate);
  return data;
}

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
      throw BusinessException.from(e, s);
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
      final data = buildGoalWriteData(goal, creation: true);
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
      throw BusinessException.from(e, s);
    }
  }

  @override
  Future<WriteOutcome> updateGoal(String workspaceId, GoalModel goal) async {
    try {
      final data = buildGoalWriteData(goal, creation: false);
      return await settleWrite(
        _getCollection(workspaceId).doc(goal.id).update(data),
        entity: WriteEntity.goal,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
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
      throw BusinessException.from(e, s);
    }
  }
}
