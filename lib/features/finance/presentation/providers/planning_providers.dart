import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/finance/domain/models/planning_month_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/planning_repository.dart';
import 'package:funances/features/finance/data/repositories/planning_repository_impl.dart';

final planningRepositoryProvider = Provider<IPlanningRepository>((ref) {
  return PlanningRepositoryImpl();
});

final overviewDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final planningsProvider = StreamProvider<List<PlanningModel>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;
  final overviewDate = ref.watch(overviewDateProvider);

  if (workspace == null) {
    return Stream.value([]);
  }

  return repository.watchPlannings(
    workspace.id,
    startDate: DateTime(overviewDate.year, overviewDate.month, 1),
    endDate: DateTime(overviewDate.year, overviewDate.month + 1, 0),
  );
});

class PlanningNotifier extends StateNotifier<AsyncValue<void>> {
  final IPlanningRepository _repository;
  final String? _workspaceId;
  final Ref _ref;

  PlanningNotifier(this._repository, this._workspaceId, this._ref) : super(const AsyncValue.data(null));

  Future<void> addPlanning(PlanningModel planning) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addPlanning(_workspaceId!, planning));
    _ref.invalidate(planningsForPeriodProvider);
  }

  Future<void> updatePlanning(PlanningModel planning) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePlanning(_workspaceId!, planning));
    _ref.invalidate(planningsForPeriodProvider);
  }

  Future<void> deletePlanning(String planningId) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePlanning(_workspaceId!, planningId));
    _ref.invalidate(planningsForPeriodProvider);
  }
}

final planningSummaryProvider = StreamProvider.family<PlanningMonthSummaryModel?, String>((ref, planningId) {
  final repository = ref.watch(planningRepositoryProvider);
  final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;
  final date = ref.watch(overviewDateProvider);

  if (workspace == null) return Stream.value(null);

  return repository.watchPlanningSummary(
    workspace.id,
    planningId,
    date.year,
    date.month,
  );
});

final planningNotifierProvider = StateNotifierProvider<PlanningNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;
  return PlanningNotifier(repository, workspaceId, ref);
});
