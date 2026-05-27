import '../models/coaching_model.dart';
import '../models/hack_model.dart';

abstract class ICoachingRepository {
  Future<List<CoachingModel>> getInsights(String workspaceId);
  Future<void> addInsight(String workspaceId, CoachingModel insight);
  Future<List<HackModel>> getFinanceHacks(String workspaceId);
}
