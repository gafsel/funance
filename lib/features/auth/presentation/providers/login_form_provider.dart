import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/auth/presentation/providers/auth_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_provider.freezed.dart';

@freezed
sealed class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String displayName,
    @Default(false) bool isSignUp,
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(false) bool isSuccess,
  }) = _LoginFormState;
}

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final Ref ref;

  LoginFormNotifier(this.ref) : super(LoginFormState());

  void updateEmail(String value) => state = state.copyWith(email: value);
  void updatePassword(String value) => state = state.copyWith(password: value);
  void updateDisplayName(String value) => state = state.copyWith(displayName: value);
  void toggleSignUp() => state = state.copyWith(isSignUp: !state.isSignUp, errorMessage: null);

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final notifier = ref.read(authNotifierProvider.notifier);
    bool success;

    if (state.isSignUp) {
      success = await notifier.signUpWithEmailAndPassword(
        state.email.trim(),
        state.password,
        state.displayName.trim(),
      );
    } else {
      success = await notifier.signInWithEmailAndPassword(
        state.email.trim(),
        state.password,
      );
    }

    if (success) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      final authState = ref.read(authNotifierProvider);
      String error = 'Auth failed';
      authState.whenOrNull(error: (e, s) => error = e.toString());
      state = state.copyWith(isLoading: false, errorMessage: error);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        // Se success for false mas não houver erro no state, é cancelamento
        final authState = ref.read(authNotifierProvider);
        if (authState.hasError) {
           state = state.copyWith(isLoading: false, errorMessage: 'Google Sign In failed');
        } else {
           state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final loginFormProvider = StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier(ref);
});
