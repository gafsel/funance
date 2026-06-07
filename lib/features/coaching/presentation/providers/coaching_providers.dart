import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/coaching/data/repositories/coaching_repository_impl.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:funances/features/coaching/domain/services/coaching_service.dart';
import 'package:funances/features/coaching/presentation/controllers/coaching_notifier.dart';
import 'package:funances/features/coaching/presentation/models/coaching_view_state.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// --- Domain Providers ---

final coachingRepositoryProvider = Provider<ICoachingRepository>((ref) {
  return CoachingRepositoryImpl();
});

final coachingServiceProvider = Provider<CoachingService>((ref) {
  final repository = ref.watch(coachingRepositoryProvider);
  return CoachingService(repository);
});

final coachingInsightsProvider =
    FutureProvider<List<CoachingModel>>((ref) async {
      final workspace =
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace;
      if (workspace == null) return [];

      final service = ref.watch(coachingServiceProvider);
      return service.getInsights(workspace.id);
    });

/// --- View Providers ---

class CoachingViewProviders {
  static final coachingNotifier =
      StateNotifierProvider<CoachingNotifier, CoachingState>((ref) {
        final service = ref.watch(coachingServiceProvider);
        return CoachingNotifier(service, ref);
      });

  static final canActionCoach = Provider<bool>((ref) {
    final insights = ref.watch(coachingInsightsProvider).valueOrNull ?? [];
    final service = ref.watch(coachingServiceProvider);
    return service.canActionCoach(insights);
  });
}
