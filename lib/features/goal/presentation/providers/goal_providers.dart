import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  return GoalRepositoryImpl();
});

final goalsProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<GoalModel>>>((ref) {
      final repository = ref.watch(goalRepositoryProvider);
      final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
      final workspace = workspaceState.currentWorkspace;
      return GoalNotifier(repository, workspace?.id);
    });

final goalProgressProvider = Provider.family<GoalProgress, GoalModel>((
  ref,
  goal,
) {
  return goal.calculateProgress();
});

extension GoalProgressUi on GoalProgress {
  Color getStatusColor(BuildContext context) {
    switch (status) {
      case GoalStatus.onTrack:
        return AppColors.limeGreen;
      case GoalStatus.atRisk:
        return AppColors.successGold;
      case GoalStatus.behind:
      case GoalStatus.lost:
        return AppColors.coralOrange;
    }
  }

  String getStatusText(AppLocalizations l10n) {
    switch (status) {
      case GoalStatus.onTrack:
        return l10n.statusOnTrack;
      case GoalStatus.atRisk:
        return l10n.statusAtRisk;
      case GoalStatus.behind:
        return l10n.statusBehind;
      case GoalStatus.lost:
        return l10n.statusLost;
    }
  }
}

class GoalNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  final IGoalRepository _repository;
  final String? _workspaceId;

  GoalNotifier(this._repository, this._workspaceId)
    : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    if (_workspaceId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getGoals(_workspaceId);
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    if (_workspaceId == null) return;
    try {
      await _repository.addGoal(_workspaceId, goal);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    if (_workspaceId == null) return;
    try {
      await _repository.updateGoal(_workspaceId, goal);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_workspaceId == null) return;
    try {
      await _repository.deleteGoal(_workspaceId, goalId);
      await loadGoals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
