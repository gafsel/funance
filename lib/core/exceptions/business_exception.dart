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
