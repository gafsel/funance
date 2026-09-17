import 'package:funances/core/time/product_week.dart';

import '../models/financial_health_model.dart';
import '../models/weekly_mission_model.dart';
import '../repositories/journey_repository.dart';

class JourneyService {
  JourneyService({required this.workspaceId, required this.repository});

  final String workspaceId;
  final IJourneyRepository repository;

  Stream<List<WeeklyMissionModel>> watchWeeklyMissions(String weekId) =>
      repository.watchWeeklyMissions(workspaceId, weekId);

  Stream<double?> watchWeeklyXp(String weekId) =>
      repository.watchWeeklyXp(workspaceId, weekId);

  Stream<FinancialHealth?> watchFinancialHealth() =>
      repository.watchFinancialHealth(workspaceId);

  Stream<List<FinancialHealthPoint>> watchHealthHistory({int months = 6}) =>
      repository.watchHealthHistory(workspaceId, months: months);

  /// Id da semana (`YYYY-Www`) de [reference].
  ///
  /// FALLBACK: quem manda é o `currentWeekId` gravado no workspace pelo
  /// servidor (`week_sync.service.ts`) — o app só calcula quando o campo ainda
  /// não existe no documento, para uma base anterior ao F1.9 não ficar sem
  /// missões na tela.
  ///
  /// A fórmula mora em [ProductWeek], que é a definição única do cliente.
  static String weekIdFor(DateTime reference) => ProductWeek.idOf(reference);
}
