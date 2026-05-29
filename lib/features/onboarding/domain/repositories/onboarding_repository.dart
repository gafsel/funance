import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';

abstract class OnboardingRepository {
  Future<PlanningSuggestions> analysePlanning({
    required String workspaceId,
  });

}
