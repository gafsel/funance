import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:funances/features/goal/data/repositories/goal_feasibility_repository_impl.dart';
import 'package:funances/features/goal/data/repositories/goal_milestone_repository_impl.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/models/goal_feasibility_model.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/goal/domain/services/goal_feasibility_service.dart';
import 'package:funances/features/goal/domain/services/goal_milestone_service.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/goal/domain/repositories/goal_milestone_repository.dart';
import 'package:funances/features/goal/presentation/providers/goal_feasibility_provider.dart';
import 'package:funances/features/goal/presentation/providers/goal_form_provider.dart';
import 'package:funances/features/goal/presentation/providers/goal_milestone_provider.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

sealed class GoalDomainProvider {
  static final repository = Provider<IGoalRepository>(
    (_) => GoalRepositoryImpl(),
  );

  static final service = Provider(
    (ref) => GoalService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
    ),
  );

  static final feasibilityRepository = Provider(
    (_) => GoalFeasibilityRepository(),
  );

  static final feasibilityService = Provider(
    (ref) => GoalFeasibilityService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(feasibilityRepository),
    ),
  );

  static final milestoneRepository = Provider<IGoalMilestoneRepository>(
    (ref) => GoalMilestoneRepositoryImpl(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
    ),
  );

  static final milestoneService = Provider(
    (ref) => GoalMilestoneService(repository: ref.read(milestoneRepository)),
  );
}

sealed class GoalViewProvider {
  static final form = StateNotifierProvider.autoDispose(
    (ref) =>
        GoalFormNotifier(goalService: ref.watch(GoalDomainProvider.service)),
  );

  static final goalsStream = StreamProvider<List<GoalModel>>((ref) {
    final service = ref.watch(GoalDomainProvider.service);
    return service.watchGoals();
  });

  static final goalById = StreamProvider.autoDispose.family<GoalModel?, String>(
    (ref, id) {
      final goals = ref.watch(goalsStream);
      return goals.when(
        data: (data) => Stream.value(data.where((g) => g.id == id).firstOrNull),
        error: (error, stack) => Stream.error(error, stack),
        loading: () => const Stream.empty(),
      );
    },
  );

  static final feasibility =
      AsyncNotifierProvider.autoDispose<
        GoalFeasibilityNotifier,
        GoalFeasibilityModel?
      >(GoalFeasibilityNotifier.new);

  static final milestone =
      NotifierProvider.autoDispose<GoalMilestoneNotifier, void>(
        GoalMilestoneNotifier.new,
      );
}
