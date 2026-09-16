import '../models/category_planning_model.dart';

/// Só a escrita usada pelo onboarding, que grava os planejamentos sugeridos
/// antes de existir um `FinanceService` com workspace.
///
/// A leitura e as demais mutações ficavam aqui para um `PlanningService` que
/// ninguém consumia — `FinanceService.getCategoryPlannings`,
/// `addCategoryPlanning` e `updateCategoryPlanning` são o caminho real.
abstract class IPlanningRepository {
  Future<void> addPlanning(String workspaceId, CategoryPlanningModel planning);
}
