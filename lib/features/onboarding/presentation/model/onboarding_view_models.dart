import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

part 'onboarding_view_models.freezed.dart';


@freezed
sealed class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  const factory OnboardingState({
    @Default(OnboardingSteps.type) OnboardingSteps currentStep,
    required WorkspaceModel workspace,
    @Default([]) List<String> inviteEmails,
    PlanningSuggestions? planningSuggestions,

    /// O documento do workspace já EXISTE no Firestore.
    ///
    /// Não dá para deduzir isso do id: `WorkspaceModel.empty()` já nasce com
    /// um uuid, então "tem id" não quer dizer "foi gravado". Enquanto o
    /// workspace nascia junto com a ENTRADA no passo do nome, a diferença não
    /// aparecia; agora que ele nasce ao SAIR desse passo — com o nome que o
    /// usuário digitou —, tentar atualizar antes disso seria um `update()`
    /// num documento que não existe.
    @Default(false) bool workspaceCreated,
  }) = _OnboardingState;
}
