import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

enum ErrorCode {
  unknown,

  /// Sem rede, ou o Firestore não conseguiu falar com o servidor
  /// (`unavailable`). O dado pode estar no cache; o que falhou foi ir buscar
  /// o resto. É o erro mais comum do app e o único em que "tentar de novo"
  /// costuma bastar.
  offline,

  /// As security rules recusaram a leitura ou a escrita
  /// (`permission-denied`). Tentar de novo não resolve: ou o usuário saiu do
  /// workspace, ou a tela pediu algo que não é dela.
  permissionDenied,

  /// Cota estourada (`resource-exhausted`): o limite diário de IA, ou o teto
  /// do próprio Firestore.
  quotaExhausted,

  /// A sessão expirou ou nunca existiu (`unauthenticated`).
  notAuthenticated,

  /// O documento pedido não existe mais (`not-found`).
  notFound,

  /// A operação passou do tempo (`deadline-exceeded`). Diferente de
  /// [offline]: houve conexão, o servidor é que não respondeu a tempo.
  timeout,
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

extension ErrorCodeSeverity on ErrorCode {
  /// Códigos que NÃO são falha.
  ///
  /// Fechar a janela do Google é uma decisão do usuário, e estar a caminho do
  /// Google é o app funcionando. Os dois subiam como exceção e viravam
  /// snackbar vermelha de erro, dizendo ao usuário que algo deu errado
  /// justamente quando nada tinha dado.
  bool get isInformational =>
      this == ErrorCode.signInCancelled || this == ErrorCode.signInRedirecting;
}

/// Traduz uma falha do Firebase para um código do app.
///
/// Antes, TODA falha de repositório virava `ErrorCode.unknown` — quase três em
/// cada quatro erros do app diziam apenas "ocorreu um erro inesperado", o que
/// é exatamente a mensagem errada para o caso mais comum de todos: o usuário
/// está sem rede. Os seis códigos abaixo cobrem o que o Firestore, o Functions
/// e o Auth realmente devolvem em produção; o resto continua `unknown`, e
/// continua indo para o Crashlytics.
ErrorCode errorCodeFor(Object? error) {
  if (error is BusinessException) return error.code;

  final String? code = switch (error) {
    FirebaseException(code: final c) => c,
    _ => null,
  };
  if (code == null) return ErrorCode.unknown;

  // A web devolve `internal` sem mensagem quando o `fetch` do callable nem
  // sai — ver `isOfflineCallable`.
  if (error is FirebaseFunctionsException &&
      code == 'internal' &&
      (error.message?.trim().isEmpty ?? true)) {
    return ErrorCode.offline;
  }

  return switch (code) {
    'unavailable' || 'network-request-failed' => ErrorCode.offline,
    'permission-denied' || 'permission_denied' => ErrorCode.permissionDenied,
    'resource-exhausted' => ErrorCode.quotaExhausted,
    'unauthenticated' => ErrorCode.notAuthenticated,
    'not-found' => ErrorCode.notFound,
    'deadline-exceeded' => ErrorCode.timeout,
    _ => ErrorCode.unknown,
  };
}

/// true quando o erro é falta de rede — o único caso em que a tela pode
/// prometer que tentar de novo tem chance de funcionar sozinho.
bool isOfflineError(Object? error) => errorCodeFor(error) == ErrorCode.offline;

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

  /// Classifica o erro original em vez de chamar tudo de `unknown`.
  ///
  /// É o construtor dos `catch` de repositório: o que chega ali é quase sempre
  /// uma `FirebaseException`, e o código dela é a única informação que permite
  /// à tela dizer "você está sem internet" em vez de "erro inesperado".
  factory BusinessException.from(Object error, StackTrace? stackTrace) {
    if (error is BusinessException) return error;

    return BusinessException(
      errorCodeFor(error),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'BusinessException: $code';
}
