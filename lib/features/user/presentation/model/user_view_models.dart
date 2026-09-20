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

    /// O avatar da Arena, já RESOLVIDO: quem nunca escolheu abre a tela com o
    /// cavaleiro marcado em vez de uma grade sem nada selecionado. O padrão
    /// pré-escolhido é o que permite salvar o perfil sem passar pelo seletor.
    @Default(HeroSkin.knight) HeroSkin avatar,
  }) = _UserProfileFormState;

  factory UserProfileFormState.initial(UserModel user) {
    return UserProfileFormState(
      id: user.id,
      displayName: user.displayName ?? '',
      email: user.email,
      photoUrl: user.photoUrl,
      avatar: HeroSkin.fromName(user.avatar),
      originalUser: user,
    );
  }
}
