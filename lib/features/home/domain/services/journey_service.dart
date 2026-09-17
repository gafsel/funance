import 'package:funances/core/utils/date_extension.dart';

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
  /// A fórmula é a do servidor (`core/utils/week.utils.ts`): semana começa no
  /// DOMINGO, o ano é o do domingo que a inicia e o número é
  /// `floor(dia_do_ano_do_domingo / 7) + 1`. A subtração dos dias é feita em
  /// UTC de propósito: `difference().inDays` em horário local perde (ou ganha)
  /// uma hora na semana da virada do horário de verão e pode mudar o número da
  /// semana.
  static String weekIdFor(DateTime reference) {
    final start = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).addCalendarDays(-(reference.weekday % 7));

    final dayOfYear = DateTime.utc(start.year, start.month, start.day)
        .difference(DateTime.utc(start.year, 1, 1))
        .inDays;

    final week = (dayOfYear / 7).floor() + 1;

    return '${start.year}-W${week.toString().padLeft(2, '0')}';
  }
}
