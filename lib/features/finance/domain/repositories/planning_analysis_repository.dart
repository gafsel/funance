import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

abstract class IPlanningAnalysisRepository {
  /// Gera (ou retorna do cache do servidor) a análise ideal 50-30-20 do mês.
  /// O reaproveitamento do cache é decidido pelo servidor: o cliente não tem
  /// como forçar uma nova chamada à IA.
  Future<Planning503020Analysis> analyze(String workspaceId);
}
