import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/goal/domain/models/goal_feasibility_model.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';

class GoalFeasibilityNotifier
    extends AutoDisposeAsyncNotifier<GoalFeasibilityModel?> {
  @override
  FutureOr<GoalFeasibilityModel?> build() {
    return null;
  }

  Future<GoalFeasibilityModel> analyze(GoalFormState formState) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(GoalDomainProvider.feasibilityService);
      final result = await service.analyze(formState);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
