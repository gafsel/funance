import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/financial_health_model.dart';
import '../../domain/models/weekly_mission_model.dart';

/// Leitura defensiva de número: o documento vem do servidor, mas um campo
/// ausente (missão criada por uma versão anterior) não pode derrubar a tela.
double? _numOrNull(Object? raw) => raw is num ? raw.toDouble() : null;

int _intOr(Object? raw, int fallback) =>
    raw is num ? raw.toInt() : fallback;

DateTime? _dateOrNull(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is DateTime) return raw;
  return null;
}

/// Uma missão semanal a partir do documento do Firestore.
///
/// Aceita `rewardXp` (o nome que `gamification.service.ts` grava hoje) e `xp`
/// (o nome do contrato do produto): o app lê os dois para não depender da
/// ordem em que servidor e cliente forem para produção.
WeeklyMissionModel weeklyMissionFromMap(String docId, Map<String, dynamic> data) {
  return WeeklyMissionModel(
    id: (data['id'] as String?) ?? docId,
    name: (data['name'] as String?) ?? '',
    type: WeeklyMissionType.parse(data['type']),
    status: WeeklyMissionStatus.parse(data['status']),
    weekId: (data['weekId'] as String?) ?? '',
    target: _intOr(data['target'], 0),
    progress: _intOr(data['progress'], 0),
    xp: _intOr(data['rewardXp'] ?? data['xp'], 0),
  );
}

/// O índice a partir do mapa `financialHealth` do workspace.
///
/// `null` quando não há score numérico: um mapa presente mas sem score é a
/// mesma coisa que índice ausente, e a tela mostra "sendo calibrada".
FinancialHealth? financialHealthFromMap(Object? raw) {
  if (raw is! Map) return null;

  final data = Map<String, dynamic>.from(raw);
  final score = _numOrNull(data['score']);
  if (score == null) return null;

  final components = data['components'];
  final componentMap = components is Map
      ? Map<String, dynamic>.from(components)
      : const <String, dynamic>{};

  return FinancialHealth(
    score: score,
    tier: FreedomTier.parse(data['tier']),
    monthKey: data['monthKey'] as String?,
    computedAt: _dateOrNull(data['computedAt']),
    components: [
      for (final component in FreedomComponent.values)
        ?_componentFromMap(component, componentMap[component.name]),
    ],
  );
}

FreedomComponentScore? _componentFromMap(
  FreedomComponent component,
  Object? raw,
) {
  if (raw is! Map) return null;

  final data = Map<String, dynamic>.from(raw);
  final score = _numOrNull(data['score']);
  if (score == null) return null;

  return FreedomComponentScore(
    component: component,
    score: score,
    months: _numOrNull(data['months']),
    rate: _numOrNull(data['rate']),
    within: _numOrNull(data['within'])?.toInt(),
    total: _numOrNull(data['total'])?.toInt(),
    delta: _numOrNull(data['delta']),
  );
}

/// Um ponto do histórico. O id do documento é a chave do mês (`YYYY-MM`) e
/// vale mais que um campo `monthKey` ausente.
FinancialHealthPoint? healthPointFromMap(
  String docId,
  Map<String, dynamic> data,
) {
  final score = _numOrNull(data['score']);
  if (score == null) return null;

  return FinancialHealthPoint(
    monthKey: (data['monthKey'] as String?) ?? docId,
    score: score,
    tier: FreedomTier.parse(data['tier']),
  );
}
