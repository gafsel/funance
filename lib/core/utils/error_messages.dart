import 'package:flutter/material.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../exceptions/business_exception.dart';

extension ErrorCodeExtension on ErrorCode {
  String message(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ErrorCode.keychainError:
        return l10n.errorKeychain;
      case ErrorCode.userNotFound:
        return l10n.errorUserNotFound;
      case ErrorCode.wrongPassword:
        return l10n.errorWrongPassword;
      case ErrorCode.emailAlreadyInUse:
        return l10n.errorEmailAlreadyInUse;
      case ErrorCode.weakPassword:
        return l10n.errorWeakPassword;
      case ErrorCode.invalidEmail:
        return l10n.errorInvalidEmail;
      case ErrorCode.networkRequestFailed:
        return l10n.errorNetworkRequestFailed;
      case ErrorCode.googleSignInConfigError:
        return l10n.errorGoogleSignInConfig;
      case ErrorCode.goalNotFound:
        return l10n.errorGoalNotFound;
      case ErrorCode.goalTypeCannotBeChanged:
        return l10n.errorGoalTypeCannotBeChanged;
      case ErrorCode.unknown:
        return l10n.errorUnknown;
      case ErrorCode.offline:
        return l10n.errorOffline;
      case ErrorCode.permissionDenied:
        return l10n.errorPermissionDenied;
      case ErrorCode.quotaExhausted:
        return l10n.errorQuotaExhausted;
      case ErrorCode.notAuthenticated:
        return l10n.errorNotAuthenticated;
      case ErrorCode.notFound:
        return l10n.errorNotFound;
      case ErrorCode.timeout:
        return l10n.errorTimeout;
      case ErrorCode.signUpFailed:
        return l10n.signUpFailed;
      case ErrorCode.signInFailed:
        return l10n.signInFailed;
      case ErrorCode.signInPopupBlocked:
        return l10n.errorSignInPopupBlocked;
      case ErrorCode.signInCancelled:
        return l10n.errorSignInCancelled;
      case ErrorCode.signInRedirecting:
        return l10n.errorSignInRedirecting;
      case ErrorCode.signInUnauthorizedDomain:
        return l10n.errorSignInUnauthorizedDomain;
      case ErrorCode.accountExistsWithDifferentCredential:
        return l10n.errorAccountExistsWithDifferentCredential;
      case ErrorCode.signInProviderDisabled:
        return l10n.errorSignInProviderDisabled;
    }
  }
}

/// Mensagem para qualquer erro que chegue a uma tela.
///
/// É o que o `error:` de um `AsyncValue.when` deve mostrar. A exceção crua
/// NUNCA vai para a tela: ela diz `[cloud_firestore/unavailable] Failed to get
/// document because the client is offline`, que é informação para o
/// Crashlytics, não para quem só quer saber que está sem internet.
String errorMessageFor(BuildContext context, Object? error) =>
    errorCodeFor(error).message(context);
