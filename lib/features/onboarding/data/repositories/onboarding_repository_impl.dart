import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/finance/data/models/finance_mapper.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<PlanningSuggestions> analysePlanning({
    required String workspaceId,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'analysePlanning',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      final result = await callable.call({'workspaceId': workspaceId});

      return FinanceMapper.toPlanningSuggestions(result.data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
