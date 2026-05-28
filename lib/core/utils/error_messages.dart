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
    }
  }
}
