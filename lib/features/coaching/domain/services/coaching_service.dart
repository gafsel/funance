import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';

class CoachingService {
  final ICoachingRepository repository;

  CoachingService(this.repository);

  Future<List<CoachingModel>> getInsights(String workspaceId) {
    return repository.getInsights(workspaceId);
  }

  Future<CoachingModel> generateCoaching(String workspaceId) {
    return repository.generateCoaching(workspaceId);
  }

  bool canActionCoach(List<CoachingModel> insights) {
    if (insights.isEmpty) return true;
    final lastInsight = insights.first;
    final diff = DateTime.now().difference(lastInsight.date);
    return diff.inDays >= 7;
  }
}
