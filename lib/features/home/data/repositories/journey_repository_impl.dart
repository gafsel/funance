import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/financial_health_model.dart';
import '../../domain/models/weekly_mission_model.dart';
import '../../domain/repositories/journey_repository.dart';
import '../models/journey_mapper.dart';

class JourneyRepositoryImpl implements IJourneyRepository {
  JourneyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId);

  @override
  Stream<List<WeeklyMissionModel>> watchWeeklyMissions(
    String workspaceId,
    String weekId,
  ) {
    if (workspaceId.isEmpty || weekId.isEmpty) {
      return Stream.value(const []);
    }

    // Filtra por `weekId` (e não por prefixo do id) porque é o campo que o
    // servidor grava e indexa — a mesma consulta do
    // `getWeeklyMissionsByWeek` no backend.
    return _workspaceDoc(workspaceId)
        .collection('weekly_missions')
        .where('weekId', isEqualTo: weekId)
        .snapshots()
        .map((snapshot) {
          final missions = snapshot.docs
              .map((doc) => weeklyMissionFromMap(doc.id, doc.data()))
              .toList();

          // Ordem estável: a do enum (consistência, disciplina, organização),
          // com os tipos desconhecidos no fim. Sem isso a lista dança a cada
          // atualização de progresso.
          missions.sort((a, b) {
            final byType = a.type.index.compareTo(b.type.index);
            return byType != 0 ? byType : a.id.compareTo(b.id);
          });

          return missions;
        });
  }

  @override
  Stream<double?> watchWeeklyXp(String workspaceId, String weekId) {
    if (workspaceId.isEmpty || weekId.isEmpty) {
      return Stream.value(null);
    }

    return _workspaceDoc(
      workspaceId,
    ).collection('weekly_xp').doc(weekId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;

      // `xp` é o nome que `FinanceService.updateWeeklyTotalXp` grava;
      // `totalXp` é o do contrato do produto. Um `as num` direto no campo
      // ausente derrubava a Jornada inteira.
      final raw = data['xp'] ?? data['totalXp'];
      return raw is num ? raw.toDouble() : null;
    });
  }

  @override
  Stream<FinancialHealth?> watchFinancialHealth(String workspaceId) {
    if (workspaceId.isEmpty) return Stream.value(null);

    return _workspaceDoc(workspaceId).snapshots().map(
      (doc) => financialHealthFromMap(doc.data()?['financialHealth']),
    );
  }

  @override
  Stream<List<FinancialHealthPoint>> watchHealthHistory(
    String workspaceId, {
    int months = 6,
  }) {
    if (workspaceId.isEmpty) return Stream.value(const []);

    // Os ids são `YYYY-MM`, então ordenar pelo id em ordem decrescente é
    // ordenar por mês — sem depender de um campo de data no documento.
    return _workspaceDoc(workspaceId)
        .collection('health_history')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(months)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ?healthPointFromMap(doc.id, doc.data()),
          ],
        );
  }
}
