import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
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

    /// O herói que o usuário escolheu para si na Arena — **nulo até ele
    /// tocar na grade**.
    ///
    /// O passo continua opcional: quem passa direto não é barrado por nada.
    /// O que mudou é o que acontece nesse caso — NADA vai para
    /// `users/{uid}`. É a ausência do campo que mantém o cavaleiro e o mago
    /// da ordem de entrada; gravar `knight` para todo mundo que pulou fazia
    /// o segundo membro de um cofre virar um cavaleiro repetido.
    HeroSkin? avatar,
  }) = _OnboardingState;
}
