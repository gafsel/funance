import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';

class CoachingService {
  final String workspaceId;
  final ICoachingRepository repository;

  CoachingService({required this.workspaceId, required this.repository});

  Future<CoachingModel?> getLastInsight() {
    return repository.getLastInsight(workspaceId);
  }

  Future<CoachingModel?> getInsight(String insightId) {
    return repository.getInsight(workspaceId, insightId);
  }

  Future<CoachingModel> generateCoaching() {
    return repository.generateCoaching(workspaceId);
  }

  Future<List<CoachingModel>> getInsightsHistory() {
    return repository.getInsightsHistory(workspaceId);
  }
}
