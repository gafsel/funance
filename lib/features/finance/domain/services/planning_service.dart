import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/repositories/planning_repository.dart';

class PlanningService {
  final String workspaceId;
  final IPlanningRepository repository;

  PlanningService({
    required this.workspaceId,
    required this.repository,
  });

  Future<void> create(CategoryPlanningModel planning) async {
    await repository.addPlanning(workspaceId, planning);
  }

  Future<void> update(CategoryPlanningModel planning) async {
    await repository.updatePlanning(workspaceId, planning);
  }

  Future<void> delete(String planningId) async {
    await repository.deletePlanning(workspaceId, planningId);
  }

  Stream<List<CategoryPlanningModel>> watchPlannings({required int month, required int year}) {
    return repository.watchPlannings(workspaceId, month: month, year: year);
  }
}
