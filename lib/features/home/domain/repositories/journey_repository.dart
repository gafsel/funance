import '../models/financial_health_model.dart';
import '../models/weekly_mission_model.dart';

/// Leitura do que o SERVIDOR já calculou para a Jornada.
///
/// Tudo aqui é somente leitura de propósito: missões semanais, XP da semana e
/// a Bússola da Liberdade são escritos por Cloud Functions. O app não tem
/// nenhuma fórmula própria para nenhum deles.
abstract class IJourneyRepository {
  /// As missões da semana [weekId] (`weekly_missions`, ids `{weekId}_{type}`).
  ///
  /// Lista vazia quando o servidor ainda não gerou as missões da semana — é o
  /// estado normal no domingo de manhã e para um workspace recém-criado.
  Stream<List<WeeklyMissionModel>> watchWeeklyMissions(
    String workspaceId,
    String weekId,
  );

  /// XP acumulado na semana [weekId] (`weekly_xp/{weekId}`).
  ///
  /// `null` quando o documento não existe: é diferente de zero XP, e a barra
  /// mostra "sem XP ainda" em vez de um zero que parece derrota.
  Stream<double?> watchWeeklyXp(String workspaceId, String weekId);

  /// `workspaces/{w}.financialHealth`. `null` enquanto o servidor não
  /// publicou o índice.
  Stream<FinancialHealth?> watchFinancialHealth(String workspaceId);

  /// Histórico mensal do índice, do mês mais recente para o mais antigo.
  Stream<List<FinancialHealthPoint>> watchHealthHistory(
    String workspaceId, {
    int months,
  });
}
