enum ErrorCode {
  unknown,
  keychainError,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  networkRequestFailed,
  goalNotFound,
  goalTypeCannotBeChanged,
}

class BusinessException implements Exception {
  final ErrorCode code;
  final dynamic originalError;

  BusinessException(this.code, {this.originalError});

  @override
  String toString() => 'BusinessException: $code';
}
