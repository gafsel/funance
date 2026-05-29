import '../models/category_planning_model.dart';

abstract class IPlanningRepository {
  Stream<List<CategoryPlanningModel>> watchPlannings(String workspaceId, {required int month, required int year});
  Future<void> addPlanning(String workspaceId, CategoryPlanningModel planning);
  Future<void> updatePlanning(String workspaceId, CategoryPlanningModel planning);
  Future<void> deletePlanning(String workspaceId, String planningId);

}
