import 'package:funances/core/files/picked_document.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
  }) = _UserProfileFormState;

  factory UserProfileFormState.initial(UserModel user) {
    return UserProfileFormState(
      id: user.id,
      displayName: user.displayName ?? '',
      email: user.email,
      photoUrl: user.photoUrl,
      originalUser: user,
    );
  }
}
