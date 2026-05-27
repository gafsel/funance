import '../models/planning_model.dart';
import '../models/planning_month_summary_model.dart';

abstract class IPlanningRepository {
  Future<List<PlanningModel>> getPlannings(String workspaceId, {DateTime? startDate, DateTime? endDate});
  /// Stream plannings that overlap the given period [startDate, endDate].
  /// Note: Firestore only supports range filters on a single field, so the
  /// implementation must post-filter by `end_date >= startDate` when needed.
  Stream<List<PlanningModel>> watchPlannings(String workspaceId, {required DateTime startDate, required DateTime endDate});
  Future<void> addPlanning(String workspaceId, PlanningModel planning);
  Future<void> updatePlanning(String workspaceId, PlanningModel planning);
  Future<void> deletePlanning(String workspaceId, String planningId);
  Future<PlanningMonthSummaryModel?> getPlanningSummary(String workspaceId, String planningId, int year, int month);
  Stream<PlanningMonthSummaryModel?> watchPlanningSummary(String workspaceId, String planningId, int year, int month);
}
