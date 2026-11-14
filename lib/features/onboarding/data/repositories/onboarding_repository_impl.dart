import 'package:funances/firebase_ambiente.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/finance/data/models/finance_mapper.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final FirebaseFunctions _functions = funcoesDoAmbiente;

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
    } on FirebaseFunctionsException catch (e, s) {
      // Código e mensagem do servidor precisam sobreviver: é deles que a tela
      // tira o texto de cota esgotada ou payload recusado.
      throw BusinessException(
        errorCodeFor(e),
        message: e.message,
        originalError: e,
        stackTrace: s,
      );
    } catch (e, s) {
      throw BusinessException.from(e, s);
    }
  }
}
