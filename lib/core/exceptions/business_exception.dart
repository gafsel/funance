import 'dart:developer' as developer;

enum ErrorCode {
  unknown,
  keychainError,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  networkRequestFailed,
  googleSignInConfigError,
  goalNotFound,
  goalTypeCannotBeChanged,
  signUpFailed,
  signInFailed,

  /// O navegador barrou a janela do Google; o app caiu para o redirect.
  signInPopupBlocked,

  /// O usuário fechou a janela do Google ou voltou atrás.
  signInCancelled,

  /// A aba está saindo para o Google via `signInWithRedirect`.
  signInRedirecting,

  /// O domínio que serve o app não está na lista de domínios autorizados do
  /// Firebase Auth. É erro de console, não do usuário.
  signInUnauthorizedDomain,

  /// O e-mail já entrou por outro provedor (senha, por exemplo).
  accountExistsWithDifferentCredential,

  /// O provedor de login está desligado no Firebase Auth.
  signInProviderDisabled,
}

class BusinessException implements Exception {
  final ErrorCode code;
  final String? message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  BusinessException(
    this.code, {
    this.message,
    this.originalError,
    this.stackTrace,
  }) {
    developer.log(
      'BusinessException: $code ${message ?? ''}',
      name: 'funances.exception',
      error: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'BusinessException: $code';
}
