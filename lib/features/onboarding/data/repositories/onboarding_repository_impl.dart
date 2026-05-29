import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<PlanningSuggestions> analysePlanning({
    required String workspaceId,
  }) async {
    try {
      final callable = _functions.httpsCallable('analysePlanning');

      final result = await callable.call({'workspaceId': workspaceId});

      return PlanningSuggestions.fromJson(
        (result.data as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
