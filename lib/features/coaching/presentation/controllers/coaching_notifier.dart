import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/services/coaching_service.dart';
import 'package:funances/features/coaching/presentation/models/coaching_view_state.dart';
import 'package:funances/features/coaching/presentation/providers/coaching_providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class CoachingNotifier extends StateNotifier<CoachingState> {
  final CoachingService _service;
  final Ref _ref;

  CoachingNotifier(this._service, this._ref) : super(CoachingState());

  void setCoaching(CoachingModel coaching) {
    state = state.copyWith(latestCoaching: coaching, error: null);
  }

  Future<CoachingModel?> generateCoaching() async {
    final workspace = _ref.read(WorkspaceViewProviders.workspace).currentWorkspace;
    if (workspace == null) return null;

    try {
      final coaching = await _service.generateCoaching(workspace.id);
      state = CoachingState(latestCoaching: coaching);
      _ref.invalidate(coachingInsightsProvider);
      return coaching;
    } catch (e) {
      state = CoachingState(error: e.toString());
      rethrow;
    }
  }
}
