import 'package:funances/core/files/picked_document.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

part 'user_view_models.freezed.dart';

@freezed
sealed class UserProfileFormState with _$UserProfileFormState {
  const factory UserProfileFormState({
    required String id,
    required String displayName,
    required String email,
    String? photoUrl,
    PickedDocument? newPhotoFile,
    UserModel? originalUser,

    /// O avatar da Arena — **nulo enquanto não houver escolha**.
    ///
    /// Nulo cobre os dois casos em que o app não tem o que marcar: quem nunca
    /// abriu o seletor e quem tem gravado um avatar que este app não conhece.
    /// Com um padrão aqui, salvar o perfil mandava `knight` para todo mundo,
    /// e uma edição de NOME trocava o herói de quem nunca tinha tocado na
    /// grade — em um cofre de duas pessoas, isso derrubava o mago da parceira
    /// para fazer dela um segundo cavaleiro.
    HeroSkin? avatar,

    /// O documento trazia um `avatar` que não está no catálogo.
    ///
    /// Vale um aviso discreto na tela: o usuário escolheu alguma coisa um dia
    /// e a grade está sem marca nenhuma, o que sem explicação parece defeito.
    @Default(false) bool avatarUnknown,
  }) = _UserProfileFormState;

  factory UserProfileFormState.initial(UserModel user) {
    return UserProfileFormState(
      id: user.id,
      displayName: user.displayName ?? '',
      email: user.email,
      photoUrl: user.photoUrl,
      avatar: HeroSkin.tryFromName(user.avatar),
      avatarUnknown:
          user.avatar != null &&
          user.avatar!.isNotEmpty &&
          HeroSkin.tryFromName(user.avatar) == null,
      originalUser: user,
    );
  }
}
