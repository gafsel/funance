
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_view_model.freezed.dart';

@freezed
sealed class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String displayName,
    @Default(false) bool isSignUp,
  }) = _LoginFormState;
}
