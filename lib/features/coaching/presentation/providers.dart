import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/coaching/data/repositories/coaching_repository_impl.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:funances/features/coaching/domain/services/coaching_service.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// --- Domain Providers ---
sealed class CoachingDomainProviders {
  static final repository = Provider<ICoachingRepository>((ref) {
    return CoachingRepositoryImpl();
  });

  static final service = Provider<CoachingService>((ref) {
    return CoachingService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.watch(repository),
    );
  });
}

sealed class CoachingViewProviders {
  static final lastInsight = FutureProvider<CoachingModel?>((ref) async {
    return ref.watch(CoachingDomainProviders.service).getLastInsight();
  });

  /// Um insight pelo id. A rota `/coaching?id=` passa o id e a tela carrega
  /// daqui — nada de slide inteiro viajando no `extra`.
  static final insightById = FutureProvider.autoDispose
      .family<CoachingModel?, String>((ref, id) async {
        return ref.watch(CoachingDomainProviders.service).getInsight(id);
      });

  static final insightsHistory = FutureProvider<List<CoachingModel>>((
    ref,
  ) async {
    return ref.watch(CoachingDomainProviders.service).getInsightsHistory();
  });
}
