import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';
import 'package:funances/features/finance/domain/repositories/planning_analysis_repository.dart';

class PlanningAnalysisService {
  final String workspaceId;
  final IPlanningAnalysisRepository repository;

  PlanningAnalysisService({
    required this.workspaceId,
    required this.repository,
  });

  Future<Planning503020Analysis> analyze({bool force = false}) {
    return repository.analyze(workspaceId, force: force);
  }
}
