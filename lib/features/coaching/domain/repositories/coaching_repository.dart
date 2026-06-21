import '../models/coaching_model.dart';

abstract class ICoachingRepository {
  Future<CoachingModel?> getLastInsight(String workspaceId);
  Future<CoachingModel> generateCoaching(String workspaceId);
  Future<List<CoachingModel>> getInsightsHistory(String workspaceId);
}
