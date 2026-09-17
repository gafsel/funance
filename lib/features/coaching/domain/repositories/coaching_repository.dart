import '../models/coaching_model.dart';

abstract class ICoachingRepository {
  Future<CoachingModel?> getLastInsight(String workspaceId);

  /// Um insight pelo id do documento — é assim que a rota `/coaching?id=`
  /// reabre o mesmo slide depois de um refresh.
  Future<CoachingModel?> getInsight(String workspaceId, String insightId);
  Future<CoachingModel> generateCoaching(String workspaceId);
  Future<List<CoachingModel>> getInsightsHistory(String workspaceId);
}
