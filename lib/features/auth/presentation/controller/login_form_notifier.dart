import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/auth/domain/services/auth_service.dart';
import 'package:funances/features/auth/presentation/model/auth_view_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

class LoginFormNotifier extends FormNotifier<LoginFormState, UserModel> {
  final AuthService service;

  LoginFormNotifier({required this.service}) : super(LoginFormState());

  void updateEmail(String value) => state = state.copyWith(email: value);
  void updatePassword(String value) => state = state.copyWith(password: value);
  void updateDisplayName(String value) =>
      state = state.copyWith(displayName: value);
  void toggleSignUp() => state = state.copyWith(isSignUp: !state.isSignUp);

  @override
  Future<UserModel> submit() async {
    if (state.isSignUp) {
      return await service.signUpWithEmailAndPassword(
        state.email.trim(),
        state.password,
        state.displayName.trim(),
      );
    } else {
      return await service.signInWithEmailAndPassword(
        state.email.trim(),
        state.password,
      );
    }
  }

  Future<UserModel> signInWithGoogle() async {
    return await service.signInWithGoogle();
  }
}
