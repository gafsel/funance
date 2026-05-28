import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/auth/presentation/providers/auth_providers.dart';

class LoginFormState {
  final String email;
  final String password;
  final String displayName;
  final bool isSignUp;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  LoginFormState({
    this.email = '',
    this.password = '',
    this.displayName = '',
    this.isSignUp = false,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    String? displayName,
    bool? isSignUp,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      isSignUp: isSignUp ?? this.isSignUp,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
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
