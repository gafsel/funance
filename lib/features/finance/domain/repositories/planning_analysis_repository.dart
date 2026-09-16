import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

abstract class IPlanningAnalysisRepository {
  /// Gera (ou retorna do cache do servidor) a análise ideal 50-30-20 do mês.
  /// Com [force] verdadeiro, o servidor ignora o cache e rechama a IA.
  Future<Planning503020Analysis> analyze(
    String workspaceId, {
    bool force = false,
  });
}
