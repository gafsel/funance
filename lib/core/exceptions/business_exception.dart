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
  final dynamic originalError;
  final StackTrace? stackTrace;

  BusinessException(this.code, {this.originalError, this.stackTrace}) {
    developer.log(
      'BusinessException: $code',
      name: 'funances.exception',
      error: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'BusinessException: $code';
}
